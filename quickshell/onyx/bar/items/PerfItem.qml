pragma ComponentBehavior: Bound
// Two 3×12 bars (cpu, mem) + labels. Polls at the slow rate (5 s) while the bar is shown;
// the popout switches SysStats to 2 s while it is open.
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
    contentSpacing: 8
    onActivated: Quickshell.execDetached(Config.perfCommand)

    readonly property bool consuming: host.shown
    onConsumingChanged: SysStats.slow += consuming ? 1 : -1
    Component.onCompleted: if (consuming) SysStats.slow++
    Component.onDestruction: if (consuming) SysStats.slow--

    component Gauge: Row {
        required property string label
        required property real value
        spacing: 3
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            width: 3
            height: 12
            radius: 1
            color: Scheme.outlineVariant
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.round(Math.max(0, Math.min(1, parent.parent.value)) * parent.height)
                radius: 1
                color: parent.parent.value > 0.85 ? Scheme.error : Scheme.fgSurfaceVariant
            }
        }
        Ink {
            mono: true
            text: parent.label
            size: Theme.barLabel
            color: root.ink
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
