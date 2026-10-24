pragma ComponentBehavior: Bound
// key/value grid, mono 11.5: keys onSurfaceVariant, values onSurface right-aligned tabular.
import QtQuick
import qs
import qs.components

Column {
    id: root

    property var rows: []   // [[key, value], ...]
    property int keyWidth: 90

    width: parent.width
    spacing: 4

    Repeater {
        model: root.rows

        Item {
            id: row
            required property var modelData
            width: root.width
            implicitHeight: 15

            Ink {
                mono: true
                text: row.modelData[0]
                size: 11.5
                color: Scheme.fgSurfaceVariant
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
            Ink {
                mono: true
                text: row.modelData[1]
                size: 11.5
                color: Scheme.fgSurface
                horizontalAlignment: Text.AlignRight
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, root.width - root.keyWidth)
            }
        }
    }
}
