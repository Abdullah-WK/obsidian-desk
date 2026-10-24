pragma ComponentBehavior: Bound
// Full-screen lock surface (§6.4): three columns on a dot field, clock that assembles on
// lock, sweep + iris on unlock, hover glyph row. Sizes scale with width (s = width / 1536).
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import qs
import qs.components
import qs.services

FocusScope {
    id: root

    required property var state
    property var screen: null

    readonly property real s: width / 1536
    readonly property bool narrow: width < 700
    readonly property real pad: width * 0.05
    readonly property real gap: width * 0.03
    readonly property real colUnit: (width - 2 * pad - 2 * gap) / 3.2
    readonly property real sideW: colUnit
    readonly property real centreW: narrow ? width - 2 * pad : colUnit * 1.2
    readonly property real centreX: narrow ? pad : pad + sideW + gap
    readonly property real rightX: centreX + centreW + gap
    readonly property bool use24h: Config.lockUse24h === null ? !Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().includes("ap") : Config.lockUse24h
    readonly property bool typing: state.typing
    readonly property bool unlocking: state.unlocking
    property bool idle: false
    property bool glyphHover: false
    property bool irisOn: false
    // continuous motions (avatar ring, scan line, pulses) advance on one 30 fps timer instead of
    // per-frame animations, so the surface is not redrawn at the display rate while at rest
    property real t: 0

    function px(v: real): real {
        return v * s;
    }

    function wake(): void {
        if (idle)
            idle = false;
        idleT.restart();
    }

    function fmtThousands(n: int): string {
        return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, " ");
    }

    focus: true

    Keys.onPressed: event => {
        wake();
        state.handleKey(event);
        event.accepted = true;
    }

    Component.onCompleted: {
        forceActiveFocus();
        SysStats.fast++;
        openAnim.start();
    }
    Component.onDestruction: SysStats.fast--

    onUnlockingChanged: if (unlocking) {
        openAnim.stop();
        closeAnim.start();
    }

    Connections {
        target: root.state
        function onActivity(): void {
            root.wake();
        }
    }

    Timer {
        id: tick
        interval: 33
        repeat: true
        running: !root.idle && !root.unlocking && !Config.reducedMotion && root.visible
        onTriggered: root.t += 0.033
    }

    Timer {
        id: idleT
        interval: 20000
        running: true
        onTriggered: root.idle = true
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    HoverHandler {
        id: pointer
        onPointChanged: {
            dots.pointerMoved(point.position.x, point.position.y);
            root.wake();
        }
        onHoveredChanged: if (!hovered) dots.pointerLeft()
    }

    // ---- entrance block -----------------------------------------------------------
    component Block: Item {
        id: blk
        property real fromX: 0
        property real fromY: 24
        property int delay: 0
        property int dur: 500
        property real dx: fromX
        property real dy: fromY
        default property alias content: inner.data
        implicitWidth: inner.childrenRect.width
        implicitHeight: inner.childrenRect.height
        opacity: 0
        transform: Translate {
            x: blk.dx
            y: blk.dy
        }
        Item {
            id: inner
            anchors.fill: parent
        }
        function play(): void {
            anim.restart();
        }
        SequentialAnimation {
            id: anim
            PauseAnimation {
                duration: Theme.d(blk.delay)
            }
            ParallelAnimation {
                NumberAnimation {
                    target: blk
                    property: "opacity"
                    to: 1
                    duration: Theme.d(blk.dur)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.decel
                }
                NumberAnimation {
                    target: blk
                    property: "dx"
                    to: 0
                    duration: Theme.d(blk.dur)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.decel
                }
                NumberAnimation {
                    target: blk
                    property: "dy"
                    to: 0
                    duration: Theme.d(blk.dur)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.decel
                }
            }
        }
    }

    component Key: Ink {
        mono: true
        size: root.px(12)
        color: Scheme.outline
        width: root.px(44)
    }

    // ---- background ---------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: Scheme.background
        visible: !root.irisOn
    }

    Item {
        id: content
        anchors.fill: parent
        transformOrigin: Item.Center

        DotField {
            id: dots
            anchors.fill: parent
            visible: Config.lockDotField
            opacity: 0
            idle: root.idle
            glyphHover: root.glyphHover
            running: !root.unlocking
        }

        // ---- left column --------------------------------------------------------
        Column {
            id: leftCol
            x: root.pad
            y: root.pad
            width: root.sideW
            spacing: root.width * 0.024
            visible: !root.narrow
            opacity: root.idle ? 0.4 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.d(200)
                }
            }

            Block {
                id: weatherBlock
                fromX: -22
                fromY: 0
                delay: 220
                visible: Config.lockShowWeather && Weather.ready
                width: parent.width
                height: visible ? implicitHeight : 0

                Column {
                    spacing: root.px(4)
                    Ink {
                        text: Weather.condition
                        size: root.px(13)
                        color: Scheme.fgSurfaceVariant
                    }
                    Row {
                        spacing: root.px(9)
                        Ink {
                            mono: true
                            text: Weather.temp + "°"
                            size: root.px(64)
                            font.weight: 200
                            tracking: -0.04
                            lineHeight: 0.95
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Icon {
                            text: Weather.icon
                            size: root.px(36)
                            weight: 300
                            color: Scheme.fgSurfaceVariant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Ink {
                        mono: true
                        text: `feels ${Weather.feels}° · high ${Weather.high}° · low ${Weather.low}°`
                        size: root.px(11)
                        color: Scheme.outline
                    }
                }
            }

            Block {
                id: fetchBlock
                fromX: -22
                fromY: 0
                delay: 300
                width: parent.width

                Row {
                    spacing: root.px(18)
                    ArchGlyph {
                        size: root.px(56)
                        y: root.px(4)
                    }
                    Column {
                        spacing: root.px(3)
                        Ink {
                            mono: true
                            text: SysInfo.userHost
                            size: root.px(12)
                            font.weight: 500
                            color: Scheme.fgSurface
                        }
                        Repeater {
                            model: [["wm", "hyprland " + SysInfo.wmVersion], ["up", SysInfo.uptime], ["pkgs", root.fmtThousands(SysInfo.pkgs)], ["batt", (root.charging ? "(+) " : "") + Math.round(root.battPct * 100) + "%"]]
                            Row {
                                required property var modelData
                                Key {
                                    text: parent.modelData[0]
                                }
                                Ink {
                                    mono: true
                                    text: parent.modelData[1]
                                    size: root.px(12)
                                    color: Scheme.fgSurfaceVariant
                                }
                            }
                        }
                    }
                }
            }

            Block {
                id: swatchBlock
                fromX: -22
                fromY: 0
                delay: 380
                width: parent.width

                Row {
                    spacing: root.px(7)
                    Repeater {
                        model: ["#1d1d21", "#2a2a2f", "#3a3a40", "#5c5c63", "#a1a1a8", "#e4e4e7", "#8fb8d8"]
                        Rectangle {
                            required property string modelData
                            width: root.px(16)
                            height: root.px(16)
                            radius: 3
                            color: modelData
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.06)
                        }
                    }
                }
            }

            Block {
                id: mediaBlock
                fromX: -22
                fromY: 0
                delay: 460
                visible: Config.lockShowMedia
                width: parent.width

                readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? (Mpris.players.values.length > 0 ? Mpris.players.values[0] : null)
                readonly property bool has: player !== null

                Timer {
                    running: mediaBlock.has && mediaBlock.player.isPlaying && !root.idle
                    interval: 1000
                    repeat: true
                    onTriggered: mediaBlock.player.positionChanged()
                }

                Column {
                    spacing: root.px(7)
                    Ink {
                        text: mediaBlock.has ? (mediaBlock.player.trackTitle || "Untitled") : "Nothing playing"
                        size: root.px(14)
                        font.weight: 500
                        color: Scheme.fgSurface
                        width: leftCol.width
                    }
                    Ink {
                        mono: true
                        text: mediaBlock.has ? `${mediaBlock.player.trackArtist || "unknown"} · ${(mediaBlock.player.identity || "player").toLowerCase()}` : "mpris · idle"
                        size: root.px(11)
                        color: Scheme.outline
                        width: leftCol.width
                    }
                    Rectangle {
                        width: leftCol.width * 0.6
                        height: 1
                        color: Scheme.outlineVariant
                        Rectangle {
                            height: 1
                            width: mediaBlock.has && mediaBlock.player.length > 0 ? parent.width * Math.min(1, mediaBlock.player.position / mediaBlock.player.length) : 0
                            color: Scheme.fgSurfaceVariant
                        }
                    }
                    Row {
                        spacing: root.px(6)
                        Repeater {
                            model: [["skip_previous", () => mediaBlock.player?.previous()], [mediaBlock.has && mediaBlock.player.isPlaying ? "pause" : "play_arrow", () => mediaBlock.player?.togglePlaying()], ["skip_next", () => mediaBlock.player?.next()]]
                            Rectangle {
                                id: ctl
                                required property var modelData
                                width: root.px(30)
                                height: root.px(30)
                                radius: 4
                                color: ctlHover.hovered && mediaBlock.has ? Scheme.surfaceContainer : "transparent"
                                border.width: 1
                                border.color: Scheme.outlineVariant
                                Icon {
                                    anchors.centerIn: parent
                                    text: ctl.modelData[0]
                                    size: root.px(15)
                                    color: mediaBlock.has ? Scheme.fgSurfaceVariant : Scheme.outlineVariant
                                }
                                HoverHandler {
                                    id: ctlHover
                                }
                                TapHandler {
                                    enabled: mediaBlock.has
                                    onTapped: ctl.modelData[1]()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---- centre column ------------------------------------------------------
        Item {
            id: centre
            x: root.centreX
            width: root.centreW
            height: root.height - root.width * 0.06

            Column {
                id: centreCol
                anchors.centerIn: parent
                spacing: 0

                Block {
                    id: tagBlock
                    fromY: 0
                    delay: 100
                    dur: 400
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: tagText.implicitWidth
                    height: tagText.implicitHeight + root.px(12) + 1

                    Ink {
                        id: tagText
                        mono: true
                        text: "LOCKED"
                        size: root.px(11)
                        font.weight: 500
                        tracking: 0.4
                        color: Scheme.outline
                        leftPadding: 0.4 * root.px(11)
                    }
                    Rectangle {
                        id: tagLine
                        width: 0
                        height: 1
                        color: Scheme.outlineVariant
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: tagText.implicitHeight + root.px(12)
                    }
                }

                Item {
                    width: 1
                    height: root.px(15)
                }

                Block {
                    id: dateBlock
                    delay: 160
                    anchors.horizontalCenter: parent.horizontalCenter
                    Ink {
                        text: Qt.formatDate(clock.date, "dddd · d MMMM")
                        size: root.px(15)
                        tracking: 0.02
                        color: Scheme.fgSurfaceVariant
                    }
                }

                Item {
                    width: 1
                    height: root.px(3)
                }

                Row {
                    id: clockRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.px(9)
                    opacity: root.idle ? 0.6 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.d(200)
                        }
                    }

                    Block {
                        id: hoursBlock
                        delay: 200
                        dur: 600
                        Ink {
                            id: hoursText
                            mono: true
                            text: Qt.formatTime(clock.date, root.use24h ? "HH" : "hh")
                            size: root.px(176)
                            font.weight: 200
                            tracking: -0.06
                            lineHeight: 0.9
                            color: Scheme.fgSurface
                        }
                    }

                    Item {
                        width: Math.max(minutesText.implicitWidth, meridiemText.implicitWidth)
                        height: hoursBlock.height

                        Block {
                            id: minutesBlock
                            delay: 280
                            dur: 600
                            y: root.px(24)
                            Ink {
                                id: minutesText
                                mono: true
                                text: Qt.formatTime(clock.date, "mm")
                                size: root.px(86)
                                font.weight: 200
                                tracking: -0.05
                                lineHeight: 0.95
                                color: Scheme.fgSurface
                            }
                        }
                        Block {
                            id: meridiemBlock
                            delay: 340
                            dur: 600
                            visible: !root.use24h
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: root.px(46)
                            Ink {
                                id: meridiemText
                                mono: true
                                text: Qt.formatTime(clock.date, "ap")
                                size: root.px(30)
                                font.weight: 300
                                tracking: 0.02
                                color: Scheme.fgSurfaceVariant
                            }
                        }
                    }
                }

                Item {
                    width: 1
                    height: root.px(34)
                }

                Block {
                    id: avatarBlock
                    delay: 400
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.px(80)
                    height: root.px(80)

                    Item {
                        id: avatar
                        width: root.px(80)
                        height: root.px(80)

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Scheme.surfaceContainer
                        }
                        Ink {
                            anchors.centerIn: parent
                            mono: true
                            text: SysInfo.user.charAt(0).toLowerCase()
                            size: root.px(30)
                            font.weight: 300
                            color: Scheme.fgSurface
                            visible: face.status !== Image.Ready
                        }
                        Image {
                            id: face
                            anchors.fill: parent
                            source: `file://${Quickshell.env("HOME")}/.face`
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(160, 160)
                            visible: false
                            layer.enabled: true
                            layer.smooth: true
                        }
                        Shape {
                            anchors.fill: parent
                            visible: face.status === Image.Ready
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeWidth: -1
                                fillItem: face
                                PathAngleArc {
                                    centerX: avatar.width / 2
                                    centerY: avatar.height / 2
                                    radiusX: avatar.width / 2
                                    radiusY: avatar.height / 2
                                    sweepAngle: 360
                                }
                            }
                        }
                        // static ring at −4 px
                        Shape {
                            anchors.fill: parent
                            anchors.margins: -4
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: Scheme.outlineVariant
                                strokeWidth: 1
                                fillColor: "transparent"
                                PathAngleArc {
                                    centerX: avatar.width / 2 + 4
                                    centerY: avatar.height / 2 + 4
                                    radiusX: avatar.width / 2 + 4
                                    radiusY: avatar.height / 2 + 4
                                    sweepAngle: 360
                                }
                            }
                        }
                        // rotating top arc, once per 6 s
                        Shape {
                            id: sweepRing
                            anchors.fill: parent
                            anchors.margins: -4
                            preferredRendererType: Shape.CurveRenderer
                            ShapePath {
                                strokeColor: Scheme.fgSurfaceVariant
                                strokeWidth: 1
                                fillColor: "transparent"
                                capStyle: ShapePath.FlatCap
                                PathAngleArc {
                                    centerX: avatar.width / 2 + 4
                                    centerY: avatar.height / 2 + 4
                                    radiusX: avatar.width / 2 + 4
                                    radiusY: avatar.height / 2 + 4
                                    startAngle: -135
                                    sweepAngle: 90
                                }
                            }
                            rotation: (root.t / 6) * 360 % 360
                        }
                    }
                }

                Item {
                    width: 1
                    height: root.px(25)
                }

                Block {
                    id: fieldBlock
                    delay: 460
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: field.implicitWidth
                    height: field.implicitHeight

                    PasswordField {
                        id: field
                        state: root.state
                        s: root.s
                    }
                }
            }
        }

        // ---- right column -------------------------------------------------------
        Column {
            id: rightCol
            x: root.rightX
            y: root.pad
            width: root.sideW
            spacing: root.width * 0.024
            visible: !root.narrow
            opacity: root.idle ? 0.4 : 1

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.d(200)
                }
            }

            Block {
                id: tilesBlock
                fromX: 22
                fromY: 0
                delay: 220
                width: parent.width
                height: tiles.implicitHeight

                Row {
                    id: tiles
                    anchors.right: parent.right
                    spacing: root.px(10)

                    component Tile: Rectangle {
                        id: tile
                        required property string icon
                        required property string key
                        required property real value
                        required property string display
                        property color barColor: value > 0.85 ? Scheme.error : Scheme.fgSurfaceVariant
                        width: Math.max(root.px(96), tileCol.implicitWidth + root.px(28))
                        height: tileCol.implicitHeight + root.px(26)
                        radius: 5
                        color: "transparent"
                        border.width: 1
                        border.color: Scheme.outlineVariant
                        clip: true

                        Column {
                            id: tileCol
                            x: root.px(14)
                            y: root.px(13)
                            spacing: root.px(5)
                            Row {
                                spacing: root.px(5)
                                Icon {
                                    text: tile.icon
                                    size: root.px(13)
                                    color: Scheme.outline
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Ink {
                                    mono: true
                                    text: tile.key
                                    size: root.px(10)
                                    color: Scheme.outline
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Ink {
                                mono: true
                                text: tile.display
                                size: root.px(32)
                                font.weight: 200
                                tracking: -0.04
                                lineHeight: 0.95
                                color: Scheme.fgSurface
                            }
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            height: 2
                            width: parent.width * Math.max(0, Math.min(1, tile.value))
                            color: tile.barColor
                        }
                    }

                    Tile {
                        icon: "device_thermostat"
                        key: Math.round(SysStats.temp) + " °c"
                        value: SysStats.cpu
                        display: Math.round(SysStats.cpu * 100) + "%"
                    }
                    Tile {
                        icon: "memory"
                        key: "mem"
                        value: SysStats.mem
                        display: Math.round(SysStats.mem * 100) + "%"
                    }
                    Tile {
                        icon: root.charging ? "battery_charging_full" : "battery_std"
                        key: "batt"
                        value: root.battPct
                        display: Math.round(root.battPct * 100) + "%"
                        visible: root.hasBattery
                        barColor: root.lowBattery ? Scheme.error : Scheme.success
                    }
                }
            }

            Block {
                id: notifBlock
                fromX: 22
                fromY: 0
                delay: 320
                visible: !Config.lockHideNotifs
                width: parent.width
                height: notifCol.implicitHeight

                Column {
                    id: notifCol
                    anchors.right: parent.right
                    width: parent.width
                    spacing: root.px(10)

                    Ink {
                        mono: true
                        text: "NOTIFICATIONS"
                        size: root.px(10)
                        font.weight: 500
                        tracking: 0.16
                        color: Scheme.outline
                        anchors.right: parent.right
                    }

                    Repeater {
                        model: root.notifs

                        Rectangle {
                            id: card
                            required property var modelData
                            anchors.right: parent.right
                            width: Math.min(rightCol.width, root.width * 0.22)
                            height: cardRow.implicitHeight + root.px(20)
                            radius: 6
                            color: Qt.rgba(17 / 255, 17 / 255, 19 / 255, 0.6)
                            border.width: 1
                            border.color: Scheme.outlineVariant

                            Row {
                                id: cardRow
                                x: root.px(12)
                                y: root.px(10)
                                width: parent.width - root.px(24)
                                spacing: root.px(10)

                                Item {
                                    width: root.px(16)
                                    height: root.px(16)
                                    IconImage {
                                        anchors.fill: parent
                                        visible: card.modelData.appIcon !== ""
                                        source: card.modelData.appIcon ? Quickshell.iconPath(card.modelData.appIcon, "notifications") : ""
                                    }
                                    Icon {
                                        anchors.centerIn: parent
                                        visible: card.modelData.appIcon === ""
                                        text: "notifications"
                                        size: root.px(16)
                                        color: Scheme.fgSurfaceVariant
                                    }
                                }
                                Column {
                                    width: parent.width - root.px(16) - root.px(10) - ageText.implicitWidth - root.px(10)
                                    spacing: root.px(2)
                                    Ink {
                                        text: card.modelData.summary || card.modelData.appName || ""
                                        size: root.px(12)
                                        font.weight: 500
                                        width: parent.width
                                    }
                                    Ink {
                                        visible: text !== ""
                                        text: (card.modelData.body || "").replace(/\s+/g, " ")
                                        size: root.px(11)
                                        color: Scheme.fgSurfaceVariant
                                        width: parent.width
                                    }
                                }
                                Ink {
                                    id: ageText
                                    mono: true
                                    text: root.age(card.modelData.time)
                                    size: root.px(9)
                                    color: Scheme.outline
                                }
                            }
                        }
                    }

                    Column {
                        anchors.right: parent.right
                        spacing: root.px(6)
                        Item {
                            anchors.right: parent.right
                            width: root.px(44)
                            height: 1
                            clip: true
                            Rectangle {
                                anchors.fill: parent
                                color: Scheme.outlineVariant
                            }
                            Rectangle {
                                id: scan
                                width: parent.width * 0.3
                                height: 1
                                color: Scheme.fgSurfaceVariant
                                readonly property real p: (root.t % 2.8) / 2.8
                                x: -width + (p * p * (3 - 2 * p)) * (parent.width + width)
                            }
                        }
                        Ink {
                            mono: true
                            text: root.notifs.length > 0 ? "nothing else new" : "nothing new"
                            size: root.px(11)
                            tracking: 0.06
                            color: Scheme.outline
                            anchors.right: parent.right
                        }
                    }
                }
            }
        }

        // ---- glyph row ----------------------------------------------------------
        Block {
            id: glyphBlock
            delay: 500
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.width * 0.026
            width: glyphRow.implicitWidth
            height: glyphRow.implicitHeight

            Row {
                id: glyphRow
                spacing: root.px(28)
                opacity: root.idle ? 0 : root.typing ? 0.35 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.d(200)
                    }
                }

                Glyph {
                    visible: root.state.fprintAvailable
                    icon: "fingerprint"
                    label: "touch sensor"
                    ringColor: Scheme.archIce
                    pulse: root.state.fprintWaiting
                    pulseT: root.t
                    size: root.px(56)
                    iconSize: root.px(24)
                    scaleF: root.s
                    onHotChanged: root.glyphHover = hot
                }
                Glyph {
                    icon: "bedtime"
                    label: "sleep"
                    size: root.px(56)
                    iconSize: root.px(24)
                    scaleF: root.s
                    onHotChanged: root.glyphHover = hot
                    onActivated: Quickshell.execDetached(["systemctl", "suspend"])
                }
                Glyph {
                    icon: "logout"
                    label: "log out"
                    size: root.px(56)
                    iconSize: root.px(24)
                    scaleF: root.s
                    onHotChanged: root.glyphHover = hot
                    onActivated: Quickshell.execDetached(Config.logoutCommand)
                }
                Glyph {
                    icon: "cached"
                    label: "reboot"
                    hold: true
                    size: root.px(56)
                    iconSize: root.px(24)
                    scaleF: root.s
                    onHotChanged: root.glyphHover = hot
                    onActivated: Quickshell.execDetached(["systemctl", "reboot"])
                }
                Glyph {
                    icon: "power_settings_new"
                    label: "power off"
                    hold: true
                    size: root.px(56)
                    iconSize: root.px(24)
                    scaleF: root.s
                    onHotChanged: root.glyphHover = hot
                    onActivated: Quickshell.execDetached(["systemctl", "poweroff"])
                }
            }
        }

        // ---- hints --------------------------------------------------------------
        Block {
            id: hintsBlock
            delay: 600
            dur: 400
            fromY: 0
            anchors.fill: parent

            Row {
                visible: root.state.fprintAvailable
                x: root.width * 0.02
                y: root.height - root.width * 0.02 - height
                spacing: root.px(8)
                Icon {
                    id: fpHint
                    text: "fingerprint"
                    size: root.px(16)
                    color: Scheme.outline
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.725 + 0.275 * Math.cos(2 * Math.PI * root.t / 3.2)
                }
                Ink {
                    mono: true
                    text: "fprint ready"
                    size: root.px(10)
                    color: Scheme.outline
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            ArchGlyph {
                size: root.px(18)
                color: Scheme.outlineVariant
                x: root.width - root.width * 0.02 - width
                y: root.height - root.width * 0.02 - height
            }
        }
    }

    // ---- unlock: sweep line + iris -------------------------------------------------
    Rectangle {
        id: sweep
        readonly property point fieldBottom: fieldBlock.mapToItem(root, fieldBlock.width / 2, fieldBlock.height)
        x: 0
        y: Math.round(fieldBottom.y) - 1
        width: root.width
        height: 1
        color: Scheme.fgSurface
        opacity: 0
        transform: Scale {
            id: sweepScale
            origin.x: sweep.fieldBottom.x
            xScale: 0
        }
    }

    Shape {
        id: iris
        anchors.fill: parent
        visible: root.irisOn
        property real r: 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: Scheme.background
            strokeWidth: -1
            fillRule: ShapePath.OddEvenFill
            startX: 0
            startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: 0 }
            PathMove { x: root.width / 2 + iris.r; y: root.height * 0.56 }
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height * 0.56
                radiusX: iris.r
                radiusY: iris.r
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // ---- sequences -------------------------------------------------------------------
    ParallelAnimation {
        id: openAnim

        NumberAnimation {
            target: dots
            property: "opacity"
            to: 1
            duration: Theme.d(700)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.decel
        }
        SequentialAnimation {
            PauseAnimation {
                duration: Theme.d(350)
            }
            NumberAnimation {
                target: tagLine
                property: "width"
                to: root.px(34)
                duration: Theme.d(500)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.decel
            }
        }
        ScriptAction {
            script: {
                for (const b of [tagBlock, dateBlock, hoursBlock, minutesBlock, meridiemBlock, weatherBlock, fetchBlock, swatchBlock, mediaBlock, tilesBlock, notifBlock, avatarBlock, fieldBlock, glyphBlock, hintsBlock])
                    b.play();
            }
        }
    }

    SequentialAnimation {
        id: closeAnim

        ScriptAction {
            script: {
                sweep.opacity = 1;
                sweepScale.xScale = 0;
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: sweepScale
                property: "xScale"
                to: 1
                duration: Theme.d(360)
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.decel
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: Theme.d(216)
                }
                NumberAnimation {
                    target: sweep
                    property: "opacity"
                    to: 0
                    duration: Theme.d(144)
                }
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: Theme.d(80)
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: content
                        property: "scale"
                        to: 0.965
                        duration: Theme.d(260)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.accel
                    }
                    NumberAnimation {
                        target: content
                        property: "opacity"
                        to: 0
                        duration: Theme.d(260)
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.accel
                    }
                }
            }
            SequentialAnimation {
                PauseAnimation {
                    duration: Theme.d(180)
                }
                ScriptAction {
                    script: {
                        iris.r = 0;
                        root.irisOn = true;
                    }
                }
                NumberAnimation {
                    target: iris
                    property: "r"
                    to: Math.max(root.width, root.height) * 1.2
                    duration: Theme.d(460)
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.decel
                }
            }
        }
    }

    // ---- data -------------------------------------------------------------------------
    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool hasBattery: battery ? battery.isLaptopBattery : false
    readonly property real battPct: battery?.percentage ?? 0
    readonly property bool charging: battery ? (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged) : false
    readonly property bool lowBattery: battPct < 0.15 && !charging

    property var notifs: []

    function age(iso: string): string {
        const t = new Date(iso).getTime();
        if (isNaN(t))
            return "";
        const m = Math.floor((Date.now() - t) / 60000);
        if (m < 1)
            return "now";
        if (m < 60)
            return m + "m";
        const h = Math.floor(m / 60);
        if (h < 24)
            return h + "h";
        return Math.floor(h / 24) + "d";
    }

    FileView {
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/caelestia/notifs.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoadFailed: root.notifs = []
        onLoaded: {
            try {
                const list = JSON.parse(text());
                root.notifs = Array.isArray(list) ? list.slice().sort((a, b) => new Date(b.time) - new Date(a.time)).slice(0, 4) : [];
            } catch (e) {
                root.notifs = [];
            }
        }
    }
}
