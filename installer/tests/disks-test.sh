#!/usr/bin/env bash
# Tests for disks.sh with a fake lsblk/findmnt (no real disks involved). Exit 0 = all passed.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$HERE/../disks.sh"
PASS=0 FAIL=0
check() { if eval "$2"; then PASS=$((PASS + 1)); echo "ok   - $1"; else FAIL=$((FAIL + 1)); echo "FAIL - $1"; fi; }
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT; mkdir -p "$T/bin" "$T/sys/firmware/efi"
cat > "$T/bin/lsblk" <<'EOS'
#!/usr/bin/env bash
case "$*" in
  *"-dbnP"*)
    echo 'NAME="nvme0n1" MODEL="Samsung\x20SSD\x20980\x20PRO\x201TB" SIZE="1000204886016" TYPE="disk" RO="0" TRAN="nvme" RM="0"'
    echo 'NAME="sda" MODEL="ATA\x20\x20Crucial\x20MX500" SIZE="500107862016" TYPE="disk" RO="0" TRAN="sata" RM="0"'
    echo 'NAME="sdb" MODEL="USB\x20Stick" SIZE="16008609792" TYPE="disk" RO="0" TRAN="usb" RM="1"'
    echo 'NAME="sdc" MODEL="Live\x20Medium" SIZE="64023257088" TYPE="disk" RO="0" TRAN="usb" RM="1"'
    echo 'NAME="sdd" MODEL="Used\x20Disk" SIZE="256060514304" TYPE="disk" RO="0" TRAN="sata" RM="0"'
    echo 'NAME="sde" MODEL="Evil\x22;rm\x20-rf\x20|x" SIZE="300000000000" TYPE="disk" RO="0" TRAN="sata" RM="0"'
    echo 'NAME="sr0" MODEL="DVD" SIZE="2000000000" TYPE="rom" RO="0" TRAN="sata" RM="1"'
    echo 'NAME="loop0" MODEL="" SIZE="900000000000" TYPE="loop" RO="0" TRAN="" RM="0"'
    echo 'NAME="sdf" MODEL="ReadOnly" SIZE="400000000000" TYPE="disk" RO="1" TRAN="sata" RM="0"'
    echo 'NAME="sdg" MODEL="Swap\x20Disk" SIZE="400000000000" TYPE="disk" RO="0" TRAN="sata" RM="0"'
    echo 'NAME="sdh" MODEL="Unknown\x20State" SIZE="400000000000" TYPE="disk" RO="0" TRAN="sata" RM="0"' ;;
  *"MOUNTPOINTS,FSTYPE /dev/sdc"*) echo 'MOUNTPOINTS="" FSTYPE="iso9660"' ;;
  *"MOUNTPOINTS,FSTYPE /dev/sdd"*) echo 'MOUNTPOINTS="/mnt/data" FSTYPE="ext4"' ;;
  *"MOUNTPOINTS,FSTYPE /dev/sdg"*) echo 'MOUNTPOINTS="[SWAP]" FSTYPE="swap"' ;;
  *"MOUNTPOINTS,FSTYPE /dev/sdh"*) exit 1 ;;   # lsblk cannot tell: the disk must not be offered
  *"MOUNTPOINTS,FSTYPE /dev/"*) echo 'MOUNTPOINTS="" FSTYPE=""' ;;
  *"PKNAME"*) echo "sdc" ;;
esac
EOS
printf '#!/usr/bin/env bash\necho /dev/sdc1\n' > "$T/bin/findmnt"; chmod +x "$T/bin"/*
OUT="$(PATH="$T/bin:$PATH" PD_SYS_DIR="$T/sys" bash "$S")"
has() { grep -q "^$1|" <<< "$OUT"; }
check "offers nvme0n1 with a clean model and exact size" 'grep -qx "nvme0n1|Samsung SSD 980 PRO 1TB|1000204886016|nvme|0" <<< "$OUT"'
check "offers sda, squeezes the double blank in the model" 'grep -qx "sda|ATA Crucial MX500|500107862016|sata|0" <<< "$OUT"'
check "sanitises a hostile model string (no quote, semicolon or pipe survives)" 'has sde && ! grep -E "^sde\|" <<< "$OUT" | grep -qE "[\";]" && [ "$(grep -E "^sde\|" <<< "$OUT" | tr -cd "|" | wc -c)" = 4 ]'
check "hides a disk under 20 GiB (sdb)" '! has sdb'
check "hides the installation medium: iso9660 (sdc)" '! has sdc'
check "hides a mounted disk (sdd)" '! has sdd'
check "hides a disk with active swap (sdg)" '! has sdg'
check "fails closed when lsblk cannot inspect a disk (sdh)" '! has sdh'
check "hides rom, loop and read-only devices" '! has sr0 && ! has loop0 && ! has sdf'
check "every line has exactly 5 fields" '[ "$(awk -F"|" "NF!=5" <<< "$OUT" | wc -l)" = 0 ]'
rm -rf "$T/sys/firmware/efi"
OUT="$(PATH="$T/bin:$PATH" PD_SYS_DIR="$T/sys" bash "$S")"
check "not UEFI: one ERR line and no disks" '[ "$OUT" = "ERR|Not booted in UEFI mode. Boot this USB stick or ISO in UEFI mode to install." ]'
mkdir -p "$T/sys/firmware/efi"
printf '#!/usr/bin/env bash\ncase "$*" in *-dbnP*) ;; esac\n' > "$T/bin/lsblk"
OUT="$(PATH="$T/bin:$PATH" PD_SYS_DIR="$T/sys" bash "$S")"
check "no disks at all: ERR line" 'grep -q "^ERR|No suitable disk" <<< "$OUT"'
echo; echo "passed: $PASS  failed: $FAIL"; [ "$FAIL" -eq 0 ]
