pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Picks the "most relevant" MPRIS player: a playing one, otherwise the first.
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property MprisPlayer active: players.find(p => p.isPlaying) ?? players[0] ?? null

    readonly property bool hasPlayer: active !== null
    readonly property bool playing: active?.isPlaying ?? false
    readonly property string title: active?.trackTitle || "Nothing playing"
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string art: active?.trackArtUrl ?? ""
    readonly property real position: active?.position ?? 0
    readonly property real length: active?.length ?? 0

    function fmt(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    // `position` is not pushed by MPRIS; poll it while something plays
    Timer {
        interval: 1000
        running: root.playing
        repeat: true
        onTriggered: root.active?.positionChanged()
    }
}
