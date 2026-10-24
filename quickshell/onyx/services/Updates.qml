pragma Singleton
// Pending updates: `checkupdates` (+ `paru -Qua` when paru exists). Checked every
// Config.updatesIntervalMin minutes, only while a connection is active and (unless
// Config.updatesOnBattery) the machine is on mains, and on demand.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs

Singleton {
    id: root

    property int count: -1          // -1 = not checked yet
    property var names: []
    property string checkedAt: ""
    property bool busy: false

    function refresh(): void {
        if (!check.running) {
            busy = true;
            check.running = true;
        }
    }

    // Runs Config.updatesCommand and re-checks when it exits.
    function open(): void {
        if (runner.running)
            return;
        runner.command = Config.updatesCommand;
        runner.running = true;
    }

    Timer {
        running: Nmcli.connected && (Config.updatesOnBattery || !UPower.onBattery)
        interval: Config.updatesIntervalMin * 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process {
        id: check
        command: ["sh", "-c", "checkupdates 2>/dev/null; if command -v paru >/dev/null 2>&1; then paru -Qua 2>/dev/null; fi; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = [];
                for (const line of text.split("\n")) {
                    const name = line.trim().split(/\s+/)[0];
                    if (name && !n.includes(name))
                        n.push(name);
                }
                root.names = n;
                root.count = n.length;
                root.checkedAt = Qt.formatTime(new Date(), "HH:mm");
                root.busy = false;
            }
        }
    }

    Process {
        id: runner
        onExited: root.refresh()
    }
}
