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
        color: root.ink
        anchors.verticalCenter: parent.verticalCenter
    }
}
