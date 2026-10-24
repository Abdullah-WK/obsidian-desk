pragma ComponentBehavior: Bound
// Authentication state shared by every lock surface (and by the windowed harness):
// password buffer, PAM (passwd + fprint), failures, cooldown, caps-lock heuristic.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs

Scope {
    id: root

    property string buffer: ""
    property int pending: 0            // dots kept on screen while PAM is checking
    readonly property bool busy: passwd.active
    readonly property bool typing: buffer.length > 0 || pending > 0
    property bool failed: false        // "incorrect" flash
    property int failures: 0
    property bool cooldown: false
    property real cooldownLeft: 0
    property bool capsLock: false
    property bool unlocking: false
    property bool fprintAvailable: false
    readonly property bool fprintWaiting: fprint.active
    property int fprintTries: 0

    signal success
    signal wrong
    signal activity

    function reset(): void {
        buffer = "";
        pending = 0;
        failed = false;
        failures = 0;
        cooldown = false;
        cooldownLeft = 0;
        unlocking = false;
        fprintTries = 0;
        if (passwd.active)
            passwd.abort();
    }

    function clear(): void {
        buffer = "";
    }

    function submit(): void {
        if (cooldown || passwd.active || unlocking || buffer.length === 0)
            return;
        pending = buffer.length;
        if (!passwd.start()) {
            pending = 0;
            fail();
        }
    }

    function fail(): void {
        buffer = "";
        pending = 0;
        failures++;
        failed = true;
        failedT.restart();
        wrong();
        if (failures >= 3) {
            failures = 0;
            cooldown = true;
            cooldownLeft = 10;
            cooldownT.start();
        }
    }

    function handleKey(event: KeyEvent): void {
        activity();
        if (unlocking)
            return;
        if (event.key === Qt.Key_CapsLock) {
            capsLock = !capsLock;
            return;
        }
        if (event.key === Qt.Key_Escape) {
            buffer = "";
            return;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            submit();
            return;
        }
        if (passwd.active || cooldown)
            return;
        if (event.key === Qt.Key_Backspace) {
            buffer = (event.modifiers & Qt.ControlModifier) ? "" : buffer.slice(0, -1);
            return;
        }
        const t = event.text;
        if (t && /^[^\x00-\x1F\x7F-\x9F]+$/.test(t)) {
            if (/[a-z]/i.test(t)) {
                const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
                capsLock = (t === t.toUpperCase()) !== shift;
            }
            buffer += t;
        }
    }

    function startFprint(): void {
        fprintTries = 0;
        if (!fprintCheck.running)
            fprintCheck.running = true;
    }

    function stopFprint(): void {
        fprintRetry.stop();
        if (fprint.active)
            fprint.abort();
    }

    PamContext {
        id: passwd

        config: "passwd"
        configDirectory: Quickshell.shellPath("lock/pam.d")

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;
            respond(root.buffer);
            root.buffer = "";
        }

        onCompleted: result => {
            root.pending = 0;
            if (result === PamResult.Success) {
                root.unlocking = true;
                root.success();
                return;
            }
            root.fail();
        }
    }

    PamContext {
        id: fprint

        config: "fprint"
        configDirectory: Quickshell.shellPath("lock/pam.d")

        onCompleted: result => {
            if (result === PamResult.Success) {
                root.unlocking = true;
                root.success();
                return;
            }
            if (root.unlocking)
                return;
            root.fprintTries++;
            if (root.fprintTries < 5)
                fprintRetry.restart();
        }
    }

    Process {
        id: fprintCheck
        command: ["sh", "-c", "command -v fprintd-verify >/dev/null 2>&1 && fprintd-list \"$USER\" 2>/dev/null | grep -qi 'finger' && echo yes || echo no"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.fprintAvailable = text.trim() === "yes";
                if (root.fprintAvailable && !fprint.active && !root.unlocking)
                    fprint.start();
            }
        }
    }

    Timer {
        id: fprintRetry
        interval: 1500
        onTriggered: if (root.fprintAvailable && !fprint.active && !root.unlocking) fprint.start()
    }

    Timer {
        id: failedT
        interval: 1500
        onTriggered: root.failed = false
    }

    Timer {
        id: cooldownT
        interval: 100
        repeat: true
        onTriggered: {
            root.cooldownLeft = Math.max(0, root.cooldownLeft - 0.1);
            if (root.cooldownLeft <= 0) {
                root.cooldown = false;
                stop();
            }
        }
    }
}
