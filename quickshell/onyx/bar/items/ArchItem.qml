// Arch glyph in archIce. Click → Caelestia launcher.
import QtQuick
import Quickshell
import qs
import qs.bar
import qs.bar.popouts
import qs.components

BarItem {
    id: root

    align: "left"
    popout: ArchPopout {
        host: root.host
    }
    onActivated: Quickshell.execDetached(["caelestia", "shell", "drawers", "toggle", "launcher"])

    ArchGlyph {
        size: 14
        anchors.verticalCenter: parent.verticalCenter
    }
}
