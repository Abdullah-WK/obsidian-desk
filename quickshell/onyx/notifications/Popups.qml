pragma ComponentBehavior: Bound
// Notification popups: a column of cards top-right, under the bar. Each card expires after
// Config.notifTimeoutMs (critical ones stay), pauses while hovered, closes on click or ×,
// and offers the sender's actions as chips. Slides in from the right, fades out.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs
import qs.components
import qs.services

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property ShellScreen modelData

            screen: modelData
            visible: Notifs.popups.length > 0 && !Notifs.dnd
            anchors {
                top: true
                right: true
            }
            margins {
                top: 10
                right: 16
            }
            implicitWidth: 380
            implicitHeight: Math.max(1, column.implicitHeight)
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "onyx-notifs"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            Column {
                id: column
                width: parent.width
                spacing: 8

                Repeater {
                    model: Notifs.popups.slice(0, Config.notifPopupsMax)

                    Item {
                        id: slot
                        required property int modelData
                        // null once the server closed the notification (it is deleteLater()'d then);
                        // the deferred Notifs.popups update removes this slot a turn later.
                        readonly property var n: Notifs.byId(modelData)
                        readonly property bool critical: n?.urgency === NotificationUrgency.Critical

                        width: parent.width
                        height: card.height
                        opacity: 0
                        x: 16

                        Component.onCompleted: enter.start()

                        ParallelAnimation {
                            id: enter
                            NumberAnimation {
                                target: slot
                                property: "opacity"
                                to: 1
                                duration: Theme.d(220)
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.decel
                            }
                            NumberAnimation {
                                target: slot
                                property: "x"
                                to: 0
                                duration: Theme.d(220)
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.decel
                            }
                        }

                        function leave(): void {
                            exit.start();
                        }

                        SequentialAnimation {
                            id: exit
                            NumberAnimation {
                                target: slot
                                property: "opacity"
                                to: 0
                                duration: Theme.d(160)
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Theme.accel
                            }
                            ScriptAction {
                                script: Notifs.closePopup(slot.modelData)
                            }
                        }

                        Timer {
                            id: expiry
                            interval: (slot.n?.expireTimeout ?? 0) > 0 ? slot.n.expireTimeout : Config.notifTimeoutMs
                            running: !slot.critical && !hover.hovered
                            onTriggered: slot.leave()
                        }

                        Rectangle {
                            id: card
                            width: parent.width
                            height: body.implicitHeight + 24
                            radius: Theme.rPanel
                            color: Scheme.surfaceContainerLow
                            border.width: 1
                            border.color: Scheme.outlineVariant

                            // urgency rule
                            Rectangle {
                                x: 1
                                y: 10
                                width: 2
                                height: parent.height - 20
                                radius: 1
                                color: slot.critical ? Scheme.error : slot.n?.urgency === NotificationUrgency.Low ? Scheme.outlineVariant : Scheme.primary
                            }

                            Column {
                                id: body
                                x: 16
                                y: 12
                                width: parent.width - 32
                                spacing: 6

                                Row {
                                    width: parent.width
                                    spacing: 10

                                    Item {
                                        width: 20
                                        height: 20
                                        anchors.verticalCenter: parent.verticalCenter
                                        Loader {
                                            anchors.fill: parent
                                            active: !!slot.n && (slot.n.image !== "" || slot.n.appIcon !== "")
                                            sourceComponent: IconImage {
                                                source: !slot.n ? "" : slot.n.image !== "" ? slot.n.image : Quickshell.iconPath(slot.n.appIcon, "notifications")
                                            }
                                        }
                                        Icon {
                                            anchors.centerIn: parent
                                            visible: !slot.n || (slot.n.image === "" && slot.n.appIcon === "")
                                            text: "notifications"
                                            size: 18
                                            color: Scheme.fgSurfaceVariant
                                        }
                                    }
                                    Ink {
                                        text: slot.n?.summary || slot.n?.appName || ""
                                        size: 13
                                        font.weight: 500
                                        width: parent.width - 30 - meta.implicitWidth - 10
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Ink {
                                        id: meta
                                        mono: true
                                        text: (slot.n?.appName || "").toLowerCase()
                                        size: 10
                                        color: Scheme.outline
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Ink {
                                    visible: text !== ""
                                    text: (slot.n?.body ?? "").replace(/<[^>]+>/g, "").replace(/\s+/g, " ").trim()
                                    size: 12
                                    color: Scheme.fgSurfaceVariant
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                    lineHeight: 1.2
                                }

                                Row {
                                    visible: (slot.n?.actions.length ?? 0) > 0
                                    spacing: 6
                                    Repeater {
                                        model: slot.n ? slot.n.actions : []
                                        Rectangle {
                                            id: chip
                                            required property NotificationAction modelData
                                            width: chipText.implicitWidth + 20
                                            height: 24
                                            radius: Theme.rChip
                                            color: chipHover.hovered ? Scheme.surfaceContainerHigh : Scheme.surfaceContainer
                                            border.width: 1
                                            border.color: Scheme.outlineVariant
                                            Ink {
                                                id: chipText
                                                anchors.centerIn: parent
                                                text: chip.modelData.text
                                                size: 11.5
                                                font.weight: 500
                                            }
                                            HoverHandler {
                                                id: chipHover
                                            }
                                            TapHandler {
                                                onTapped: {
                                                    if (slot.n)
                                                        chip.modelData.invoke();
                                                    slot.leave();
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // close
                            Icon {
                                text: "close"
                                size: 14
                                color: closeHover.hovered ? Scheme.fgSurface : Scheme.outline
                                opacity: hover.hovered ? 1 : 0
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 10
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Theme.colour
                                    }
                                }
                                HoverHandler {
                                    id: closeHover
                                }
                                TapHandler {
                                    onTapped: {
                                        Notifs.dismiss(slot.modelData);
                                    }
                                }
                            }

                            HoverHandler {
                                id: hover
                            }
                            TapHandler {
                                onTapped: {
                                    const def = slot.n?.actions.find(a => a.identifier === "default");
                                    if (def)
                                        def.invoke();
                                    slot.leave();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
