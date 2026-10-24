pragma ComponentBehavior: Bound
// Big count mono 40/300 archIce; first 4 package chips then +n; "checked HH:MM · click to open …".
// 0 → "up to date". Click runs Config.updatesCommand and re-checks afterwards.
import QtQuick
import qs
import qs.components
import qs.services

Card {
    id: root

    title: "pacman"
    interval: Config.updatesIntervalMin + " min"

    readonly property var shownNames: Updates.names.slice(0, 4)

    Row {
        spacing: 10
        visible: Updates.count !== 0

        Ink {
            mono: true
            text: Updates.count < 0 ? "–" : Updates.count
            size: 40
            font.weight: 300
            tracking: -0.03
            color: Scheme.archIce
            lineHeight: 0.9
            anchors.baseline: parent.bottom
        }
        Ink {
            text: Updates.count < 0 ? (Updates.busy ? "checking…" : "not checked") : "updates available"
            size: 13
            color: Scheme.fgSurfaceVariant
            anchors.baseline: parent.bottom
        }
    }

    Ink {
        visible: Updates.count === 0
        mono: true
        text: "up to date"
        size: 13
        color: Scheme.fgSurfaceVariant
        height: 24
    }

    Flow {
        visible: Updates.count > 0
        width: parent.width
        spacing: 6

        Repeater {
            model: root.shownNames
            Rectangle {
                required property string modelData
                width: chip.implicitWidth + 14
                height: 20
                radius: Theme.rChip
                color: Scheme.surfaceContainerLow
                border.width: 1
                border.color: Scheme.outlineVariant

                Ink {
                    id: chip
                    anchors.centerIn: parent
                    mono: true
                    text: parent.modelData
                    size: 11
                    color: Scheme.fgSurfaceVariant
                }
            }
        }
        Rectangle {
            visible: Updates.count > 4
            width: more.implicitWidth + 14
            height: 20
            radius: Theme.rChip
            color: Scheme.surfaceContainerLow
            border.width: 1
            border.color: Scheme.outlineVariant

            Ink {
                id: more
                anchors.centerIn: parent
                mono: true
                text: "+" + (Updates.count - 4)
                size: 11
                color: Scheme.fgSurfaceVariant
            }
        }
    }

    Ink {
        mono: true
        text: (Updates.checkedAt ? "checked " + Updates.checkedAt : "not checked") + " · click → " + Config.updatesCommand.slice(-1)[0] + " in " + Config.updatesCommand[0]
        size: 11.5
        color: Scheme.outline
        width: parent.width
    }

    TapHandler {
        onTapped: Updates.open()
    }
}
