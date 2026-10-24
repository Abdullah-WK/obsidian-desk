// 28 × 16 switch: track outlineVariant → primary, 12 px knob.
import QtQuick
import qs

Rectangle {
    id: root

    property bool checked: false
    signal toggled

    width: 28
    height: 16
    radius: 8
    color: checked ? Scheme.primary : Scheme.surfaceContainerHighest
    border.width: 1
    border.color: checked ? Scheme.primary : Scheme.outlineVariant

    Behavior on color {
        ColorAnimation {
            duration: Theme.colour
        }
    }

    Rectangle {
        x: root.checked ? root.width - width - 2 : 2
        anchors.verticalCenter: parent.verticalCenter
        width: 12
        height: 12
        radius: 6
        color: root.checked ? Scheme.fgPrimary : Scheme.fgSurfaceVariant

        Behavior on x {
            NumberAnimation {
                duration: Theme.colour
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.standard
            }
        }
    }

    TapHandler {
        onTapped: root.toggled()
    }
}
