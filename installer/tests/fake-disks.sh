#!/usr/bin/env bash
# Stand-in for pixeldots-disks in UI tests. FAKE_DISKS=none -> error, FAKE_DISKS=nouefi -> not UEFI.
case "${FAKE_DISKS:-two}" in
  none)   echo "ERR|No suitable disk found (it must be 20 GiB or more and not the installation medium)." ;;
  nouefi) echo "ERR|Not booted in UEFI mode. Boot this USB stick or ISO in UEFI mode to install." ;;
  *)
    echo "nvme0n1|Samsung SSD 980 PRO 1TB|1000204886016|nvme|0"
    echo "sda|ATA Crucial MX500|500107862016|sata|0"
    ;;
esac
