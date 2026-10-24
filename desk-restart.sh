#!/usr/bin/env bash
# Complete desktop restart: reload Hyprland, restart Caelestia and the onyx companion shell.
# Refuses while the companion lock is engaged (restarting a lock client releases the lock).
set -u
if [ "$(qs -c onyx ipc call lock isLocked 2>/dev/null)" = true ]; then
    echo "onyx holds the session lock; unlock first" >&2; exit 1
fi
hyprctl reload >/dev/null 2>&1 && echo "hyprland reloaded"
caelestia shell -k >/dev/null 2>&1; qs -c onyx kill >/dev/null 2>&1; sleep 0.6
setsid -f caelestia shell -d >/dev/null 2>&1
setsid -f qs -c onyx >/dev/null 2>&1
for _ in $(seq 40); do qs -c onyx ipc show >/dev/null 2>&1 && caelestia shell lock isLocked >/dev/null 2>&1 && break; sleep 0.25; done
echo "caelestia: $(pgrep -u "$UID" -f '^qs -c caelestia' >/dev/null && echo running || echo NOT running)"
echo "onyx:      $(pgrep -u "$UID" -f '^qs -c onyx$' >/dev/null && echo running || echo NOT running) · ipc: $(qs -c onyx ipc show 2>/dev/null | grep -o 'target [a-z]*' | awk '{print $2}' | tr '\n' ' ')"
