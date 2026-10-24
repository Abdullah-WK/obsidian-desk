// launcher · super: Apps/actions/calc, Wallpaper, Shell settings
import QtQuick
import Quickshell
import qs

Column {
    id: root

    required property var host

    width: 196
    spacing: 10

    function run(cmd: var): void {
        Quickshell.execDetached(cmd);
        host.closePopout();
    }

    PopoutHeader {
        label: "launcher"
        value: "super"
    }
    Column {
        width: parent.width
        spacing: 2
        PopRow {
            icon: "search"
            text: "Apps, actions, calc"
            onClicked: root.run(["caelestia", "shell", "drawers", "toggle", "launcher"])
        }
        PopRow {
            icon: "image"
            text: "Wallpaper"
            onClicked: root.run(["caelestia", "wallpaper"])
        }
        PopRow {
            icon: "settings"
            text: "Shell settings"
            onClicked: root.run(["caelestia", "shell", "nexus", "open"])
        }
    }
}
