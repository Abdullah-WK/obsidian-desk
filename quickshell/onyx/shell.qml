//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
// Obsidian desk companion shell: top bar (per screen), lock, desktop widgets (per screen).
// Run with `qs -c onyx`. IPC: `qs -c onyx ipc call bar pin|unpin|toggle`, `... lock lock|unlock|isLocked`.
import QtQuick
import Quickshell
import qs
import qs.bar
import qs.lock
import qs.widgets

ShellRoot {
    id: root

    Lock {
        id: sessionLock
    }

    Ipc {
        lock: sessionLock
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property ShellScreen modelData

            screen: modelData
            lock: sessionLock
        }
    }

    Variants {
        model: Quickshell.screens

        Widgets {
            required property ShellScreen modelData

            screen: modelData
        }
    }
}
