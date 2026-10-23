import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.components
import qs.config
import qs.services

// Bottom-centre launcher.
//   <text>   apps          =2+2 / 12*3   calculator (Enter copies the result)
//   >        actions       :             clipboard history (cliphist)
DrawerPanel {
    id: root

    readonly property string query: search.text.trim()
    property var clipEntries: []
    readonly property var results: compute(query, clipEntries)

    width: 640
    height: content.implicitHeight + 24
    hideY: 40

    // ── result building ─────────────────────────────────────────────
    readonly property var actions: [
        {
            name: "Lock",
            desc: "Lock the session",
            symbol: "lock",
            run: () => Lockscreen.lock()
        },
        {
            name: "Logout",
            desc: "End the session",
            symbol: "logout",
            run: () => Quickshell.execDetached(["loginctl", "terminate-user", Quickshell.env("USER")])
        },
        {
            name: "Suspend",
            desc: "Sleep",
            symbol: "bedtime",
            run: () => Quickshell.execDetached(["systemctl", "suspend"])
        },
        {
            name: "Reboot",
            desc: "Restart the computer",
            symbol: "restart_alt",
            run: () => Quickshell.execDetached(["systemctl", "reboot"])
        },
        {
            name: "Shutdown",
            desc: "Power off",
            symbol: "power_settings_new",
            run: () => Quickshell.execDetached(["systemctl", "poweroff"])
        },
        {
            name: "Wallpaper",
            desc: "Choose a wallpaper and colour scheme",
            symbol: "wallpaper",
            run: () => Visibilities.open("wallpaper")
        },
        {
            name: "Random wallpaper",
            desc: "Pick one from your wallpaper folder",
            symbol: "casino",
            run: () => Wallpapers.random()
        },
        {
            name: "Dark mode",
            desc: "Use the dark scheme",
            symbol: "dark_mode",
            run: () => Wallpapers.setMode("dark")
        },
        {
            name: "Light mode",
            desc: "Use the light scheme",
            symbol: "light_mode",
            run: () => Wallpapers.setMode("light")
        },
        {
            name: "Do not disturb",
            desc: "Toggle notification popups",
            symbol: "notifications_off",
            run: () => Notifs.toggleDnd()
        },
        {
            name: "Clipboard history",
            desc: "Search copied items",
            symbol: "content_paste",
            run: () => Visibilities.openLauncher(":")
        },
        {
            name: "Restart shell",
            desc: "Reload this shell",
            symbol: "refresh",
            run: () => Quickshell.reload(true)
        }
    ]

    function fuzzy(text: string, q: string): bool {
        let i = 0;
        for (let j = 0; j < text.length && i < q.length; j++)
            if (text[j] === q[i])
                i++;
        return i === q.length;
    }

    function score(entry: var, q: string): int {
        const name = entry.name.toLowerCase();
        if (name === q)
            return 100;
        if (name.startsWith(q))
            return 80;
        if (name.includes(" " + q))
            return 70;
        if (name.includes(q))
            return 60;
        if ((entry.genericName ?? "").toLowerCase().includes(q))
            return 40;
        if ((entry.keywords ?? []).toString().toLowerCase().includes(q))
            return 30;
        if ((entry.comment ?? "").toLowerCase().includes(q))
            return 20;
        return fuzzy(name, q) ? 10 : 0;
    }

    function tryCalc(q: string): var {
        const expr = q.startsWith("=") ? q.slice(1) : q;
        // digits and operators only; at least one operator (a leading '-' doesn't count)
        if (!/^[0-9+\-*\/%^().,\s]+$/.test(expr) || !/[+\-*\/%^]/.test(expr.replace(/^\s*-/, "")))
            return null;
        try {
            const value = eval("(" + expr.replace(/\^/g, "**").replace(/,/g, ".") + ")");
            if (typeof value !== "number" || !isFinite(value))
                return null;
            return parseFloat(value.toPrecision(12));
        } catch (e) {
            return null;
        }
    }

    function compute(q: string, clip: var): var {
        // actions
        if (q.startsWith(">")) {
            const f = q.slice(1).trim().toLowerCase();
            return actions.filter(a => f === "" || a.name.toLowerCase().includes(f) || a.desc.toLowerCase().includes(f));
        }

        // clipboard
        if (q.startsWith(":")) {
            const f = q.slice(1).trim().toLowerCase();
            return clip.filter(c => f === "" || c.text.toLowerCase().includes(f)).slice(0, 50).map(c => ({
                        name: c.text.replace(/\s+/g, " ").slice(0, 120),
                        desc: "Copy to clipboard",
                        symbol: "content_paste",
                        run: () => /^\d+$/.test(c.id) && Quickshell.execDetached(["sh", "-c", "cliphist decode " + c.id + " | wl-copy"])
                    }));
        }

        const out = [];

        const calc = tryCalc(q);
        if (calc !== null)
            out.push({
                name: String(calc),
                desc: "Result · Enter to copy",
                symbol: "calculate",
                run: () => Quickshell.execDetached(["wl-copy", String(calc)])
            });

        const apps = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        let matched;
        if (q === "") {
            matched = apps.slice().sort((a, b) => a.name.localeCompare(b.name));
        } else {
            const lq = q.toLowerCase();
            matched = apps.map(e => ({
                        e: e,
                        s: score(e, lq)
                    })).filter(x => x.s > 0).sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name)).map(x => x.e);
        }

        for (const e of matched.slice(0, 50))
            out.push({
                name: e.name,
                desc: e.comment || e.genericName || "",
                icon: e.icon,
                run: () => e.execute()
            });

        return out;
    }

    function activate(index: int): void {
        const item = results[index];
        if (!item)
            return;
        Visibilities.close();
        item.run();
    }

    onShownChanged: {
        if (shown) {
            search.text = Visibilities.launcherQuery;
            list.currentIndex = 0;
            search.forceActiveFocus();
        }
    }

    onQueryChanged: {
        list.currentIndex = 0;
        if (query.startsWith(":") && !clip.running)
            clip.running = true;
    }

    Process {
        id: clip
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.clipEntries = text.split("\n").filter(l => l !== "").map(l => {
                    const t = l.indexOf("\t");
                    return {
                        id: l.slice(0, t),
                        text: l.slice(t + 1)
                    };
                });
            }
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // search field
        StyledRect {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: Appearance.rounding.full
            color: Colors.surfaceContainerHighest

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 12

                MaterialIcon {
                    text: root.query.startsWith(">") ? "terminal" : root.query.startsWith(":") ? "content_paste" : "search"
                    color: Colors.primary
                    size: 24
                }

                TextInput {
                    id: search
                    Layout.fillWidth: true
                    color: Colors.onSurface
                    selectionColor: Colors.primary
                    selectedTextColor: Colors.onPrimary
                    font.family: Appearance.font.sans
                    font.pixelSize: Appearance.font.bodyLarge
                    clip: true

                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onTabPressed: list.incrementCurrentIndex()
                    Keys.onReturnPressed: root.activate(list.currentIndex)
                    Keys.onEnterPressed: root.activate(list.currentIndex)

                    StyledText {
                        anchors.fill: parent
                        visible: search.text === ""
                        text: "Search apps  ·  =calc  ·  >actions  ·  :clipboard"
                        color: Colors.onSurfaceVariant
                        font.pixelSize: Appearance.font.bodyLarge
                    }
                }
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            implicitHeight: Math.min(count, 7) * 56
            model: root.results
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: Appearance.anim.fast
            visible: count > 0

            Behavior on implicitHeight {
                Anim {
                    duration: Appearance.anim.slow
                    easing.bezierCurve: Appearance.anim.emphasizedDecel
                }
            }

            delegate: StyledRect {
                id: item

                required property var modelData
                required property int index

                readonly property bool current: ListView.isCurrentItem

                width: ListView.view.width
                height: 56
                radius: Appearance.rounding.lg
                color: current ? Colors.secondaryContainer : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 14

                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        MaterialIcon {
                            anchors.centerIn: parent
                            visible: !!item.modelData.symbol
                            text: item.modelData.symbol ?? ""
                            size: 26
                            color: item.current ? Colors.onSecondaryContainer : Colors.primary
                        }
                        Loader {
                            anchors.fill: parent
                            active: !item.modelData.symbol
                            sourceComponent: AppIcon {
                                name: item.modelData.icon ?? ""
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            Layout.fillWidth: true
                            text: item.modelData.name
                            color: item.current ? Colors.onSecondaryContainer : Colors.onSurface
                            font.pixelSize: Appearance.font.bodyLarge
                        }
                        StyledText {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: item.modelData.desc ?? ""
                            color: Colors.onSurfaceVariant
                            font.pixelSize: Appearance.font.label
                        }
                    }
                }

                StateLayer {
                    radius: item.radius
                    onClicked: root.activate(item.index)
                }
            }
        }
    }
}
