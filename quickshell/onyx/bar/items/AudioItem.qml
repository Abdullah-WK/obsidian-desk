// Default sink icon by level/mute. Scroll ±5 %. Click toggles mute. Popout: audio.
import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.bar
import qs.bar.popouts
import qs.components

BarItem {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property string icon: muted ? "volume_off" : volume < 0.01 ? "volume_mute" : volume < 0.5 ? "volume_down" : "volume_up"

    align: "right"
    popout: AudioPopout {
        host: root.host
    }

    onActivated: host.openPopout(root)
    onScrolled: delta => {
        if (!sink?.audio)
            return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (delta > 0 ? 0.05 : -0.05)));
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Icon {
        text: root.icon
        color: root.ink
        anchors.verticalCenter: parent.verticalCenter
    }
}
