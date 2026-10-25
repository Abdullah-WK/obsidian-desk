#!/usr/bin/env bash
# dev helper: restart the installed companion shell and show its log head (refuses while locked)
[ "$(qs -c onyx ipc call lock isLocked 2>/dev/null)" = true ] && { echo "REFUSING: onyx holds the session lock"; exit 1; }
LOG=${XDG_CACHE_HOME:-$HOME/.cache}/onyx/dev.log; mkdir -p "$(dirname "$LOG")"
pkill -f '^qs -c onyx'; sleep 0.6
setsid -f sh -c "qs -c onyx > $LOG 2>&1"
sleep "${1:-5}"
sed 's/\x1b\[[0-9;]*m//g' "$LOG" | grep -v '^ *INFO' | grep -v textinput | head -"${2:-40}"
echo "== ipc =="; qs -c onyx ipc show 2>&1 | grep -o 'target [a-z]*' | tr '\n' ' '; echo
echo "== proc =="; ps -eo pid,rss,pcpu,args | grep 'qs -c onyx$' | grep -v grep
