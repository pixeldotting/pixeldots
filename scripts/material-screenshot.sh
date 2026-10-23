#!/usr/bin/env bash
# material-screenshot [region|full|window] — saves to ~/Pictures/Screenshots, copies to clipboard.

mode="${1:-region}"
dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$mode" in
    region)
        geom="$(slurp -d)" || exit 0
        grim -g "$geom" "$file"
        ;;
    full)
        grim "$file"
        ;;
    window)
        geom="$(hyprctl -j activewindow | jq -r 'select(.address != null) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
        [ -n "$geom" ] || exit 1
        grim -g "$geom" "$file"
        ;;
    *)
        echo "usage: material-screenshot [region|full|window]" >&2
        exit 1
        ;;
esac

wl-copy < "$file"
notify-send -i "$file" "Screenshot saved" "$file"
