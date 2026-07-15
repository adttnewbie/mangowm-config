import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string scriptDir: Quickshell.env("HOME") + "/.local/share/mango/scripts"

    function viewTag(tag) {
        if (tag < 1 || tag > 9) {
            console.warn("Invalid tag:", tag)
            return
        }
        var proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["${root.scriptDir}/ipc.sh", "view-tag", "${tag}"]
                running: true
            }
        `, root)
    }

    function moveFocusedClientToTag(tag) {
        if (tag < 1 || tag > 9) {
            console.warn("Invalid tag:", tag)
            return
        }
        var proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["${root.scriptDir}/ipc.sh", "move-to-tag", "${tag}"]
                running: true
            }
        `, root)
    }

    function reloadConfig() {
        var proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["${root.scriptDir}/ipc.sh", "reload"]
                running: true
            }
        `, root)
    }

    function quitSession() {
        var proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["${root.scriptDir}/ipc.sh", "quit"]
                running: true
            }
        `, root)
    }

    function switchKeyboardLayout() {
        var proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["${root.scriptDir}/ipc.sh", "switch-keyboard-layout"]
                running: true
            }
        `, root)
    }
}
