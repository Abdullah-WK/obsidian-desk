# shellcheck shell=bash
# Shared helpers for install.sh / uninstall.sh / enable-lock.sh (sourced, not run).
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CFG=${XDG_CONFIG_HOME:-$HOME/.config}
STATE=${XDG_STATE_HOME:-$HOME/.local/state}
CAE=$CFG/caelestia
ONYX_CFG=$CFG/onyx
MARKER=$ONYX_CFG/.lock-verified
BACKUPS=$STATE/caelestia/backups
THEME_GTK=$STATE/caelestia/theme/gtk.css

c_bold=$'\e[1m'; c_dim=$'\e[2m'; c_warn=$'\e[33m'; c_ok=$'\e[32m'; c_off=$'\e[0m'
step() { printf '\n%s== %s%s\n' "$c_bold" "$*" "$c_off"; }
ok()   { printf '  %s✓%s %s\n' "$c_ok" "$c_off" "$*"; }
warn() { printf '  %s!%s %s\n' "$c_warn" "$c_off" "$*"; }
note() { printf '  %s·%s %s\n' "$c_dim" "$c_off" "$*"; }
todo() { TODO+=("$*"); printf '  %s→ run yourself:%s %s\n' "$c_warn" "$c_off" "$*"; }
TODO=()

# backup <path>: copies <path> (file, dir or symlink) into $BK keeping its absolute path.
backup() {
    local p=$1
    [ -e "$p" ] || [ -L "$p" ] || return 0
    mkdir -p "$BK$(dirname "$p")"
    cp -a "$p" "$BK$p"
}

# show_diff <old> <new>
show_diff() {
    if [ -e "$1" ]; then
        diff -u --label "before" --label "after" "$1" "$2" | sed 's/^/    /' | head -80 || true
    else
        note "new file"
    fi
}

scheme_dir() {
    local py
    py=$(head -1 "$(command -v caelestia)" 2>/dev/null | sed -n 's/^#!//p' | awk '{print $1}')
    [ -x "$py" ] || py=python3
    "$py" -c 'import caelestia.utils.paths as p; print(p.scheme_data_dir)' 2>/dev/null
}

# merge_json <dest> <overlay> [python-expression applied to merged dict as `d`]
# Deep merge: overlay wins on leaves, objects merge, arrays are replaced; other keys kept.
merge_json() {
    python3 - "$1" "$2" "${3:-}" <<'PY'
import json, sys, os
dest, overlay, post = sys.argv[1], sys.argv[2], sys.argv[3]
def load(p):
    try:
        with open(p) as f: return json.load(f)
    except FileNotFoundError: return {}
def merge(a, b):
    for k, v in b.items():
        if isinstance(v, dict) and isinstance(a.get(k), dict): merge(a[k], v)
        else: a[k] = v
    return a
d = merge(load(dest), load(overlay))
if post: exec(post, {"d": d})
os.makedirs(os.path.dirname(dest), exist_ok=True)
tmp = dest + ".tmp"
with open(tmp, "w") as f: json.dump(d, f, indent=4); f.write("\n")
os.replace(tmp, dest)
PY
}

# idle lock action: Caelestia's lock until the §7 marker exists, then the companion lock.
idle_lock_post() {
    if [ -e "$MARKER" ]; then
        echo 't=d.setdefault("general",{}).setdefault("idle",{}).get("timeouts",[])
if t: t[0]["idleAction"]=["qs","-c","onyx","ipc","call","lock","lock"]'
    else
        echo 't=d.setdefault("general",{}).setdefault("idle",{}).get("timeouts",[])
if t: t[0]["idleAction"]="lock"'
    fi
}
