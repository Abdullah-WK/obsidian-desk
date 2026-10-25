#!/usr/bin/env bash
# Restores the files install.sh backed up (latest obsidian-* backup, or the one given),
# removes the symlinks, hook, companion config and exec-once, and re-applies the old scheme.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
BK=${1:-$(ls -d "$BACKUPS"/obsidian-* 2>/dev/null | sort | tail -1)}
[ -d "${BK:-}" ] || { echo "no backup directory found under $BACKUPS"; exit 1; }
printf '%sObsidian desk · uninstall%s (restoring from %s)\n' "$c_bold" "$c_off" "$BK"

qs -c onyx kill >/dev/null 2>&1 || true
restore() { # restore <abs path>
    local p=$1
    if [ -e "$BK$p" ] || [ -L "$BK$p" ]; then
        rm -rf "$p"; mkdir -p "$(dirname "$p")"; cp -a "$BK$p" "$p"; ok "restored $p"
    else
        rm -rf "$p"; note "removed $p (did not exist before)"
    fi
}
for f in shell.json cli.json hypr-vars.lua hypr-user.lua hypr-obsidian.lua templates/gtk.css hooks/post-scheme.sh templates/thunar-graphite.css; do
    restore "$CAE/$f"
done
for v in gtk-3.0 gtk-4.0; do restore "$CFG/$v/gtk.css"; restore "$CFG/$v/thunar.css"; done
python3 "$HERE/caelestia/override/patch-notifs.py" --undo
rm -rf "$CFG/quickshell/onyx"; ok "removed $CFG/quickshell/onyx"
rm -rf "$ONYX_CFG"; ok "removed $ONYX_CFG"
if [ -e "$BK/scheme-before.json" ]; then
    read -r n fl m v < <(python3 -c 'import json;d=json.load(open("'"$BK"'/scheme-before.json"));print(d["name"],d["flavour"],d["mode"],d.get("variant",""))')
    if [ "$n" = dynamic ]; then caelestia scheme set -n "$n" -f "$fl" -m "$m" -v "$v"; else caelestia scheme set -n "$n" -f "$fl" -m "$m"; fi
    ok "scheme back to $n/$fl/$m"
fi
hyprctl reload >/dev/null 2>&1 && ok "hyprctl reload"
SCHEME_DIR=$(scheme_dir)
[ -n "$SCHEME_DIR" ] && note "scheme file left in place; remove with: sudo rm -r $SCHEME_DIR/onyx"
note "Thunar xfconf settings and dconf gtk/icon theme were not reverted (harmless defaults)."
