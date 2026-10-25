#!/usr/bin/env bash
# Undo the 2026-10-25 "retain splash" boot handover that hung the boot on a blank screen:
# unmask plymouth-quit(+wait) and delete the sddm.service drop-in. Plymouth itself stays.
#   sudo bash plymouth/undo-handover.sh
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
systemctl unmask plymouth-quit.service plymouth-quit-wait.service
rm -f /etc/systemd/system/sddm.service.d/onyx-plymouth.conf
rmdir /etc/systemd/system/sddm.service.d 2>/dev/null || true
systemctl daemon-reload
echo "state now:"
systemctl is-enabled plymouth-quit.service plymouth-quit-wait.service || true
ls /etc/systemd/system/sddm.service.d 2>/dev/null || echo "sddm drop-in: gone"
echo "done: next boot uses the stock Plymouth → SDDM handover (no more blank-screen hang)."
