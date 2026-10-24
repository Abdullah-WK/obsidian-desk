pragma ComponentBehavior: Bound
// performance · 2 s: cpu, mem (GB), gpu, nvme (%), temp (°C). Polls only while loaded.
import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

Column {
    id: root

    required property var host

    width: 226
    spacing: 10

    Component.onCompleted: SysStats.fast++
    Component.onDestruction: SysStats.fast--

    PopoutHeader {
        label: "performance"
        value: "2 s"
    }

    component Bar: Item {
        required property string label
        required property real value
        required property string display
        width: parent.width
        implicitHeight: 14

        Ink {
            mono: true
            text: parent.label
            size: 11
            color: Scheme.fgSurfaceVariant
            width: 34
            anchors.verticalCenter: parent.verticalCenter
        }
        Meter {
            x: 44
            width: parent.width - 44 - 52
            value: parent.value
            thickness: 5
            anchors.verticalCenter: parent.verticalCenter
        }
        Ink {
            mono: true
            text: parent.display
            size: 11
            color: Scheme.fgSurface
            horizontalAlignment: Text.AlignRight
            width: 42
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Column {
        width: parent.width
        spacing: 6
        Bar {
            label: "cpu"
            value: SysStats.cpu
            display: Math.round(SysStats.cpu * 100) + "%"
        }
        Bar {
            label: "mem"
            value: SysStats.mem
            display: SysStats.memUsed.toFixed(1) + "G"
        }
        Bar {
            label: "gpu"
            value: SysStats.gpuOff ? 0 : SysStats.gpu
            display: SysStats.gpuOff ? "off" : Math.round(SysStats.gpu * 100) + "%"
        }
        Bar {
            label: "nvme"
            value: SysStats.disk
            display: Math.round(SysStats.disk * 100) + "%"
        }
        Bar {
            label: "cpu°"
            value: SysStats.temp / 100
            display: Math.round(SysStats.temp) + "°"
        }
        Bar {
            label: "gpu°"
            value: SysStats.gpuOff ? 0 : SysStats.gpuTemp / 100
            display: SysStats.gpuOff ? "off" : Math.round(SysStats.gpuTemp) + "°"
        }
    }

    PopCta {
        text: "click → " + Config.perfCommand.slice(-1)[0] + " · red above 85%"
        clickable: true
        onClicked: {
            Quickshell.execDetached(Config.perfCommand);
            root.host.closePopout();
        }
    }
}
