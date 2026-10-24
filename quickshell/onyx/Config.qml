pragma Singleton
// User settings: ~/.config/onyx/config.json (watched). Every key has a default.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var data: ({})
    readonly property var lockData: data.lock ?? ({})
    readonly property var widgetData: data.widgets ?? ({})

    readonly property bool reducedMotion: data.reducedMotion ?? false
    readonly property bool barPinned: data.barPinned ?? false
    readonly property int updatesIntervalMin: Math.max(1, data.updatesIntervalMin ?? 60)
    readonly property bool updatesOnBattery: data.updatesOnBattery ?? false
    readonly property bool widgetsEnabled: data.widgetsEnabled ?? true
    readonly property bool widgetClock: widgetData.clock ?? true
    readonly property bool widgetSystem: widgetData.system ?? true
    readonly property bool widgetVitals: widgetData.vitals ?? true
    readonly property bool widgetUpdates: widgetData.updates ?? true
    readonly property var perfCommand: toCommand(data.perfCommand ?? "foot -e btop")
    readonly property var updatesCommand: toCommand(data.updatesCommand ?? "foot -e paru")
    readonly property var logoutCommand: toCommand(data.logoutCommand ?? "loginctl terminate-session self")
    readonly property var trayHidden: Array.isArray(data.trayHidden) ? data.trayHidden : []

    readonly property bool lockHideNotifs: lockData.hideNotifs ?? false
    // null → follow the locale; true/false force 24 h / 12 h
    readonly property var lockUse24h: lockData.use24h ?? null
    readonly property bool lockShowWeather: lockData.showWeather ?? true
    readonly property bool lockShowMedia: lockData.showMedia ?? true
    readonly property bool lockDotField: lockData.dotField ?? true
    readonly property int lockDebugAutoUnlockSec: data.lockDebugAutoUnlockSec ?? 0

    function toCommand(v: var): var {
        if (Array.isArray(v))
            return v;
        if (typeof v === "string")
            return v.trim().split(/\s+/);
        return [];
    }

    FileView {
        path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/onyx/config.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoadFailed: root.data = ({})
        onLoaded: {
            try {
                root.data = JSON.parse(text());
            } catch (e) {
                console.warn("onyx: config.json unparsable, using defaults");
                root.data = ({});
            }
        }
    }
}
