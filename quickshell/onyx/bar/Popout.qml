pragma ComponentBehavior: Bound
// Shared popout container: one frame below the bar that fades/drops in and morphs its
// size and position when the active item changes. Closes 300 ms after the cursor leaves
// both the item and the frame.
import QtQuick
import qs

Item {
    id: root

    required property var host
    required property Item bar

    property var item: null
    property var anchorItem: null
    property Component content: null
    property bool settled: false

    readonly property bool open: item !== null
    readonly property alias hovered: hh.hovered
    readonly property alias frame: frame
    readonly property bool held: (item ? item.hot : false) || hh.hovered

    function show(it: var): void {
        closeT.stop();
        if (item === it)
            return;
        item = it;
        anchorItem = it;
        content = it.popout;
        settle.restart();
    }

    function hide(): void {
        item = null;
        settled = false;
        settle.stop();
    }

    onHeldChanged: {
        if (held)
            closeT.stop();
        else
            closeT.restart();
    }

    Timer {
        id: closeT
        interval: Theme.hoverGrace
        onTriggered: root.hide()
    }

    Timer {
        id: settle
        interval: Theme.popout + 20
        onTriggered: root.settled = true
    }

    anchors.fill: parent

    Rectangle {
        id: frame

        readonly property real contentW: loader.item ? loader.item.implicitWidth : 0
        readonly property real contentH: loader.item ? loader.item.implicitHeight : 0
        readonly property real targetW: Math.max(Theme.popoutMinWidth, contentW + Theme.popoutPadding * 2)
        readonly property real targetH: contentH + Theme.popoutPadding * 2
        readonly property real targetX: {
            const it = root.anchorItem;
            const barW = root.bar.width;
            if (!it)
                return Theme.barPadding;
            const p = it.mapToItem(root, 0, 0);
            let x = p.x;
            if (it.align === "center")
                x = p.x + it.width / 2 - targetW / 2;
            else if (it.align === "right")
                x = p.x + it.width - targetW;
            return Math.max(Theme.barPadding, Math.min(barW - Theme.barPadding - targetW, x));
        }

        width: targetW
        height: targetH
        x: targetX
        y: Theme.barHeight + Theme.popoutGap + (root.open ? 0 : -6)
        opacity: root.open ? 1 : 0
        visible: opacity > 0
        color: Scheme.surfaceContainerLow
        border.color: Scheme.outlineVariant
        border.width: 1
        radius: Theme.rPanel
        clip: true

        Behavior on width {
            enabled: root.settled
            NumberAnimation {
                duration: Theme.morph
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.standard
            }
        }
        Behavior on height {
            enabled: root.settled
            NumberAnimation {
                duration: Theme.morph
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.standard
            }
        }
        Behavior on x {
            enabled: root.settled
            NumberAnimation {
                duration: Theme.morph
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.standard
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: Theme.popout
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.decel
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.popout
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.decel
            }
        }

        Loader {
            id: loader
            x: Theme.popoutPadding
            y: Theme.popoutPadding
            active: root.open || frame.opacity > 0
            sourceComponent: root.content
        }

        HoverHandler {
            id: hh
        }
    }
}
