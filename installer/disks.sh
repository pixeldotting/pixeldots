#!/usr/bin/env bash
# Lists the disks that may be offered for installation, one per line:
#     name|model|size_bytes|transport|removable
# or a single line "ERR|message" when nothing can be offered. The UI shows exactly this list and install-iso.sh
# asks again right before it touches a disk, so a disk that is not printed here can never be written.
#
# A disk is offered only if it is: a whole disk (not a partition, loop, rom), writable, >= 20 GiB,
# not mounted anywhere (also not via a partition or as swap), without an installation-medium filesystem
# (iso9660/squashfs) on it, and not the device behind /iso. Anything that cannot be checked is NOT offered.
#
# PD_SYS_DIR (default /sys) exists so the tests can fake the firmware directory.
set -uo pipefail

MIN_BYTES=$((20 * 1024 * 1024 * 1024))

if [ ! -d "${PD_SYS_DIR:-/sys}/firmware/efi" ]; then
    echo "ERR|Not booted in UEFI mode. Boot this USB stick or ISO in UEFI mode to install."
    exit 0
fi

# value of KEY="..." in an `lsblk -P` line (lsblk escapes quotes and spaces as \xNN)
field() {
    local re="(^| )$1=\"([^\"]*)\""
    [[ $2 =~ $re ]] && printf '%s' "${BASH_REMATCH[2]}"
    return 0
}

clean_model() {  # decode \xNN, keep a safe character set only, squeeze blanks
    local m
    m="$(printf '%b' "$1" | LC_ALL=C tr -cd 'A-Za-z0-9 ._()/+-' | LC_ALL=C tr -s ' ')"
    m="${m# }"
    m="${m% }"
    printf '%s' "${m:-Unknown disk}"
}

live_disk=""
if live_src="$(findmnt -n -o SOURCE /iso 2> /dev/null)" && [ -n "$live_src" ]; then
    live_disk="$(lsblk -no PKNAME "$live_src" 2> /dev/null | head -n1)"
    [ -n "$live_disk" ] || live_disk="${live_src##*/}"
fi

found=0
while IFS= read -r line; do
    [ "$(field TYPE "$line")" = disk ] || continue
    [ "$(field RO "$line")" = 0 ] || continue
    name="$(field NAME "$line")"
    [[ $name =~ ^[a-z0-9]+$ ]] || continue
    [ "$name" != "$live_disk" ] || continue
    size="$(field SIZE "$line")"
    [[ $size =~ ^[0-9]+$ ]] && [ "$size" -ge "$MIN_BYTES" ] || continue
    # in use? fail closed: if lsblk cannot tell, the disk is not offered
    inuse="$(lsblk -nP -o MOUNTPOINTS,FSTYPE "/dev/$name" 2> /dev/null)" || continue
    if grep -Eq 'MOUNTPOINTS="[^"]+"|FSTYPE="(iso9660|squashfs)"' <<< "$inuse"; then continue; fi
    printf '%s|%s|%s|%s|%s\n' "$name" "$(clean_model "$(field MODEL "$line")")" "$size" "$(field TRAN "$line")" "$(field RM "$line")"
    found=1
done < <(lsblk -dbnP -o NAME,MODEL,SIZE,TYPE,RO,TRAN,RM 2> /dev/null)

if [ "$found" = 0 ]; then
    echo "ERR|No suitable disk found (it must be 20 GiB or more and not the installation medium)."
fi
