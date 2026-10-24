// "class · title" 11 px: class onSurfaceVariant, title onSurface, title elides in the middle.
import QtQuick
import Quickshell.Hyprland
import qs
import qs.bar
import qs.components

BarItem {
    id: root

    property real maxWidth: 360

    readonly property HyprlandToplevel toplevel: Hyprland.activeToplevel
    readonly property string appClass: toplevel ? (toplevel.wayland?.appId || toplevel.lastIpcObject?.class || "") : ""
    readonly property string title: toplevel?.title ?? ""

    visible: toplevel !== null && (appClass !== "" || title !== "")
    contentSpacing: 0

    Ink {
        text: root.appClass + (root.title ? " · " : "")
        size: Theme.barText
        color: Scheme.fgSurfaceVariant
        anchors.verticalCenter: parent.verticalCenter
    }
    Ink {
        text: root.title
        size: Theme.barText
        font.weight: 500
        color: Scheme.fgSurface
        elide: Text.ElideMiddle
        width: Math.min(implicitWidth, root.maxWidth)
        anchors.verticalCenter: parent.verticalCenter
    }
}
