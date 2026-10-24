// Horizontal track + fill. Fill goes to error above `hot` (0.85 by default).
import QtQuick
import qs

Rectangle {
    id: root

    property real value: 0
    property real hot: 0.85
    property int thickness: 5
    property color fillColor: value > hot ? Scheme.error : Scheme.fgSurfaceVariant

    implicitHeight: thickness
    radius: thickness / 2
    color: Scheme.surfaceContainerHighest
    clip: true

    Rectangle {
        width: Math.round(Math.max(0, Math.min(1, root.value)) * parent.width)
        height: parent.height
        radius: parent.radius
        color: root.fillColor

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
    }
}
