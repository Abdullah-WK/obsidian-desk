// Horizontal 0..1 slider: 4 px track in surfaceContainerHighest, primary fill, 10 px knob.
// Press/drag sets, wheel steps by `step`. `interactive: false` makes a read-only meter
// (the OSD) whose fill animates.
import QtQuick
import qs

Item {
    id: root

    property real value: 0
    property real step: 0.05
    property bool interactive: true
    property color accent: Scheme.primary

    signal moved(real v)

    implicitHeight: 14

    function set(v: real): void {
        root.moved(Math.max(0, Math.min(1, v)));
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        radius: 2
        color: Scheme.surfaceContainerHighest

        Rectangle {
            width: Math.round(Math.max(0, Math.min(1, root.value)) * parent.width)
            height: parent.height
            radius: 2
            color: root.accent

            Behavior on width {
                enabled: !root.interactive
                NumberAnimation {
                    duration: Theme.popout
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.standard
                }
            }
        }
    }
    Rectangle {
        visible: root.interactive
        x: Math.round(Math.max(0, Math.min(1, root.value)) * (parent.width - width))
        anchors.verticalCenter: parent.verticalCenter
        width: 10
        height: 10
        radius: 5
        color: root.accent
    }
    MouseArea {
        anchors.fill: parent
        enabled: root.interactive
        onPressed: mouse => root.set(mouse.x / width)
        onPositionChanged: mouse => {
            if (pressed)
                root.set(mouse.x / width);
        }
    }
    WheelHandler {
        enabled: root.interactive
        onWheel: event => root.set(root.value + (event.angleDelta.y > 0 ? root.step : -root.step))
    }
}
