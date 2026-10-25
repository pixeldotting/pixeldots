#!/usr/bin/env bash
# Runs the "Prepare release files" step of .github/workflows/iso.yml locally on fake ISOs (sparse files).
# Needs python3 + PyYAML. Exit 0 = all checks passed.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT; cd "$W" || exit 1
python3 - "$ROOT/.github/workflows/iso.yml" <<'PY' || exit 1
import sys, re, yaml
d = yaml.safe_load(open(sys.argv[1]))
on = d.get('on', d.get(True))
assert list(on.keys()) == ['workflow_dispatch'], "the workflow must be manual only, triggers: %s" % list(on.keys())
step = [s for s in d['jobs']['build']['steps'] if s.get('name') == 'Prepare release files'][0]
open('prep.sh', 'w').write(re.sub(r'\$\{\{[^}]*\}\}', 'X', step['run']))
PY
PASS=0 FAIL=0
check() { if eval "$2"; then PASS=$((PASS + 1)); echo "ok   - $1"; else FAIL=$((FAIL + 1)); echo "FAIL - $1"; fi; }
prep() { rm -rf result release notes.md ge; mkdir -p result/iso; truncate -s "$1" result/iso/nixos-test.iso; : > ge
         TAG_INPUT="$2" GITHUB_ENV="$PWD/ge" GITHUB_SHA=0123456789abcdef0123456789abcdef01234567 bash prep.sh > out.txt 2>&1; RC=$?; }
# (the "manual only" assertion lives in the python block above and aborts this script if it fails)
prep 100M v0.1.0
check "small ISO: ok, one ISO + SHA256SUMS, tag exported" '[ $RC -eq 0 ] && [ -f release/pixeldots-v0.1.0-x86_64.iso ] && [ -f release/SHA256SUMS ] && grep -q "^TAG=v0.1.0$" ge'
check "small ISO: notes do not mention splitting" '! grep -q "split" notes.md'
prep 2200M ""
check "big ISO: ok, tag generated" '[ $RC -eq 0 ] && grep -qE "^TAG=iso-[0-9]{8}-[0-9]{6}$" ge'
check "big ISO: split, no unsplit ISO left, every file under 2 GiB" '! ls release | grep -qE "\.iso$" && ls release | grep -q "\.iso\.part00$" && [ "$(stat -c %s release/* | sort -n | tail -1)" -lt 2147483648 ]'
check "big ISO: joined parts have the checksum SHA256SUMS lists for the whole ISO" '[ "$(cd release && cat pixeldots-*.iso.part* | sha256sum | cut -c1-64)" = "$(grep -E "x86_64.iso\$" release/SHA256SUMS | cut -c1-64)" ]'
check "big ISO: notes explain how to join" 'grep -q "cat pixeldots-" notes.md'
for t in 'a b' 'x;rm' '../x' "$(printf 'a%.0s' $(seq 70))"; do prep 10M "$t"; check "bad tag refused: ${t:0:20}" '[ $RC -ne 0 ] && [ ! -d release ] || [ -z "$(ls release 2>/dev/null)" ]'; done
rm -rf result; mkdir -p result/iso; : > ge; TAG_INPUT=t GITHUB_ENV="$PWD/ge" GITHUB_SHA=x bash prep.sh > out.txt 2>&1
check "no ISO built: refused" '[ $? -ne 0 ] && grep -q "found 0" out.txt'
echo; echo "passed: $PASS  failed: $FAIL"; [ "$FAIL" -eq 0 ]
