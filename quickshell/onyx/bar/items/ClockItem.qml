// HH:mm mono 11.5/500, +0.02 em. Popout: calendar.
import QtQuick
import Quickshell
import qs
import qs.bar
import qs.bar.popouts
import qs.components

BarItem {
    id: root

    align: "center"
    popout: CalendarPopout {
        host: root.host
    }
    contentSpacing: 8

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Ink {
        mono: true
        text: Qt.formatTime(clock.date, "HH:mm")
        size: 13
        font.weight: 500
        tracking: 0.02
        color: root.ink
        anchors.verticalCenter: parent.verticalCenter
    }
    Ink {
        mono: true
        text: "·  " + Qt.formatDate(clock.date, "ddd d MMM").toLowerCase()
        size: Theme.barLabel
        color: Scheme.outline
        anchors.verticalCenter: parent.verticalCenter
    }
}
