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
plymouth-set-default-theme -R onyx
echo "onyx splash installed; preview without rebooting: plymouthd; plymouth --show-splash; sleep 5; plymouth quit"
