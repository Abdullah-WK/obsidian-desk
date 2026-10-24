pragma Singleton
// Notifications as Caelestia persists them (~/.local/state/caelestia/notifs.json, watched) plus
// Caelestia's notifs IPC for do-not-disturb and clear-all. "Unread" = newer than the last time
// the bell popout was opened (nothing is unread at start-up).
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var list: []
    property real seenAt: Date.now()
    property bool dnd: false
    readonly property int unread: list.filter(n => new Date(n.time).getTime() > seenAt).length

    function markSeen(): void {
        seenAt = Date.now();
    }

    function refreshDnd(): void {
        if (!dndProc.running)
            dndProc.running = true;
    }

    function toggleDnd(): void {
        if (!toggleProc.running)
            toggleProc.running = true;
    }

    function clear(): void {
        Quickshell.execDetached(["caelestia", "shell", "notifs", "clear"]);
    }

    function age(iso: string): string {
        const t = new Date(iso).getTime();
        if (isNaN(t))
            return "";
        const m = Math.floor((Date.now() - t) / 60000);
        if (m < 1)
            return "now";
        if (m < 60)
            return m + "m";
        const h = Math.floor(m / 60);
        return h < 24 ? h + "h" : Math.floor(h / 24) + "d";
    }

    FileView {
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/caelestia/notifs.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoadFailed: root.list = []
        onLoaded: {
            try {
                const l = JSON.parse(text());
                root.list = Array.isArray(l) ? l.slice().sort((a, b) => new Date(b.time) - new Date(a.time)) : [];
            } catch (e) {
                root.list = [];
            }
        }
    }

    Process {
        id: dndProc
        command: ["caelestia", "shell", "notifs", "isDndEnabled"]
        stdout: StdioCollector {
            onStreamFinished: root.dnd = text.trim() === "true"
        }
    }

    Process {
        id: toggleProc
        command: ["caelestia", "shell", "notifs", "toggleDnd"]
        onExited: root.refreshDnd()
    }

    Component.onCompleted: refreshDnd()
}
