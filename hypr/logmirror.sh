#!/usr/bin/env bash
# Mirror this Hyprland session's log and SDDM's session log (both are lost at logout/reboot:
# tmpfs and truncate-on-login) into ~/.local/state/hyprland/, keeping the last 6 sessions.
# Started from hypr-obsidian.lua at every login; safe to run again (one mirror per instance).
set -u
dir="${XDG_STATE_HOME:-$HOME/.local/state}/hyprland"
mkdir -p "$dir"
sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
[ -n "$sig" ] || exit 0
src="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/$sig/hyprland.log"
stamp=$(date +%Y-%m-%d_%H%M%S)
# one mirror per instance: a marker named after the signature (pgrep would match our own caller)
mark="$dir/.mirroring-$sig"
[ -e "$mark" ] && exit 0
: > "$mark"
ln -sfn "hyprland-$stamp.log" "$dir/hyprland-current.log"
ln -sfn "session-$stamp.log" "$dir/session-current.log"
setsid -f tail -n +1 -F "$src" > "$dir/hyprland-$stamp.log" 2>/dev/null </dev/null
sess="$HOME/.local/share/sddm/wayland-session.log"
[ -f "$sess" ] && setsid -f tail -n +1 -F "$sess" > "$dir/session-$stamp.log" 2>/dev/null </dev/null
# prune: keep the newest 6 of each
for p in hyprland session; do
    ls -t "$dir"/$p-20*.log 2>/dev/null | tail -n +7 | xargs -r rm -f
done
