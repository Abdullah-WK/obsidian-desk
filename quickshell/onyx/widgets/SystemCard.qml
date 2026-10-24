pragma ComponentBehavior: Bound
// Arch glyph 40 archIce; user@host, kernel, uptime, pkgs, shell, wm. Keys outline, 64 px column.
import QtQuick
import qs
import qs.components
import qs.services

Card {
    id: root

    title: "system"
    interval: "on login"

    Row {
        width: parent.width
        spacing: 16

        ArchGlyph {
            size: 40
            y: 4
        }

        Column {
            width: parent.width - 56
            spacing: 2

            Ink {
                mono: true
                text: SysInfo.userHost
                size: 12.5
                font.weight: 500
                color: Scheme.fgSurface
                height: 20
            }

            Repeater {
                model: [["kernel", SysInfo.kernel], ["uptime", SysInfo.uptime], ["pkgs", SysInfo.pkgs + " · " + SysInfo.aur + " aur"], ["shell", "caelestia " + SysInfo.shellVersion], ["wm", "hyprland " + SysInfo.wmVersion]]

                Item {
                    id: row
                    required property var modelData
                    width: parent.width
                    height: 20

                    Ink {
                        mono: true
                        text: row.modelData[0]
                        size: 12.5
                        color: Scheme.outline
                        width: 64
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Ink {
                        mono: true
                        text: row.modelData[1]
                        size: 12.5
                        color: Scheme.fgSurfaceVariant
                        x: 64
                        width: parent.width - 64
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
