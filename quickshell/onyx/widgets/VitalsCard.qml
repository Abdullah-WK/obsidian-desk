pragma ComponentBehavior: Bound
// cpu, mem, nvme, temp, net with 6 px tracks. 5 s interval only while the card is visible.
import QtQuick
import qs
import qs.components
import qs.services

Card {
    id: root

    property bool live: false

    title: "vitals"
    interval: "5 s"

    onLiveChanged: SysStats.slow += live ? 1 : -1
    Component.onCompleted: if (live) SysStats.slow++
    Component.onDestruction: if (live) SysStats.slow--

    component Row_: Item {
        required property string label
        required property real value
        required property string display
        width: parent.width
        height: 22

        Ink {
            mono: true
            text: parent.label
            size: 12.5
            color: Scheme.fgSurfaceVariant
            width: 40
            anchors.verticalCenter: parent.verticalCenter
        }
        Meter {
            x: 52
            width: parent.width - 52 - 60
            value: parent.value
            thickness: 6
            anchors.verticalCenter: parent.verticalCenter
        }
        Ink {
            mono: true
            text: parent.display
            size: 12.5
            color: Scheme.fgSurface
            horizontalAlignment: Text.AlignRight
            width: 48
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Column {
        width: parent.width
        spacing: 2

        Row_ {
            label: "cpu"
            value: SysStats.cpu
            display: Math.round(SysStats.cpu * 100) + "%"
        }
        Row_ {
            label: "mem"
            value: SysStats.mem
            display: SysStats.memUsed.toFixed(1) + "G"
        }
        Row_ {
            label: "nvme"
            value: SysStats.disk
            display: Math.round(SysStats.disk * 100) + "%"
        }
        Row_ {
            label: "cpu°"
            value: SysStats.temp / 100
            display: Math.round(SysStats.temp) + "°"
        }
        Row_ {
            label: "gpu°"
            value: SysStats.gpuOff ? 0 : SysStats.gpuTemp / 100
            display: SysStats.gpuOff ? "off" : Math.round(SysStats.gpuTemp) + "°"
        }
        Row_ {
            label: "net"
            value: Math.min(1, SysStats.netRx / (12.5 * 1048576))
            display: SysStats.fmtRate(SysStats.netRx) + "↓"
        }
    }
}
