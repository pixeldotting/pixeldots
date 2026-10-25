#!/usr/bin/env bash
# install-iso.sh: backend of the ISO installer. Runs as root (the UI starts it through sudo).
#
# Input (set by the UI): PD_LOCALE PD_LAYOUT PD_TZ PD_HOSTNAME PD_USER PD_APPS PD_MODE PD_VARIANT PD_AUTOSTART
#                        PD_DISK (kernel name, e.g. sda) PD_DISK_MODEL PD_DISK_SIZE (bytes) PD_ERASE_CONFIRM (= PD_DISK)
#                        first line of stdin = the new user's password (never argv, env, a file or the log)
# Optional / tests:      PD_DATA_DIR  directory with apps.tsv        PD_DISKS_CMD  the pixeldots-disks program
#                        PD_MNT       mount point (default /mnt)      PD_ETC_DIR    where /etc/pixeldots lives
#                        PD_DRY_RUN=1 validate, generate the config into PD_OUT_DIR, touch no disk, run nothing destructive
#                        PD_SYS_DIR   fake /sys for the tests         PD_LOG        log file (default /tmp/pixeldots-install.log)
#                        PD_DEV_DIR   device directory (default /dev); the tests point it at a temp dir of plain files
#
# Order matters: (1) validate everything and hash the password, (2) generate the Nix files in a temp dir,
# (3) re-check the disk against pixeldots-disks, and only then (4) partition, format, mount, nixos-install.
# Nothing is substituted into Nix before it passed a regex, and nothing destructive runs before (1)-(3) succeeded.
#
# Output: lines "@@ <percent> <message>" drive the UI progress bar; the rest is shown as a log.
# Every output line goes through a filter that hides $6$... hashes, as a second line of defence.
set -euo pipefail
shopt -u patsub_replacement 2> /dev/null || true

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA="${PD_DATA_DIR:-$HERE/data}"
ETC="${PD_ETC_DIR:-/etc/pixeldots}"
MNT="${PD_MNT:-/mnt}"
DRY="${PD_DRY_RUN:-0}"
DISKS_CMD="${PD_DISKS_CMD:-pixeldots-disks}"
LOG="${PD_LOG:-/tmp/pixeldots-install.log}"
export PATH="$PATH:/run/current-system/sw/bin"

exec > >(sed -u -E 's/\$6\$[^ "'"'"']*/[hash hidden]/g' | tee -a "$LOG") 2>&1

progress() { echo "@@ $1 $2"; }
die() { echo "error: $*" >&2; exit 1; }
re() { [[ $2 =~ $1 ]] || die "invalid $3"; }  # value deliberately not echoed
run() { echo "+ $*"; if [ "$DRY" = 1 ]; then return 0; fi; "$@"; }

IFS= read -r PW || PW=""

# ───────────────────────── 1. validate ─────────────────────────
progress 2 "Checking answers"
for v in PD_LOCALE PD_LAYOUT PD_TZ PD_HOSTNAME PD_USER PD_MODE PD_VARIANT PD_AUTOSTART PD_DISK PD_DISK_MODEL PD_DISK_SIZE PD_ERASE_CONFIRM; do
    [ -n "${!v:-}" ] || die "missing input $v"
done
PD_APPS="${PD_APPS:-}"
re '^[A-Za-z]{2,3}_[A-Za-z]{2}\.UTF-8$' "$PD_LOCALE" "locale"
re '^[a-z]{2,3}(,[a-z]{2,3})*$' "$PD_LAYOUT" "keyboard layout"
re '^[A-Za-z0-9_+/-]+$' "$PD_TZ" "time zone"
re '^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$' "$PD_HOSTNAME" "host name"
re '^[a-z_][a-z0-9_-]{0,31}$' "$PD_USER" "user name"
[ "$PD_USER" != root ] || die "invalid user name"
re '^(dark|light)$' "$PD_MODE" "mode"
re '^scheme-[a-z-]+$' "$PD_VARIANT" "palette style"
re '^[01]$' "$PD_AUTOSTART" "autostart"
re '^[a-z0-9]+$' "$PD_DISK" "disk"
re '^[0-9]+$' "$PD_DISK_SIZE" "disk size"
re '^[A-Za-z0-9 ._()/+-]*$' "$PD_DISK_MODEL" "disk model"
[ "$PD_ERASE_CONFIRM" = "$PD_DISK" ] || die "erasing $PD_DISK was not confirmed"
LC_ALL=C re '^[ -~]{6,64}$' "$PW" "password (6 to 64 printable ASCII characters)"

