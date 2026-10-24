// IPC targets. `qs -c onyx ipc call bar pin|unpin|toggle|isPinned`
//              `qs -c onyx ipc call lock lock|unlock|isLocked`
import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.lock

Scope {
    id: root

    required property Lock lock

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
