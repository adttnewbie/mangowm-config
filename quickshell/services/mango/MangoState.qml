import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    signal tagChanged(int tag, bool active)
    signal monitorChanged()
    signal keyboardLayoutChanged(string layout)
    signal activeClientChanged(string title, string appid)

    property var tags: []
    property var monitors: []
    property string keyboardLayout: "us"
    property var activeClient: ({title: "", appid: ""})

    Component.onCompleted: {
        refreshTags()
        refreshMonitors()
        refreshKeyboard()
    }

    function refreshTags() {
        var proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["${Quickshell.env("HOME")}/.local/share/mango/scripts/tags.sh", "list"]
                running: true
                stdout: StdioCollector {
                    onCompleted: function(text) {
                        try {
                            var data = JSON.parse(text)
                            root.tags = data.tags || []
                        } catch (e) {
                            console.warn("Failed to parse tags:", e)
                        }
                    }
                }
            }
        `, root)
    }

    function refreshMonitors() {
        var proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["${Quickshell.env("HOME")}/.local/share/mango/scripts/monitors.sh"]
                running: true
                stdout: StdioCollector {
                    onCompleted: function(text) {
                        try {
                            var data = JSON.parse(text)
                            root.monitors = data.monitors || []
                        } catch (e) {
                            console.warn("Failed to parse monitors:", e)
                        }
                    }
                }
            }
        `, root)
    }

    function refreshKeyboard() {
        var proc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["${Quickshell.env("HOME")}/.local/share/mango/scripts/keyboard.sh", "get"]
                running: true
                stdout: StdioCollector {
                    onCompleted: function(text) {
                        try {
                            var data = JSON.parse(text)
                            root.keyboardLayout = data.layout || "us"
                        } catch (e) {
                            console.warn("Failed to parse keyboard:", e)
                        }
                    }
                }
            }
        `, root)
    }
}
