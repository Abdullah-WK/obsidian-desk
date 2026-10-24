pragma Singleton
// NetworkManager through nmcli: `nmcli monitor` drives refreshes (no polling);
// list/connect via one-shot processes; signal in dBm from /proc/net/wireless.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false      // any wifi/ethernet device connected
    property string type: ""            // "wifi" | "ethernet" | ""
    property string device: ""
    property string ssid: ""
    property string ip: ""
    property int signal: 0              // %
    property int dbm: 0
    property string rate: ""
    property bool wifiEnabled: true
    property var networks: []           // {ssid, signal, rate, security, active, known}
    property var known: []
    property bool connecting: false
    property string lastError: ""

    function splitT(line: string): var {
        // nmcli -t escapes ':' as '\:'
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (ch === "\\" && i + 1 < line.length) {
                cur += line[i + 1];
                i++;
            } else if (ch === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += ch;
            }
        }
        out.push(cur);
        return out;
    }

    function refresh(): void {
        if (!devProc.running)
            devProc.running = true;
        if (!wifiProc.running)
            wifiProc.running = true;
        if (!knownProc.running)
            knownProc.running = true;
        if (!radioProc.running)
            radioProc.running = true;
    }

    function rescan(): void {
        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]);
    }

    function connect(ssid: string, password: string): void {
        connecting = true;
        lastError = "";
        if (password)
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid, "password", password];
        else if (known.includes(ssid))
            connectProc.command = ["nmcli", "con", "up", "id", ssid];
        else
            connectProc.command = ["nmcli", "dev", "wifi", "connect", ssid];
        connectProc.running = true;
    }

    function disconnect(): void {
        if (device)
            Quickshell.execDetached(["nmcli", "dev", "disconnect", device]);
    }

    function setWifi(on: bool): void {
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
    }

    function readDbm(): void {
        wireless.reload();
        for (const line of wireless.text().split("\n")) {
            if (!line.includes(":"))
                continue;
            const f = line.trim().split(/\s+/);
            const v = parseFloat(f[3]);
            if (!isNaN(v))
                dbm = Math.round(v);
        }
    }

    Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce
        interval: 400
        onTriggered: root.refresh()
    }

    Timer {
        running: true
        interval: 300
        onTriggered: root.refresh()
    }

    Process {
        id: devProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let dev = "", typ = "", con = "", anyConnected = false;
                for (const line of text.split("\n")) {
                    const f = root.splitT(line);
                    if (f.length < 4)
                        continue;
                    if (f[2].startsWith("connected") && (f[1] === "wifi" || f[1] === "ethernet")) {
                        anyConnected = true;
                        if (!dev || f[1] === "ethernet") {
                            dev = f[0];
                            typ = f[1];
                            con = f[3];
                        }
                    }
                }
                root.connected = anyConnected;
                root.device = dev;
                root.type = typ;
                if (typ === "ethernet")
                    root.ssid = con;
                if (dev) {
                    ipProc.command = ["nmcli", "-t", "-f", "IP4.ADDRESS", "dev", "show", dev];
                    ipProc.running = true;
                } else {
                    root.ip = "";
                }
                root.readDbm();
            }
        }
    }

    Process {
        id: ipProc
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/IP4\.ADDRESS\[1\]:([^\/\n]+)/);
                root.ip = m ? m[1] : "";
            }
        }
    }

    Process {
        id: wifiProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,RATE,SECURITY", "dev", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = new Set();
                const list = [];
                let activeSsid = "", activeSignal = 0, activeRate = "";
                for (const line of text.split("\n")) {
                    const f = root.splitT(line);
                    if (f.length < 5 || !f[1])
                        continue;
                    const active = f[0] === "yes";
                    const n = {
                        ssid: f[1],
                        signal: parseInt(f[2]) || 0,
                        rate: f[3].replace(" Mbit/s", "M"),
                        security: f[4],
                        active: active,
                        known: root.known.includes(f[1])
                    };
                    if (active) {
                        activeSsid = n.ssid;
                        activeSignal = n.signal;
                        activeRate = n.rate;
                    }
                    if (seen.has(n.ssid)) {
                        const i = list.findIndex(x => x.ssid === n.ssid);
                        if (n.signal > list[i].signal || active)
                            list[i] = n;
                        continue;
                    }
                    seen.add(n.ssid);
                    list.push(n);
                }
                list.sort((a, b) => (b.active - a.active) || (b.known - a.known) || (b.signal - a.signal));
                root.networks = list;
                if (root.type !== "ethernet") {
                    root.ssid = activeSsid;
                    root.signal = activeSignal;
                    root.rate = activeRate;
                }
            }
        }
    }

    Process {
        id: knownProc
        command: ["nmcli", "-t", "-f", "NAME,TYPE", "con", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const k = [];
                for (const line of text.split("\n")) {
                    const f = root.splitT(line);
                    if (f.length >= 2 && f[1] === "802-11-wireless")
                        k.push(f[0]);
                }
                root.known = k;
                root.networks = root.networks.map(n => Object.assign({}, n, { known: k.includes(n.ssid) }));
            }
        }
    }

    Process {
        id: radioProc
        command: ["nmcli", "-t", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiEnabled = text.trim() === "enabled"
        }
    }

    Process {
        id: connectProc
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    root.lastError = text.trim().replace(/^Error: /, "");
            }
        }
        onExited: {
            root.connecting = false;
            root.refresh();
        }
    }

    FileView {
        id: wireless
        path: "/proc/net/wireless"
        blockLoading: true
        printErrors: false
    }
}
