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
    readonly property int shown: 5
    readonly property int first: activeId > shown ? activeId - shown + 1 : 1

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
        spacing: 5
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.shown

            Rectangle {
                id: square

                required property int index
                readonly property int wsId: root.first + index
                readonly property HyprlandWorkspace ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                readonly property bool active: root.activeId === wsId
                readonly property bool occupied: ws ? (ws.lastIpcObject?.windows ?? 0) > 0 : false

                width: active ? 14 : 7
                height: 7
                radius: 2
                color: active ? Scheme.primary : occupied ? Scheme.fgSurfaceVariant : Scheme.outlineVariant

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.colour
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.standard
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Theme.colour
                    }
                }

                TapHandler {
                    onTapped: root.focusWorkspace(square.wsId)
                }
            }
        }
    }
}
