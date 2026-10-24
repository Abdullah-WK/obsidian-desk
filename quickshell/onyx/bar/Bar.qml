pragma ComponentBehavior: Bound
// Top status bar for one screen. Hidden above the edge; a 2 px hot zone reveals it.
// Popouts render inside this window (below the bar strip) so nothing maps/unmaps.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.lock
import qs.services
import qs.components
import qs.bar.items

Scope {
    id: root

    required property ShellScreen screen
    required property Lock lock

    readonly property bool gameMode: GameMode.enabled
    readonly property bool pinned: Runtime.barPinned
    property bool revealed: false
    readonly property bool shown: !gameMode && (pinned || revealed)
    readonly property bool anyHover: hot.hovered || barHover.hovered || popout.hovered
    readonly property bool holding: anyHover || popout.open
    readonly property var openItem: popout.item

    function reveal(): void {
        if (gameMode)
            return;
        retract.stop();
        revealed = true;
    }

    function openPopout(item: var): void {
        popout.show(item);
    }

    function closePopout(): void {
        popout.hide();
    }

    onHoldingChanged: {
        if (holding) {
            retract.stop();
            revealed = true;
        } else {
            retract.restart();
        }
    }

    onPinnedChanged: {
        if (pinned) {
            revealed = true;
            barBody.forceActiveFocus();
        } else if (!holding) {
            retract.restart();
        }
    }

    onGameModeChanged: if (gameMode) {
        popout.hide();
        revealed = false;
    }

    Timer {
        id: retract
        interval: Theme.hoverGrace
        onTriggered: if (!root.pinned && !root.holding) root.revealed = false
    }

    HotZone {
        id: hot
        screen: root.screen
        enabled: !root.gameMode
        onEntered: {
            GameMode.check();
            root.reveal();
        }
    }

    PanelWindow {
        id: win

        screen: root.screen
        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Theme.barHeight + Theme.popoutSpace
        // pinned: reserve the strip so windows tile below it; hidden: no reserved space
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: root.pinned && !root.gameMode ? Theme.barHeight : 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "onyx-bar"
        WlrLayershell.keyboardFocus: root.pinned ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // Input mask follows the slide offset explicitly: an item-based Region does not
        // track a translated parent, so the hidden bar would otherwise keep a stale mask.
        mask: Region {
            regions: [
                Region {
                    x: 0
                    y: slide.y
                    width: barBody.width
                    height: barBody.height
                },
                Region {
                    x: popout.frame.x
                    y: slide.y + popout.frame.y
                    width: popout.open ? popout.frame.width : 0
                    height: popout.open ? popout.frame.height : 0
                }
            ]
        }

        Item {
            id: slide

            width: parent.width
            height: parent.height
            y: root.shown ? 0 : -Theme.hideOffset

            Behavior on y {
                NumberAnimation {
                    duration: Theme.barReveal
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.shown ? Theme.decel : Theme.accel
                }
            }

            FocusScope {
                id: barBody

                width: parent.width
                height: Theme.barHeight

                Keys.onEscapePressed: Runtime.barPinned = false

                Rectangle {
                    anchors.fill: parent
                    color: Scheme.background
                }

                Hairline {
                    anchors.bottom: parent.bottom
                    width: parent.width
                }

                HoverHandler {
                    id: barHover
                }

                // 1 px hairline between logical groups
                component GroupSep: Rectangle {
                    width: 1
                    height: 14
                    color: Scheme.outlineVariant
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    id: leftGroup
                    x: Theme.barPadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.s2

                    ArchItem {
                        id: archItem
                        host: root
                    }
                    WorkspacesItem {
                        id: wsItem
                        host: root
                        screen: root.screen
                    }
                    ActiveWindowItem {
                        id: awItem
                        host: root
                        maxWidth: Math.max(80, barBody.width / 2 - leftGroup.x - 170 - clock.width / 2 - 20 - (mediaItem.visible ? mediaItem.width + 20 : 0))
                    }
                    GroupSep {
                        visible: mediaItem.visible
                    }
                    MediaItem {
                        id: mediaItem
                        host: root
                    }
                }

                ClockItem {
                    id: clock
                    host: root
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    id: rightGroup
                    readonly property bool trayVisible: children[0].visible
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.barPadding
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.s2

                    TrayItem {
                        host: root
                    }
                    GroupSep {
                        visible: rightGroup.trayVisible
                    }
                    NotifsItem {
                        host: root
                    }
                    PerfItem {
                        id: perfItem
                        host: root
                    }
                    GroupSep {}
                    WifiItem {
                        id: wifiItem
                        host: root
                    }
                    BluetoothItem {
                        id: btItem
                        host: root
                    }
                    AudioItem {
                        id: audioItem
                        host: root
                    }
                    GroupSep {}
                    BatteryItem {
                        id: battItem
                        host: root
                    }
                    SessionItem {
                        id: sessItem
                        host: root
                    }
                }
            }

            Popout {
                id: popout
                host: root
                bar: barBody
            }
        }
    }
}
