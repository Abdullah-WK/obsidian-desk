//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
// Obsidian desk companion shell: top bar (per screen), lock, session screen, launcher,
// wallpaper picker, notifications, desktop widgets (per screen). Run with `qs -c onyx`.
// IPC: `qs -c onyx ipc call bar|lock|session|launcher|wallpaper …`.
//
// Login (ONYX_LOCK_ON_START=1, set by hypr-obsidian.lua once the lock is verified): the lock is
// created and engaged before anything else loads, so the lock surface is the first frame; the
// rest of the shell is brought up 400 ms later behind it.
import QtQuick
import Quickshell
import qs
import qs.bar
import qs.lock
import qs.wallpaper
import qs.session
import qs.launcher
import qs.notifications
import qs.widgets
import qs.corners
import qs.osd

ShellRoot {
    id: root

    readonly property bool lockFirst: Quickshell.env("ONYX_LOCK_ON_START") === "1"
    property bool restReady: !lockFirst

    Lock {
        id: sessionLock
        Component.onCompleted: if (root.lockFirst) engage()
    }

    Timer {
        running: root.lockFirst
        interval: 400
        onTriggered: root.restReady = true
    }

    Ipc {
        lock: sessionLock
        wallpaper: rest.item ? rest.item.wallpaper : null
        session: rest.item ? rest.item.session : null
        launcher: rest.item ? rest.item.launcher : null
    }

    Loader {
        id: rest
        active: root.restReady

        sourceComponent: Scope {
            readonly property alias wallpaper: wallpaperPicker
            readonly property alias session: sessionScreen
            readonly property alias launcher: launcher

            WallpaperPicker {
                id: wallpaperPicker
            }

            SessionScreen {
                id: sessionScreen
                lock: sessionLock
            }

            Popups {}

            Osd {}

            Launcher {
                id: launcher
                lock: sessionLock
                session: sessionScreen
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

                Corners {
                    required property ShellScreen modelData

                    screen: modelData
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
    }
}
