//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
// Obsidian desk companion shell: top bar (per screen), lock, desktop widgets (per screen).
// Run with `qs -c onyx`. IPC: `qs -c onyx ipc call bar pin|unpin|toggle`, `... lock lock|unlock|isLocked`.
import QtQuick
import Quickshell
import qs
import qs.bar
import qs.lock
import qs.wallpaper
import qs.widgets

ShellRoot {
    id: root

    Lock {
        id: sessionLock
    }

    // Login: hypr-obsidian.lua starts the shell with ONYX_LOCK_ON_START=1 once the lock is
    // verified, so the lock is the first thing on screen (hypr-user.lua re-asserts it after).
    Timer {
        running: Quickshell.env("ONYX_LOCK_ON_START") === "1"
        interval: 150
        onTriggered: sessionLock.engage()
    }

    WallpaperPicker {
        id: wallpaperPicker
    }

    Ipc {
        lock: sessionLock
        wallpaper: wallpaperPicker
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
