// Network state from nmcli: wifi bars by signal, lan for ethernet, wifi_off otherwise.
import QtQuick
import qs
import qs.bar
import qs.bar.popouts
import qs.components
import qs.services

BarItem {
    id: root

    readonly property string icon: {
        if (Nmcli.type === "ethernet")
            return "lan";
        if (!Nmcli.wifiEnabled || !Nmcli.connected)
            return "wifi_off";
        if (Nmcli.signal > 66)
            return "wifi";
        if (Nmcli.signal > 33)
            return "wifi_2_bar";
        return "wifi_1_bar";
    }

    align: "right"
    popout: WifiPopout {
        host: root.host
    }
    onActivated: host.openPopout(root)

    Icon {
        text: root.icon
        color: root.ink
        anchors.verticalCenter: parent.verticalCenter
    }
}
