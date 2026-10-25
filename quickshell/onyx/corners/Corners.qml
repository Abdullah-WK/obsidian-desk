// Rounded screen corners: a click-through Top-layer window per screen painting four inverted
// arcs in the bar colour, so the work area reads as one rounded slab under the bar. The top
// pair sits under the bar strip while the bar is pinned (and follows it when it hides); the
// bottom pair sits on the screen edge. Top-layer surfaces are not drawn over fullscreen
// windows, so videos and games keep square corners. Static: nothing animates at rest.
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

Scope {
    id: root

    required property ShellScreen screen

    readonly property int r: Theme.rScreen
    readonly property bool barStrip: Runtime.barPinned && !GameMode.enabled
    readonly property int top: barStrip ? Theme.barHeight : 0

    PanelWindow {
        screen: root.screen
        visible: Config.screenCorners
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "onyx-corners"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        // empty mask → every click passes through to what is underneath
        mask: Region {}

        component Corner: Shape {
            id: corner
            // which corner: 0 TL, 1 TR, 2 BL, 3 BR
            required property int which
            width: root.r
            height: root.r
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Scheme.background
                strokeWidth: -1
                // square minus a quarter disc, drawn in the corner's own frame then mirrored
                startX: 0
                startY: 0
                PathLine { x: root.r; y: 0 }
                PathArc {
                    x: 0
                    y: root.r
                    radiusX: root.r
                    radiusY: root.r
                    direction: PathArc.Counterclockwise
                }
                PathLine { x: 0; y: 0 }
            }
            transform: Scale {
                origin.x: root.r / 2
                origin.y: root.r / 2
                xScale: (corner.which % 2) ? -1 : 1
                yScale: corner.which > 1 ? -1 : 1
            }
        }

        Corner {
            which: 0
            x: 0
            y: root.top
            Behavior on y { NumberAnimation { duration: Theme.barReveal } }
        }
        Corner {
            which: 1
            x: parent.width - root.r
            y: root.top
            Behavior on y { NumberAnimation { duration: Theme.barReveal } }
        }
        Corner {
            which: 2
            x: 0
            y: parent.height - root.r
        }
        Corner {
            which: 3
            x: parent.width - root.r
            y: parent.height - root.r
        }
    }
}
