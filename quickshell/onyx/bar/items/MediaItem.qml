// Now playing: shown only while a player is playing. Click pauses, scroll skips.
import QtQuick
import Quickshell.Services.Mpris
import qs
import qs.bar
import qs.components

BarItem {
    id: root

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? null

    visible: player !== null
    contentSpacing: 7
    onActivated: player?.togglePlaying()
    onScrolled: delta => {
        if (!player)
            return;
        if (delta < 0 && player.canGoNext)
            player.next();
        else if (delta > 0 && player.canGoPrevious)
            player.previous();
    }

    Icon {
        text: "music_note"
        color: root.ink
        anchors.verticalCenter: parent.verticalCenter
    }
    Ink {
        text: root.player ? (root.player.trackTitle || "Untitled") + (root.player.trackArtist ? " · " + root.player.trackArtist : "") : ""
        size: Theme.barText
        color: root.ink
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 240)
        anchors.verticalCenter: parent.verticalCenter
    }
}
