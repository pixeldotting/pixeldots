pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Current weather from wttr.in (no API key). Empty weatherLocation = auto-detect by IP.
Singleton {
    id: root

    property bool loaded: false
    property real temp: 0
    property real feelsLike: 0
    property int humidity: 0
    property real wind: 0
    property string description: ""
    property string icon: "partly_cloudy_day"

    function reload(): void {
        if (!proc.running)
            proc.running = true;
    }

    // wttr.in / WWO weather codes -> Material Symbols
    function iconFor(code: int): string {
        if (code === 113)
            return "clear_day";
        if (code === 116)
            return "partly_cloudy_day";
        if (code === 119 || code === 122)
            return "cloud";
        if ([143, 248, 260].includes(code))
            return "foggy";
        if ([200, 386, 389, 392, 395].includes(code))
            return "thunderstorm";
        if ([179, 182, 185, 227, 230, 281, 284, 323, 326, 329, 332, 335, 338, 350, 368, 371, 374, 377].includes(code))
            return "weather_snowy";
        if ([176, 263, 266, 293, 296, 353].includes(code))
            return "rainy_light";
        if ([299, 302, 305, 308, 311, 314, 317, 320, 356, 359, 362, 365].includes(code))
            return "rainy";
        return "partly_cloudy_day";
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.reload()
    }

    Timer {
        id: retry
        interval: 60 * 1000
        onTriggered: root.reload()
    }

    Process {
        id: proc
        command: ["curl", "-sf", "--max-time", "10", "https://wttr.in/" + encodeURIComponent(Config.weatherLocation) + "?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text).current_condition[0];
                    root.temp = parseFloat(c.temp_C);
                    root.feelsLike = parseFloat(c.FeelsLikeC);
                    root.humidity = parseInt(c.humidity);
                    root.wind = parseFloat(c.windspeedKmph);
                    root.description = c.weatherDesc?.[0]?.value ?? "";
                    root.icon = root.iconFor(parseInt(c.weatherCode));
                    root.loaded = true;
                } catch (e) {
                    retry.restart();
                }
            }
        }
        onExited: code => {
            if (code !== 0)
                retry.restart();
        }
    }
}
