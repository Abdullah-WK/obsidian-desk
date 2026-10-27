pragma ComponentBehavior: Bound
// Full-screen session screen in the lock's language: dot field, vignette, a row of ring glyphs
// (lock · sleep · log out · reboot · power off). Super+Esc / Ctrl+Alt+Del toggle it; Esc closes.
// Keys: ←/→ Tab/Shift+Tab move, Enter/Space activates (hold on reboot/off), letters l s o r p.
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.lock
import qs.services

Scope {
    id: root

    required property var lock

    property bool open: false
    property bool closing: false

    function show(): void {
        closing = false;
        open = true;
    }

    function hide(): void {
        if (!open || closing)
            return;
        closing = true;
        closeT.restart();
    }

    function toggle(): void {
        if (open)
            hide();
        else
            show();
    }

    function run(cmd: var): void {
        hide();
        Quickshell.execDetached(cmd);
    }

    Timer {
        id: closeT
        interval: Theme.d(260) + 20
        onTriggered: {
            root.open = false;
            root.closing = false;
        }
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
            WlrLayershell.namespace: "onyx-session"
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onVisibleChanged: if (visible) surface.enter()

            FocusScope {
                id: surface

                anchors.fill: parent
                focus: true

                readonly property real s: width / 1536
                readonly property list<Item> glyphs: [gLock, gSleep, gLogout, gReboot, gOff]

                function px(v: real): real {
                    return v * s;
                }

                function enter(): void {
                    content.opacity = 0;
                    content.scale = 1;
                    dots.opacity = 0;
                    row.y = px(24);
                    gLock.forceActiveFocus();
                    openAnim.restart();
                }

                function focusStep(d: int): void {
                    const i = glyphs.findIndex(g => g.activeFocus);
                    const n = (i < 0 ? 0 : i + d + glyphs.length) % glyphs.length;
                    glyphs[n].forceActiveFocus();
                }

                Keys.onPressed: event => {
                    if (event.isAutoRepeat)
                        return;
                    switch (event.key) {
                    case Qt.Key_Escape:
                    case Qt.Key_Q:
                        root.hide();
                        break;
                    case Qt.Key_Left:
                    case Qt.Key_Backtab:
                        focusStep(-1);
                        break;
                    case Qt.Key_Right:
                    case Qt.Key_Tab:
                        focusStep(1);
                        break;
                    case Qt.Key_L:
                        gLock.forceActiveFocus();
                        gLock.startHold();
                        break;
                    case Qt.Key_S:
                        gSleep.forceActiveFocus();
                        gSleep.startHold();
                        break;
                    case Qt.Key_O:
                        gLogout.forceActiveFocus();
                        gLogout.startHold();
                        break;
                    case Qt.Key_R:
                        gReboot.forceActiveFocus();
                        gReboot.startHold();
                        break;
                    case Qt.Key_P:
                        gOff.forceActiveFocus();
                        gOff.startHold();
                        break;
                    default:
                        return;
                    }
                    event.accepted = true;
                }
                Keys.onReleased: event => {
                    if (event.isAutoRepeat)
                        return;
                    if (event.key === Qt.Key_R)
                        gReboot.cancelHold();
                    else if (event.key === Qt.Key_P)
                        gOff.cancelHold();
                }

                Connections {
                    target: root
                    function onClosingChanged(): void {
                        if (root.closing)
                            closeAnim.restart();
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Scheme.background
                }

                Item {
                    id: content
                    anchors.fill: parent
                    transformOrigin: Item.Center

                    DotField {
                        id: dots
                        anchors.fill: parent
                        running: root.open && !root.closing
                        opacity: 0

                        HoverHandler {
                            onPointChanged: dots.pointerMoved(point.position.x, point.position.y)
                            onHoveredChanged: if (!hovered) dots.pointerLeft()
                        }
                    }

                    // tag + identity, top left
                    Column {
                        x: parent.width * 0.05
                        y: parent.width * 0.05
                        spacing: surface.px(10)

                        Ink {
                            mono: true
                            text: "SESSION"
                            size: surface.px(11)
                            font.weight: 500
                            tracking: 0.4
                            color: Scheme.outline
                        }
                        Rectangle {
                            width: surface.px(34)
                            height: 1
                            color: Scheme.outlineVariant
                        }
                        Ink {
                            mono: true
                            text: SysInfo.userHost + "  ·  up " + SysInfo.uptime
                            size: surface.px(12)
                            color: Scheme.fgSurfaceVariant
                        }
                    }

                    // glyph row, centred
                    Row {
                        id: row
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -surface.px(20)
                        spacing: surface.px(56)

                        component Entry: Column {
                            id: entry
                            required property string icon
                            required property string label
                            required property string hint
                            property bool hold: false
                            property color accent: Scheme.archIce
                            property var action: () => {}
                            readonly property alias glyph: g
                            spacing: surface.px(18)

                            Glyph {
                                id: g
                                icon: entry.icon
                                label: entry.hint
                                hold: entry.hold
                                accent: entry.accent
                                size: surface.px(96)
                                iconSize: surface.px(40)
                                scaleF: surface.s
                                onHotChanged: dots.glyphHover = hot
                                onActivated: entry.action()
                            }
                            Ink {
                                mono: true
                                text: entry.label
                                size: surface.px(12)
                                tracking: 0.08
                                color: g.hot ? Scheme.fgSurface : Scheme.outline
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.colour
                                    }
                                }
                            }
                        }

                        Entry {
                            id: gLockEntry
                            icon: "lock"
                            label: "lock"
                            hint: "L"
                            accent: Scheme.glyphLock
                            action: () => {
                                root.hide();
                                root.lock.engage();
                            }
                        }
                        Entry {
                            id: gSleepEntry
                            icon: "bedtime"
                            label: "sleep"
                            hint: "S"
                            accent: Scheme.glyphSleep
                            action: () => root.run(["systemctl", "suspend"])
                        }
                        Entry {
                            id: gLogoutEntry
                            icon: "logout"
                            label: "log out"
                            hint: "O"
                            accent: Scheme.glyphLogout
                            action: () => root.run(Config.logoutCommand)
                        }
                        Entry {
                            id: gRebootEntry
                            icon: "cached"
                            label: "reboot"
                            hint: "R · hold"
                            accent: Scheme.glyphReboot
                            hold: true
                            action: () => root.run(["systemctl", "reboot"])
                        }
                        Entry {
                            id: gOffEntry
                            icon: "power_settings_new"
                            label: "power off"
                            hint: "P · hold"
                            accent: Scheme.glyphPower
                            hold: true
                            action: () => root.run(["systemctl", "poweroff"])
                        }
                    }

                    // aliases for keyboard handling
                    readonly property Item gLock: gLockEntry.glyph
                    readonly property Item gSleep: gSleepEntry.glyph
                    readonly property Item gLogout: gLogoutEntry.glyph
                    readonly property Item gReboot: gRebootEntry.glyph
                    readonly property Item gOff: gOffEntry.glyph

                    Ink {
                        mono: true
                        text: "esc · back"
                        size: surface.px(10)
                        tracking: 0.06
                        color: Scheme.outline
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: parent.width * 0.026
                    }
                    ArchGlyph {
                        size: surface.px(18)
                        color: Scheme.outlineVariant
                        x: parent.width - parent.width * 0.02 - width
                        y: parent.height - parent.width * 0.02 - height
                    }
                }

                // ids used by the key handler
                readonly property Item gLock: content.gLock
                readonly property Item gSleep: content.gSleep
                readonly property Item gLogout: content.gLogout
                readonly property Item gReboot: content.gReboot
                readonly property Item gOff: content.gOff

                ParallelAnimation {
                    id: openAnim
                    NumberAnimation {
                        target: dots
                        property: "opacity"
                        to: 1
                        duration: Theme.d(600)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.decel
                    }
                    NumberAnimation {
                        target: content
                        property: "opacity"
                        to: 1
                        duration: Theme.d(360)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.decel
                    }
                    NumberAnimation {
                        target: row
                        property: "y"
                        to: 0
                        duration: Theme.d(500)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.decel
                    }
                }

                ParallelAnimation {
                    id: closeAnim
                    NumberAnimation {
                        target: content
                        property: "opacity"
                        to: 0
                        duration: Theme.d(260)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.accel
                    }
                    NumberAnimation {
                        target: content
                        property: "scale"
                        to: 0.965
                        duration: Theme.d(260)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.accel
                    }
                }
            }
        }
    }
}
