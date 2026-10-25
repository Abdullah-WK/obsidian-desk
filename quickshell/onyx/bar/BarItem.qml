pragma ComponentBehavior: Bound
// Base for every bar item: 24 px high, 7 px padding, hover fill, 120 ms dwell → popout,
// Tab focus (when the bar is pinned) opens the popout, Enter activates.
import QtQuick
import qs
import qs.components

Item {
    id: root

    required property var host
    property Component popout: null
    property string align: "left"
    property bool interactive: true
    property real contentSpacing: 6
    default property alias content: inner.data

    readonly property bool hot: hh.hovered || activeFocus
    readonly property bool open: host.openItem === root
    readonly property color ink: hot ? Scheme.fgSurface : Scheme.fgSurfaceVariant

    signal activated
    signal scrolled(int delta)

    implicitWidth: inner.implicitWidth + Theme.itemPadding * 2
    implicitHeight: Theme.itemHeight
    activeFocusOnTab: popout !== null

    onActiveFocusChanged: if (activeFocus && popout) host.openPopout(root)

    Keys.onReturnPressed: root.activated()
    Keys.onEnterPressed: root.activated()

    Rectangle {
        anchors.fill: parent
        radius: Theme.rChip
        color: root.open ? Scheme.surfaceContainerHigh : root.hot && root.interactive ? Scheme.surfaceContainer : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.popout
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -4
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.open ? parent.width - 8 : 0
        height: 2
        radius: 1
        gradient: Sweep {}

        Behavior on width {
            NumberAnimation {
                duration: Theme.morph
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.standard
            }
        }
    }

    Row {
        id: inner
        anchors.centerIn: parent
        spacing: root.contentSpacing
    }

    HoverHandler {
        id: hh
        onHoveredChanged: {
            if (hovered) {
                if (root.popout)
                    dwell.restart();
            } else {
                dwell.stop();
            }
        }
    }

    TapHandler {
        onTapped: root.activated()
    }

    WheelHandler {
        onWheel: event => root.scrolled(event.angleDelta.y)
    }

    Timer {
        id: dwell
        interval: Theme.popoutDelay
        onTriggered: root.host.openPopout(root)
    }
}
