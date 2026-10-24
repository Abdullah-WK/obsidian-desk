// h5: left label (Inter 500 10 caps 0.12 em outline) · right value (mono 10.5 onSurfaceVariant)
import QtQuick
import qs
import qs.components

Item {
    id: root

    property string label: ""
    property string value: ""
    property bool showSwitch: false
    property bool checked: false

    signal toggled

    implicitHeight: 24
    width: parent.width

    Hairline {
        width: parent.width
        anchors.bottom: parent.bottom
    }

    Ink {
        text: root.label.toUpperCase()
        size: 10
        font.weight: 500
        tracking: 0.12
        color: Scheme.outline
        anchors.left: parent.left
        anchors.baseline: parent.top
        anchors.baselineOffset: 12
    }
    Ink {
        mono: true
        text: root.value
        size: 10.5
        color: Scheme.fgSurfaceVariant
        anchors.right: sw.visible ? sw.left : parent.right
        anchors.rightMargin: sw.visible ? 10 : 0
        anchors.baseline: parent.top
        anchors.baselineOffset: 12
    }
    PopSwitch {
        id: sw
        visible: root.showSwitch
        checked: root.checked
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 1
        onToggled: root.toggled()
    }
}
