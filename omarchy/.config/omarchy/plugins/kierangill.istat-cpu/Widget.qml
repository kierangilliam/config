import QtQuick
import qs.Commons
import "../istat-common" as Istat
import "../istat-common/Model.js" as Model

// iStat Menus-style CPU widget: stacked user/system mini graph + busy % in
// the bar; the drop-down shows the breakdown, per-core bars, load, uptime,
// processor model, and the top CPU consumers.
Istat.IstatPanel {
  id: root
  moduleName: "kierangill.istat-cpu"
  ipcTarget: "kierangill.istat-cpu"
  section: "cpu"

  readonly property bool showText: setting("showText", true)
  readonly property int topProcs: setting("topProcs", 5)

  readonly property color cUser: "#4a9eff"
  readonly property color cSystem: "#ff615c"
  readonly property color cNice: "#5cd675"
  readonly property color cIdle: Qt.rgba(fg.r, fg.g, fg.b, 0.22)

  property var cpu: ({ user: 0, system: 0, nice: 0, idle: 100, busy: 0, cores: [] })
  property var hUser: []
  property var hSys: []
  property var hNice: []
  property var procs: []
  property var loadAvg: [0, 0, 0]
  property real uptime: 0
  property string model: ""

  readonly property int miniWidth: 26
  readonly property int miniHeight: 14

  verticalText: pct(cpu.busy)
  tooltipText: "CPU " + pct(cpu.busy)

  onSnapshot: function(snap, dtSec) {
    if (prevSnap) {
      cpu = Model.cpuDelta(prevSnap.stat, snap.stat)
      hUser = Model.push(hUser, cpu.user, Model.HISTORY)
      hSys = Model.push(hSys, cpu.system, Model.HISTORY)
      hNice = Model.push(hNice, cpu.nice, Model.HISTORY)
      procs = Model.topBy(Model.procDelta(prevSnap.procs, snap.procs, dtSec, snap.clk, snap.page), "cpu", topProcs)
    }
    loadAvg = snap.load
    uptime = snap.uptime
    miniGraph.requestPaint()
    cpuGraph.requestPaint()
    coresGraph.requestPaint()
  }

  Istat.ModelName { onReady: function(name) { root.model = name } }

  // ---------------------------------------------------------------- bar
  barContent: Row {
    spacing: Style.space(4)

    Canvas {
      id: miniGraph
      width: root.miniWidth
      height: root.miniHeight
      anchors.verticalCenter: parent.verticalCenter
      onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        var c = root.buttonForeground
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
      color: root.cpu.busy > 85 ? root.warn : root.buttonForeground
      font.family: root.family
      font.pixelSize: Style.font.caption
      width: 30
    }
  }

  // -------------------------------------------------------------- panel
  component Title: Istat.SectionTitle { fg: root.fg; family: root.family }
  component Row_: Istat.InfoRow { fg: root.fg; family: root.family }
  component Proc: Istat.ProcRow { fg: root.fg; family: root.family }
  component Head: Istat.SubHead { foreground: root.fg; fontFamily: root.family }
  component Rule: Istat.Rule { foreground: root.fg }

  Title { title: "CPU"; value: root.pct(root.cpu.busy) }

  Istat.Graph {
    id: cpuGraph
    height: Style.space(60)
    onPaint: Model.paintHistory(getContext("2d"), width, height,
      [{ data: root.hSys, color: root.cSystem }, { data: root.hUser, color: root.cUser }, { data: root.hNice, color: root.cNice }],
      Model.HISTORY, root.fg)
  }

  Row_ { dot: root.cUser; label: "User"; value: root.pct1(root.cpu.user) }
  Row_ { dot: root.cSystem; label: "System"; value: root.pct1(root.cpu.system) }
  Row_ { dot: root.cNice; label: "Nice"; value: root.pct1(root.cpu.nice) }
  Row_ { dot: root.cIdle; label: "Idle"; value: root.pct1(root.cpu.idle) }

  Rule {}
  Row_ { label: "Cores"; value: root.cpu.cores.length + " cores" }
  Istat.Graph {
    id: coresGraph
    height: Style.space(26)
    onPaint: Model.paintBars(getContext("2d"), width, height, root.cpu.cores, root.cUser, root.fg)
  }

  Rule {}
  Row_ { label: "Load Average"; value: root.loadAvg.map(function(x) { return Number(x).toFixed(2) }).join("  ") }
  Row_ { label: "Uptime"; value: Model.fmtUptime(root.uptime) }
  Row_ { label: "Processor"; value: root.model; dimValue: true }

  Rule {}
  Head { text: "PROCESSES" }
  Repeater {
    model: root.procs
    Proc { name: modelData.name; value: modelData.cpu.toFixed(1) + "%" }
  }
}
