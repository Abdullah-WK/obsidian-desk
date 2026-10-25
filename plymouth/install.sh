#!/usr/bin/env bash
# Root-side Plymouth setup for the Onyx splash. Run with sudo from the repo:
#   sudo bash plymouth/install.sh
# Does: install plymouth if missing, copy the theme, add the `plymouth` mkinitcpio hook after udev,
# add `splash` to GRUB_CMDLINE_LINUX_DEFAULT, set the theme and rebuild initramfs + grub config.
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
[ "$(id -u)" = 0 ] || { echo "run with sudo"; exit 1; }
pacman -Q plymouth >/dev/null 2>&1 || pacman -S --needed --noconfirm plymouth
install -d /usr/share/plymouth/themes/onyx
install -m644 "$HERE/onyx/"* /usr/share/plymouth/themes/onyx/
[ -f /usr/share/plymouth/themes/onyx/logo.png ] || { echo "logo.png missing: run 'qs -p plymouth/render-logo.qml' as the user first"; exit 1; }
if ! grep -qE '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf; then
    cp -n /etc/mkinitcpio.conf /etc/mkinitcpio.conf.bak-onyx
    sed -i -E 's/^(HOOKS=\([^)]*\budev)\b/\1 plymouth/' /etc/mkinitcpio.conf
    echo "mkinitcpio: plymouth hook added after udev"
fi
if [ -f /etc/default/grub ] && ! grep -qE '^GRUB_CMDLINE_LINUX_DEFAULT=.*\bsplash\b' /etc/default/grub; then
    cp -n /etc/default/grub /etc/default/grub.bak-onyx
    sed -i -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT=")/\1splash /' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg
    echo "grub: splash added to the kernel command line"
fi
# 2026-10-25: the earlier "retain splash" handover (masking plymouth-quit* and quitting Plymouth
# from an sddm.service ExecStartPre) deadlocked the VT handoff on this machine: SDDM's X server on
# VT 2 never came up and the boot sat on a blank screen. Stock Plymouth quit units are used; this
# block undoes that handover wherever it was applied.
if [ -e /etc/systemd/system/sddm.service.d/onyx-plymouth.conf ] || [ "$(systemctl is-enabled plymouth-quit.service 2>/dev/null)" = masked ]; then
    systemctl unmask plymouth-quit.service plymouth-quit-wait.service 2>/dev/null || true
    rm -f /etc/systemd/system/sddm.service.d/onyx-plymouth.conf
    rmdir /etc/systemd/system/sddm.service.d 2>/dev/null || true
    systemctl daemon-reload
    echo "removed the retain-splash handover (plymouth-quit unmasked, sddm drop-in deleted)"
fi
# keep the console quiet behind the splash
if [ -f /etc/default/grub ]; then
    for p in "vt.global_cursor_default=0" "systemd.show_status=auto" "rd.udev.log_level=3"; do
        grep -qE "^GRUB_CMDLINE_LINUX_DEFAULT=.*\b${p%%=*}=" /etc/default/grub || sed -i -E "s/^(GRUB_CMDLINE_LINUX_DEFAULT=\")/\1$p /" /etc/default/grub
    done
    grub-mkconfig -o /boot/grub/grub.cfg >/dev/null
    echo "grub: console cursor and status messages hidden"
fi
plymouth-set-default-theme -R onyx
echo "onyx splash installed; preview without rebooting: plymouthd; plymouth --show-splash; sleep 5; plymouth quit"
