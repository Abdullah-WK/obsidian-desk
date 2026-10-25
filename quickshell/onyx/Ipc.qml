// IPC targets. `qs -c onyx ipc call bar pin|unpin|toggle|isPinned`
//              `qs -c onyx ipc call lock lock|unlock|isLocked`
//              `qs -c onyx ipc call wallpaper open|close|toggle`
//              `qs -c onyx ipc call session open|close|toggle`
//              `qs -c onyx ipc call launcher open|close|toggle`
import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.lock
import qs.wallpaper
import qs.session
import qs.launcher

Scope {
    id: root

    required property Lock lock
    required property WallpaperPicker wallpaper
    required property SessionScreen session
    required property Launcher launcher

    IpcHandler {
        target: "bar"

        function pin(): void {
            Runtime.barPinned = true;
        }
        function unpin(): void {
            Runtime.barPinned = false;
        }
        function toggle(): void {
            Runtime.barPinned = !Runtime.barPinned;
        }
        function isPinned(): bool {
            return Runtime.barPinned;
        }
    }

    IpcHandler {
        target: "wallpaper"

        function open(): void {
            root.wallpaper.show();
        }
        function close(): void {
            root.wallpaper.hide();
        }
        function toggle(): void {
            root.wallpaper.toggle();
        }
    }

    IpcHandler {
        target: "launcher"

        function open(): void {
            root.launcher.show();
        }
        function close(): void {
            root.launcher.hide();
        }
        function toggle(): void {
            root.launcher.toggle();
        }
    }

    IpcHandler {
        target: "session"

        function open(): void {
            root.session.show();
        }
        function close(): void {
            root.session.hide();
        }
        function toggle(): void {
            root.session.toggle();
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock.engage();
        }
        function unlock(): void {
            root.lock.release();
        }
        function isLocked(): bool {
            return root.lock.locked;
        }
    }
}
