pragma Singleton
// Runtime state shared between screens: bar pin (IPC / Super+Shift+B / Esc).
import QtQuick
import Quickshell
import qs

Singleton {
    id: root

    property bool barPinned: Config.barPinned
}
