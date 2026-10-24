// Text with the Obsidian defaults: Inter 13 onSurface, or mono when `mono` is set.
import QtQuick
import qs

Text {
    id: root

    property bool mono: false
    property real tracking: 0 // em
    property real size: 13   // px (set through pointSize so half sizes work)

    font.family: mono ? Theme.mono : Theme.ui
    font.pointSize: Math.max(1, size * 0.75)
    font.weight: 400
    font.letterSpacing: tracking * size
    font.features: mono ? ({ "tnum": 1 }) : ({})
    color: Scheme.fgSurface
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
