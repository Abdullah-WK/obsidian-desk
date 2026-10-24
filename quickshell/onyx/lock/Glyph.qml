pragma ComponentBehavior: Bound
// Ring-draw hover glyph: 56 px hit area, 24 px icon, 1 px track, ring draws clockwise from
// the top on hover/focus, icon lifts 2 px, label fades up. Hold glyphs fill a 2 px error
// ring over 600 ms and confirm as a solid disc.
import QtQuick
import QtQuick.Shapes
import qs
import qs.components

Item {
    id: root

    required property string icon
    required property string label
    property bool hold: false
    property color ringColor: Scheme.fgSurface
    property bool pulse: false
    property real size: 56
    property real iconSize: 24
    property real scaleF: 1

    signal activated

    readonly property bool hot: hh.hovered || activeFocus
    property real progress: 0
    property bool done: false

    width: size
    height: size
    activeFocusOnTab: true

    function fire(): void {
        done = true;
        fireT.restart();
    }

    function startHold(): void {
        if (!hold) {
            fire();
            return;
        }
        holdAnim.restart();
    }

    function cancelHold(): void {
        if (hold && !done) {
            holdAnim.stop();
            progress = 0;
        }
    }

    Keys.onPressed: event => {
        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) && !event.isAutoRepeat) {
            startHold();
            event.accepted = true;
        }
    }
    Keys.onReleased: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            cancelHold();
            event.accepted = true;
        }
    }

    Timer {
        id: fireT
        interval: 220
        onTriggered: {
            root.activated();
            root.done = false;
            root.progress = 0;
        }
    }

    NumberAnimation {
        id: holdAnim
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: Theme.hold
        easing.type: Easing.Linear
        onFinished: if (root.progress >= 1) root.fire()
    }

    // confirmed disc
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: width / 2
        color: Scheme.fgSurface
        visible: root.done
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // track
        ShapePath {
            strokeColor: Scheme.outlineVariant
            strokeWidth: 1
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - 1
                radiusY: root.size / 2 - 1
                startAngle: 0
                sweepAngle: 360
            }
        }
        // draw on hover
        ShapePath {
            strokeColor: root.ringColor
            strokeWidth: 1
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - 1
                radiusY: root.size / 2 - 1
                startAngle: -90
                sweepAngle: root.hot && !root.done ? 360 : 0

                Behavior on sweepAngle {
                    NumberAnimation {
                        duration: Theme.ring
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.decel
                    }
                }
            }
        }
        // hold fill
        ShapePath {
            strokeColor: Scheme.error
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - 1
                radiusY: root.size / 2 - 1
                startAngle: -90
                sweepAngle: root.done ? 0 : root.progress * 360
            }
        }
    }

    Icon {
        id: glyph
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.hot ? -2 : 0
        text: root.icon
        size: root.iconSize
        weight: 400
        color: root.done ? Scheme.fgPrimary : root.progress > 0 ? Scheme.error : root.hot ? Scheme.fgSurface : Scheme.outline

        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: Theme.lift
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.decel
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Theme.colour
            }
        }

        SequentialAnimation on opacity {
            running: root.pulse && !root.hot && !root.done
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.45
                duration: 1600
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                to: 1
                duration: 1600
                easing.type: Easing.InOutSine
            }
            onStopped: glyph.opacity = 1
        }
    }

    Ink {
        id: lbl
        mono: true
        text: root.label + (root.hold && root.progress > 0 && !root.done ? " · hold" : "")
        size: 10 * root.scaleF
        tracking: 0.06
        color: root.progress > 0 && !root.done ? Scheme.error : Scheme.fgSurfaceVariant
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 6 + (root.hot ? 0 : -4)
        opacity: root.hot ? 1 : 0

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation {
                    duration: Theme.d(100)
                }
                NumberAnimation {
                    duration: Theme.colour
                }
            }
        }
        Behavior on anchors.topMargin {
            SequentialAnimation {
                PauseAnimation {
                    duration: Theme.d(100)
                }
                NumberAnimation {
                    duration: Theme.colour
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.decel
                }
            }
        }
    }

    HoverHandler {
        id: hh
    }

    MouseArea {
        anchors.fill: parent
        onPressed: root.startHold()
        onReleased: root.cancelHold()
        onCanceled: root.cancelHold()
    }
}
