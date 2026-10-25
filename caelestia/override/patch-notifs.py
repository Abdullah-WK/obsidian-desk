#!/usr/bin/env python3
"""Stop Caelestia's own notification server from registering (onyx owns the bus name).
Patches ~/.config/quickshell/caelestia/services/Notifs.qml in place (backup .bak-onyx-notifs).
Idempotent; run with --undo to restore the backup."""
import os, shutil, sys
p = os.path.expanduser("~/.config/quickshell/caelestia/services/Notifs.qml")
bak = p + ".bak-onyx-notifs"
if "--undo" in sys.argv:
    if os.path.exists(bak):
        shutil.move(bak, p); print("restored Caelestia's notification server")
    sys.exit(0)
if not os.path.exists(p):
    print("no Caelestia override at", p, "(nothing to patch; Caelestia's packaged server stays active)"); sys.exit(0)
s = open(p).read()
if "onyx owns org.freedesktop.Notifications" in s:
    print("already patched"); sys.exit(0)
old = "    NotificationServer {\n        id: server\n\n        keepOnReload: false"
new = ("    // onyx owns org.freedesktop.Notifications (see ~/Projects/obsidian-desk, notifications/).\n"
       "    // The server is kept but never created, so Caelestia's popups, dock and lock list stay empty.\n"
       "    QtObject {\n        id: server\n        readonly property var trackedNotifications: ({ values: [] })\n    }\n\n"
       "    Component {\n        id: disabledServer\n    NotificationServer {\n        keepOnReload: false")
marker = "    FileView {\n        id: storage"
if old not in s or marker not in s:
    print("unexpected Notifs.qml layout; not patched"); sys.exit(1)
shutil.copy(p, bak)
s = s.replace(old, new, 1).replace(marker, "    }\n\n" + marker, 1)
open(p, "w").write(s)
print("patched (backup", bak + ")")
