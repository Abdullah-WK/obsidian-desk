pragma ComponentBehavior: Bound
// Two 3×10 bars (cpu, mem) + labels. Polls (2 s) only while the bar is shown.
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
    onConsumingChanged: SysStats.fast += consuming ? 1 : -1
    Component.onCompleted: if (consuming) SysStats.fast++
    Component.onDestruction: if (consuming) SysStats.fast--

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
