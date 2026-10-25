// Renders the Arch glyph to PNGs for the Plymouth theme (run: qs -p plymouth/render-logo.qml from the repo root).
import QtQuick
import QtQuick.Shapes
import Quickshell

ShellRoot {
    FloatingWindow {
        id: win
        implicitWidth: 300
        implicitHeight: 300
        color: "transparent"
        visible: true

        Item {
            id: art
            width: 256
            height: 256
            anchors.centerIn: parent

            Shape {
                width: 64
                height: 64
                x: (256 - 64) / 2
                y: (256 - 64) / 2
                scale: 4
                transformOrigin: Item.Center
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: -1
                    fillGradient: LinearGradient {
                        x1: 8; y1: 2; x2: 56; y2: 62
                        GradientStop { position: 0; color: "#8cd4e2" }
                        GradientStop { position: 0.35; color: "#9b8ce2" }
                        GradientStop { position: 0.7; color: "#e28cd4" }
                        GradientStop { position: 1; color: "#e2c58c" }
                    }
                    PathSvg { path: "M32 3c-2.6 6.4-4.2 10.6-7.1 16.8 1.8 1.9 4 4.1 7.5 6.6-3.8-1.6-6.4-3.1-8.3-4.8C20.4 30.2 14.6 41.1 3 61c9.1-5.3 16.2-8.5 22.8-9.8-.3-1.2-.4-2.5-.4-3.9l0-.3c.1-5.8 3.2-10.3 6.8-10 3.6.3 6.4 5.3 6.3 11.1 0 1.1-.1 2.1-.3 3.1 6.5 1.3 13.5 4.5 22.5 9.7-1.8-3.3-3.4-6.2-4.9-9.1-2.4-1.9-4.9-4.3-10-7 3.5.9 6 2 8 3.1C47.8 36.1 42.6 26 32 3z" }
                }
            }
        }

        Timer {
            running: true
            interval: 600
            onTriggered: art.grabToImage(result => {
                result.saveToFile(Quickshell.env("ONYX_LOGO_OUT") || "/tmp/arch-logo.png");
                console.warn("PROBE saved logo");
                Qt.quit();
            })
        }
    }
}
