pragma ComponentBehavior: Bound
// wifi · −NN dBm: networks by strength (connected = selected with link rate); kv: ip, ↓/↑.
// Click connects; secured + unknown → inline password field.
import QtQuick
import qs
import qs.components
import qs.services

Column {
    id: root

    required property var host

    property string asking: ""   // ssid waiting for a password

    width: 216
    spacing: 10

    Component.onCompleted: {
        SysStats.fast++;
        Nmcli.rescan();
        Nmcli.refresh();
    }
    Component.onDestruction: SysStats.fast--

    function iconFor(n: var): string {
        if (n.active)
            return "wifi";
        if (n.signal > 66)
            return "wifi";
        if (n.signal > 33)
            return "wifi_2_bar";
        return "wifi_1_bar";
    }

    function choose(n: var): void {
        if (n.active)
            return;
        if (n.known || !n.security || n.security === "--") {
            asking = "";
            Nmcli.connect(n.ssid, "");
        } else {
            asking = n.ssid;
            pw.text = "";
            pw.forceActiveFocus();
        }
    }

    PopoutHeader {
        label: Nmcli.type === "ethernet" ? "ethernet" : "wifi"
        value: Nmcli.type === "ethernet" ? "wired" : !Nmcli.wifiEnabled ? "off" : Nmcli.connected ? Nmcli.dbm + " dBm" : "disconnected"
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: Nmcli.networks.slice(0, 7)

            Column {
                id: entry
                required property var modelData
                width: parent.width
                spacing: 2

                PopRow {
                    icon: root.iconFor(entry.modelData)
                    text: entry.modelData.ssid
                    selected: entry.modelData.active
                    trailing: entry.modelData.active ? entry.modelData.rate : (Nmcli.connecting && !entry.modelData.active && root.asking === "" ? "…" : (entry.modelData.security || "open").toLowerCase().replace("wpa2 wpa3", "wpa3").split(" ")[0])
                    onClicked: root.choose(entry.modelData)
                }

                Rectangle {
                    visible: root.asking === entry.modelData.ssid
                    width: parent.width
                    height: 26
                    radius: Theme.rChip
                    color: Scheme.surfaceContainer
                    border.width: 1
                    border.color: pw.activeFocus ? Scheme.outline : Scheme.outlineVariant

                    TextInput {
                        id: pw
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        font.family: Theme.mono
                        font.pointSize: 11.5 * 0.75
                        color: Scheme.fgSurface
                        selectionColor: Scheme.primaryContainer
                        onAccepted: {
                            Nmcli.connect(entry.modelData.ssid, text);
                            root.asking = "";
                        }
                        Keys.onEscapePressed: root.asking = ""

                        Ink {
                            visible: !pw.text
                            mono: true
                            text: "password · enter"
                            size: 11
                            color: Scheme.outline
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        PopRow {
            visible: Nmcli.networks.length === 0
            icon: "wifi_find"
            text: Nmcli.wifiEnabled ? "Scanning…" : "Wi-Fi is off"
            enabled: !Nmcli.wifiEnabled
            onClicked: Nmcli.setWifi(true)
        }
    }

    Ink {
        visible: Nmcli.lastError !== ""
        width: parent.width
        mono: true
        text: Nmcli.lastError
        size: 10.5
        color: Scheme.error
        wrapMode: Text.Wrap
        elide: Text.ElideNone
    }

    PopKv {
        rows: [["ip", Nmcli.ip || "—"], ["↓ ↑", SysStats.fmtRate(SysStats.netRx) + " · " + SysStats.fmtRate(SysStats.netTx)]]
    }

    PopCta {
        text: "click to connect · password inline"
    }
}
