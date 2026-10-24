// Windowed test for the lock surface: real PAM, no WlSessionLock. Run with
//   qs -p ~/.config/quickshell/onyx/LockHarness.qml   (must live at the config root so qs.* resolves)
// Type the password to see the close sequence; the window closes 700 ms after success.
import QtQuick
import Quickshell
import qs
import qs.lock
import qs.services

ShellRoot {
    LockState {
        id: state
        onSuccess: closeT.restart()
    }

    Component.onCompleted: Weather.active = Config.lockShowWeather

    Timer {
        id: closeT
        interval: Theme.d(640) + 400
        onTriggered: Qt.quit()
    }

    FloatingWindow {
        id: win
        title: "onyx lock harness"
        implicitWidth: 1536
        implicitHeight: 864
        color: "black"
        visible: true

        LockSurface {
            anchors.fill: parent
            state: state
        }
    }
}