APPS_NIX="" UNFREE=0
IFS=',' read -ra ids <<< "$PD_APPS"
for id in "${ids[@]}"; do
    [ -n "$id" ] || continue
    re '^[a-z0-9_-]+$' "$id" "app id"
    row="$(grep -E "^${id}\|" "$DATA/apps.tsv" || true)"
    [ -n "$row" ] || die "unknown app"
    IFS='|' read -r _ _ attr unfree _ <<< "$row"
    re '^[A-Za-z0-9_-]+$' "$attr" "nixpkgs attribute"
    APPS_NIX+="$attr "
    if [ "$unfree" = 1 ]; then UNFREE=1; fi
done

STATE_VERSION="$(cat "$ETC/state-version" 2> /dev/null || true)"
re '^[0-9]{2}\.[0-9]{2}$' "$STATE_VERSION" "state version ($ETC/state-version)"
FLAKE_URL="$(cat "$ETC/flake-url" 2> /dev/null || true)"
re '^github:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(/[0-9a-f]{40})?$' "$FLAKE_URL" "flake url ($ETC/flake-url)"
case "$(uname -m)" in x86_64) SYSTEM=x86_64-linux ;; aarch64) SYSTEM=aarch64-linux ;; *) die "unsupported architecture" ;; esac

if [ "$DRY" != 1 ]; then
    [ "$(id -u)" -eq 0 ] || die "must run as root"
    for t in parted mkfs.fat mkfs.ext4 wipefs mount umount nixos-generate-config nixos-install curl udevadm; do
        command -v "$t" > /dev/null || die "missing tool: $t"
    done
fi

# hash the password now: if hashing fails nothing has been touched yet. The plaintext is dropped right after.
progress 4 "Hashing the password"
if command -v mkpasswd > /dev/null; then
    HASH="$(printf '%s' "$PW" | mkpasswd -m sha-512 -s)"
elif command -v openssl > /dev/null; then
    HASH="$(printf '%s\n' "$PW" | openssl passwd -6 -stdin)"
else
    die "neither mkpasswd nor openssl found"
fi
PW=""
re '^\$6\$[./0-9A-Za-z$]+$' "$HASH" "password hash"

# ───────────────────────── 2. generate the config (temp dir) ─────────────────────────
progress 6 "Preparing the system configuration"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

XKBOPTS=""
if [[ $PD_LAYOUT == *,* ]]; then XKBOPTS="grp:alt_shift_toggle"; fi
UNFREE_NIX=""
if [ "$UNFREE" = 1 ]; then UNFREE_NIX='  nixpkgs.config.allowUnfree = true;'; fi
AUTOSTART_NIX=""
if [ "$PD_AUTOSTART" = 1 ]; then
    AUTOSTART_NIX='  programs.fish.loginShellInit = '"''"'
    if test -z "$WAYLAND_DISPLAY"; and test "$XDG_VTNR" = 1
      exec Hyprland
    end
  '"''"';'
fi

cat > "$TMP/flake.nix" << 'NIX'
# Generated by the pixeldots installer.
{
  description = "pixeldots system (generated by the pixeldots installer)";

  inputs = {
    pixeldots.url = "@URL@";
    nixpkgs.follows = "pixeldots/nixpkgs";
    home-manager.follows = "pixeldots/home-manager";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      pixeldots,
      ...
    }:
    {
      nixosConfigurations."@HOST@" = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit pixeldots; };
        modules = [
          ./hardware-configuration.nix
          pixeldots.nixosModules.default
          home-manager.nixosModules.home-manager
          ./pixeldots-local.nix
        ];
      };
    };
}
NIX

