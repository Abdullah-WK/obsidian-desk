#!/usr/bin/env bash
# Obsidian desk installer (idempotent, run as the user). Root-only steps are printed as
# commands for you to run; re-run this script afterwards to finish.
set -uo pipefail
source "$(dirname "$0")/lib.sh"
BK=$BACKUPS/obsidian-$(date +%F-%H%M%S)
mkdir -p "$BK"
printf '%sObsidian desk · install%s\n' "$c_bold" "$c_off"
note "backups → $BK"
cp -a "$STATE/caelestia/scheme.json" "$BK/scheme-before.json" 2>/dev/null || true

# 1 ─ packages ---------------------------------------------------------------------
step "1 packages"
have() { pacman -Q "$1" >/dev/null 2>&1 || pacman -Q "$1-git" >/dev/null 2>&1; }
missing=()
for p in inter-font ttf-jetbrains-mono-nerd pacman-contrib papirus-icon-theme adw-gtk-theme quickshell; do
    have "$p" && ok "$p" || missing+=("$p")
done
for p in papirus-folders power-profiles-daemon; do have "$p" && ok "$p (optional)" || note "$p not installed (optional)"; done
if ((${#missing[@]})); then
    todo "sudo pacman -S --needed ${missing[*]}"
fi
[ "$(fc-list : family | grep -ci "^Inter")" -gt 0 ] && ok "font Inter" || warn "font Inter missing until inter-font is installed (Caelestia and the companion fall back)"
[ "$(fc-list : family | grep -c "JetBrainsMono Nerd Font")" -gt 0 ] && ok "font JetBrainsMono Nerd Font" || warn "JetBrainsMono Nerd Font missing"

# 2 ─ scheme into the CLI data dir --------------------------------------------------
step "2 colour scheme"
SCHEME_DIR=$(scheme_dir)
SCHEME_OK=0
if [ -z "$SCHEME_DIR" ]; then
    warn "could not resolve caelestia's scheme_data_dir"
else
    target=$SCHEME_DIR/onyx/obsidian/dark.txt
    if cmp -s "$HERE/scheme/dark.txt" "$target" 2>/dev/null; then
        ok "scheme present: $target"; SCHEME_OK=1
    elif sudo -n install -Dm644 "$HERE/scheme/dark.txt" "$target" 2>/dev/null; then
        ok "scheme installed: $target"; SCHEME_OK=1
    else
        todo "sudo install -Dm644 $HERE/scheme/dark.txt $target"
    fi
fi

# 3 ─ shell.json / cli.json ------------------------------------------------------------
step "3 caelestia config"
for f in shell.json cli.json; do
    backup "$CAE/$f"
    tmp=$(mktemp)
    [ -e "$CAE/$f" ] && cp "$CAE/$f" "$tmp"
    if [ "$f" = shell.json ]; then
        merge_json "$CAE/$f" "$HERE/caelestia/$f" "$(idle_lock_post)"
    else
        merge_json "$CAE/$f" "$HERE/caelestia/$f"
    fi
    ok "$f merged (your extra keys kept)"
    show_diff "$tmp" "$CAE/$f"
    rm -f "$tmp"
done
[ -e "$MARKER" ] || note "idle lock action stays on Caelestia's lock until enable-lock.sh records a passed §7 test"

# 4 ─ template + hook ----------------------------------------------------------------
step "4 gtk template and post-scheme hook"
mkdir -p "$CAE/templates" "$CAE/hooks"
backup "$CAE/templates/gtk.css"; install -m644 "$HERE/caelestia/templates/gtk.css" "$CAE/templates/gtk.css"; ok "templates/gtk.css"
backup "$CAE/hooks/post-scheme.sh"; install -m755 "$HERE/caelestia/hooks/post-scheme.sh" "$CAE/hooks/post-scheme.sh"; ok "hooks/post-scheme.sh"
if [ -e "$CAE/templates/thunar-graphite.css" ]; then
    backup "$CAE/templates/thunar-graphite.css"; rm -f "$CAE/templates/thunar-graphite.css" "$STATE/caelestia/theme/thunar-graphite.css"
    note "removed the older thunar-graphite.css template (superseded; copy in backup)"
fi

# 5 ─ apply the scheme -----------------------------------------------------------------
step "5 apply scheme"
if ((SCHEME_OK)); then
    caelestia scheme set -n onyx -f obsidian -m dark && ok "caelestia scheme set -n onyx -f obsidian -m dark"
else
    # render the template with the current scheme so the GTK symlink has a target now
    read -r n fl m v < <(python3 -c 'import json;d=json.load(open("'"$STATE"'/caelestia/scheme.json"));print(d["name"],d["flavour"],d["mode"],d.get("variant",""))' 2>/dev/null || echo "")
    if [ -n "${n:-}" ]; then
        if [ "$n" = dynamic ]; then caelestia scheme set -n "$n" -f "$fl" -m "$m" -v "$v" >/dev/null 2>&1; else caelestia scheme set -n "$n" -f "$fl" -m "$m" >/dev/null 2>&1; fi
        warn "onyx scheme not installed yet: templates rendered with the current scheme ($n/$fl/$m)"
    fi
    todo "caelestia scheme set -n onyx -f obsidian -m dark   # after the sudo install above"
fi

# 6 ─ GTK symlinks ------------------------------------------------------------------------
step "6 gtk symlinks"
for v in gtk-3.0 gtk-4.0; do
    d=$CFG/$v; mkdir -p "$d"
    if [ -L "$d/gtk.css" ] && [ "$(readlink "$d/gtk.css")" = "$THEME_GTK" ]; then
        ok "$v/gtk.css already linked"
    else
        backup "$d/gtk.css"; ln -sfn "$THEME_GTK" "$d/gtk.css"; ok "$v/gtk.css → $THEME_GTK"
    fi
    if [ -e "$d/thunar.css" ]; then backup "$d/thunar.css"; rm -f "$d/thunar.css"; note "$v/thunar.css removed (stale CLI output)"; fi
done
[ -e "$THEME_GTK" ] || warn "$THEME_GTK does not exist yet (appears after the scheme is applied)"

# 7 ─ dconf ----------------------------------------------------------------------------------
step "7 gtk settings"
bash "$CAE/hooks/post-scheme.sh" && ok "gtk-theme adw-gtk3-dark · color-scheme prefer-dark · icon-theme Papirus-Dark"
if command -v papirus-folders >/dev/null 2>&1; then
    cur=$(papirus-folders -l --theme Papirus-Dark 2>/dev/null | grep -o '>.*' | tr -d '> ' || true)
    [ "$cur" = grey ] && ok "Papirus folders grey" || todo "sudo papirus-folders -C grey --theme Papirus-Dark"
fi
bash "$HERE/thunar/apply.sh" >/dev/null && ok "thunar xfconf applied"

# 8 ─ companion config -----------------------------------------------------------------------
step "8 companion quickshell config"
dest=$CFG/quickshell/onyx
if [ -L "$dest" ]; then rm -f "$dest"; note "replaced symlink $dest"; fi
mkdir -p "$dest"
rsync -a --delete --exclude '_*' "$HERE/quickshell/onyx/" "$dest/" && ok "$dest"
mkdir -p "$ONYX_CFG"
if [ -e "$ONYX_CFG/config.json" ]; then
    backup "$ONYX_CFG/config.json"
    # add new defaults, keep the user's values
    python3 - "$ONYX_CFG/config.json" "$HERE/onyx/config.json" <<'PY'
import json,sys
user=json.load(open(sys.argv[1])); dflt=json.load(open(sys.argv[2]))
def fill(a,b):
    for k,v in b.items():
        if k not in a: a[k]=v
        elif isinstance(v,dict) and isinstance(a[k],dict): fill(a[k],v)
fill(user,dflt); json.dump(user,open(sys.argv[1],"w"),indent=2)
PY
    ok "onyx/config.json kept (new keys added)"
else
    install -m644 "$HERE/onyx/config.json" "$ONYX_CFG/config.json"; ok "onyx/config.json"
fi

# 9 ─ hyprland ---------------------------------------------------------------------------------
step "9 hyprland"
if [ -e "$CFG/hypr/hyprland.lua" ]; then
    for f in hypr-vars.lua hypr-user.lua; do
        backup "$CAE/$f"
        if ! cmp -s "$HERE/hypr/$f" "$CAE/$f"; then
            tmp=$(mktemp); [ -e "$CAE/$f" ] && cp "$CAE/$f" "$tmp"
            install -m644 "$HERE/hypr/$f" "$CAE/$f"; ok "$CAE/$f"; show_diff "$tmp" "$CAE/$f"; rm -f "$tmp"
        else ok "$CAE/$f unchanged"; fi
    done
    backup "$CAE/hypr-obsidian.lua"; install -m644 "$HERE/hypr/obsidian.lua" "$CAE/hypr-obsidian.lua"; ok "$CAE/hypr-obsidian.lua (required from hypr-user.lua)"
    hyprctl reload >/dev/null 2>&1 && ok "hyprctl reload"
    errs=$(hyprctl configerrors 2>/dev/null | grep -v '^$' || true)
    [ -z "$errs" ] || [ "$errs" = "no errors" ] && ok "hyprctl configerrors: none" || warn "hyprctl configerrors: $errs"
else
    note "classic hyprland.conf detected: add 'source = $HERE/hypr/obsidian.conf' to ~/.config/hypr/hyprland.conf"
fi

# 10 ─ start the companion ------------------------------------------------------------------
step "10 start"
if pgrep -u "$UID" -f '^qs -c onyx' >/dev/null; then
    qs -c onyx kill >/dev/null 2>&1; sleep 0.5
fi
setsid -f qs -c onyx >/dev/null 2>&1
for _ in $(seq 40); do qs -c onyx ipc show >/dev/null 2>&1 && break; sleep 0.25; done
targets=$(qs -c onyx ipc show 2>/dev/null | grep -o 'target [a-z]*' | awk '{print $2}' | sort | tr '\n' ' ')
case "$targets" in *bar*lock*) ok "qs -c onyx running · ipc targets: $targets";; *) warn "qs -c onyx ipc targets: '$targets' (expected bar lock) — see: qs -c onyx log";; esac

# 11 ─ summary ----------------------------------------------------------------------------------
step "summary"
note "backups in $BK · revert with: $HERE/uninstall.sh $BK"
if [ -e "$MARKER" ]; then
    ok "companion lock is live (Super+L, idle, login)"
else
    note "lock: test per §7 with 'qs -c onyx ipc call lock lock' (30 s debug auto-unlock is on), then run $HERE/enable-lock.sh"
fi
if ((${#TODO[@]})); then
    printf '\n%sroot steps still needed (then re-run install.sh):%s\n' "$c_warn" "$c_off"
    printf '  %s\n' "${TODO[@]}"
fi
