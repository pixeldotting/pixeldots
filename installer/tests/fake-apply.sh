#!/usr/bin/env bash
# Stand-in for apply.sh in UI tests: prints progress markers and the received environment (no password).
IFS= read -r pw
echo "@@ 5 Checking answers"
echo "got pw length: ${#pw}"
echo "locale=$PD_LOCALE layout=$PD_LAYOUT tz=$PD_TZ host=$PD_HOSTNAME user=$PD_USER"
echo "apps=$PD_APPS mode=$PD_MODE variant=$PD_VARIANT autostart=$PD_AUTOSTART"
sleep 0.3
echo -e "\033[32mcolored line\033[0m"
echo "@@ 50 Building the system"
sleep 0.3
echo "@@ 90 Activating"
[ "${FAKE_FAIL:-0}" = 1 ] && { echo "error: something broke"; exit 1; }
exit 0
