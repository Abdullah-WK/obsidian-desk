pragma ComponentBehavior: Bound
// Workspaces of this monitor: 5 shown, 7×7 squares r 2; occupied onSurfaceVariant,
// active primary 14×7, empty outlineVariant. Scroll switches.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.bar

BarItem {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int maxShown: 5
    // last occupied workspace id (within the window) → trailing empty squares are hidden
    readonly property int lastOccupied: Hyprland.workspaces.values.reduce((m, w) => (w.id > 0 && (w.lastIpcObject?.windows ?? 0) > 0 && w.id > m) ? w.id : m, 0)
    readonly property int first: activeId > maxShown ? activeId - maxShown + 1 : 1
    readonly property int shown: Math.max(1, Math.min(maxShown, Math.max(activeId, lastOccupied) - first + 1))

    interactive: false
    contentSpacing: 5
    implicitWidth: implicitContentWidth + 16

    readonly property real implicitContentWidth: squares.implicitWidth

    function focusWorkspace(id: int): void {
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = "${id}" })` : `workspace ${id}`);
    }

    onScrolled: delta => {
        const next = Math.max(1, Math.min(10, activeId + (delta < 0 ? 1 : -1)));
        if (next !== activeId)
            focusWorkspace(next);
    }

    Row {
        id: squares
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.shown

            Item {
                id: square

                required property int index
                readonly property int wsId: root.first + index
                readonly property HyprlandWorkspace ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                readonly property bool active: root.activeId === wsId
                readonly property bool occupied: ws ? (ws.lastIpcObject?.windows ?? 0) > 0 : false

                // full item height as the hit area; the 8 px square sits in the middle
                width: active ? 16 : 8
                height: Theme.itemHeight

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.colour
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.standard
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width
                    height: 8
                    radius: 2
                    color: square.active ? Scheme.primary : square.occupied ? Scheme.fgSurfaceVariant : Scheme.outlineVariant

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.colour
                        }
                    }
                }

                TapHandler {
                    onTapped: root.focusWorkspace(square.wsId)
                }
            }
        }
    }
}
