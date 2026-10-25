pragma ComponentBehavior: Bound
// System tray (StatusNotifier): one bar item per client with an onyx popout that renders the
// client's own DBus menu (Discord: show, mute, deafen, quit …). Left click activates, middle
// click secondary-activates, scroll is forwarded. Clients in Config.trayHidden are skipped.
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs
import qs.bar
import qs.bar.popouts

Row {
    id: root

    required property var host

    readonly property var items: SystemTray.items.values.filter(i => !Config.trayHidden.some(h => (i.id || "").toLowerCase().includes(h.toLowerCase())))

    visible: items.length > 0
    spacing: Theme.itemGap
    anchors.verticalCenter: parent.verticalCenter

    Repeater {
        model: root.items

        BarItem {
            id: entry

            required property SystemTrayItem modelData

            host: root.host
            align: "right"
            popout: modelData.hasMenu ? trayPopout : null
            onActivated: {
                if (entry.modelData.onlyMenu && entry.modelData.hasMenu)
                    host.openPopout(entry);
                else
                    entry.modelData.activate();
            }
            onScrolled: delta => entry.modelData.scroll(delta, false)

            Component {
                id: trayPopout
                TrayPopout {
                    host: entry.host
                    item: entry.modelData
                }
            }

            Loader {
                active: entry.modelData.icon !== ""
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: IconImage {
                    implicitSize: Theme.iconSize
                    source: entry.modelData.icon
                    opacity: entry.hot ? 1 : 0.85
                }
            }

            TapHandler {
                acceptedButtons: Qt.MiddleButton
                onTapped: entry.modelData.secondaryActivate()
            }
        }
    }
}
