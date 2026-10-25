pragma Singleton
// Screen backlight + keyboard backlight through brightnessctl. `udevadm monitor` on the backlight
// class drives refreshes (the dots' XF86 keys go through Caelestia, which writes the same
// sysfs node, so changes from anywhere land here). Keyboard LEDs emit no uevent: re-read after
// our own writes and whenever the popout opens. `generation` bumps on every screen-level
// change after startup and drives the OSD.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string device: ""
    property string kbdDevice: ""
    property real level: 0        // 0..1
    property real kbdLevel: 0     // 0..1
    property bool ready: false
    property int generation: 0

    readonly property bool available: device !== ""
    readonly property bool kbdAvailable: kbdDevice !== ""

    function setLevel(v: real): void {
        if (!available)
            return;
        v = Math.max(0.01, Math.min(1, v));
        if (Math.abs(v - level) > 0.0001) {
            level = v;
            generation++;
        }
        Quickshell.execDetached(["brightnessctl", "-q", "-d", device, "s", Math.round(v * 100) + "%"]);
    }

    function setKbd(v: real): void {
        if (!kbdAvailable)
            return;
        v = Math.max(0, Math.min(1, v));
        kbdLevel = v;
        Quickshell.execDetached(["brightnessctl", "-q", "-d", kbdDevice, "s", Math.round(v * 100) + "%"]);
        kbdReread.restart();
    }

    function refresh(): void {
        if (!list.running)
            list.running = true;
    }

    function parse(text: string): void {
        let dev = "", lvl = level, kdev = "", klvl = kbdLevel;
        for (const line of text.split("\n")) {
            const f = line.split(",");
            if (f.length < 5)
                continue;
            const cur = parseFloat(f[2]), max = parseFloat(f[4]);
            if (!(max > 0))
                continue;
            if (f[1] === "backlight" && dev === "") {
                dev = f[0];
                lvl = cur / max;
            } else if (f[1] === "leds" && f[0].includes("kbd_backlight") && kdev === "") {
                kdev = f[0];
                klvl = cur / max;
            }
        }
        device = dev;
        kbdDevice = kdev;
        kbdLevel = klvl;
        if (!ready) {
            level = lvl;
            ready = true;
        } else if (Math.abs(lvl - level) > 0.004) {
            level = lvl;
            generation++;
        }
    }

    Process {
        id: list
        command: ["brightnessctl", "-m", "-l"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: monitor
        // stdbuf: udevadm fully buffers stdout on a pipe, so events would arrive late or never
        command: ["stdbuf", "-oL", "udevadm", "monitor", "-u", "-s", "backlight"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("change"))
                    debounce.restart();
            }
        }
    }

    Timer {
        id: debounce
        interval: 60
        onTriggered: root.refresh()
    }

    Timer {
        id: kbdReread
        interval: 150
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
