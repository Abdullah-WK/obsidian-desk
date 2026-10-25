// The Arch mark as a Shape path (no image). Solid in `color` by default; `iridescent` fills it
// with the ice-blue → violet → pink → peach sweep and `glow` adds a soft radial halo behind it
// (a radial-gradient disc, no shader effects).
import QtQuick
import QtQuick.Shapes
import qs

Item {
    id: root

    property real size: 16
    property color color: Scheme.archIce
    property bool iridescent: false
    property real glow: 0          // 0 … 1

    implicitWidth: size
    implicitHeight: size

    // halo
    Shape {
        visible: root.iridescent && root.glow > 0
        anchors.centerIn: parent
        width: root.size * 2.6
        height: root.size * 2.6
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.size * 1.3
                centerY: root.size * 1.3
                focalX: centerX
                focalY: centerY
                centerRadius: root.size * 1.3
                GradientStop {
                    position: 0
                    color: Qt.rgba(0.66, 0.55, 0.89, 0.55 * root.glow)
                }
                GradientStop {
                    position: 0.45
                    color: Qt.rgba(0.85, 0.55, 0.78, 0.18 * root.glow)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0.55, 0.83, 0.89, 0)
                }
            }
            PathAngleArc {
                centerX: root.size * 1.3
                centerY: root.size * 1.3
                radiusX: root.size * 1.3
                radiusY: root.size * 1.3
                sweepAngle: 360
            }
        }
    }

    Shape {
        width: 64
        height: 64
        x: (root.size - 64) / 2
        y: (root.size - 64) / 2
        scale: root.size / 64
        transformOrigin: Item.Center
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.iridescent ? "transparent" : root.color
            strokeWidth: -1
            fillGradient: root.iridescent ? sweep : null
            PathSvg {
                path: "M32 3c-2.6 6.4-4.2 10.6-7.1 16.8 1.8 1.9 4 4.1 7.5 6.6-3.8-1.6-6.4-3.1-8.3-4.8C20.4 30.2 14.6 41.1 3 61c9.1-5.3 16.2-8.5 22.8-9.8-.3-1.2-.4-2.5-.4-3.9l0-.3c.1-5.8 3.2-10.3 6.8-10 3.6.3 6.4 5.3 6.3 11.1 0 1.1-.1 2.1-.3 3.1 6.5 1.3 13.5 4.5 22.5 9.7-1.8-3.3-3.4-6.2-4.9-9.1-2.4-1.9-4.9-4.3-10-7 3.5.9 6 2 8 3.1C47.8 36.1 42.6 26 32 3z"
            }
        }
    }

    // same hues as the prompt's username and the fetch logo
    LinearGradient {
        id: sweep
        x1: 8
        y1: 2
        x2: 56
        y2: 62
        GradientStop {
            position: 0
            color: "#8cd4e2"
        }
        GradientStop {
            position: 0.35
            color: "#9b8ce2"
        }
        GradientStop {
            position: 0.7
            color: "#e28cd4"
        }
        GradientStop {
            position: 1
            color: "#e2c58c"
        }
    }
}
