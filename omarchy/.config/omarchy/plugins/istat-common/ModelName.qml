import QtQuick
import Quickshell.Io
import "Model.js" as Model

// Reads the machine / CPU model once and emits it shortened.
Item {
  id: modelName
  signal ready(string name)
  Process {
    id: proc
    command: ["sh", "-c", "cat /proc/device-tree/model 2>/dev/null || grep -m1 -iE '^(model name|hardware)' /proc/cpuinfo | cut -d: -f2-"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: modelName.ready(Model.shortModel(text)) }
  }
  Component.onCompleted: proc.running = true
}
