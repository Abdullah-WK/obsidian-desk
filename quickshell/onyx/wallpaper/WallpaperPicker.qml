pragma ComponentBehavior: Bound
// Wallpaper picker in the hyprquickpaper style: a full-width strip of sheared thumbnails over a
// scrim. ←/→ h/l j/k move, Tab wraps, u/d page, Enter/Space/click select, Esc closes, wheel and
// drag scroll. Selecting runs `caelestia wallpaper -f <file>`. Opens on the current wallpaper.
// Thumbnails are decoded by Qt at thumbnail size (no external cache) and kept once loaded.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.components

Scope {
    id: root

    property bool open: false
    property bool loaded: false
    property var files: []
    property string current: ""

    readonly property string dir: Config.wallpaperDir

    function show(): void {
        loaded = true;
        if (!scan.running)
            scan.running = true;
        open = true;
    }

    function hide(): void {
        open = false;
    }

    function toggle(): void {
        if (open)
            hide();
        else
            show();
    }

    function select(path: string): void {
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path]);
        current = path;
        if (!Config.wallpaperKeepOpen)
            hide();
    }

    function baseName(p: string): string {
        return p.split("/").pop().replace(/\.[^.]+$/, "");
    }

    Process {
        id: scan
        command: ["sh", "-c", `find "$1" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.avif' \\) -not -path '*/.*' | sort -f`, "find", root.dir]
        stdout: StdioCollector {
            onStreamFinished: root.files = text.split("\n").filter(l => l.length > 0)
        }
    }

    FileView {
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/caelestia/wallpaper/path.txt`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.current = text().trim()
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            visible: root.open
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "onyx-wallpaper"
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onVisibleChanged: if (visible) stripLoader.item?.focusStrip()

            Rectangle {
                anchors.fill: parent
                color: Scheme.alpha(Scheme.background, 0.6)

                TapHandler {
                    onTapped: root.hide()
                }
            }

            Loader {
                id: stripLoader
                active: root.loaded
                anchors.centerIn: parent
                width: parent.width
                height: Config.wallpaperHeight + 56

                sourceComponent: FocusScope {
                    id: strip

                    readonly property int shown: Math.max(1, Config.wallpaperShown)
                    readonly property real tileH: Config.wallpaperHeight
                    readonly property real shear: Config.wallpaperShear
                    readonly property real shearOffset: tileH * Math.abs(shear)
                    readonly property real tileW: (width - 2 * Theme.s6) / shown - list.spacing
                    property int selectedIndex: 0

                    function focusStrip(): void {
                        list.forceActiveFocus();
                        goToCurrent();
                    }

                    function goToCurrent(): void {
                        const i = root.files.indexOf(root.current);
                        selectedIndex = i >= 0 ? i : 0;
                        list.positionViewAtIndex(selectedIndex, ListView.Center);
                    }

                    function clamp(i: int): int {
                        return Math.max(0, Math.min(root.files.length - 1, i));
                    }

                    function wrap(i: int): int {
                        const n = root.files.length;
                        return n > 0 ? ((i % n) + n) % n : 0;
                    }

                    function move(i: int): void {
                        selectedIndex = clamp(i);
                        list.positionViewAtIndex(selectedIndex, ListView.Contain);
                    }

                    function activate(): void {
                        if (root.files.length > 0)
                            root.select(root.files[selectedIndex]);
                    }

                    Connections {
                        target: root
                        function onFilesChanged(): void {
                            strip.goToCurrent();
                        }
                    }

                    ListView {
                        id: list

                        x: Theme.s6
                        width: parent.width - 2 * Theme.s6
                        height: strip.tileH
                        orientation: ListView.Horizontal
                        spacing: 4
                        clip: true
                        model: root.files
                        cacheBuffer: Math.max(0, width)
                        // room for the shear on the open side; a strip shorter than the view is centred
                        readonly property real estimated: count * (strip.tileW + spacing) - spacing
                        leftMargin: Math.max(strip.shear < 0 ? strip.shearOffset : 0, (width - estimated - strip.shearOffset) / 2)
                        rightMargin: strip.shear > 0 ? strip.shearOffset : 0
                        focus: true
                        highlightMoveDuration: Theme.d(220)

                        Keys.onPressed: event => {
                            switch (event.key) {
                            case Qt.Key_Right:
                            case Qt.Key_Down:
                            case Qt.Key_L:
                            case Qt.Key_J:
                                strip.move(strip.selectedIndex + 1);
                                break;
                            case Qt.Key_Left:
                            case Qt.Key_Up:
                            case Qt.Key_H:
                            case Qt.Key_K:
                                strip.move(strip.selectedIndex - 1);
                                break;
                            case Qt.Key_Tab:
                                strip.move(strip.wrap(strip.selectedIndex + 1));
                                break;
                            case Qt.Key_Backtab:
                                strip.move(strip.wrap(strip.selectedIndex - 1));
                                break;
                            case Qt.Key_D:
                            case Qt.Key_PageDown:
                                strip.move(strip.selectedIndex + strip.shown);
                                break;
                            case Qt.Key_U:
                            case Qt.Key_PageUp:
                                strip.move(strip.selectedIndex - strip.shown);
                                break;
                            case Qt.Key_Home:
                                strip.move(0);
                                break;
                            case Qt.Key_End:
                                strip.move(root.files.length - 1);
                                break;
                            case Qt.Key_Return:
                            case Qt.Key_Enter:
                            case Qt.Key_Space:
                                strip.activate();
                                break;
                            case Qt.Key_Escape:
                            case Qt.Key_Q:
                                root.hide();
                                break;
                            default:
                                return;
                            }
                            event.accepted = true;
                        }

                        WheelHandler {
                            onWheel: event => strip.move(strip.selectedIndex + (event.angleDelta.y < 0 ? 1 : -1))
                        }

                        Behavior on contentX {
                            NumberAnimation {
                                duration: Theme.d(220)
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.decel
                            }
                        }

                        delegate: Item {
                            id: tile

                            required property int index
                            required property string modelData

                            readonly property bool active: index === strip.selectedIndex
                            readonly property bool isCurrent: modelData === root.current

                            width: strip.tileW
                            height: strip.tileH

                            Rectangle {
                                anchors.fill: parent
                                color: Scheme.surfaceContainerLow
                                transform: Shear {
                                    xFactor: strip.shear
                                }
                            }

                            Image {
                                id: img
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                smooth: true
                                mipmap: false
                                source: "file://" + tile.modelData
                                sourceSize.width: 640
                                sourceSize.height: 360
                                opacity: tile.active ? 1 : 0.55
                                transform: Shear {
                                    xFactor: strip.shear
                                }

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Theme.colour
                                    }
                                }
                            }

                            Ink {
                                visible: img.status !== Image.Ready
                                anchors.centerIn: parent
                                mono: true
                                text: img.status === Image.Error ? "unreadable" : "loading…"
                                size: 11
                                color: Scheme.outline
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.width: tile.active ? 2 : 1
                                border.color: tile.active ? Scheme.primary : Scheme.alpha(Scheme.outlineVariant, 0.8)
                                transform: Shear {
                                    xFactor: strip.shear
                                }
                            }

                            // current wallpaper mark
                            Rectangle {
                                visible: tile.isCurrent
                                width: 8
                                height: 8
                                radius: 4
                                color: Scheme.primary
                                x: parent.width - 18 - strip.shearOffset * 0.5
                                y: 10
                            }

                            HoverHandler {
                                onHoveredChanged: if (hovered) strip.selectedIndex = tile.index
                            }
                            TapHandler {
                                onTapped: {
                                    strip.selectedIndex = tile.index;
                                    strip.activate();
                                }
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: list.bottom
                        anchors.topMargin: Theme.s5
                        spacing: Theme.s3

                        Ink {
                            mono: true
                            text: root.files.length > 0 ? root.baseName(root.files[strip.selectedIndex] ?? "") : "no wallpapers in " + root.dir
                            size: 12
                            color: Scheme.fgSurface
                        }
                        Ink {
                            mono: true
                            visible: root.files.length > 0
                            text: `${strip.selectedIndex + 1} / ${root.files.length}` + (root.files[strip.selectedIndex] === root.current ? " · current" : "")
                            size: 12
                            color: Scheme.outline
                        }
                    }
                }
            }
        }
    }
}
