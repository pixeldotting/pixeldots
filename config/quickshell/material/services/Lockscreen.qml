pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool locked: false

    function lock(): void {
        locked = true;
    }
}