cat > "$TMP/pixeldots-local.nix" << 'NIX'
# Generated by the pixeldots installer (your answers). Edit freely; the installer does not run again.
{
  config,
  lib,
  pkgs,
  pixeldots,
  ...
}:
{
  system.stateVersion = "@STATE@";
  nixpkgs.hostPlatform = lib.mkDefault "@SYSTEM@";
@UNFREE@
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "@HOST@";
  time.timeZone = "@TZ@";
  i18n.defaultLocale = "@LOCALE@";
  services.xserver.xkb.layout = "@LAYOUT@";
  services.xserver.xkb.options = "@XKBOPTS@";
  console.useXkbConfig = true;

  users.users."@USER@" = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
    ];
    shell = pkgs.fish;
    hashedPassword = "@HASH@";
  };
  programs.fish.enable = true;
@AUTOSTART@

  environment.systemPackages = with pkgs; [ @APPS@];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "pixeldots-bak";
    users."@USER@" =
      { lib, ... }:
      {
        imports = [ pixeldots.homeManagerModules.default ];
        programs.material.enable = true;
        home.stateVersion = config.system.stateVersion;

        # keyboard layout for Hyprland (the config reads an optional user.lua)
        xdg.configFile."hypr/user.lua".text = ''
          hl.config({ input = { kb_layout = "@LAYOUT@", kb_options = "@XKBOPTS@" } })
        '';

        # first colour scheme: the mode and palette picked in the installer (only if no state exists yet)
        home.activation.pixeldotsLook = lib.hm.dag.entryBefore [ "materialTheme" ] ''
          state="''${XDG_STATE_HOME:-$HOME/.local/state}/material/state.json"
          if [ ! -e "$state" ]; then
            mkdir -p "$(dirname "$state")"
            printf '{"wallpaper":"","mode":"%s","variant":"%s"}\n' "@MODE@" "@VARIANT@" > "$state"
          fi
        '';
      };
  };
}
NIX

subst() {  # every value below passed a regex above
    local f="$1" t
    t="$(< "$f")"
    t="${t//@URL@/$FLAKE_URL}"
    t="${t//@HOST@/$PD_HOSTNAME}"
    t="${t//@STATE@/$STATE_VERSION}"
    t="${t//@SYSTEM@/$SYSTEM}"
    t="${t//@UNFREE@/$UNFREE_NIX}"
    t="${t//@TZ@/$PD_TZ}"
    t="${t//@LOCALE@/$PD_LOCALE}"
    t="${t//@LAYOUT@/$PD_LAYOUT}"
    t="${t//@XKBOPTS@/$XKBOPTS}"
    t="${t//@USER@/$PD_USER}"
    t="${t//@HASH@/$HASH}"
    t="${t//@AUTOSTART@/$AUTOSTART_NIX}"
    t="${t//@APPS@/$APPS_NIX}"
    t="${t//@MODE@/$PD_MODE}"
    t="${t//@VARIANT@/$PD_VARIANT}"
    printf '%s\n' "$t" > "$f"
}
subst "$TMP/flake.nix"
subst "$TMP/pixeldots-local.nix"
HASH=""

# ───────────────────────── 3. re-check the target disk ─────────────────────────
progress 8 "Checking the target disk"
if [ "$DRY" != 1 ]; then
    [ -d "${PD_SYS_DIR:-/sys}/firmware/efi" ] || die "not booted in UEFI mode"
