// 300 wide, padding 18/20, r 10, rgba(9,9,11,.6), 1 px outlineVariant. Title row: label + interval.
import QtQuick
import qs
import qs.components

Rectangle {
    id: root

    property string title: ""
    property string interval: ""
    default property alias content: body.data

    width: 300
    implicitHeight: body.implicitHeight + 18 * 2 + head.height + 12
    radius: Theme.rWindow
    color: Scheme.alpha(Scheme.background, 0.6)
    border.width: 1
    border.color: Scheme.outlineVariant

    Item {
        id: head
        x: 20
        y: 18
        width: parent.width - 40
        height: 12

        Ink {
            text: root.title.toUpperCase()
            size: 10
            font.weight: 500
            tracking: 0.12
            color: Scheme.outline
            anchors.left: parent.left
            anchors.baseline: parent.bottom
        }
        Ink {
            mono: true
            text: root.interval
            size: 10
            color: Scheme.outline
            anchors.right: parent.right
            anchors.baseline: parent.bottom
        }
    }

    Column {
        id: body
        x: 20
        y: head.y + head.height + 12
        width: parent.width - 40
        spacing: 6
    }
}
