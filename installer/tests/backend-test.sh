#!/usr/bin/env bash
# Tests for install-iso.sh with fake system tools: no disk, no root-only side effects outside a temp dir.
# Run:  bash installer/tests/backend-test.sh      (exit 0 = all passed)
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$HERE/../install-iso.sh"
PASS=0 FAIL=0
ok()   { PASS=$((PASS + 1)); echo "ok   - $1"; }
bad()  { FAIL=$((FAIL + 1)); echo "FAIL - $1"; }
check() { if eval "$2"; then ok "$1"; else bad "$1   [$2]"; fi; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
BIN="$W/bin" ETC="$W/etc" SYS="$W/sys" DEV="$W/dev" MNT="$W/mnt" CALLS="$W/calls.log"
mkdir -p "$BIN" "$ETC" "$SYS/firmware/efi" "$DEV" "$MNT"
cp "$HERE/../data/apps.tsv" "$W/apps.tsv"
echo "26.05" > "$ETC/state-version"
echo "github:pixeldotting/pixeldots/0123456789abcdef0123456789abcdef01234567" > "$ETC/flake-url"
touch "$DEV/sda1" "$DEV/sda2" "$DEV/nvme0n1p1" "$DEV/nvme0n1p2"

# every tool the script may call is a logger; nixos-* also do their small visible job
for t in parted wipefs mkfs.fat mkfs.ext4 mount umount udevadm curl sync; do
    printf '#!/usr/bin/env bash\necho "%s $*" >> "%s"\n' "$t" "$CALLS" > "$BIN/$t"
done
cat > "$BIN/nixos-generate-config" <<EOS
#!/usr/bin/env bash
echo "nixos-generate-config \$*" >> "$CALLS"
root=\$2; mkdir -p "\$root/etc/nixos"; echo '{ }' > "\$root/etc/nixos/hardware-configuration.nix"; echo '{ }' > "\$root/etc/nixos/configuration.nix"
EOS
cat > "$BIN/nixos-install" <<EOS
#!/usr/bin/env bash
echo "nixos-install \$*" >> "$CALLS"
for i in \$(seq 1 40); do echo "building thing \$i"; done
echo 'users.users.x.hashedPassword = "\$6\$salt\$LEAKEDHASH";'
[ "\${FAKE_INSTALL_FAIL:-0}" = 1 ] && { echo "error: build failed"; exit 1; }
exit 0
EOS
# pixeldots-disks stand-in: what the UI would have offered
cat > "$BIN/pixeldots-disks" <<'EOS'
#!/usr/bin/env bash
echo "nvme0n1|Samsung SSD 980 PRO 1TB|1000204886016|nvme|0"
echo "sda|ATA Crucial MX500|500107862016|sata|0"
EOS
chmod +x "$BIN"/*

# defaults for a valid request; each test overrides what it needs (later assignments win in `env`)
BASE=(PD_LOCALE=ru_RU.UTF-8 PD_LAYOUT=us,ru PD_TZ=Europe/Berlin PD_HOSTNAME=my-box PD_USER=alice PD_APPS=firefox,discord,btop
      PD_MODE=light PD_VARIANT=scheme-expressive PD_AUTOSTART=1 PD_DISK=sda "PD_DISK_MODEL=ATA Crucial MX500" PD_DISK_SIZE=500107862016
      PD_ERASE_CONFIRM=sda)
# run <password> [VAR=value ...]  -> sets RC, OUT; resets the call log
run_backend() {
    local pw="$1"; shift
    : > "$CALLS"; rm -rf "$W/out" "$MNT"; mkdir -p "$MNT"
    OUT="$(printf '%s\n' "$pw" | env -i PATH="$BIN:/usr/bin:/bin" "${BASE[@]}" \
        PD_DATA_DIR="$W" PD_ETC_DIR="$ETC" PD_SYS_DIR="$SYS" PD_DEV_DIR="$DEV" PD_MNT="$MNT" PD_LOG="$W/install.log" \
        PD_DISKS_CMD="$BIN/pixeldots-disks" PD_OUT_DIR="$W/out" "$@" bash "$SCRIPT" 2>&1)"
    RC=$?
}
PW='S3cret-pass!99'
nocalls() { [ ! -s "$CALLS" ]; }
leak() { grep -rqF -- "$PW" "$W/out" "$W/install.log" "$CALLS" 2> /dev/null; }

echo "== dry run =="
run_backend "$PW" PD_DRY_RUN=1
check "dry run succeeds" '[ $RC -eq 0 ]'
check "dry run generated flake.nix and pixeldots-local.nix" '[ -f "$W/out/flake.nix" ] && [ -f "$W/out/pixeldots-local.nix" ]'
check "hashedPassword is a sha-512 hash" 'grep -qE "hashedPassword = \"\\\$6\\\$[./0-9A-Za-z\$]+\";" "$W/out/pixeldots-local.nix"'
check "the plaintext password is in no generated file, log or call record" '! leak'
check "no unreplaced @PLACEHOLDER@ left" '! grep -q "@[A-Z]*@" "$W/out/flake.nix" "$W/out/pixeldots-local.nix"'
check "host, user, tz, locale, layout, stateVersion substituted" 'grep -q "networking.hostName = \"my-box\"" "$W/out/pixeldots-local.nix" && grep -q "users.users.\"alice\"" "$W/out/pixeldots-local.nix" && grep -q "time.timeZone = \"Europe/Berlin\"" "$W/out/pixeldots-local.nix" && grep -q "i18n.defaultLocale = \"ru_RU.UTF-8\"" "$W/out/pixeldots-local.nix" && grep -q "xkb.layout = \"us,ru\"" "$W/out/pixeldots-local.nix" && grep -q "stateVersion = \"26.05\"" "$W/out/pixeldots-local.nix"'
check "apps resolved, unfree enabled because of discord" 'grep -q "firefox discord btop" "$W/out/pixeldots-local.nix" && grep -q "allowUnfree = true" "$W/out/pixeldots-local.nix"'
check "flake pins the ISO revision" 'grep -q "github:pixeldotting/pixeldots/0123456789abcdef0123456789abcdef01234567" "$W/out/flake.nix"'
check "dry run runs no tool" 'nocalls || ! grep -qvE "^$" "$CALLS"'

echo "== invalid input is rejected BEFORE any command runs =="
run_backend "$PW" PD_DRY_RUN=1
check "control: the unmodified request is accepted (so the rejections below are not vacuous)" '[ $RC -eq 0 ]'
for kv in 'PD_HOSTNAME=a;b' 'PD_HOSTNAME=-bad' 'PD_HOSTNAME=has space' 'PD_HOSTNAME=x"y' 'PD_USER=Root' 'PD_USER=root' 'PD_USER=al"ice' 'PD_USER=1abc' 'PD_USER=a b' \
          'PD_TZ=Europe/Berlin;rm' 'PD_TZ=a b' 'PD_LAYOUT=us;x' 'PD_LAYOUT=US' 'PD_LOCALE=en_US' 'PD_MODE=blue' 'PD_VARIANT=scheme-x;y' 'PD_APPS=nope' 'PD_APPS=firefox,;x' \
          'PD_AUTOSTART=2' 'PD_DISK=sda;rm' 'PD_DISK=../sda' 'PD_DISK_SIZE=12x' 'PD_DISK_MODEL=ev"il'; do
    run_backend "$PW" "$kv"
    check "rejected: $kv" '[ $RC -ne 0 ] && nocalls'
done
run_backend "short" ; check "rejected: password too short" '[ $RC -ne 0 ] && nocalls'
run_backend "" ;      check "rejected: empty password" '[ $RC -ne 0 ] && nocalls'
run_backend "$(printf 'pässword99')"; check "rejected: non-ASCII password" '[ $RC -ne 0 ] && nocalls'
run_backend "$PW" PD_ERASE_CONFIRM=; check "rejected: erase not confirmed (empty)" '[ $RC -ne 0 ] && nocalls'
run_backend "$PW" PD_ERASE_CONFIRM=nvme0n1; check "rejected: confirmation for another disk" '[ $RC -ne 0 ] && nocalls'
check "error messages do not echo the password" '! leak'

echo "== disk re-check =="
run_backend "$PW" PD_DISK=sdb PD_ERASE_CONFIRM=sdb; check "rejected: disk not offered by pixeldots-disks (and for that reason)" '[ $RC -ne 0 ] && nocalls && grep -q "is not an installable disk" <<< "$OUT"'
run_backend "$PW" PD_DISK_SIZE=500107862017;       check "rejected: size changed since the user chose (and for that reason)" '[ $RC -ne 0 ] && nocalls && grep -q "changed since you chose it" <<< "$OUT"'
run_backend "$PW" PD_DISK_MODEL="Other model";     check "rejected: model changed since the user chose" '[ $RC -ne 0 ] && nocalls'
rm -rf "$SYS/firmware/efi"; run_backend "$PW";       check "rejected: not booted in UEFI mode" '[ $RC -ne 0 ] && nocalls'
mkdir -p "$SYS/firmware/efi"

echo "== real run with fake tools (sda) =="
run_backend "$PW"
check "succeeds" '[ $RC -eq 0 ]'
check "calls happen in the safe order" '[ "$(cut -d" " -f1 "$CALLS" | tr "\n" ,)" = "curl,umount,wipefs,parted,parted,parted,parted,udevadm,mkfs.fat,mkfs.ext4,mount,mount,nixos-generate-config,nixos-install,sync,umount," ]'
check "partitioning commands target only the chosen disk" '! grep -E "^(wipefs|parted)" "$CALLS" | grep -v -- "$DEV/sda\b"'
check "no command mentions another disk" '! grep -qE "nvme0n1|sdb|sdc" "$CALLS"'
check "mkfs on partition 1 (FAT32 ESP) and 2 (ext4)" 'grep -qF "mkfs.fat -F 32 -n BOOT $DEV/sda1" "$CALLS" && grep -qF "mkfs.ext4 -F -q -L nixos $DEV/sda2" "$CALLS"'
check "GPT, 1 GiB ESP, esp flag" 'grep -q "mklabel gpt" "$CALLS" && grep -q "mkpart ESP fat32 1MiB 1025MiB" "$CALLS" && grep -q "set 1 esp on" "$CALLS"'
check "nixos-install uses --root, --flake path:..#host and --no-root-passwd" 'grep -qF "nixos-install --root $MNT --flake path:$MNT/etc/nixos#my-box --no-root-passwd" "$CALLS"'
check "config written into the target, configuration.nix removed" '[ -f "$MNT/etc/nixos/flake.nix" ] && [ -f "$MNT/etc/nixos/pixeldots-local.nix" ] && [ ! -e "$MNT/etc/nixos/configuration.nix" ]'
check "the hash printed by nixos-install is hidden in the output and the log" '! grep -q LEAKEDHASH <<< "$OUT" && ! grep -q LEAKEDHASH "$W/install.log" && grep -q "hash hidden" "$W/install.log"'
check "plaintext password nowhere" '! grep -rqF -- "$PW" "$MNT" "$W/install.log" "$CALLS" && ! grep -qF -- "$PW" <<< "$OUT"'
check "progress markers reach 100" 'grep -q "^@@ 100 " <<< "$OUT"'

echo "== nvme naming =="
run_backend "$PW" PD_DISK=nvme0n1 PD_ERASE_CONFIRM=nvme0n1 PD_DISK_MODEL="Samsung SSD 980 PRO 1TB" PD_DISK_SIZE=1000204886016
check "succeeds" '[ $RC -eq 0 ]'
check "partitions are nvme0n1p1 / nvme0n1p2" 'grep -qF "mkfs.fat -F 32 -n BOOT $DEV/nvme0n1p1" "$CALLS" && grep -qF "mkfs.ext4 -F -q -L nixos $DEV/nvme0n1p2" "$CALLS"'
check "sda is untouched" '! grep -q "sda" "$CALLS"'

echo "== install failure =="
run_backend "$PW" FAKE_INSTALL_FAIL=1
check "fails with a clear error and does not umount as if finished" '[ $RC -ne 0 ] && grep -q "nixos-install failed" <<< "$OUT" && ! grep -q "^@@ 100" <<< "$OUT"'

echo; echo "passed: $PASS  failed: $FAIL"
[ "$FAIL" -eq 0 ]