fi
entry="$("$DISKS_CMD" | grep -E "^${PD_DISK}\|" || true)"
[ -n "$entry" ] || die "disk $PD_DISK is not an installable disk (it may be mounted, too small, or the installation medium)"
IFS='|' read -r d_name d_model d_size _ _ <<< "$entry"
[ "$d_name" = "$PD_DISK" ] && [ "$d_model" = "$PD_DISK_MODEL" ] && [ "$d_size" = "$PD_DISK_SIZE" ] \
    || die "disk $PD_DISK changed since you chose it (model or size differ): go back and choose again"
echo "target: $PD_DISK ($d_model, $d_size bytes)"

if [ "$DRY" != 1 ]; then
    progress 9 "Checking the network"
    curl -fsS -m 20 -o /dev/null https://cache.nixos.org/nix-cache-info \
        || die "no network. Connect (Ctrl+Alt+F2, run nmtui, Ctrl+Alt+F1) and press Retry"
fi

# ───────────────────────── 4. partition, format, mount, install ─────────────────────────
DEVDIR="${PD_DEV_DIR:-/dev}"
DEV="$DEVDIR/$PD_DISK"
if [[ $PD_DISK =~ [0-9]$ ]]; then PART="${DEV}p"; else PART="$DEV"; fi
ESP="${PART}1"
ROOT="${PART}2"

progress 12 "Partitioning $DEV"
if [ "$DRY" != 1 ]; then umount -R "$MNT" 2> /dev/null || true; fi
run wipefs -af "$DEV"
run parted -s "$DEV" -- mklabel gpt
run parted -s "$DEV" -- mkpart ESP fat32 1MiB 1025MiB
run parted -s "$DEV" -- set 1 esp on
run parted -s "$DEV" -- mkpart nixos ext4 1025MiB 100%
run udevadm settle
if [ "$DRY" != 1 ]; then
    # a block device, or (tests only, PD_DEV_DIR set) a plain file standing in for one
    blk() { [ -b "$1" ] || { [ -n "${PD_DEV_DIR:-}" ] && [ -e "$1" ]; }; }
    for _ in $(seq 1 20); do blk "$ESP" && blk "$ROOT" && break; sleep 0.5; done
    blk "$ESP" && blk "$ROOT" || die "partitions did not appear: $ESP $ROOT"
fi

progress 20 "Formatting"
run mkfs.fat -F 32 -n BOOT "$ESP"
run mkfs.ext4 -F -q -L nixos "$ROOT"

progress 24 "Mounting"
run mount "$ROOT" "$MNT"
run mkdir -p "$MNT/boot"
run mount -o umask=077 "$ESP" "$MNT/boot"

progress 28 "Generating the hardware configuration"
run nixos-generate-config --root "$MNT"

if [ "$DRY" = 1 ]; then
    OUT="${PD_OUT_DIR:?PD_OUT_DIR is required in dry-run mode}"
else
    OUT="$MNT/etc/nixos"
fi
mkdir -p "$OUT"
rm -f "$OUT/configuration.nix"
cp "$TMP/flake.nix" "$TMP/pixeldots-local.nix" "$OUT/"
echo "generated files: $(cd "$OUT" && ls -1 | tr '\n' ' ')"

progress 32 "Installing NixOS (downloads packages, this is the slow part)"
lines=0
pct=32
if [ "$DRY" = 1 ]; then
    echo "+ nixos-install --root $MNT --flake path:$OUT#$PD_HOSTNAME --no-root-passwd"
else
    if ! nixos-install --root "$MNT" --flake "path:$OUT#$PD_HOSTNAME" --no-root-passwd 2>&1 \
        | while IFS= read -r line; do
            echo "$line"
            lines=$((lines + 1))
            if [ $((lines % 15)) -eq 0 ] && [ "$pct" -lt 96 ]; then
                pct=$((pct + 1))
                echo "@@ $pct Installing NixOS (downloads packages, this is the slow part)"
            fi
        done; then
        die "nixos-install failed, see $LOG"
    fi
    progress 98 "Finishing"
    sync
    umount -R "$MNT"
fi
progress 100 "Done"
