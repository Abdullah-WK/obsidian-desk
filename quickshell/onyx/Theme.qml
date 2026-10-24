pragma Singleton
// Design tokens (§2): type, space, radius, motion. d(ms) is 0 under Config.reducedMotion.
import QtQuick
import Quickshell
import qs

Singleton {
    id: root

    // Type
    readonly property string ui: "Inter"
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string icons: "Material Symbols Rounded"

    // Space (base 4)
    readonly property int s1: 4
    readonly property int s2: 6
    readonly property int s3: 10
    readonly property int s4: 14
    readonly property int s5: 18
    readonly property int s6: 24

    // Radius
    readonly property int rChip: 3
    readonly property int rItem: 5
    readonly property int rPanel: 7
    readonly property int rWindow: 10
    readonly property int rFrame: 12

    // Bar geometry (§6.2)
    // one step up from the spec's 32/24/15 so the bar reads easily; popouts keep their sizes
    readonly property int barHeight: 36
    readonly property int barPadding: 10
    readonly property int itemHeight: 28
    readonly property int itemPadding: 8
    readonly property int itemGap: 2
    readonly property int iconSize: 17
    readonly property real barText: 12.5
    readonly property real barLabel: 12
    readonly property int popoutGap: 9
    readonly property int popoutMinWidth: 220
    readonly property int popoutPadding: 12
    readonly property int popoutSpace: 520
    readonly property int hideOffset: barHeight + 6

    // Curves: standard (.2,0,0,1), decel (0,0,0,1), accel (.3,0,1,1). No springs.
    readonly property var standard: [0.2, 0, 0, 1, 1, 1]
    readonly property var decel: [0, 0, 0, 1, 1, 1]
    readonly property var accel: [0.3, 0, 1, 1, 1, 1]

    // Durations
    function d(ms: int): int {
        return Config.reducedMotion ? 0 : ms;
    }
    readonly property int barReveal: d(160)
    readonly property int popout: d(120)
    readonly property int popoutDelay: 120
    readonly property int morph: d(160)
    readonly property int ring: d(340)
    readonly property int lift: d(220)
    readonly property int colour: d(180)
    readonly property int hold: d(600)
    readonly property int dot: d(200)
    readonly property int shake: d(300)
    readonly property int hoverGrace: 300
}
