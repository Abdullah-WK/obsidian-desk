// HH:mm mono 56/300 −0.04 em right-aligned; FRIDAY · 24 OCTOBER · W43 Inter 500 11 caps 0.14 em.
import QtQuick
import Quickshell
import qs
import qs.components

Card {
    id: root

    title: "clock"
    interval: "1 min"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function isoWeek(d: date): int {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }

    Ink {
        mono: true
        text: Qt.formatTime(clock.date, "HH:mm")
        size: 56
        font.weight: 300
        tracking: -0.04
        color: Scheme.fgSurface
        width: parent.width
        horizontalAlignment: Text.AlignRight
        lineHeight: 0.9
    }
    Ink {
        text: (Qt.formatDate(clock.date, "dddd · d MMMM") + " · W" + root.isoWeek(clock.date)).toUpperCase()
        size: 11
        font.weight: 500
        tracking: 0.14
        color: Scheme.fgSurfaceVariant
        width: parent.width
        horizontalAlignment: Text.AlignRight
    }
}
