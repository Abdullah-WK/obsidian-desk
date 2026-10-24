pragma ComponentBehavior: Bound
// session · user@host: lock, sleep, reboot, off tiles. Reboot and off need a 600 ms hold
// (error ring fills around the tile); release early cancels.
import QtQuick
import QtQuick.Shapes
import Quickshell
import qs
import qs.components
import qs.services

Column {
    id: root

    required property var host

    width: 216
    spacing: 10

    PopoutHeader {
        label: "session"
        value: SysInfo.userHost
    }

    component Tile: Item {
        id: tile

        required property string icon
        required property string label
        property bool hold: false
        property var action: () => {}

        property real progress: 0
        property bool done: false

        width: (root.width - 18) / 4
        height: 52

        function fire(): void {
            done = true;
            fireT.restart();
        }

        Timer {
            id: fireT
            interval: 200
            onTriggered: {
                tile.action();
                tile.done = false;
                tile.progress = 0;
            }
        }

        NumberAnimation {
            id: holdAnim
            target: tile
            property: "progress"
            from: 0
            to: 1
            duration: Theme.hold
            easing.type: Easing.Linear
            onFinished: if (tile.progress >= 1) tile.fire()
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.rItem
            color: tile.done ? Scheme.fgSurface : hh.hovered ? Scheme.surfaceContainerHigh : Scheme.surfaceContainer

            Behavior on color {
                ColorAnimation {
                    duration: Theme.colour
                }
            }
        }

        Shape {
            anchors.fill: parent
            visible: tile.progress > 0 && !tile.done
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                readonly property real perim: 2 * (tile.width + tile.height) - 8 * Theme.rItem + 2 * Math.PI * Theme.rItem
                strokeColor: Scheme.error
                strokeWidth: 2
                fillColor: "transparent"
                capStyle: ShapePath.FlatCap
                strokeStyle: ShapePath.DashLine
                dashPattern: [perim / 2, perim / 2]
                dashOffset: (perim / 2) * (1 - tile.progress)

                startX: tile.width / 2
                startY: 1
                PathLine { x: tile.width - Theme.rItem; y: 1 }
                PathArc { x: tile.width - 1; y: Theme.rItem; radiusX: Theme.rItem; radiusY: Theme.rItem }
                PathLine { x: tile.width - 1; y: tile.height - Theme.rItem }
                PathArc { x: tile.width - Theme.rItem; y: tile.height - 1; radiusX: Theme.rItem; radiusY: Theme.rItem }
                PathLine { x: Theme.rItem; y: tile.height - 1 }
                PathArc { x: 1; y: tile.height - Theme.rItem; radiusX: Theme.rItem; radiusY: Theme.rItem }
                PathLine { x: 1; y: Theme.rItem }
                PathArc { x: Theme.rItem; y: 1; radiusX: Theme.rItem; radiusY: Theme.rItem }
                PathLine { x: tile.width / 2; y: 1 }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4

            Icon {
                text: tile.icon
                size: 17
                color: tile.done ? Scheme.fgPrimary : tile.progress > 0 ? Scheme.error : Scheme.fgSurface
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Ink {
                mono: true
                text: tile.label + (tile.hold && tile.progress > 0 && !tile.done ? " · hold" : "")
                size: 9.5
                color: tile.done ? Scheme.fgPrimary : tile.progress > 0 ? Scheme.error : Scheme.fgSurfaceVariant
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        HoverHandler {
            id: hh
        }
        MouseArea {
            anchors.fill: parent
            onPressed: {
                if (tile.hold) {
                    holdAnim.restart();
                }
            }
            onReleased: {
                if (tile.hold && !tile.done) {
                    holdAnim.stop();
                    tile.progress = 0;
                }
            }
            onCanceled: {
                if (tile.hold && !tile.done) {
                    holdAnim.stop();
                    tile.progress = 0;
                }
            }
            onClicked: if (!tile.hold) tile.fire()
        }
    }

    Row {
        width: parent.width
        spacing: 6

        Tile {
            icon: "lock"
            label: "lock"
            action: () => {
                root.host.closePopout();
                root.host.lock.engage();
            }
        }
        Tile {
            icon: "bedtime"
            label: "sleep"
            action: () => Quickshell.execDetached(["systemctl", "suspend"])
        }
        Tile {
            icon: "cached"
            label: "reboot"
            hold: true
            action: () => Quickshell.execDetached(["systemctl", "reboot"])
        }
        Tile {
            icon: "power_settings_new"
            label: "off"
            hold: true
            action: () => Quickshell.execDetached(["systemctl", "poweroff"])
        }
    }

    PopCta {
        text: "reboot and off need a 600 ms hold"
    }
}
