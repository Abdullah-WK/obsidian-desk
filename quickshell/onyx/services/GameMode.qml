pragma Singleton
// Caelestia's game mode sets animations:enabled = 0 through hyprctl keywords, which emits
// no Hyprland event. State is read on start, on `configreloaded` (game mode off) and on
// demand (the hot zone calls check() on contact), never on a timer.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property bool enabled: false

    function check(): void {
        if (!proc.running)
            proc.running = true;
    }

    Process {
        id: proc
        running: true
        command: ["hyprctl", "getoption", "animations:enabled", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.enabled = JSON.parse(text).int === 0;
                } catch (e) {
                    root.enabled = false;
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event: HyprlandEvent): void {
            if (event.name === "configreloaded")
                root.check();
        }
    }
}
