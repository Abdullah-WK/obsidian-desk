pragma Singleton
// onyx is the notification daemon: Quickshell's NotificationServer owns org.freedesktop.Notifications.
// Live popups (Notifs.popups) are shown by notifications/Popups.qml; history (Notifs.list, newest
// first, persisted to ~/.local/state/onyx/notifs.json) feeds the bell popout and the lock screen.
// "Unread" = newer than the last time the bell popout was opened. DND suppresses popups only.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs

Singleton {
    id: root

    property var list: []          // history: {id, time, summary, body, appName, appIcon, image, urgency, actions:[{id,text}]}
    property var popups: []        // live Notification objects currently shown
    property real seenAt: Date.now()
    property bool dnd: false
    readonly property int unread: list.filter(n => new Date(n.time).getTime() > seenAt).length
    readonly property int maxHistory: 60

    function entryFor(n: Notification): var {
        return {
            id: n.id,
            time: new Date().toISOString(),
            summary: n.summary,
            body: n.body,
            appName: n.appName,
            appIcon: n.appIcon,
            image: n.image,
            urgency: n.urgency,
            actions: n.actions.map(a => ({ id: a.identifier, text: a.text }))
        };
    }

    function persist(): void {
        history.setText(JSON.stringify(list));
        state.setText(JSON.stringify({ dnd: dnd, seenAt: seenAt }));
    }

    function markSeen(): void {
        seenAt = Date.now();
        persist();
    }

    function toggleDnd(): void {
        dnd = !dnd;
        if (dnd)
            popups = [];
        persist();
    }

    function refreshDnd(): void {}

    function clear(): void {
        list = [];
        popups = [];
        for (const n of server.trackedNotifications.values)
            n.dismiss();
        persist();
    }

    function remove(id: int): void {
        list = list.filter(e => e.id !== id);
        persist();
    }

    function closePopup(n: Notification): void {
        popups = popups.filter(p => p !== n);
    }

    function dismiss(n: Notification): void {
        closePopup(n);
        n.dismiss();
    }

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
        return h < 24 ? h + "h" : Math.floor(h / 24) + "d";
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            root.list = [root.entryFor(n), ...root.list].slice(0, root.maxHistory);
            if (!root.dnd)
                root.popups = [n, ...root.popups.filter(p => p !== n)];
            root.persist();
        }
    }

    Connections {
        target: server
        function onTrackedNotificationsChanged(): void {
            // drop popups whose notification was closed by the sender
            const live = server.trackedNotifications.values;
            root.popups = root.popups.filter(p => live.includes(p));
        }
    }

    FileView {
        id: history
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/onyx/notifs.json`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const l = JSON.parse(text());
                if (Array.isArray(l))
                    root.list = l.slice(0, root.maxHistory);
            } catch (e) {}
        }
    }

    FileView {
        id: state
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/onyx/notifs-state.json`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.dnd = s.dnd ?? false;
                root.seenAt = s.seenAt ?? Date.now();
            } catch (e) {}
        }
    }
}
