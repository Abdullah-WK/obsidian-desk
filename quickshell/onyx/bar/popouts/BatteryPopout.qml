// battery · state: charge, remaining, draw W, profile; 4 px charge bar; click profile cycles.
import QtQuick
import Quickshell.Services.UPower
import qs
import qs.components

Column {
    id: root

    required property var host

    readonly property UPowerDevice dev: UPower.displayDevice
    readonly property real pct: dev?.percentage ?? 0
    readonly property bool charging: dev ? dev.state === UPowerDeviceState.Charging : false
    readonly property string state: dev ? UPowerDeviceState.toString(dev.state).toLowerCase() : "unknown"

    width: 206
    spacing: 10

    function fmtTime(sec: real): string {
        if (!sec || sec <= 0)
            return "—";
        const h = Math.floor(sec / 3600), m = Math.round((sec % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    function cycleProfile(): void {
        const p = PowerProfiles.profile;
        if (p === PowerProfile.PowerSaver)
            PowerProfiles.profile = PowerProfile.Balanced;
        else if (p === PowerProfile.Balanced)
            PowerProfiles.profile = PowerProfiles.hasPerformanceProfile ? PowerProfile.Performance : PowerProfile.PowerSaver;
        else
            PowerProfiles.profile = PowerProfile.PowerSaver;
    }

    PopoutHeader {
        label: "battery"
        value: root.state.replace("fullycharged", "full")
    }

    PopKv {
        rows: [["charge", Math.round(root.pct * 100) + "%"], ["remaining", root.charging ? root.fmtTime(root.dev?.timeToFull) + " to full" : root.fmtTime(root.dev?.timeToEmpty)], ["draw", (root.dev?.changeRate ?? 0).toFixed(1) + " W"], ["profile", PowerProfile.toString(PowerProfiles.profile).replace(/([a-z])([A-Z])/g, "$1-$2").toLowerCase()]]
    }

    Meter {
        width: parent.width
        thickness: 4
        value: root.pct
        hot: 2
        fillColor: root.pct < 0.15 && !root.charging ? Scheme.error : Scheme.success
    }

    PopCta {
        text: "click profile to cycle · ppd"
        clickable: true
        onClicked: root.cycleProfile()
    }
}
