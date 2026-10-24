// Material Symbols Rounded glyph. size in px, weight 100–700, fill 0–1.
import QtQuick
import qs

Text {
    id: root

    property int size: Theme.iconSize
    property int weight: 400
    property real fill: 0

    font.family: Theme.icons
    font.pixelSize: size
    font.variableAxes: ({
            "FILL": fill,
            "wght": weight,
            "GRAD": 0,
            "opsz": Math.max(20, Math.min(48, size))
        })
    color: Scheme.fgSurfaceVariant
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    lineHeight: 1
}
