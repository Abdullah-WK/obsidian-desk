pragma ComponentBehavior: Bound
// WlSessionLock with one LockSurface per screen. Engaged by IPC (`lock lock`), the
// Hyprland global shortcut `onyx:lock` and Caelestia's idle action. Released only
// after the 640 ms close sequence (Config.lockDebugAutoUnlockSec releases early for §7).
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services

Scope {
    id: root

    readonly property bool locked: lock.locked
    readonly property alias state: state

    function engage(): void {
        if (lock.locked)
            return;
        state.reset();
        lock.locked = true;
        Weather.active = Config.lockShowWeather;
        state.startFprint();
    }

    function release(): void {
        releaseT.stop();
        state.stopFprint();
        lock.locked = false;
        state.unlocking = false;
        Weather.active = false;
    }

    LockState {
        id: state
        onSuccess: releaseT.restart()
    }

    Timer {
        id: releaseT
        interval: Theme.d(640) + 30
        onTriggered: root.release()
    }

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            id: surface

            color: "transparent"

            LockSurface {
                anchors.fill: parent
                state: root.state
                screen: surface.screen
            }
        }
    }

    GlobalShortcut {
        appid: "onyx"
        name: "lock"
        description: "Lock the session with the Obsidian lock"
        onPressed: root.engage()
    }

    Timer {
        running: lock.locked && Config.lockDebugAutoUnlockSec > 0
        interval: Config.lockDebugAutoUnlockSec * 1000
        onTriggered: {
            console.warn(`onyx: debug auto-unlock after ${Config.lockDebugAutoUnlockSec}s (set lockDebugAutoUnlockSec to 0 after §7)`);
            root.release();
        }
    }
}
