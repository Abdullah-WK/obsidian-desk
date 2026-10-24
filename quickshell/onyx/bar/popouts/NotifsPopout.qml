pragma ComponentBehavior: Bound
// notifications · N: DND switch in the header, last six notifications, clear all.
import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.components
import qs.services

Column {
    id: root

    required property var host

    width: 260
    spacing: 10

    Component.onCompleted: {
        Notifs.refreshDnd();
        Notifs.markSeen();
    }

    PopoutHeader {
        label: "notifications"
        value: Notifs.dnd ? "do not disturb" : (Notifs.list.length > 0 ? Notifs.list.length + "" : "none")
        showSwitch: true
        checked: !Notifs.dnd
        onToggled: Notifs.toggleDnd()
    }

    Column {
        width: parent.width
        spacing: 4

        Repeater {
            model: Notifs.list.slice(0, 6)

            Rectangle {
                id: card
                required property var modelData
                width: parent.width
                height: cardRow.implicitHeight + 16
                radius: Theme.rItem
                color: Scheme.surfaceContainer
                border.width: 1
                border.color: Scheme.outlineVariant

                Row {
                    id: cardRow
                    x: 10
                    y: 8
                    width: parent.width - 20
                    spacing: 10

                    Item {
                        width: 16
                        height: 16
                        Loader {
                            anchors.fill: parent
                            active: !!card.modelData.appIcon
                            sourceComponent: IconImage {
                                source: Quickshell.iconPath(card.modelData.appIcon, "notifications")
                            }
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: !card.modelData.appIcon
                            text: "notifications"
                            size: 16
                            color: Scheme.fgSurfaceVariant
                        }
                    }
                    Column {
                        width: parent.width - 26 - ageText.implicitWidth - 10
                        spacing: 2
                        Ink {
                            text: card.modelData.summary || card.modelData.appName || ""
                            size: 12
                            font.weight: 500
                            width: parent.width
                        }
                        Ink {
                            visible: text !== ""
                            text: (card.modelData.body || "").replace(/\s+/g, " ")
                            size: 11
                            color: Scheme.fgSurfaceVariant
                            width: parent.width
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                            elide: Text.ElideRight
                        }
                    }
                    Ink {
                        id: ageText
                        mono: true
                        text: Notifs.age(card.modelData.time)
                        size: 10
                        color: Scheme.outline
                    }
                }
            }
        }

        Ink {
            visible: Notifs.list.length === 0
            mono: true
            text: "nothing new"
            size: 11.5
            color: Scheme.outline
            height: 24
        }
    }

    PopCta {
        text: Notifs.list.length > 0 ? "clear all" : "notifications stay here until cleared"
        clickable: Notifs.list.length > 0
        onClicked: Notifs.clear()
    }
}
