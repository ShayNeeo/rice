
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string text: "--%"
    property real usage: 0
    property int _prevTotal: 0
    property int _prevIdle: 0

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!getCPU.running)
                getCPU.running = true
        }
    }

    Process {
        id: getCPU
        command: ["sh", "-c",
            "read _ cpu nice sys idle iowait irq softirq steal rest < /proc/stat; " +
            "total=$((cpu+nice+sys+idle+iowait+irq+softirq+steal)); " +
            "echo $total $idle"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const s = text.trim()
                const parts = s.split(" ")
                if (parts.length >= 2) {
                    const total = parseInt(parts[0])
                    const idle = parseInt(parts[1])
                    if (!isNaN(total) && !isNaN(idle) && root._prevTotal > 0) {
                        const diffTotal = total - root._prevTotal
                        const diffIdle = idle - root._prevIdle
                        if (diffTotal > 0) {
                            root.usage = (1 - diffIdle / diffTotal) * 100
                            root.text = Math.round(root.usage) + "%"
                        }
                    }
                    root._prevTotal = total
                    root._prevIdle = idle
                }
            }
        }
    }
}
