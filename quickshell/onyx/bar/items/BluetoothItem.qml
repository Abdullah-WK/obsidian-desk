// Adapter state icon. Click toggles the adapter. Popout: paired devices.
import QtQuick
import Quickshell.Bluetooth
import qs
import qs.bar
import qs.bar.popouts
import qs.components

BarItem {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool on: adapter?.enabled ?? false
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)
    readonly property string icon: !on ? "bluetooth_disabled" : connected ? "bluetooth_connected" : "bluetooth"

    align: "right"
    popout: BluetoothPopout {
        host: root.host
    }
    visible: adapter !== null

    onActivated: if (adapter) adapter.enabled = !adapter.enabled

    Icon {
        text: root.icon
        color: root.ink
        anchors.verticalCenter: parent.verticalCenter
    }
}
