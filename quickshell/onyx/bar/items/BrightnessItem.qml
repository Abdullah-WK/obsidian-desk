// Screen backlight icon by level. Scroll ±5 %. Click opens the display popout
// (screen + keyboard backlight sliders). Hidden when there is no backlight device.
import QtQuick
import qs
import qs.bar
import qs.bar.popouts
import qs.components
import qs.services

BarItem {
    id: root

    readonly property real level: Brightness.level
    readonly property string icon: level < 0.34 ? "brightness_low" : level < 0.67 ? "brightness_medium" : "brightness_high"

    align: "right"
    visible: Brightness.available
    popout: BrightnessPopout {
        host: root.host
    }

    onActivated: host.openPopout(root)
    onScrolled: delta => Brightness.setLevel(Brightness.level + (delta > 0 ? 0.05 : -0.05))

    Icon {
        text: root.icon
        color: root.ink
        anchors.verticalCenter: parent.verticalCenter
    }
}
