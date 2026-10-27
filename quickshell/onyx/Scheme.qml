pragma Singleton
// Colours by Material 3 role ("on*" roles are exposed as fg*: a QML property named onSurface
// is parsed as a signal handler and reads back as black), read from Caelestia's live scheme file so every surface
// follows `caelestia scheme set`. Falls back to the Obsidian tokens if the file is
// missing or unparsable. archIce is the one chromatic colour and is never schemed.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var fallback: ({
            background: "#09090b",
            onBackground: "#ececee",
            surface: "#09090b",
            surfaceDim: "#09090b",
            surfaceContainerLowest: "#050506",
            surfaceContainerLow: "#111113",
            surfaceContainer: "#16161a",
            surfaceContainerHigh: "#1d1d21",
            surfaceContainerHighest: "#242428",
            onSurface: "#ececee",
            onSurfaceVariant: "#a1a1a8",
            outline: "#5c5c63",
            outlineVariant: "#2a2a2f",
            primary: "#e4e4e7",
            onPrimary: "#141416",
            primaryContainer: "#3a3a40",
            onPrimaryContainer: "#e9e9ec",
            secondary: "#b4b4bb",
            tertiary: "#d0d0d6",
            error: "#ffb4ab",
            onError: "#690005",
            success: "#a9c2ad"
        })

    property var colours: ({})
    property string name: ""       // scheme name from scheme.json ("onyx", "dynamic", …)
    readonly property bool onyx: name === "" || name === "onyx"

    function c(name: string): color {
        const v = colours[name];
        return (typeof v === "string" && /^[0-9a-fA-F]{6}$/.test(v)) ? "#" + v : fallback[name];
    }

    readonly property color background: c("background")
    readonly property color fgBackground: c("onBackground")
    readonly property color surface: c("surface")
    readonly property color surfaceDim: c("surfaceDim")
    readonly property color surfaceContainerLowest: c("surfaceContainerLowest")
    readonly property color surfaceContainerLow: c("surfaceContainerLow")
    readonly property color surfaceContainer: c("surfaceContainer")
    readonly property color surfaceContainerHigh: c("surfaceContainerHigh")
    readonly property color surfaceContainerHighest: c("surfaceContainerHighest")
    readonly property color fgSurface: c("onSurface")
    readonly property color fgSurfaceVariant: c("onSurfaceVariant")
    readonly property color outline: c("outline")
    readonly property color outlineVariant: c("outlineVariant")
    readonly property color primary: c("primary")
    readonly property color fgPrimary: c("onPrimary")
    readonly property color primaryContainer: c("primaryContainer")
    readonly property color fgPrimaryContainer: c("onPrimaryContainer")
    readonly property color secondary: c("secondary")
    readonly property color tertiary: c("tertiary")
    readonly property color error: c("error")
    readonly property color fgError: c("onError")
    readonly property color success: c("success")
    // fixed accents outside the scheme
    readonly property color crimson: "#dc143c"
    // the one chromatic token of the Obsidian scheme; under any other scheme it follows primary
    readonly property color archIce: onyx ? "#8fb8d8" : primary
    // session / lock action accents: deliberately chromatic, never schemed
    readonly property color glyphLock: "#7cc4ff"
    readonly property color glyphSleep: "#b48cff"
    readonly property color glyphLogout: "#ffb454"
    readonly property color glyphReboot: "#ff8a5b"
    readonly property color glyphPower: "#ff5c6c"

    function alpha(col: color, a: real): color {
        return Qt.rgba(col.r, col.g, col.b, a);
    }

    FileView {
        path: `${Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"}/caelestia/scheme.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoadFailed: root.colours = ({})
        onLoaded: {
            try {
                const json = JSON.parse(text());
                root.colours = json.colours ?? ({});
                root.name = json.name ?? "";
            } catch (e) {
                console.warn("onyx: scheme.json unparsable, using fallback colours");
                root.colours = ({});
            }
        }
    }
}
