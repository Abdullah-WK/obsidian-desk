// IPC targets. `qs -c onyx ipc call bar pin|unpin|toggle|isPinned`
//              `qs -c onyx ipc call lock lock|unlock|isLocked`
//              `qs -c onyx ipc call wallpaper open|close|toggle`
import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.lock
import qs.wallpaper

Scope {
    id: root

    required property Lock lock
    required property WallpaperPicker wallpaper

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
