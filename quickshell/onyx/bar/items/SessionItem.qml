// Power glyph. Popout: lock / sleep / reboot / off.
import QtQuick
import qs
import qs.bar
import qs.bar.popouts
import qs.components

BarItem {
    id: root

    align: "right"
    popout: SessionPopout {
        host: root.host
    }
    onActivated: host.openPopout(root)

    Icon {
        text: "power_settings_new"
        weight: 500
        color: root.hot ? "#ff3b5e" : Scheme.crimson

        Behavior on color {
            ColorAnimation {
                duration: Theme.colour
            }
        }
        anchors.verticalCenter: parent.verticalCenter
    }
}
