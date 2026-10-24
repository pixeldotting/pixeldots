#!/usr/bin/env bash
# Stand-in for the ISO backend in UI tests: shows what it received (never the password itself).
IFS= read -r pw
echo "@@ 5 Checking answers"
echo "pw length: ${#pw}"
echo "user=$PD_USER host=$PD_HOSTNAME tz=$PD_TZ layout=$PD_LAYOUT"
echo "disk=$PD_DISK model=$PD_DISK_MODEL size=$PD_DISK_SIZE confirm=$PD_ERASE_CONFIRM"
[ -n "${FAKE_LEAK_HASH:-}" ] && echo 'users.users.x.hashedPassword = "$6$abc$LEAKEDHASHVALUE";'   # tests that the UI hides hashes
sleep 0.3
echo "@@ 60 Installing"
sleep 0.3
exit 0
