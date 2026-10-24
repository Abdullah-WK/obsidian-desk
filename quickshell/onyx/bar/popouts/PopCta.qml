// Footer line: hairline + mono 10.5 outline text. Optionally clickable.
import QtQuick
import qs
import qs.components

Item {
    id: root

    property string text: ""
    property bool clickable: false

    signal clicked

    width: parent.width
    implicitHeight: 20

    Hairline {
        width: parent.width
        anchors.top: parent.top
    }
    Ink {
        mono: true
        text: root.text
        size: 10.5
        color: root.clickable && hh.hovered ? Scheme.fgSurfaceVariant : Scheme.outline
        anchors.bottom: parent.bottom
        width: parent.width
    }
    HoverHandler {
        id: hh
        enabled: root.clickable
    }
    TapHandler {
        enabled: root.clickable
        onTapped: root.clicked()
    }
}
