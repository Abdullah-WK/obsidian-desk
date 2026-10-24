pragma ComponentBehavior: Bound
// System tray (StatusNotifier): one 15 px icon per client. Left click activates, middle click
// secondary-activates, right click opens the client's menu, scroll is forwarded.
// Clients listed in Config.trayHidden are skipped. Hidden entirely when there is nothing to show.
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs
import qs.bar

BarItem {
    id: root

    readonly property var items: SystemTray.items.values.filter(i => !Config.trayHidden.some(h => (i.id || "").toLowerCase().includes(h.toLowerCase())))

    visible: items.length > 0
    interactive: false
    contentSpacing: 6

    Repeater {
        model: root.items

        Item {
            id: entry

            required property SystemTrayItem modelData

            width: Theme.iconSize + 6
            height: Theme.itemHeight
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: Theme.rChip
                color: hh.hovered ? Scheme.surfaceContainer : "transparent"

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.popout
                    }
                }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: Theme.iconSize
                source: entry.modelData.icon
                opacity: hh.hovered ? 1 : 0.85
            }

            QsMenuAnchor {
                id: menu
                menu: entry.modelData.menu
                anchor.item: entry
                anchor.rect.y: entry.height + Theme.popoutGap
            }

            HoverHandler {
                id: hh
            }
            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: {
                    if (entry.modelData.onlyMenu && entry.modelData.hasMenu)
                        menu.open();
                    else
                        entry.modelData.activate();
                }
            }
            TapHandler {
                acceptedButtons: Qt.MiddleButton
                onTapped: entry.modelData.secondaryActivate()
            }
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: if (entry.modelData.hasMenu) menu.open()
            }
            WheelHandler {
                onWheel: event => entry.modelData.scroll(event.angleDelta.y, false)
            }
        }
    }
}
