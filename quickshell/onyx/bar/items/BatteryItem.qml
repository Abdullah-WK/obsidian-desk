// UPower display device as a 22 px ring (2 px, success; error below 15 % on battery) with the
// percentage inside; a small bolt sits at the ring's shoulder while charging.
// Hidden without a battery. Popout: battery.
import QtQuick
import QtQuick.Shapes
import Quickshell.Services.UPower
import qs
import qs.bar
import qs.bar.popouts
import qs.components

BarItem {
    id: root

    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property real pct: dev?.percentage ?? 0
    readonly property bool charging: dev ? (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.FullyCharged) : false
    readonly property bool low: pct < 0.15 && !charging
    readonly property color tone: low ? Scheme.error : Scheme.success
    readonly property int ringSize: 22

    align: "right"
    popout: BatteryPopout {
        host: root.host
    }
    visible: dev ? dev.isLaptopBattery : false
    onActivated: host.openPopout(root)

    Item {
        width: root.ringSize
        height: root.ringSize
        anchors.verticalCenter: parent.verticalCenter

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            // track
            ShapePath {
                fillColor: "transparent"
                strokeColor: Scheme.outlineVariant
                strokeWidth: 2
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root.ringSize / 2
                    centerY: root.ringSize / 2
                    radiusX: root.ringSize / 2 - 1
                    radiusY: root.ringSize / 2 - 1
                    startAngle: 0
                    sweepAngle: 360
                }
            }
            // charge
            ShapePath {
                fillColor: "transparent"
                strokeColor: root.tone
                strokeWidth: 2
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: root.ringSize / 2
                    centerY: root.ringSize / 2
                    radiusX: root.ringSize / 2 - 1
                    radiusY: root.ringSize / 2 - 1
                    startAngle: -90
                    sweepAngle: Math.max(root.pct > 0 ? 4 : 0, 360 * root.pct)

                    Behavior on sweepAngle {
                        NumberAnimation {
                            duration: Theme.ring
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.standard
                        }
                    }
                }
            }
        }

        Ink {
            anchors.centerIn: parent
            mono: true
            // 100 is written as "00" would be confusing; drop to a smaller size instead
            text: Math.round(root.pct * 100)
            size: root.pct >= 0.995 ? 7 : 8.5
            font.weight: 500
            color: root.low ? Scheme.error : root.ink
            tracking: -0.04
        }

        // bolt at the ring's top-right shoulder while on mains
        Rectangle {
            visible: root.charging
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -3
            anchors.topMargin: -3
            width: 11
            height: 11
            radius: 5.5
            color: Scheme.background

            Icon {
                anchors.centerIn: parent
                text: "bolt"
                size: 9
                weight: 600
                fill: 1
                color: root.tone
            }
        }
    }
}
