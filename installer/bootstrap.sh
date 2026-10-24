#!/usr/bin/env bash
# pixeldots bootstrapper: builds the installer (C++/SDL2) from the flake, runs it inside `cage`
# (a kiosk Wayland compositor), and when it finishes starts Hyprland.
#
#   bash installer/bootstrap.sh [--local] [--software] [--dry-run]
#   curl -fsSL https://raw.githubusercontent.com/pixeldotting/pixeldots/main/installer/bootstrap.sh | bash
#
#   --local     the generated system flake uses this checkout instead of github:pixeldotting/pixeldots
#   --software  software rendering (virtual machines without a GPU)
#   --dry-run   only generate the flake into ~/.local/state/pixeldots-installer/out, change nothing
#
# Run it from a real console (TTY) as a normal user with sudo, on an installed NixOS system.
set -euo pipefail

REPO_URL="https://github.com/pixeldotting/pixeldots"
NIXF=(--extra-experimental-features "nix-command flakes")
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/pixeldots-installer"
LOCAL=0 SOFTWARE=0 DRY=0

say() { printf '\033[1;35m::\033[0m %s\n' "$*"; }
die() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

for a in "$@"; do
    case "$a" in
        --local) LOCAL=1 ;;
        --software) SOFTWARE=1 ;;
        --dry-run) DRY=1 ;;
        -h | --help) sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown option: $a" ;;
    esac
done

[ "$(id -u)" -ne 0 ] || die "run as your normal user (with sudo), not as root"
[ -e /etc/NIXOS ] || die "this is not NixOS"
command -v nix > /dev/null || die "nix not found"
command -v sudo > /dev/null || die "sudo not found (add your user to wheel and enable security.sudo)"
mkdir -p "$STATE"

# 1. Checkout: use the one this script lives in, otherwise clone to ~/pixeldots.
SELF="${BASH_SOURCE[0]:-}"
if [ -n "$SELF" ] && [ -f "$(dirname "$SELF")/../flake.nix" ]; then
    REPO="$(cd "$(dirname "$SELF")/.." && pwd)"
else
    REPO="$HOME/pixeldots"
    if [ -d "$REPO/.git" ]; then
        say "Updating $REPO"
        nix "${NIXF[@]}" shell nixpkgs#git -c git -C "$REPO" pull --ff-only || say "could not update, using the existing checkout"
    else
        say "Cloning $REPO_URL into $REPO"
        nix "${NIXF[@]}" shell nixpkgs#git -c git clone "$REPO_URL" "$REPO"
    fi
fi
say "Checkout: $REPO"

# 2. sudo once, up front: the installer has no way to type a password into a terminal.
if [ "$DRY" != 1 ]; then
    say "sudo is needed to write /etc/nixos/pixeldots and run nixos-rebuild"
    sudo -v
    ( while kill -0 "$$" 2> /dev/null; do sudo -n true 2> /dev/null || exit; sleep 45; done ) &
    KEEPALIVE=$!
    trap 'kill "$KEEPALIVE" 2> /dev/null || true' EXIT
fi

# 3. Build the installer (this downloads SDL2, wayland, cage and compiles the C++ code).
if [ -d "$REPO/.git" ]; then SRC="git+file://$REPO"; else SRC="path:$REPO"; fi
say "Building the installer"
SESSION="$(nix "${NIXF[@]}" build "$SRC#pixeldots-installer-session" --no-link --print-out-paths)/bin/pixeldots-installer-session"
[ -x "$SESSION" ] || die "build produced no $SESSION"

# 4. Run it under cage.
export PD_APPLY="$REPO/installer/apply.sh"
export PD_REPO="$REPO"
export PD_DEFAULT_USER="$USER"
export PD_LOG="$STATE/install.log"
export PD_STATE="$STATE"
export XKB_DEFAULT_LAYOUT=us # passwords are typed with the US layout in the installer
[ "$LOCAL" = 1 ] && export PD_FLAKE_URL="$SRC"
if [ "$SOFTWARE" = 1 ]; then
    export WLR_RENDERER=pixman WLR_NO_HARDWARE_CURSORS=1 LIBGL_ALWAYS_SOFTWARE=1
fi
if [ "$DRY" = 1 ]; then
    export PD_DRY_RUN=1 PD_OUT_DIR="$STATE/out"
fi

say "Starting the installer (log: $PD_LOG)"
rc=0
"$SESSION" "$REPO/installer/data" || rc=$?
[ "$rc" -eq 0 ] || die "installer exited with code $rc (see $PD_LOG)"
[ "$DRY" != 1 ] || { say "Dry run done: generated files are in $PD_OUT_DIR"; exit 0; }

# 5. Leave cage, start the new desktop. A login shell is emulated so the new system's
# environment (session variables, PATH) is loaded instead of the old one.
HYPR=/run/current-system/sw/bin/Hyprland
[ -x "$HYPR" ] || die "$HYPR not found: the system switch did not complete"
if [ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]; then
    say "Installed. Already inside a graphical session: log out and log in again to get Hyprland."
    exit 0
fi
say "Starting Hyprland"
exec env -u __NIXOS_SET_ENVIRONMENT_DONE bash -l -c "exec $HYPR"
