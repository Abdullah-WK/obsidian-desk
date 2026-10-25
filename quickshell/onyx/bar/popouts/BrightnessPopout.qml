// display · NN%: screen backlight slider, keyboard backlight slider (when the laptop has one).
import QtQuick
import qs
import qs.components
import qs.services

Column {
    id: root

    required property var host

    width: 206
    spacing: 10

    Component.onCompleted: Brightness.refresh()

    PopoutHeader {
        label: "display"
        value: Math.round(Brightness.level * 100) + "%"
    }

    Row {
        width: parent.width
        spacing: 10

        Icon {
            text: "brightness_medium"
            size: 16
            color: Scheme.fgSurfaceVariant
            anchors.verticalCenter: parent.verticalCenter
        }
        Slider {
            width: parent.width - 26
            anchors.verticalCenter: parent.verticalCenter
            value: Brightness.level
            onMoved: v => Brightness.setLevel(v)
        }
    }

    Column {
        visible: Brightness.kbdAvailable
        width: parent.width
        spacing: 6

        Row {
            width: parent.width
            Ink {
                text: "keyboard backlight"
                size: Theme.barLabel
                color: Scheme.fgSurfaceVariant
                width: parent.width - value.width
            }
            Ink {
                id: value
                mono: true
                text: Math.round(Brightness.kbdLevel * 100) + "%"
                size: Theme.barLabel
                color: Scheme.fgSurfaceVariant
            }
        }
        Row {
            width: parent.width
            spacing: 10

            Icon {
                text: "keyboard"
                size: 16
                color: Scheme.fgSurfaceVariant
                anchors.verticalCenter: parent.verticalCenter
            }
            Slider {
                width: parent.width - 26
                anchors.verticalCenter: parent.verticalCenter
                value: Brightness.kbdLevel
                step: 0.25
                onMoved: v => Brightness.setKbd(v)
            }
        }
    }

    PopCta {
        text: "scroll the bar icon · brightness ±5%"
    }
}
