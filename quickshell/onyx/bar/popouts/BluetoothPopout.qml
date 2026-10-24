pragma ComponentBehavior: Bound
// bluetooth · on/off: paired devices (battery when exposed), connected = selected; click toggles.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs

Column {
    id: root

    required property var host

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var devices: Bluetooth.devices.values.filter(d => d.paired || d.connected).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))

    width: 196
    spacing: 10

    function iconFor(d: BluetoothDevice): string {
        const i = d.icon ?? "";
        if (i.includes("headset") || i.includes("headphone") || i.includes("audio"))
            return "headphones";
        if (i.includes("mouse"))
            return "mouse";
        if (i.includes("keyboard"))
            return "keyboard";
        if (i.includes("phone"))
            return "smartphone";
        if (i.includes("speaker"))
            return "speaker";
        return "bluetooth";
    }

    PopoutHeader {
        label: "bluetooth"
        value: root.adapter ? (root.adapter.enabled ? "on" : "off") : "none"
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: root.devices
            PopRow {
                required property BluetoothDevice modelData
                icon: root.iconFor(modelData)
                text: modelData.name || modelData.deviceName || modelData.address
                selected: modelData.connected
                trailing: modelData.connected ? (modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : "connected") : modelData.state === BluetoothDeviceState.Connecting ? "…" : "paired"
                onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            }
        }
        PopRow {
            visible: root.devices.length === 0
            icon: "bluetooth_searching"
            text: "No paired devices"
            enabled: false
        }
    }

    PopCta {
        text: "click → nexus bluetooth"
        clickable: true
        onClicked: {
            Quickshell.execDetached(["caelestia", "shell", "nexus", "open"]);
            root.host.closePopout();
        }
    }
}
