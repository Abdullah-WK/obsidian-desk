#!/usr/bin/env bash
# foot.ini touches (the file belongs to the Caelestia dots; backup kept). Idempotent.
F=${XDG_CONFIG_HOME:-$HOME/.config}/foot/foot.ini
[ -f "$F" ] || exit 0
cp -n "$F" "$F.bak-obsidian" 2>/dev/null
python3 - "$F" <<'PY'
import re,sys
p=sys.argv[1]; s=open(p).read()
s=re.sub(r'^pad=.*$','pad=14x14',s,flags=re.M)
s=re.sub(r'^alpha=.*$','alpha=1.0',s,flags=re.M)
def ensure(section,key,val):
    global s
    if re.search(rf'^\[{re.escape(section)}\]',s,flags=re.M):
        body=re.split(rf'^\[{re.escape(section)}\]\n',s,flags=re.M)
        head,rest=s.split(f'[{section}]\n',1)
        sec,_,tail=rest.partition('\n[')
        if re.search(rf'^{key}=',sec,flags=re.M): sec=re.sub(rf'^{key}=.*$',f'{key}={val}',sec,flags=re.M)
        else: sec=sec.rstrip('\n')+f'\n{key}={val}\n'
        s=head+f'[{section}]\n'+sec+('\n['+tail if _ else '')
    else:
        s=s.rstrip('\n')+f'\n\n[{section}]\n{key}={val}\n'
ensure('mouse','hide-when-typing','yes')
open(p,'w').write(s)
PY
echo "foot: pad 14x14, opaque, hide pointer while typing (Ctrl+Shift+U opens URLs by default)"
