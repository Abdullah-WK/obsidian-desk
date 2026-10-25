// Focused window: app icon + title (the icon already says which app). Titles elide in the
// middle past ~48 characters; an empty workspace reads "Desktop" in onSurfaceVariant.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.bar
import qs.components

BarItem {
    id: root

    property real maxWidth: 320

    readonly property HyprlandToplevel toplevel: Hyprland.activeToplevel
    readonly property string appClass: toplevel ? (toplevel.wayland?.appId || toplevel.lastIpcObject?.class || "") : ""
    readonly property string title: toplevel?.title ?? ""
    readonly property bool empty: toplevel === null || (appClass === "" && title === "")

    contentSpacing: 0

    AppIcon {
        appClass: root.empty ? "" : root.appClass
        anchors.verticalCenter: parent.verticalCenter
    }
    Item {
        visible: !root.empty && root.appClass !== ""
        width: 8
        height: 1
    }
    Ink {
        text: root.empty ? "Desktop" : (root.title || root.appClass)
        size: Theme.barText
        font.weight: root.empty ? 400 : 500
        color: root.empty ? Scheme.fgSurfaceVariant : Scheme.fgSurface
        elide: Text.ElideMiddle
        width: Math.min(implicitWidth, root.maxWidth)
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color {
            ColorAnimation {
                duration: Theme.colour
            }
        }
    }
}
