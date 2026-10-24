pragma Singleton
// cpu / mem / gpu / nvme / temp / net from /proc, hwmon, df and nvidia-smi (or amdgpu sysfs).
// The timer only runs while a consumer is registered: `SysStats.fast++` (2 s, perf popout and
// bar perf item) or `SysStats.slow++` (5 s, vitals card). Decrement when hidden.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int fast: 0
    property int slow: 0
    readonly property bool active: fast + slow > 0

    property real cpu: 0          // 0..1
    property real memUsed: 0      // GiB
    property real memTotal: 0     // GiB
    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0
    property real gpu: 0          // 0..1
    property bool gpuOff: true    // dGPU asleep (RTD3) or no GPU source
    property real disk: 0         // 0..1 of /
    property real temp: 0         // °C (cpu package)
    property real gpuTemp: 0      // °C (dGPU; 0 while asleep)
    property real netRx: 0        // B/s
    property real netTx: 0        // B/s

    property string tempPath: ""
    property string gpuStatusPath: ""
    property string amdBusyPath: ""

    // previous samples
    property real prevIdle: 0
    property real prevTotal: 0
    property real prevRx: 0
    property real prevTx: 0
    property real prevTime: 0

    function tick(): void {
        stat.reload();
        meminfo.reload();
        netdev.reload();
        parseCpu(stat.text());
        parseMem(meminfo.text());
        parseNet(netdev.text());
        if (tempPath) {
            tempFile.reload();
            const v = parseInt(tempFile.text());
            if (!isNaN(v))
                temp = v / 1000;
        }
        if (!df.running)
            df.running = true;
        if (amdBusyPath) {
            amdBusy.reload();
            const v = parseInt(amdBusy.text());
            if (!isNaN(v)) {
                gpu = v / 100;
                gpuOff = false;
            }
        } else if (gpuStatusPath) {
            gpuStatus.reload();
            if (gpuStatus.text().trim() === "active") {
                if (!nvidia.running)
                    nvidia.running = true;
            } else {
                gpuOff = true;
                gpu = 0;
                gpuTemp = 0;
            }
        }
    }

    function parseCpu(text: string): void {
        const line = text.split("\n")[0] ?? "";
        const f = line.trim().split(/\s+/).slice(1).map(Number);
        if (f.length < 4)
            return;
        const idle = f[3] + (f[4] ?? 0);
        const total = f.reduce((a, b) => a + b, 0);
        const dIdle = idle - prevIdle;
        const dTotal = total - prevTotal;
        if (prevTotal > 0 && dTotal > 0)
            cpu = Math.max(0, Math.min(1, 1 - dIdle / dTotal));
        prevIdle = idle;
        prevTotal = total;
    }

    function parseMem(text: string): void {
        let total = 0, avail = 0;
        for (const line of text.split("\n")) {
            if (line.startsWith("MemTotal:"))
                total = parseInt(line.split(/\s+/)[1]);
            else if (line.startsWith("MemAvailable:"))
                avail = parseInt(line.split(/\s+/)[1]);
        }
        if (total > 0) {
            memTotal = total / 1048576;
            memUsed = (total - avail) / 1048576;
        }
    }

    function parseNet(text: string): void {
        let rx = 0, tx = 0;
        for (const line of text.split("\n")) {
            const i = line.indexOf(":");
            if (i < 0)
                continue;
            const name = line.slice(0, i).trim();
            if (name === "lo")
                continue;
            const f = line.slice(i + 1).trim().split(/\s+/).map(Number);
            rx += f[0] ?? 0;
            tx += f[8] ?? 0;
        }
        const now = Date.now();
        if (prevTime > 0) {
            const dt = (now - prevTime) / 1000;
            if (dt > 0) {
                netRx = Math.max(0, (rx - prevRx) / dt);
                netTx = Math.max(0, (tx - prevTx) / dt);
            }
        }
        prevRx = rx;
        prevTx = tx;
        prevTime = now;
    }

    function fmtRate(bps: real): string {
        if (bps >= 1048576)
            return (bps / 1048576).toFixed(1) + "M";
        if (bps >= 1024)
            return Math.round(bps / 1024) + "K";
        return Math.round(bps) + "B";
    }

    Timer {
        running: root.active
        interval: root.fast > 0 ? 2000 : 5000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    onActiveChanged: {
        if (!active) {
            prevTotal = 0;
            prevTime = 0;
        }
    }

    FileView {
        id: stat
        path: "/proc/stat"
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: netdev
        path: "/proc/net/dev"
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: tempFile
        path: root.tempPath
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: gpuStatus
        path: root.gpuStatusPath
        blockLoading: true
        printErrors: false
    }
    FileView {
        id: amdBusy
        path: root.amdBusyPath
        blockLoading: true
        printErrors: false
    }

    Process {
        id: df
        command: ["df", "--output=pcent", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/(\d+)%/);
                if (m)
                    root.disk = parseInt(m[1]) / 100;
            }
        }
    }

    Process {
        id: nvidia
        command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.split(",").map(x => parseInt(x));
                if (!isNaN(f[0])) {
                    root.gpu = f[0] / 100;
                    root.gpuOff = false;
                }
                if (!isNaN(f[1]))
                    root.gpuTemp = f[1];
            }
        }
    }

    // One-off probe for the temperature sensor and the GPU source.
    Process {
        id: probe
        running: true
        command: ["sh", "-c", `
for h in /sys/class/hwmon/hwmon*; do
  n=$(cat "$h/name" 2>/dev/null)
  case "$n" in coretemp|k10temp|zenpower|cpu_thermal|acpitz) [ -r "$h/temp1_input" ] && { echo "temp=$h/temp1_input"; break; };; esac
done
for d in /sys/bus/pci/drivers/nvidia/0000*; do [ -e "$d/power/runtime_status" ] && { echo "nv=$d/power/runtime_status"; break; }; done
for c in /sys/class/drm/card*/device/gpu_busy_percent; do [ -r "$c" ] && { echo "amd=$c"; break; }; done
true`]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    if (line.startsWith("temp="))
                        root.tempPath = line.slice(5);
                    else if (line.startsWith("nv="))
                        root.gpuStatusPath = line.slice(3);
                    else if (line.startsWith("amd="))
                        root.amdBusyPath = line.slice(4);
                }
            }
        }
    }
}
