pragma ComponentBehavior: Bound
// Desktop widgets column, top-right, 16 px from the frame. Layer "bottom" (under every
// window, above the wallpaper; "background" would be re-covered whenever Caelestia's
// wallpaper layer remaps). Click-through except the Updates card. Hidden in game mode.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

PanelWindow {
    id: root

    readonly property bool shown: Config.widgetsEnabled && !GameMode.enabled

    anchors {
        top: true
        right: true
    }
    margins {
        top: 16
        right: 16
    }
    implicitWidth: 300
    implicitHeight: Math.max(1, column.implicitHeight)
    // reserve nothing, but respect other layers' zones (the pinned bar, Caelestia's frame)
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    visible: shown
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "onyx-widgets"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: updates.visible ? updates : null
    }

    Column {
        id: column
        width: parent.width
        spacing: 14

        ClockCard {
            visible: Config.widgetClock
        }
        SystemCard {
            visible: Config.widgetSystem
        }
        VitalsCard {
            visible: Config.widgetVitals
            live: root.shown && visible
        }
        UpdatesCard {
            id: updates
            visible: Config.widgetUpdates
        }
    }
}
