#!/usr/bin/env bash
# material-theme — single entry point for wallpaper + Material You colour state.
#
#   material-theme init                    first run: pick a wallpaper, generate colours
#   material-theme wallpaper <file>        set wallpaper and regenerate colours
#   material-theme random                  random wallpaper from the wallpaper dir
#   material-theme mode dark|light|toggle  switch scheme brightness
#   material-theme variant <scheme-name>   e.g. scheme-tonal-spot, scheme-expressive
#   material-theme apply                   regenerate colours from the current state
#
# State lives in $XDG_STATE_HOME/material/state.json (read live by the Quickshell shell).
# matugen writes colours.json next to it plus the Hyprland/kitty/GTK/Qt/starship files
# listed in ~/.config/matugen/config.toml.

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/material"
STATE="$STATE_DIR/state.json"
WALL_DIR="${MATERIAL_WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

ensure_state() {
    mkdir -p "$STATE_DIR"
    if [ ! -s "$STATE" ]; then
        printf '{"wallpaper":"","mode":"dark","variant":"scheme-tonal-spot"}\n' > "$STATE"
    fi
}

get() { jq -r --arg k "$1" '.[$k] // ""' "$STATE"; }

# In-place rewrite (not rename) so file watchers keep following the same inode.
put() {
    local tmp
    tmp="$(mktemp -p "$STATE_DIR")"
    jq --arg k "$1" --arg v "$2" '.[$k] = $v' "$STATE" > "$tmp" && cat "$tmp" > "$STATE"
    rm -f "$tmp"
}

list_wallpapers() {
    [ -d "$WALL_DIR" ] || return 0
    find -L "$WALL_DIR" -maxdepth 2 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | sort
}

apply() {
    local wp mode variant
    wp="$(get wallpaper)"
    mode="$(get mode)"
    variant="$(get variant)"

    if [ -z "$wp" ] || [ ! -f "$wp" ]; then
        echo "material-theme: no wallpaper set (put images into $WALL_DIR)" >&2
        return 1
    fi

    matugen image "$wp" -m "$mode" -t "$variant" > /dev/null

    # Tell GTK/libadwaita/portal-aware apps whether we're light or dark.
    dconf write /org/gnome/desktop/interface/color-scheme "'prefer-$mode'" 2> /dev/null || true

    # Hyprland re-reads colors.lua on reload.
    hyprctl reload > /dev/null 2>&1 || true
}

cmd="${1:-apply}"
ensure_state

case "$cmd" in
    init)
        if [ -z "$(get wallpaper)" ] || [ ! -f "$(get wallpaper)" ]; then
            first="$(list_wallpapers | head -n1 || true)"
            if [ -n "$first" ]; then put wallpaper "$first"; fi
        fi
        # Only regenerate when colours are missing (don't stomp a running theme on every login).
        if [ ! -s "$STATE_DIR/colors.json" ] || [ ! -s "$HOME/.config/hypr/colors.lua" ]; then
            apply
        fi
        ;;
    wallpaper)
        [ -f "${2:-}" ] || { echo "usage: material-theme wallpaper <file>" >&2; exit 1; }
        put wallpaper "$(realpath "$2")"
        apply
        ;;
    random)
        current="$(get wallpaper)"
        pick="$(list_wallpapers | grep -vxF "$current" | shuf -n1 || true)"
        [ -n "$pick" ] || pick="$(list_wallpapers | shuf -n1 || true)"
        [ -n "$pick" ] || { echo "material-theme: no wallpapers in $WALL_DIR" >&2; exit 1; }
        put wallpaper "$pick"
        apply
        ;;
    mode)
        case "${2:-toggle}" in
            dark | light) put mode "$2" ;;
            toggle) if [ "$(get mode)" = "dark" ]; then put mode light; else put mode dark; fi ;;
            *) echo "usage: material-theme mode dark|light|toggle" >&2; exit 1 ;;
        esac
        apply
        ;;
    variant)
        [ -n "${2:-}" ] || { echo "usage: material-theme variant <scheme-name>" >&2; exit 1; }
        put variant "$2"
        apply
        ;;
    apply)
        apply
        ;;
    *)
        echo "unknown command: $cmd" >&2
        exit 1
        ;;
esac
