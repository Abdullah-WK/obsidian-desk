pragma ComponentBehavior: Bound
// audio · NN%: slider, sink rows (selected = default), mic row with mute state.
import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.components

Column {
    id: root

    required property var host

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property real volume: sink?.audio?.volume ?? 0

    width: 206
    spacing: 10

    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks]
    }

    function setVolume(v: real): void {
        if (!sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function sinkName(n: PwNode): string {
        // nickname is the short, user-facing name ("Speakers", "HDMI 2"); description is the long chipset string
        const name = n.nickname || n.description || n.name;
        return name.replace(/^Family 17h\/19h\/1ah |^700 Series Chipset Family /, "").replace(" Output", "");
    }

    function sinkIcon(n: PwNode): string {
        const s = (n.description + " " + n.name).toLowerCase();
        if (s.includes("headphone") || s.includes("headset") || s.includes("bluez"))
            return "headphones";
        if (s.includes("hdmi") || s.includes("display"))
            return "tv";
        return "speaker";
    }

    PopoutHeader {
        label: "audio"
        value: root.sink?.audio?.muted ? "muted" : Math.round(root.volume * 100) + "%"
        showSwitch: root.sink?.audio !== undefined && root.sink?.audio !== null
        checked: !(root.sink?.audio?.muted ?? true)
        onToggled: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
    }

    Item {
        id: slider
        width: parent.width
        implicitHeight: 14

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Scheme.surfaceContainerHighest

            Rectangle {
                width: Math.round(root.volume * parent.width)
                height: parent.height
                radius: 2
                color: Scheme.primary
            }
        }
        Rectangle {
            x: Math.round(root.volume * (parent.width - width))
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: Scheme.primary
        }
        MouseArea {
            anchors.fill: parent
            onPressed: mouse => root.setVolume(mouse.x / width)
            onPositionChanged: mouse => {
                if (pressed)
                    root.setVolume(mouse.x / width);
            }
        }
        WheelHandler {
            onWheel: event => root.setVolume(root.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
        }
    }

    Column {
        width: parent.width
        spacing: 2

        Repeater {
            model: root.sinks
            PopRow {
                required property PwNode modelData
                icon: root.sinkIcon(modelData)
                text: root.sinkName(modelData)
                selected: modelData === root.sink
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }
        PopRow {
            visible: root.source !== null
            icon: root.source?.audio?.muted ? "mic_off" : "mic"
            text: root.source ? root.sinkName(root.source) : "Mic"
            trailing: root.source?.audio?.muted ? "muted" : Math.round((root.source?.audio?.volume ?? 0) * 100) + "%"
            onClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
        }
    }

    PopCta {
        text: "scroll the bar icon · volume ±5%"
    }
}
