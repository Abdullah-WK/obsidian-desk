pragma Singleton
// Static system facts read once at login (host, kernel, package counts, shell/wm versions)
// and uptime re-read every 60 s.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") || "user"
    property string host: "arch"
    property string kernel: ""
    property int pkgs: 0
    property int aur: 0
    property string shellVersion: ""
    property string wmVersion: ""
    property string uptime: ""
    property real uptimeSec: 0

    readonly property string userHost: `${user}@${host}`

    function fmtUptime(sec: real): string {
        const m = Math.floor(sec / 60);
        const h = Math.floor(m / 60);
        const d = Math.floor(h / 24);
        if (d > 0)
            return `${d}d ${h % 24}h`;
        if (h > 0)
            return `${h}h ${m % 60}m`;
        return `${m} min`;
    }

    function readUptime(): void {
        up.reload();
        const v = parseFloat(up.text());
        if (!isNaN(v)) {
            uptimeSec = v;
            uptime = fmtUptime(v);
        }
    }

    FileView {
        id: up
        path: "/proc/uptime"
        blockLoading: true
        printErrors: false
    }

    Timer {
        running: true
        interval: 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.readUptime()
    }

    FileView {
        path: "/etc/hostname"
        printErrors: false
        onLoaded: {
            const t = text().trim();
            if (t)
                root.host = t;
        }
    }

    Process {
        running: true
        command: ["sh", "-c", `
echo "kernel=$(uname -r)"
echo "pkgs=$(pacman -Qq 2>/dev/null | wc -l)"
echo "aur=$(pacman -Qmq 2>/dev/null | wc -l)"
echo "shell=$(pacman -Q caelestia-shell 2>/dev/null | awk '{print $2}' | cut -d- -f1)"
echo "wm=$(hyprctl version 2>/dev/null | head -1 | awk '{print $2}')"`]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=");
                    if (i < 0)
                        continue;
                    const k = line.slice(0, i), v = line.slice(i + 1).trim();
                    if (k === "kernel")
                        root.kernel = v;
                    else if (k === "pkgs")
                        root.pkgs = parseInt(v) || 0;
                    else if (k === "aur")
                        root.aur = parseInt(v) || 0;
                    else if (k === "shell")
                        root.shellVersion = v;
                    else if (k === "wm")
                        root.wmVersion = v;
                }
            }
        }
    }
}
