#!/usr/bin/env bash
# dev helper: start|stop the windowed lock harness (keeps the launch path out of the caller's argv)
LOG=${XDG_CACHE_HOME:-$HOME/.cache}/onyx/harness.log; mkdir -p "$(dirname "$LOG")"
case "$1" in
  start) setsid -f sh -c "qs -p $HOME/.config/quickshell/onyx/LockHarness.qml > $LOG 2>&1" >/dev/null 2>&1 </dev/null ;;
  stop) pkill -f 'LockHarnes[s].qml' ;;
esac
