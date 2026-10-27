pragma ComponentBehavior: Bound
// Ring-draw hover glyph: 56 px hit area, 24 px icon, 1 px track. At rest it is monochrome; on
// hover/focus the action's accent takes over: a soft radial halo, a tinted disc, a 2 px accent
// ring drawn clockwise from the top, the icon fills and lifts 2 px, the label fades up.
// Hold glyphs fill a 3 px accent ring over 600 ms and confirm as a solid accent disc.
import QtQuick
import QtQuick.Shapes
import qs
import qs.components

Item {
    id: root

    required property string icon
    required property string label
    property bool hold: false
    property color accent: Scheme.archIce
    property color ringColor: accent
    property bool pulse: false
    property real pulseT: 0   // driven by the surface tick; pulses 3.2 s while waiting
    property real size: 56
    property real iconSize: 24
    property real scaleF: 1

    signal activated

    readonly property bool hot: hh.hovered || activeFocus
    property real progress: 0
    property bool done: false

    // 0 → 1 as the glyph becomes hot; drives halo, tint and icon together
    property real hotT: hot ? 1 : 0

    Behavior on hotT {
        NumberAnimation {
            duration: Theme.ring
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.decel
        }
    }

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
        // Wayland auto-repeat arrives as release+press pairs flagged isAutoRepeat;
        // ignoring them keeps a held key from cancelling its own hold.
        if (event.isAutoRepeat)
            return;
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

    // halo: radial accent glow behind the disc, only while hot (nothing rendered at rest)
    Shape {
        id: halo
        width: root.size * 2.1
        height: width
        anchors.centerIn: parent
        preferredRendererType: Shape.CurveRenderer
        visible: opacity > 0.005
        opacity: root.done ? 0.8 : root.hotT * (0.5 + 0.5 * root.progress)

        ShapePath {
            strokeColor: "transparent"
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: halo.width / 2
                centerY: halo.height / 2
                focalX: halo.width / 2
                focalY: halo.height / 2
                centerRadius: halo.width / 2
                GradientStop {
                    position: 0
                    color: Qt.alpha(root.accent, 0.38)
                }
                GradientStop {
                    position: 0.42
                    color: Qt.alpha(root.accent, 0.11)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
            PathAngleArc {
                centerX: halo.width / 2
                centerY: halo.height / 2
                radiusX: halo.width / 2
                radiusY: halo.width / 2
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // tinted disc while hot; deepens as a hold progresses
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: width / 2
        color: root.accent
        opacity: root.done ? 0 : root.hotT * 0.1 + root.progress * 0.2
    }

    // confirmed disc
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: width / 2
        color: root.accent
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
        // accent ring drawn on hover/focus
        ShapePath {
            strokeColor: root.ringColor
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - 1.5
                radiusY: root.size / 2 - 1.5
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
            strokeColor: root.accent
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root.size / 2 - 2
                radiusY: root.size / 2 - 2
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
        fill: root.hot || root.done ? 1 : 0
        scale: root.done ? 1 : 1 + 0.06 * root.hotT
        color: root.done ? Scheme.background : root.hot || root.progress > 0 ? root.accent : Scheme.outline

        Behavior on fill {
            NumberAnimation {
                duration: Theme.colour
            }
        }
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

        opacity: root.pulse && !root.hot && !root.done ? 0.725 + 0.275 * Math.cos(2 * Math.PI * root.pulseT / 3.2) : 1
    }

    Ink {
        id: lbl
        mono: true
        text: root.label + (root.hold && root.progress > 0 && !root.done ? " · hold" : "")
        size: 10 * root.scaleF
        tracking: 0.06
        color: root.progress > 0 && !root.done ? root.accent : Scheme.fgSurfaceVariant
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
