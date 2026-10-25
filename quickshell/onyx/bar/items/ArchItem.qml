// Arch glyph in archIce. Click → Caelestia launcher.
import QtQuick
import Quickshell
import qs
import qs.bar
import qs.bar.popouts
import qs.components
import qs.services

BarItem {
    id: root

    align: "left"
    popout: ArchPopout {
        host: root.host
    }
    onActivated: Quickshell.execDetached(["caelestia", "shell", "drawers", "toggle", "launcher"])

    Item {
        width: 20
        height: 20
        anchors.verticalCenter: parent.verticalCenter

        ArchGlyph {
            size: 20
            iridescent: true
            glow: root.hot ? 1 : 0.7

            Behavior on glow {
                NumberAnimation {
                    duration: Theme.colour
                }
            }
        }
        // pending updates badge
        Rectangle {
            visible: Updates.count > 0
            x: 14
            y: -2
            width: 7
            height: 7
            radius: 3.5
            color: Scheme.archIce
            border.width: 1
            border.color: Scheme.background
        }
    }
}
