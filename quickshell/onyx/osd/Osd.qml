pragma ComponentBehavior: Bound
// On-screen indicator for volume and brightness changes (keys, scroll, anything): a small
// click-through pill centred just under the bar — icon, 120 px meter, value — that fades
// after Config.osdHideMs. Suppressed while a bar popout is open (its slider already shows
// the value) and for the first moments after start (initial values are not changes).
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs
import qs.components
import qs.services

Scope {
    id: root

    property string kind: ""      // "volume" | "brightness"
    property bool shown: false
    property bool armed: false

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real value: kind === "volume" ? (muted ? 0 : volume) : Brightness.level
    readonly property string icon: kind === "volume"
        ? (muted ? "volume_off" : volume < 0.01 ? "volume_mute" : volume < 0.5 ? "volume_down" : "volume_up")
        : (Brightness.level < 0.34 ? "brightness_low" : Brightness.level < 0.67 ? "brightness_medium" : "brightness_high")
    readonly property string label: kind === "volume" && muted ? "muted" : Math.round(value * 100) + "%"

    PwObjectTracker {
        objects: [root.sink]
    }

    function show(k: string): void {
        if (!armed || !Config.osdEnabled || Runtime.popoutOpen)
            return;
        kind = k;
        shown = true;
        hide.restart();
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged(): void {
            root.show("volume");
        }
        function onMutedChanged(): void {
            root.show("volume");
        }
    }
    Connections {
        target: Brightness
        function onGenerationChanged(): void {
            root.show("brightness");
        }
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: root.armed = true
    }
    Timer {
        id: hide
        interval: Config.osdHideMs
        onTriggered: root.shown = false
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData

            screen: modelData
            visible: card.opacity > 0
            anchors.top: true
            margins.top: (Runtime.barPinned && !GameMode.enabled ? Theme.barHeight : 0) + 10
            implicitWidth: card.width + 2
            implicitHeight: card.height + 2
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "onyx-osd"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Rectangle {
                id: card
                anchors.centerIn: parent
                width: row.implicitWidth + 2 * Theme.s4
                height: 36
                radius: Theme.rPanel
                color: Scheme.surfaceContainer
                border.width: 1
                border.color: Scheme.outlineVariant
                opacity: root.shown ? 1 : 0
                scale: root.shown ? 1 : 0.96

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.popout
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.shown ? Theme.decel : Theme.accel
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.popout
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.standard
                    }
                }

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 10

                    Icon {
                        text: root.icon
                        size: 17
                        color: Scheme.fgSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Slider {
                        width: 120
                        interactive: false
                        value: root.value
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Ink {
                        mono: true
                        text: root.label
                        size: Theme.barLabel
                        color: Scheme.fgSurfaceVariant
                        width: valueMetrics.width
                        horizontalAlignment: Text.AlignRight
                        anchors.verticalCenter: parent.verticalCenter

                        TextMetrics {
                            id: valueMetrics
                            font.family: Theme.mono
                            font.pointSize: Math.max(1, Theme.barLabel * 0.75)
                            text: "muted"
                        }
                    }
                }
            }
        }
    }
}
