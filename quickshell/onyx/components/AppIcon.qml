// App icon for a Hyprland/wayland app id: icon themes name app icons after the app id in
// nearly every case; otherwise the desktop entry's icon; otherwise a generic executable.
import QtQuick
import Quickshell
import Quickshell.Widgets

IconImage {
    id: root

    property string appClass: ""

    readonly property var entry: appClass ? (DesktopEntries.heuristicLookup(appClass) ?? DesktopEntries.byId(appClass)) : null
    readonly property string iconName: entry?.icon ? entry.icon : appClass.toLowerCase()

    implicitSize: 16
    source: appClass ? Quickshell.iconPath(iconName, "application-x-executable") : ""
    visible: appClass !== ""
}
