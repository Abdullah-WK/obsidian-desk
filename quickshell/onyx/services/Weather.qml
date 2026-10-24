pragma Singleton
// Weather for the lock: wttr.in JSON (IP geolocation), cached 30 min in
// ~/.cache/onyx/weather.json, fetched only while `active` (the lock is engaged).
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property bool ready: false
    property string condition: ""
    property int temp: 0
    property int feels: 0
    property int high: 0
    property int low: 0
    property int code: 0
    property real fetchedAt: 0

    readonly property string icon: {
        const night = new Date().getHours() < 6 || new Date().getHours() >= 19;
        const c = code;
        if (c === 113)
            return night ? "clear_night" : "clear_day";
        if (c === 116)
            return night ? "partly_cloudy_night" : "partly_cloudy_day";
        if (c === 119 || c === 122)
            return "cloud";
        if ([143, 248, 260].includes(c))
            return "foggy";
        if ([200, 386, 389, 392, 395].includes(c))
            return "thunderstorm";
        if ([179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(c))
            return "weather_snowy";
        if ([176, 263, 266, 293, 296, 299, 302, 305, 308, 353, 356, 359].includes(c))
            return "rainy";
        return "cloud";
    }

    function apply(json: var): void {
        const cc = json.current_condition?.[0];
        if (!cc)
            return;
        condition = cc.weatherDesc?.[0]?.value ?? "";
        temp = parseInt(cc.temp_C);
        feels = parseInt(cc.FeelsLikeC);
        code = parseInt(cc.weatherCode);
        high = parseInt(json.weather?.[0]?.maxtempC ?? cc.temp_C);
        low = parseInt(json.weather?.[0]?.mintempC ?? cc.temp_C);
        ready = true;
    }

    function maybeFetch(): void {
        if (!active || fetch.running)
            return;
        if (Date.now() - fetchedAt < 30 * 60 * 1000)
            return;
        fetch.running = true;
    }

    onActiveChanged: if (active) maybeFetch()

    Timer {
        running: root.active
        interval: 30 * 60 * 1000
        repeat: true
        onTriggered: root.maybeFetch()
    }

    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const json = JSON.parse(text);
                    root.apply(json);
                    root.fetchedAt = Date.now();
                    cache.setText(JSON.stringify({ at: root.fetchedAt, json: json }));
                } catch (e) {}
            }
        }
    }

    FileView {
        id: cache
        path: `${Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache"}/onyx/weather.json`
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const c = JSON.parse(text());
                root.fetchedAt = c.at ?? 0;
                root.apply(c.json);
            } catch (e) {}
        }
    }
}
