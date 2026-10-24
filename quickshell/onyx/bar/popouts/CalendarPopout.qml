pragma ComponentBehavior: Bound
// Month YYYY · Wnn; 7-column calendar, Monday first; today = primary; kv: weekday · day N, uptime.
// Scroll changes the month, click today returns.
import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

Column {
    id: root

    required property var host

    property date view: new Date()
    readonly property date today: clock.date

    width: 212
    spacing: 10

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function isoWeek(d: date): int {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }

    function dayOfYear(d: date): int {
        const y0 = new Date(d.getFullYear(), 0, 0);
        return Math.floor((d - y0) / 86400000);
    }

    function shiftMonth(n: int): void {
        view = new Date(view.getFullYear(), view.getMonth() + n, 1);
    }

    readonly property var cells: {
        const y = view.getFullYear(), m = view.getMonth();
        const first = new Date(y, m, 1);
        const lead = (first.getDay() + 6) % 7;
        const start = new Date(y, m, 1 - lead);
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push({
                day: d.getDate(),
                other: d.getMonth() !== m,
                today: d.getFullYear() === today.getFullYear() && d.getMonth() === today.getMonth() && d.getDate() === today.getDate()
            });
        }
        return out;
    }

    WheelHandler {
        onWheel: event => root.shiftMonth(event.angleDelta.y < 0 ? 1 : -1)
    }

    PopoutHeader {
        label: Qt.formatDate(root.view, "MMMM yyyy")
        value: "W" + root.isoWeek(root.view.getMonth() === root.today.getMonth() && root.view.getFullYear() === root.today.getFullYear() ? root.today : root.view)
    }

    Grid {
        columns: 7
        columnSpacing: 2
        rowSpacing: 2
        width: parent.width

        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            Ink {
                required property string modelData
                mono: true
                text: modelData
                size: 9.5
                color: Scheme.outline
                width: 28
                height: 16
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Repeater {
            model: root.cells
            Rectangle {
                id: cell
                required property var modelData
                width: 28
                height: 20
                radius: Theme.rChip
                color: modelData.today ? Scheme.primary : "transparent"

                Ink {
                    anchors.centerIn: parent
                    mono: true
                    text: cell.modelData.day
                    size: 10.5
                    font.weight: cell.modelData.today ? 500 : 400
                    color: cell.modelData.today ? Scheme.fgPrimary : cell.modelData.other ? Scheme.outlineVariant : Scheme.fgSurfaceVariant
                }
                TapHandler {
                    onTapped: if (cell.modelData.today) root.view = new Date()
                }
            }
        }
    }

    PopKv {
        rows: [[Qt.formatDate(root.today, "dddd") + " · day " + root.dayOfYear(root.today), Qt.formatTime(root.today, "HH:mm:ss")], ["uptime", SysInfo.uptime]]
    }
}
