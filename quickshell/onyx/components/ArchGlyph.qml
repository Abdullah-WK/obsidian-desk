// The Arch mark as a Shape path (no image). Colour defaults to archIce.
import QtQuick
import QtQuick.Shapes
import qs

Item {
    id: root

    property real size: 16
    property color color: Scheme.archIce

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 64
        height: 64
        scale: root.size / 64
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeWidth: -1
            PathSvg {
                path: "M32 3c-2.6 6.4-4.2 10.6-7.1 16.8 1.8 1.9 4 4.1 7.5 6.6-3.8-1.6-6.4-3.1-8.3-4.8C20.4 30.2 14.6 41.1 3 61c9.1-5.3 16.2-8.5 22.8-9.8-.3-1.2-.4-2.5-.4-3.9l0-.3c.1-5.8 3.2-10.3 6.8-10 3.6.3 6.4 5.3 6.3 11.1 0 1.1-.1 2.1-.3 3.1 6.5 1.3 13.5 4.5 22.5 9.7-1.8-3.3-3.4-6.2-4.9-9.1-2.4-1.9-4.9-4.3-10-7 3.5.9 6 2 8 3.1C47.8 36.1 42.6 26 32 3z"
            }
        }
    }
}
