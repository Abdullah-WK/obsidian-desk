// Row: icon · text [· right]. Selected = surfaceContainer with a 2 px primary inset rule.
import QtQuick
import qs
import qs.components

Rectangle {
    id: root

    property string icon: ""
    property string text: ""
    property string trailing: ""
    property bool selected: false
    property bool enabled: true

    signal clicked

    readonly property bool hot: hh.hovered && enabled

    width: parent.width
    implicitHeight: 30
    radius: Theme.rItem
    color: selected ? Scheme.surfaceContainer : hot ? Scheme.alpha(Scheme.surfaceContainer, 0.6) : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: Theme.popout
        }
    }

    Rectangle {
        visible: root.selected
        width: 2
        height: parent.height
        radius: 1
        color: Scheme.primary
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        x: 10
        spacing: 10

        Icon {
            visible: root.icon !== ""
            text: root.icon
            color: root.selected ? Scheme.fgSurface : Scheme.fgSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }
        Ink {
            text: root.text
            size: 12
            font.weight: root.selected ? 500 : 400
            color: root.selected || root.hot ? Scheme.fgSurface : Scheme.fgSurfaceVariant
            width: Math.min(implicitWidth, root.width - 16 - (root.icon ? 25 : 0) - (rightText.visible ? rightText.implicitWidth + 10 : 0))
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Ink {
        id: rightText
        visible: root.trailing !== ""
        mono: true
        text: root.trailing
        size: 10.5
        color: Scheme.outline
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
    }

    HoverHandler {
        id: hh
    }
    TapHandler {
        enabled: root.enabled
        onTapped: root.clicked()
    }
}
