// "class · title" 11 px: class onSurfaceVariant, title onSurface, title elides in the middle.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import qs
import qs.bar
import qs.components

BarItem {
    id: root

    property real maxWidth: 360

    readonly property HyprlandToplevel toplevel: Hyprland.activeToplevel
    readonly property string appClass: toplevel ? (toplevel.wayland?.appId || toplevel.lastIpcObject?.class || "") : ""
    readonly property string title: toplevel?.title ?? ""
    // icon themes name app icons after the app id / class in nearly every case; fall back to the desktop entry
    readonly property var entry: appClass ? (DesktopEntries.heuristicLookup(appClass) ?? DesktopEntries.byId(appClass)) : null
    readonly property string iconName: entry?.icon ? entry.icon : appClass.toLowerCase()
    readonly property string iconSource: appClass ? Quickshell.iconPath(iconName, "application-x-executable") : ""

    visible: toplevel !== null && (appClass !== "" || title !== "")
    contentSpacing: 0

    Loader {
        active: root.iconSource !== ""
        visible: active
        anchors.verticalCenter: parent.verticalCenter
        sourceComponent: IconImage {
            implicitSize: 16
            source: root.iconSource
        }
    }
    Item {
        visible: root.iconSource !== ""
        width: 8
        height: 1
    }
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
