// Bell with an unread dot; popout lists recent notifications with DND and clear-all.
import QtQuick
import qs
import qs.bar
import qs.bar.popouts
import qs.components
import qs.services

BarItem {
    id: root

    align: "right"
    popout: NotifsPopout {
        host: root.host
    }
    onActivated: host.openPopout(root)

    Item {
        width: Theme.iconSize
        height: Theme.iconSize
        anchors.verticalCenter: parent.verticalCenter

        Icon {
            anchors.centerIn: parent
            text: Notifs.dnd ? "notifications_off" : "notifications"
            color: root.ink
        }
        Rectangle {
            visible: Notifs.unread > 0 && !Notifs.dnd
            x: parent.width - 6
            y: -1
            width: 7
            height: 7
            radius: 3.5
            color: Scheme.primary
            border.width: 1
            border.color: Scheme.background
        }
    }
}
