pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string scriptDir: Quickshell.env("HOME") + "/.local/share/mango/scripts"

    function monitorsCommand() {
        return [root.scriptDir + "/ipc.sh", "monitors"]
    }

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

    function dispatchMonitorRule(rule) {
        Quickshell.execDetached([root.scriptDir + "/ipc.sh", "monitor-rule", rule])
    }

    function dispatchBatch(cmds) {
        Quickshell.execDetached([root.scriptDir + "/ipc.sh", "batch", cmds])
    }

    function dispatchSubmap(submap) {
        Quickshell.execDetached([root.scriptDir + "/ipc.sh", "submap", submap])
    }

    function dispatchSpawn(execStr) {
        Quickshell.execDetached([root.scriptDir + "/ipc.sh", "spawn", execStr])
    }

    function dispatchCommand(dispatcher, command) {
        Quickshell.execDetached([root.scriptDir + "/ipc.sh", "dispatch", dispatcher, command])
    }
}
