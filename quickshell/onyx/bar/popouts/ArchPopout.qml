// launcher · super: Apps/actions/calc, Wallpaper, Shell settings
import QtQuick
import Quickshell
import qs
import qs.services

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
            onClicked: root.run(["qs", "-c", "onyx", "ipc", "call", "wallpaper", "open"])
        }
        PopRow {
            icon: "settings"
            text: "Shell settings"
            onClicked: root.run(["caelestia", "shell", "nexus", "open"])
        }
    }

    PopCta {
        text: Updates.count > 0 ? `${Updates.count} updates · open ${Config.updatesCommand.slice(-1)[0]}` : Updates.count === 0 ? "up to date" : "updates not checked yet"
        clickable: Updates.count > 0
        onClicked: {
            Updates.open();
            root.host.closePopout();
        }
    }
}
