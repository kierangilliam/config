import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// iStat Menus-style bar widget + native drop-down panel.
//
// The bar shows a small stacked CPU history graph with the current percentage
// and a memory usage bar with its percentage. Clicking opens a shell Panel
// (same machinery as Power/Network/Bluetooth) with the full CPU / memory
// breakdown, per-core bars, and top processes. Data comes from one
// `collect.sh` snapshot per tick; deltas are computed here.
Panel {
  id: root
  moduleName: "kierangill.istat"
  ipcTarget: "kierangill.istat"

  readonly property int interval: setting("interval", 2000)
  readonly property bool showText: setting("showText", true)
  readonly property int topProcs: setting("topProcs", 5)

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color warn: bar ? bar.urgent : Color.urgent
  readonly property string family: bar ? bar.fontFamily : Style.font.family
  readonly property bool vertical: bar ? bar.vertical : false

  // iStat-ish palette for the series. Text stays on the theme foreground.
  readonly property color cUser: "#4a9eff"
  readonly property color cSystem: "#ff615c"
  readonly property color cNice: "#5cd675"
  readonly property color cApp: "#4a9eff"
  readonly property color cWired: "#ff9e38"
  readonly property color cCompressed: "#b878f5"
  readonly property color cCached: "#999ead"
  readonly property color cFree: Qt.rgba(fg.r, fg.g, fg.b, 0.22)
  readonly property color cPressure: "#5cd675"
  readonly property color cSwap: "#ffcc4d"

  // ------------------------------------------------------------- state
  property var cpu: ({ user: 0, system: 0, nice: 0, idle: 100, busy: 0, cores: [] })
  property var mem: ({ total: 0, free: 0, available: 0, app: 0, wired: 0, compressed: 0, cached: 0,
                       swapTotal: 0, swapUsed: 0, pressure: 0, used: 0, usedPct: 0 })
  property var hUser: []
  property var hSys: []
  property var hNice: []
  property var hMem: []
  property var cpuProcs: []
  property var memProcs: []
  property var loadAvg: [0, 0, 0]
  property real uptime: 0
  property string model: ""
  property var prevSnap: null
  property real prevTime: 0

  readonly property string collectPath: String(Qt.resolvedUrl("collect.sh")).replace(/^file:\/\//, "")
  readonly property int miniWidth: 26
  readonly property int miniHeight: 14

  function pct(v) { return Math.round(Math.min(100, Math.max(0, v))) + "%" }
  function pct1(v) { return Math.min(100, Math.max(0, v)).toFixed(1) + "%" }

  function ingest(text) {
    var snap = Model.parseSnapshot(text)
    var now = Date.now()
    if (prevSnap) {
      cpu = Model.cpuDelta(prevSnap.stat, snap.stat)
      hUser = Model.push(hUser, cpu.user, Model.HISTORY)
      hSys = Model.push(hSys, cpu.system, Model.HISTORY)
      hNice = Model.push(hNice, cpu.nice, Model.HISTORY)
      var procs = Model.procDelta(prevSnap.procs, snap.procs, (now - prevTime) / 1000, snap.clk, snap.page)
      cpuProcs = Model.topBy(procs, "cpu", topProcs)
      memProcs = Model.topBy(procs, "rss", topProcs)
    }
    mem = Model.memStats(snap)
    hMem = Model.push(hMem, mem.usedPct, Model.HISTORY)
    loadAvg = snap.load
    uptime = snap.uptime
    prevSnap = snap
    prevTime = now
    miniGraph.requestPaint()
    miniMem.requestPaint()
    cpuGraph.requestPaint()
    coresGraph.requestPaint()
    memSegments.requestPaint()
    pressureGraph.requestPaint()
  }

  function refresh() { if (!collect.running) collect.running = true }

  Process {
    id: collect
    command: ["sh", root.collectPath]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.ingest(text) }
  }

  Process {
    id: modelProc
    command: ["sh", "-c", "cat /proc/device-tree/model 2>/dev/null || grep -m1 -iE '^(model name|hardware)' /proc/cpuinfo | cut -d: -f2-"]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.model = Model.shortModel(text) }
  }

  Component.onCompleted: modelProc.running = true

  Timer {
    interval: root.opened ? Math.min(1500, root.interval) : root.interval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  onOpenedChanged: if (opened) refresh()

  // ---------------------------------------------------------- bar button
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property real openPanelIndicatorWidth: root.vertical ? 0 : miniRow.implicitWidth

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.vertical ? -1 : miniRow.implicitWidth + Style.space(16)
    fixedHeight: root.vertical ? miniColumn.implicitHeight + Style.space(8) : -1
    tooltipText: "CPU " + root.pct(root.cpu.busy) + " · Memory " + root.pct(root.mem.usedPct)
    onPressed: function(b) { root.toggle() }

    Row {
      id: miniRow
      visible: !root.vertical
      anchors.centerIn: parent
      spacing: Style.space(4)

      Canvas {
        id: miniGraph
        width: root.miniWidth
        height: root.miniHeight
        anchors.verticalCenter: parent.verticalCenter
        onPaint: {
          var ctx = getContext("2d")
          var w = width, h = height
          var c = button.foreground
          ctx.clearRect(0, 0, w, h)
          ctx.fillStyle = Model.rgba(c, 0.12)
          ctx.fillRect(0, 0, w, h)
          var u = root.hUser.slice(-root.miniWidth), s = root.hSys.slice(-root.miniWidth)
          var n = u.length
          if (n === 0) return
          var x0 = w - n
          function area(vals, base, alpha) {
            ctx.beginPath()
            ctx.moveTo(x0, h)
            for (var i = 0; i < n; i++) ctx.lineTo(x0 + i, h - Math.min(1, (base[i] + vals[i]) / 100) * h)
            ctx.lineTo(x0 + n - 1, h)
            ctx.closePath()
            ctx.fillStyle = Model.rgba(c, alpha)
            ctx.fill()
          }
          area(u, s, 0.45)
          area(s, new Array(n).fill(0), 0.95)
        }
      }

      Text {
        visible: root.showText
        anchors.verticalCenter: parent.verticalCenter
        text: root.pct(root.cpu.busy)
        color: root.cpu.busy > 85 ? root.warn : button.foreground
        font.family: root.family
        font.pixelSize: Style.font.caption
        width: 30
      }

      Canvas {
        id: miniMem
        width: 22
        height: 7
        anchors.verticalCenter: parent.verticalCenter
        onPaint: {
          var ctx = getContext("2d")
          var w = width, h = height
          var c = button.foreground
          ctx.clearRect(0, 0, w, h)
          Model.rrect(ctx, 0, 0, w, h, h / 2)
          ctx.fillStyle = Model.rgba(c, 0.2)
          ctx.fill()
          var fw = Math.max(h, w * Math.min(1, root.mem.usedPct / 100))
          Model.rrect(ctx, 0, 0, fw, h, h / 2)
          ctx.fillStyle = Model.rgba(root.mem.usedPct > 90 ? root.warn : c, 0.95)
          ctx.fill()
        }
      }

      Text {
        visible: root.showText
        anchors.verticalCenter: parent.verticalCenter
        text: root.pct(root.mem.usedPct)
        color: root.mem.usedPct > 90 ? root.warn : button.foreground
        font.family: root.family
        font.pixelSize: Style.font.caption
        width: 30
      }
    }

    Column {
      id: miniColumn
      visible: root.vertical
      anchors.centerIn: parent
      spacing: 2
      Text { text: root.pct(root.cpu.busy); color: button.foreground; font.family: root.family; font.pixelSize: Style.font.caption; anchors.horizontalCenter: parent.horizontalCenter }
      Text { text: root.pct(root.mem.usedPct); color: button.foreground; font.family: root.family; font.pixelSize: Style.font.caption; anchors.horizontalCenter: parent.horizontalCenter }
    }
  }

  // --------------------------------------------------------------- panel
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: column
          width: parent.width
          spacing: Style.space(3)

          // ================================================= CPU
          SectionTitle { title: "CPU"; value: root.pct(root.cpu.busy) }

          Graph {
            id: cpuGraph
            height: Style.space(60)
            onPaint: Model.paintHistory(getContext("2d"), width, height,
              [{ data: root.hSys, color: root.cSystem }, { data: root.hUser, color: root.cUser }, { data: root.hNice, color: root.cNice }],
              Model.HISTORY, root.fg)
          }

          InfoRow { dot: root.cUser; label: "User"; value: root.pct1(root.cpu.user) }
          InfoRow { dot: root.cSystem; label: "System"; value: root.pct1(root.cpu.system) }
          InfoRow { dot: root.cNice; label: "Nice"; value: root.pct1(root.cpu.nice) }
          InfoRow { dot: root.cFree; label: "Idle"; value: root.pct1(root.cpu.idle) }

          Rule {}
          InfoRow { label: "Cores"; value: root.cpu.cores.length + " cores" }
          Graph {
            id: coresGraph
            height: Style.space(26)
            onPaint: Model.paintBars(getContext("2d"), width, height, root.cpu.cores, root.cUser, root.fg)
          }

          Rule {}
          InfoRow { label: "Load Average"; value: root.loadAvg.map(function(x) { return Number(x).toFixed(2) }).join("  ") }
          InfoRow { label: "Uptime"; value: Model.fmtUptime(root.uptime) }
          InfoRow { label: "Processor"; value: root.model; dimValue: true }

          Rule {}
          SubHead { text: "PROCESSES" }
          Repeater {
            model: root.cpuProcs
            ProcRow { name: modelData.name; value: modelData.cpu.toFixed(1) + "%" }
          }

          // ============================================== Memory
          Item { width: 1; height: Style.space(10) }
          SectionTitle { title: "Memory"; value: root.pct(root.mem.usedPct) }

          Graph {
            id: memSegments
            height: Style.space(14)
            onPaint: {
              var t = root.mem.total || 1
              Model.paintSegments(getContext("2d"), width, height, [
                { frac: root.mem.app / t, color: root.cApp },
                { frac: root.mem.wired / t, color: root.cWired },
                { frac: root.mem.compressed / t, color: root.cCompressed },
                { frac: root.mem.cached / t, color: root.cCached },
                { frac: root.mem.free / t, color: root.cFree }
              ], root.fg)
            }
          }

          InfoRow { dot: root.cApp; label: "App Memory"; value: Model.fmtBytes(root.mem.app) }
          InfoRow { dot: root.cWired; label: "Wired Memory"; value: Model.fmtBytes(root.mem.wired) }
          InfoRow { dot: root.cCompressed; label: "Compressed"; value: Model.fmtBytes(root.mem.compressed) }
          InfoRow { dot: root.cCached; label: "Cached Files"; value: Model.fmtBytes(root.mem.cached) }
          InfoRow { dot: root.cFree; label: "Free"; value: Model.fmtBytes(root.mem.free) }

          Rule {}
          InfoRow { label: "Memory Used"; value: Model.fmtBytes(root.mem.used) }
          InfoRow { label: "Physical Memory"; value: Model.fmtBytes(root.mem.total) }
          InfoRow {
            dot: root.cSwap; label: "Swap Used"
            value: root.mem.swapTotal ? Model.fmtBytes(root.mem.swapUsed) + " of " + Model.fmtBytes(root.mem.swapTotal) : "None"
          }

          Rule {}
          InfoRow {
            label: "Memory Pressure"
            value: root.pct(root.mem.usedPct) + (root.mem.pressure ? "  (PSI " + root.mem.pressure.toFixed(1) + ")" : "")
          }
          Graph {
            id: pressureGraph
            height: Style.space(40)
            onPaint: Model.paintHistory(getContext("2d"), width, height, [{ data: root.hMem, color: root.cPressure }], Model.HISTORY, root.fg)
          }

          Rule {}
          SubHead { text: "PROCESSES" }
          Repeater {
            model: root.memProcs
            ProcRow { name: modelData.name; value: Model.fmtBytes(modelData.rss) }
          }
        }
      }
    }
  }

  // ---------------------------------------------------------- components
  component SectionTitle: Item {
    property string title: ""
    property string value: ""
    width: parent.width
    implicitHeight: Math.max(t.implicitHeight, v.implicitHeight) + Style.space(6)

    Text {
      id: t
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: parent.title
      color: root.fg
      font.family: root.family
      font.pixelSize: Style.font.title
      font.bold: true
    }
    Text {
      id: v
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: parent.value
      color: root.fg
      font.family: root.family
      font.pixelSize: Style.font.title
      font.bold: true
    }
  }

  component SubHead: PanelSectionHeader {
    foreground: root.fg
    fontFamily: root.family
  }

  component Rule: PanelSeparator {
    foreground: root.fg
  }

  component Graph: Canvas {
    width: parent.width
  }

  component InfoRow: Item {
    property string label: ""
    property string value: ""
    property color dot: "transparent"
    property bool dimValue: false
    readonly property bool hasDot: dot.a > 0

    width: parent.width
    implicitHeight: Math.max(l.implicitHeight, v.implicitHeight) + Style.space(4)

    Rectangle {
      id: d
      visible: parent.hasDot
      width: Style.space(9)
      height: width
      radius: width / 2
      color: parent.dot
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }
    Text {
      id: l
      anchors.left: parent.hasDot ? d.right : parent.left
      anchors.leftMargin: parent.hasDot ? Style.space(7) : 0
      anchors.right: v.left
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      text: parent.label
      color: root.fg
      font.family: root.family
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }
    Text {
      id: v
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: parent.value
      color: root.fg
      opacity: parent.dimValue ? 0.55 : 0.85
      font.family: root.family
      font.pixelSize: Style.font.bodySmall
    }
  }

  component ProcRow: Item {
    id: prow
    property string name: ""
    property string value: ""
    readonly property string iconSource: {
      var cands = Model.iconCandidates(name)
      for (var i = 0; i < cands.length; i++) {
        var p = Quickshell.iconPath(cands[i], true)
        if (p) return p
      }
      return ""
    }
    readonly property int iconSize: Style.space(18)

    width: parent.width
    implicitHeight: Math.max(iconSize, n.implicitHeight) + Style.space(4)

    Image {
      id: icon
      visible: prow.iconSource !== ""
      source: prow.iconSource
      width: prow.iconSize
      height: prow.iconSize
      sourceSize: Qt.size(width, height)
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }
    Rectangle {
      id: tile
      visible: prow.iconSource === ""
      width: prow.iconSize
      height: prow.iconSize
      radius: width * 0.25
      color: Qt.hsva(Model.hueFor(prow.name), 0.55, 0.85, 1)
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      Text {
        anchors.centerIn: parent
        text: (prow.name.charAt(0) || "?").toUpperCase()
        color: "white"
        font.bold: true
        font.pixelSize: parent.height * 0.62
      }
    }
    Text {
      id: n
      anchors.left: parent.left
      anchors.leftMargin: prow.iconSize + Style.space(8)
      anchors.right: v.left
      anchors.rightMargin: Style.space(12)
      anchors.verticalCenter: parent.verticalCenter
      text: prow.name
      color: root.fg
      font.family: root.family
      font.pixelSize: Style.font.bodySmall
      elide: Text.ElideRight
    }
    Text {
      id: v
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: prow.value
      color: root.fg
      opacity: 0.8
      font.family: root.family
      font.pixelSize: Style.font.bodySmall
    }
  }
}
