pragma ComponentBehavior: Bound
// cpu / mem as "label value%" with a 2 px meter underneath each. Polls at the slow rate (5 s)
// while the bar is shown; the popout switches SysStats to 2 s while it is open.
// Click → Config.perfCommand. Popout: performance bars.
import QtQuick
import Quickshell
import qs
import qs.bar
import qs.bar.popouts
import qs.components
import qs.services

BarItem {
    id: root

    align: "right"
    popout: PerfPopout {
        host: root.host
    }
    contentSpacing: 10
    onActivated: Quickshell.execDetached(Config.perfCommand)

    readonly property bool consuming: host.shown
    onConsumingChanged: SysStats.slow += consuming ? 1 : -1
    Component.onCompleted: if (consuming) SysStats.slow++
    Component.onDestruction: if (consuming) SysStats.slow--

    component Gauge: Column {
        id: gauge
        required property string label
        required property real value
        readonly property real v: Math.max(0, Math.min(1, value))
        readonly property bool high: v > 0.85
        spacing: 3
        anchors.verticalCenter: parent.verticalCenter

        Row {
            spacing: 4
            Ink {
                mono: true
                text: gauge.label
                size: Theme.barLabel
                color: Scheme.fgSurfaceVariant
            }
            Ink {
                mono: true
                // fixed 3-cell width so the row does not jitter between 7 % and 100 %
                text: Math.round(gauge.v * 100) + "%"
                size: Theme.barLabel
                color: gauge.high ? Scheme.error : root.ink
                width: metrics.width
                horizontalAlignment: Text.AlignRight

                TextMetrics {
                    id: metrics
                    font.family: Theme.mono
                    font.pointSize: Math.max(1, Theme.barLabel * 0.75)
                    text: "100%"
                }
            }
        }

        // meter: track outlineVariant, fill onSurfaceVariant (error above 85 %)
        Rectangle {
            width: parent.width
            height: 2
            radius: 1
            color: Scheme.outlineVariant

            Rectangle {
                width: Math.round(parent.width * gauge.v)
                height: parent.height
                radius: 1
                color: gauge.high ? Scheme.error : Scheme.fgSurfaceVariant

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.ring
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.standard
                    }
                }
            }
        }
    }

    Gauge {
        label: "cpu"
        value: SysStats.cpu
    }
    Gauge {
        label: "mem"
        value: SysStats.mem
    }
}
