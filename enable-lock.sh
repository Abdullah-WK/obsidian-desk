#!/usr/bin/env bash
# §7 step 4: after three clean lock/unlock cycles, switch the debug auto-unlock off and
# point Super+L, the idle timeout and the login lock at the companion lock.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
if [ "${1:-}" = "--undo" ]; then
    rm -f "$MARKER"; echo "marker removed; re-running install.sh restores Caelestia's lock bindings"; exec "$HERE/install.sh"
fi
if [ "$(qs -c onyx ipc call lock isLocked 2>/dev/null)" = "true" ]; then
    echo "the companion lock is engaged right now; unlock first"; exit 1
fi
mkdir -p "$ONYX_CFG"; touch "$MARKER"
python3 - "$ONYX_CFG/config.json" <<'PY'
import json,sys; p=sys.argv[1]; d=json.load(open(p)); d["lockDebugAutoUnlockSec"]=0; json.dump(d,open(p,"w"),indent=2)
PY
ok "lockDebugAutoUnlockSec = 0"
merge_json "$CAE/shell.json" "$HERE/caelestia/shell.json" "$(idle_lock_post)"
ok "shell.json idle lock → qs -c onyx ipc call lock lock"
hyprctl reload >/dev/null 2>&1 && ok "hyprctl reload: Super+L → companion lock, Super+Alt+L → Caelestia lock, login lock → companion"
note "Caelestia's lock stays installed (lockBeforeSleep fallback)."
