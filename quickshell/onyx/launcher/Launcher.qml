pragma ComponentBehavior: Bound
// Full-screen onyx launcher: dot field, one search line, up to eight rows.
//   text   → apps (fuzzy over name / generic name / keywords; most used first when empty)
//   >text  → desktop actions (lock, sleep, log out, reboot, power off, wallpaper, session, settings, screenshot, restart)
//   =expr  → calculator (Enter copies the result)
// ↑/↓ Tab move, Enter runs, Esc clears then closes. Launch counts persist in ~/.config/onyx/launcher-usage.json.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.components
import qs.lock
import qs.services

Scope {
    id: root

    required property var lock
    required property var session
    required property var wallpaper

    property bool open: false
    property bool closing: false
    property string query: ""
    property int selected: 0
    property bool mouseArmed: false   // hover only steers the selection after the pointer has moved
    property var usage: ({})
    readonly property int maxRows: 8

    readonly property string mode: query.startsWith(">") ? "actions" : query.startsWith("=") ? "calc" : "apps"
    readonly property string term: mode === "apps" ? query.trim() : query.slice(1).trim()

    readonly property var actions: [
        { name: "Lock", hint: "onyx lock", icon: "lock", run: () => root.lock.engage() },
        { name: "Sleep", hint: "systemctl suspend", icon: "bedtime", run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { name: "Log out", hint: Config.logoutCommand.join(" "), icon: "logout", run: () => Quickshell.execDetached(Config.logoutCommand) },
        { name: "Reboot", hint: "systemctl reboot", icon: "cached", run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { name: "Power off", hint: "systemctl poweroff", icon: "power_settings_new", run: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
        { name: "Session screen", hint: "super + esc", icon: "grid_view", run: () => root.session.show() },
        { name: "Wallpaper", hint: "super + shift + w", icon: "image", run: () => root.wallpaper.show() },
        { name: "Shell settings", hint: "caelestia nexus", icon: "settings", run: () => Quickshell.execDetached(["caelestia", "shell", "nexus", "open"]) },
        { name: "Screenshot", hint: "caelestia screenshot", icon: "screenshot_region", run: () => Quickshell.execDetached(["caelestia", "screenshot"]) },
        { name: "Pin / unpin bar", hint: "super + shift + b", icon: "push_pin", run: () => Runtime.barPinned = !Runtime.barPinned },
        { name: "Do not disturb", hint: Notifs.dnd ? "on → off" : "off → on", icon: "notifications_off", run: () => Notifs.toggleDnd() },
        { name: "Restart desktop", hint: "desk-restart", icon: "restart_alt", run: () => Quickshell.execDetached(["sh", "-c", "sleep 0.3; desk-restart"]) }
    ]

    // ---- matching ------------------------------------------------------------------
    function score(hay: string, needle: string): int {
        if (!needle)
            return 1;
        const h = hay.toLowerCase(), n = needle.toLowerCase();
        if (h === n)
            return 100;
        if (h.startsWith(n))
            return 80;
        const w = h.split(/[\s\-_./]+/);
        if (w.some(x => x.startsWith(n)))
            return 60;
        if (h.includes(n))
            return 40;
        // subsequence
        let i = 0;
        for (const ch of h) {
            if (ch === n[i])
                i++;
            if (i === n.length)
                return 15;
        }
        return 0;
    }

    readonly property var results: {
        if (mode === "calc") {
            const r = calc(term);
            return r === null ? [] : [{ kind: "calc", name: r, hint: term || "type an expression", icon: "calculate" }];
        }
        if (mode === "actions") {
            return actions.map(a => ({ kind: "action", name: a.name, hint: a.hint, icon: a.icon, s: score(a.name, term), run: a.run }))
                          .filter(a => a.s > 0).sort((a, b) => b.s - a.s).slice(0, maxRows);
        }
        const apps = DesktopEntries.applications.values;
        const list = [];
        for (const e of apps) {
            if (e.noDisplay)
                continue;
            const s = Math.max(score(e.name, term), score(e.genericName || "", term) - 10, ...(e.keywords || []).map(k => score(k, term) - 20));
            if (s <= 0)
                continue;
            list.push({ kind: "app", name: e.name, hint: e.genericName || e.comment || "", icon: e.icon, entry: e, s: s, used: usage[e.id] || 0 });
        }
        list.sort((a, b) => (b.s - a.s) || (b.used - a.used) || a.name.localeCompare(b.name));
        return list.slice(0, maxRows);
    }

    function calc(expr: string): var {
        if (!expr)
            return null;
        let e = expr.replace(/\^/g, "**").replace(/×/g, "*").replace(/÷/g, "/").replace(/,/g, "");
        e = e.replace(/\b(sqrt|sin|cos|tan|log|ln|abs|floor|ceil|round|pi|e)\b/gi, m => ({ ln: "Math.log", log: "Math.log10", pi: "Math.PI", e: "Math.E" })[m.toLowerCase()] ?? "Math." + m.toLowerCase());
        if (/[^0-9+\-*/%().\sMathPIElogsqrtincabfhurdE]/.test(e.replace(/Math\.\w+/g, "")))
            return null;
        try {
            const v = Function('"use strict"; return (' + e + ");")();
            if (typeof v !== "number" || !isFinite(v))
                return null;
            return Number.isInteger(v) ? String(v) : String(Math.round(v * 1e10) / 1e10);
        } catch (err) {
            return null;
        }
    }

    // ---- actions -------------------------------------------------------------------
    function show(): void {
        query = "";
        selected = 0;
        mouseArmed = false;
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

    function activate(): void {
        const r = results[selected];
        if (!r)
            return;
        if (r.kind === "app") {
            usage[r.entry.id] = (usage[r.entry.id] || 0) + 1;
            usageFile.setText(JSON.stringify(usage));
            r.entry.execute();
        } else if (r.kind === "action") {
            r.run();
        } else if (r.kind === "calc") {
            Quickshell.execDetached(["sh", "-c", `printf '%s' "$1" | wl-copy`, "copy", r.name]);
        }
        hide();
    }

    onQueryChanged: selected = 0

    Timer {
        id: closeT
        interval: Theme.d(220) + 20
        onTriggered: {
            root.open = false;
            root.closing = false;
        }
    }

    FileView {
        id: usageFile
        path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/onyx/launcher-usage.json`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {}
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
            WlrLayershell.namespace: "onyx-launcher"
            WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            onVisibleChanged: if (visible) surface.enter()

            FocusScope {
                id: surface

                anchors.fill: parent
                focus: true

                readonly property real s: width / 1536
                readonly property real fieldW: Math.min(620 * s, width * 0.6)

                function px(v: real): real {
                    return v * s;
                }

                function enter(): void {
                    content.opacity = 0;
                    content.scale = 1;
                    dots.opacity = 0;
                    panel.y = surface.height * 0.27 + px(18);
                    input.forceActiveFocus();
                    openAnim.restart();
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
                            onPointChanged: {
                                dots.pointerMoved(point.position.x, point.position.y);
                                root.mouseArmed = true;
                            }
                            onHoveredChanged: if (!hovered) dots.pointerLeft()
                        }
                    }

                    TapHandler {
                        onTapped: root.hide()
                    }

                    Column {
                        x: surface.width * 0.05
                        y: surface.width * 0.05
                        spacing: surface.px(10)

                        Ink {
                            mono: true
                            text: root.mode === "calc" ? "CALCULATE" : root.mode === "actions" ? "ACTIONS" : "LAUNCH"
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
                    }

                    Column {
                        id: panel
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: surface.height * 0.27
                        width: surface.fieldW
                        spacing: surface.px(14)

                        // search line
                        Item {
                            width: parent.width
                            height: surface.px(46)

                            Icon {
                                id: searchGlyph
                                text: root.mode === "calc" ? "calculate" : root.mode === "actions" ? "bolt" : "search"
                                size: surface.px(20)
                                color: Scheme.outline
                                anchors.left: parent.left
                                anchors.leftMargin: surface.px(4)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            TextInput {
                                id: input
                                anchors.left: searchGlyph.right
                                anchors.leftMargin: surface.px(14)
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: Theme.mono
                                font.pointSize: Math.max(1, surface.px(16) * 0.75)
                                color: Scheme.fgSurface
                                selectionColor: Scheme.primaryContainer
                                selectedTextColor: Scheme.fgSurface
                                cursorVisible: true
                                text: root.query
                                onTextChanged: root.query = text

                                Keys.onPressed: event => {
                                    switch (event.key) {
                                    case Qt.Key_Escape:
                                        if (text.length > 0)
                                            text = "";
                                        else
                                            root.hide();
                                        break;
                                    case Qt.Key_Down:
                                    case Qt.Key_Tab:
                                        root.selected = Math.min(root.results.length - 1, root.selected + 1);
                                        break;
                                    case Qt.Key_Up:
                                    case Qt.Key_Backtab:
                                        root.selected = Math.max(0, root.selected - 1);
                                        break;
                                    case Qt.Key_J:
                                        if (event.modifiers & Qt.ControlModifier) {
                                            root.selected = Math.min(root.results.length - 1, root.selected + 1);
                                            break;
                                        }
                                        return;
                                    case Qt.Key_K:
                                        if (event.modifiers & Qt.ControlModifier) {
                                            root.selected = Math.max(0, root.selected - 1);
                                            break;
                                        }
                                        return;
                                    case Qt.Key_Return:
                                    case Qt.Key_Enter:
                                        root.activate();
                                        break;
                                    default:
                                        return;
                                    }
                                    event.accepted = true;
                                }

                                Ink {
                                    visible: !input.text
                                    mono: true
                                    text: "apps  ·  >actions  ·  =calc"
                                    size: surface.px(13)
                                    color: Scheme.outline
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 1
                                color: input.text ? Scheme.outline : Scheme.outlineVariant
                            }
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: input.text ? parent.width : 0
                                height: 1
                                gradient: Sweep {}
                                opacity: 0.8

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Theme.d(260)
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Theme.decel
                                    }
                                }
                            }
                        }

                        // results
                        Column {
                            width: parent.width
                            spacing: 2

                            Repeater {
                                model: root.results

                                Rectangle {
                                    id: row
                                    required property var modelData
                                    required property int index
                                    readonly property bool active: index === root.selected

                                    width: parent.width
                                    height: surface.px(48)
                                    radius: Theme.rItem
                                    color: active ? Scheme.surfaceContainer : rowHover.hovered ? Scheme.alpha(Scheme.surfaceContainer, 0.5) : "transparent"

                                    Rectangle {
                                        visible: row.active
                                        width: 2
                                        height: parent.height - 12
                                        y: 6
                                        radius: 1
                                        gradient: Sweep {}
                                    }

                                    Item {
                                        x: surface.px(16)
                                        width: surface.px(22)
                                        height: surface.px(22)
                                        anchors.verticalCenter: parent.verticalCenter
                                        Loader {
                                            anchors.fill: parent
                                            active: row.modelData.kind === "app"
                                            sourceComponent: IconImage {
                                                source: Quickshell.iconPath(row.modelData.icon || "", "application-x-executable")
                                            }
                                        }
                                        Icon {
                                            anchors.centerIn: parent
                                            visible: row.modelData.kind !== "app"
                                            text: row.modelData.icon
                                            size: surface.px(20)
                                            color: row.active ? Scheme.fgSurface : Scheme.fgSurfaceVariant
                                        }
                                    }
                                    Ink {
                                        text: row.modelData.name
                                        size: surface.px(row.modelData.kind === "calc" ? 18 : 14)
                                        mono: row.modelData.kind === "calc"
                                        font.weight: 500
                                        color: row.active ? Scheme.fgSurface : Scheme.fgSurfaceVariant
                                        anchors.left: parent.left
                                        anchors.leftMargin: surface.px(52)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(implicitWidth, parent.width - surface.px(52) - hint.width - surface.px(28))
                                    }
                                    Ink {
                                        id: hint
                                        mono: true
                                        text: row.modelData.hint
                                        size: surface.px(11)
                                        color: Scheme.outline
                                        anchors.right: parent.right
                                        anchors.rightMargin: surface.px(14)
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: Math.min(implicitWidth, parent.width * 0.4)
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    HoverHandler {
                                        id: rowHover
                                        onHoveredChanged: if (hovered && root.mouseArmed) root.selected = row.index
                                    }
                                    TapHandler {
                                        onTapped: {
                                            root.selected = row.index;
                                            root.activate();
                                        }
                                    }
                                }
                            }

                            Ink {
                                visible: root.results.length === 0 && root.query.length > 0
                                mono: true
                                text: root.mode === "calc" ? "…" : "nothing matches"
                                size: surface.px(12)
                                color: Scheme.outline
                                height: surface.px(40)
                                leftPadding: surface.px(16)
                            }
                        }
                    }

                    Ink {
                        mono: true
                        text: "esc · back     ↑↓ · move     ⏎ · open"
                        size: surface.px(10)
                        tracking: 0.06
                        color: Scheme.outline
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: surface.width * 0.026
                    }
                    ArchGlyph {
                        size: surface.px(18)
                        color: Scheme.outlineVariant
                        x: surface.width - surface.width * 0.02 - width
                        y: surface.height - surface.width * 0.02 - height
                    }
                }

                ParallelAnimation {
                    id: openAnim
                    NumberAnimation {
                        target: dots
                        property: "opacity"
                        to: 1
                        duration: Theme.d(500)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.decel
                    }
                    NumberAnimation {
                        target: content
                        property: "opacity"
                        to: 1
                        duration: Theme.d(300)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.decel
                    }
                    NumberAnimation {
                        target: panel
                        property: "y"
                        to: surface.height * 0.27
                        duration: Theme.d(420)
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
                        duration: Theme.d(220)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.accel
                    }
                    NumberAnimation {
                        target: content
                        property: "scale"
                        to: 0.97
                        duration: Theme.d(220)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.accel
                    }
                }
            }
        }
    }
}
