// Dot field: 3 px squares on a 14 px grid. Wave canvas repaints every 500 ms (1 s idle);
// the lamp canvas repaints only around the pointer (≤ 30 fps) and composites exactly:
// a_lamp = (a_target − a_wave) / (1 − a_wave). Plus the static vignette.
import QtQuick
import qs

Item {
    id: root

    property real pointerX: -9999
    property real pointerY: -9999
    property bool hasPointer: false
    property bool glyphHover: false
    property bool idle: false
    property bool running: true
    property bool vignette: true

    readonly property int step: 14
    readonly property int dot: 3
    readonly property real radius: 260
    property real phase: 0
    property real lastTick: Date.now()
    property var prevBox: null

    function pointerMoved(x: real, y: real): void {
        pointerX = x;
        pointerY = y;
        hasPointer = true;
        if (!throttle.running)
            throttle.start();
    }

    function pointerLeft(): void {
        hasPointer = false;
        lamp.requestPaint();
    }

    function waveAlpha(x: real, y: real): real {
        return 0.04 + 0.03 * (0.5 + 0.5 * Math.sin(phase * 0.7 + x / 90 + y / 140));
    }

    function fillBuckets(ctx: var, buckets: var): void {
        for (const key in buckets) {
            const pts = buckets[key];
            ctx.fillStyle = `rgba(236,236,238,${key})`;
            ctx.beginPath();
            for (let i = 0; i < pts.length; i += 2)
                ctx.rect(pts[i], pts[i + 1], dot, dot);
            ctx.fill();
        }
    }

    Timer {
        running: root.running && root.visible
        interval: root.idle ? 1000 : 500
        repeat: true
        onTriggered: {
            const now = Date.now();
            root.phase += (now - root.lastTick) / 1000 * (root.idle ? 0.5 : 1);
            root.lastTick = now;
            wave.requestPaint();
            if (root.hasPointer)
                lamp.requestPaint();
        }
    }

    Timer {
        id: throttle
        interval: 33
        onTriggered: lamp.requestPaint()
    }

    Canvas {
        id: wave
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const buckets = ({});
            const half = root.step / 2, d2 = root.dot / 2;
            for (let y = half; y < height; y += root.step) {
                for (let x = half; x < width; x += root.step) {
                    const a = Math.round(root.waveAlpha(x, y) * 200) / 200;
                    const k = a.toFixed(3);
                    if (!buckets[k]) buckets[k] = []; buckets[k].push(x - d2, y - d2);
                }
            }
            root.fillBuckets(ctx, buckets);
        }
    }

    Canvas {
        id: lamp
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            const R = root.radius, glow = 260;
            if (root.prevBox)
                ctx.clearRect(root.prevBox[0], root.prevBox[1], root.prevBox[2], root.prevBox[3]);
            if (!root.hasPointer) {
                root.prevBox = null;
                return;
            }
            const px = root.pointerX, py = root.pointerY;
            const bx = Math.floor(px - glow) - 2, by = Math.floor(py - glow) - 2, bw = glow * 2 + 4;
            ctx.clearRect(bx, by, bw, bw);
            root.prevBox = [bx, by, bw, bw];

            const g = ctx.createRadialGradient(px, py, 0, px, py, glow);
            g.addColorStop(0, "rgba(236,236,238,0.06)");
            g.addColorStop(0.6, "rgba(236,236,238,0)");
            g.addColorStop(1, "rgba(236,236,238,0)");
            ctx.fillStyle = g;
            ctx.fillRect(bx, by, bw, bw);

            const peak = root.glyphHover ? 0.33 : 0.22;
            const buckets = ({});
            const half = root.step / 2, d2 = root.dot / 2;
            const x0 = Math.floor((px - R) / root.step) * root.step + half;
            const y0 = Math.floor((py - R) / root.step) * root.step + half;
            for (let y = Math.max(half, y0); y < Math.min(height, py + R); y += root.step) {
                for (let x = Math.max(half, x0); x < Math.min(width, px + R); x += root.step) {
                    const dx = x - px, dy = y - py;
                    const d = Math.sqrt(dx * dx + dy * dy);
                    if (d >= R)
                        continue;
                    const aw = root.waveAlpha(x, y);
                    const l = peak * (1 - d / R);
                    const at = Math.min(0.5, aw + l * l * 3);
                    const al = (at - aw) / (1 - aw);
                    if (al < 0.004)
                        continue;
                    const k = (Math.round(al * 100) / 100).toFixed(2);
                    if (!buckets[k]) buckets[k] = []; buckets[k].push(x - d2, y - d2);
                }
            }
            root.fillBuckets(ctx, buckets);
        }
    }

    Canvas {
        id: vig
        anchors.fill: parent
        visible: root.vignette
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const cx = width / 2, cy = height / 2;
            const r = Math.sqrt(cx * cx + cy * cy);
            const g = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
            g.addColorStop(0, "rgba(5,5,6,0)");
            g.addColorStop(0.4, "rgba(5,5,6,0)");
            g.addColorStop(1, "rgba(5,5,6,0.6)");
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
        }
    }
}
