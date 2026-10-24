// 2 px strip at the top edge, overlay layer, no exclusive zone, no keyboard.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool enabled: true
    readonly property alias hovered: hh.hovered

    signal entered

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 2
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: enabled
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "onyx-hotzone"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    HoverHandler {
        id: hh
        onHoveredChanged: if (hovered) root.entered()
    }
}
