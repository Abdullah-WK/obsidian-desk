// UPower display device: icon + percent. Hidden without a battery. Popout: battery.
import QtQuick
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
    readonly property string icon: {
        if (charging)
            return "battery_charging_full";
        if (pct >= 0.98)
            return "battery_full";
        const n = Math.max(0, Math.min(6, Math.round(pct * 6)));
        return `battery_${n}_bar`;
    }

    align: "right"
    popout: BatteryPopout {
        host: root.host
    }
    visible: dev ? dev.isLaptopBattery : false
    onActivated: host.openPopout(root)

    Icon {
        text: root.icon
        color: root.pct < 0.15 && !root.charging ? Scheme.error : root.ink
        anchors.verticalCenter: parent.verticalCenter
    }
    Ink {
        mono: true
        text: Math.round(root.pct * 100)
        size: Theme.barLabel
        color: root.ink
        anchors.verticalCenter: parent.verticalCenter
    }
}
