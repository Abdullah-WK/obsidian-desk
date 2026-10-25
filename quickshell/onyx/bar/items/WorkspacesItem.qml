pragma ComponentBehavior: Bound
// Workspaces of this monitor: a fixed window of 5 pips (shifts when the active workspace is
// past it). Empty: 6×6 square outlineVariant. Occupied: the app icon of a window on that
// workspace (monochrome under Graphite). Active: iridescent sweep — a 16×6 pill when empty, a
// 2 px underline below the icon when occupied. Scroll switches, tap focuses.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.bar
import qs.components

BarItem {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int count: 5
    readonly property int first: activeId > count ? activeId - count + 1 : 1

    interactive: false
    contentSpacing: 0
    implicitWidth: pips.implicitWidth + 16

    function focusWorkspace(id: int): void {
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = "${id}" })` : `workspace ${id}`);
    }

    onScrolled: delta => {
        const next = Math.max(1, Math.min(10, activeId + (delta < 0 ? 1 : -1)));
        if (next !== activeId)
            focusWorkspace(next);
    }

    Row {
        id: pips
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.count

            Item {
                id: pip

                required property int index
                readonly property int wsId: root.first + index
                readonly property HyprlandWorkspace ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                readonly property bool active: root.activeId === wsId
                readonly property var windows: ws ? (ws.toplevels?.values ?? []) : []
                readonly property bool occupied: windows.length > 0
                // prefer the focused window of that workspace, else its first one
                readonly property var lead: windows.find(t => t.activated) ?? windows[0] ?? null
                readonly property string appClass: lead ? (lead.wayland?.appId || lead.lastIpcObject?.class || "") : ""

                width: 18
                height: Theme.itemHeight

                // empty square ↔ active pill
                Rectangle {
                    anchors.centerIn: parent
                    visible: !pip.occupied
                    width: pip.active ? 16 : 6
                    height: 6
                    radius: 2
                    color: Scheme.outlineVariant
                    gradient: pip.active ? pillSweep : null

                    Sweep {
                        id: pillSweep
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.colour
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.standard
                        }
                    }
                }

                // occupied: app icon, dimmed unless active
                AppIcon {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: pip.active ? -1 : 0
                    visible: pip.occupied
                    appClass: pip.appClass
                    implicitSize: 15
                    opacity: pip.active ? 1 : 0.55

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.colour
                        }
                    }
                }

                // active + occupied: sweep underline, like an open bar item
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 3
                    width: pip.active && pip.occupied ? 14 : 0
                    height: 2
                    radius: 1
                    gradient: underlineSweep

                    Sweep {
                        id: underlineSweep
                    }

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.colour
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Theme.standard
                        }
                    }
                }

                TapHandler {
                    onTapped: root.focusWorkspace(pip.wsId)
                }
            }
        }
    }
}
