pragma ComponentBehavior: Bound
// 300 × 40 field: hairline bottom, lock glyph (caps lock → red keyboard_capslock),
// placeholder that fades on the first key, 6 px dots, arrow submits. Wrong: hairline → error,
// 3 px shake, "incorrect" for 1.5 s. Cooldown: thin countdown line.
import QtQuick
import qs
import qs.components

Item {
    id: root

    required property var state
    property real s: 1

    readonly property int dots: state.pending > 0 ? state.pending : state.buffer.length
    readonly property bool typing: dots > 0

    implicitWidth: 300 * s
    implicitHeight: 40 * s

    Connections {
        target: root.state
        function onWrong(): void {
            shake.restart();
        }
    }

    Item {
        id: body
        anchors.fill: parent

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: body; property: "x"; to: -3; duration: Theme.shake / 5 }
            NumberAnimation { target: body; property: "x"; to: 3; duration: Theme.shake / 5 }
            NumberAnimation { target: body; property: "x"; to: -3; duration: Theme.shake / 5 }
            NumberAnimation { target: body; property: "x"; to: 3; duration: Theme.shake / 5 }
            NumberAnimation { target: body; property: "x"; to: 0; duration: Theme.shake / 5 }
        }

        Rectangle {
            id: hairline
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: root.state.unlocking ? Scheme.fgSurface : root.state.failed ? Scheme.error : Scheme.outlineVariant

            Behavior on color {
                ColorAnimation {
                    duration: Theme.colour
                }
            }
        }

        // cooldown countdown line
        Rectangle {
            anchors.bottom: parent.bottom
            height: 1
            width: root.state.cooldown ? parent.width * (root.state.cooldownLeft / 10) : 0
            color: Scheme.error
            visible: root.state.cooldown
        }

        Icon {
            id: leftGlyph
            anchors.left: parent.left
            anchors.leftMargin: 14 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: root.state.capsLock ? "keyboard_capslock" : "lock"
            size: 16 * root.s
            color: root.state.capsLock ? Scheme.error : Scheme.outline
        }

        Ink {
            mono: true
            text: root.state.cooldown ? `wait ${Math.ceil(root.state.cooldownLeft)} s` : "enter your password"
            size: 12 * root.s
            color: Scheme.outline
            anchors.left: leftGlyph.right
            anchors.leftMargin: 12 * root.s
            anchors.verticalCenter: parent.verticalCenter
            opacity: root.typing ? 0 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.dot
                }
            }
        }

        Row {
            anchors.left: leftGlyph.right
            anchors.leftMargin: 12 * root.s
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7 * root.s

            Repeater {
                model: Math.min(root.dots, 24)

                Rectangle {
                    width: 6 * root.s
                    height: 6 * root.s
                    radius: width / 2
                    color: Scheme.fgSurface
                    scale: 0.4
                    opacity: root.state.busy ? 0.6 : 1

                    Component.onCompleted: grow.start()

                    NumberAnimation on scale {
                        id: grow
                        running: false
                        to: 1
                        duration: Theme.dot
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.decel
                    }
                }
            }
        }

        Icon {
            anchors.right: parent.right
            anchors.rightMargin: 12 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: "arrow_forward"
            size: 16 * root.s
            color: root.typing || goHover.hovered ? Scheme.fgSurfaceVariant : Scheme.outline

            HoverHandler {
                id: goHover
            }
            TapHandler {
                onTapped: root.state.submit()
            }
        }
    }

    Ink {
        mono: true
        text: "incorrect"
        size: 11 * root.s
        color: Scheme.error
        anchors.top: parent.bottom
        anchors.topMargin: 8 * root.s
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: root.state.failed ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.colour
            }
        }
    }
}
