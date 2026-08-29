import QtQuick
import qs.Commons
import "../istat-common" as Istat
import "../istat-common/Model.js" as Model

// iStat Menus-style memory widget: usage pill + used % in the bar; the
// drop-down shows the segmented breakdown, totals, swap, a pressure history
// graph, and the top memory consumers.
Istat.IstatPanel {
  id: root
  moduleName: "kierangill.istat-memory"
  ipcTarget: "kierangill.istat-memory"
  section: "mem"

  readonly property bool showText: setting("showText", true)
  readonly property int topProcs: setting("topProcs", 5)

  readonly property color cApp: "#4a9eff"
  readonly property color cWired: "#ff9e38"
  readonly property color cCompressed: "#b878f5"
  readonly property color cCached: "#999ead"
  readonly property color cFree: Qt.rgba(fg.r, fg.g, fg.b, 0.22)
  readonly property color cPressure: "#5cd675"
  readonly property color cSwap: "#ffcc4d"

  property var mem: ({ total: 0, free: 0, available: 0, app: 0, wired: 0, compressed: 0, cached: 0,
                       swapTotal: 0, swapUsed: 0, pressure: 0, used: 0, usedPct: 0 })
  property var hMem: []
  property var procs: []

  verticalText: pct(mem.usedPct)
  tooltipText: "Memory " + pct(mem.usedPct) + " · " + Model.fmtBytes(mem.used) + " of " + Model.fmtBytes(mem.total)

  onSnapshot: function(snap, dtSec) {
    mem = Model.memStats(snap)
    hMem = Model.push(hMem, mem.usedPct, Model.HISTORY)
    if (prevSnap)
      procs = Model.topBy(Model.procDelta(prevSnap.procs, snap.procs, dtSec, snap.clk, snap.page), "rss", topProcs)
    miniMem.requestPaint()
    memSegments.requestPaint()
    pressureGraph.requestPaint()
  }

  // ---------------------------------------------------------------- bar
  barContent: Row {
    spacing: Style.space(4)

    Canvas {
      id: miniMem
      width: 22
      height: 7
      anchors.verticalCenter: parent.verticalCenter
      onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        var c = root.buttonForeground
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
      color: root.mem.usedPct > 90 ? root.warn : root.buttonForeground
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

  Title { title: "Memory"; value: root.pct(root.mem.usedPct) }

  Istat.Graph {
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

  Row_ { dot: root.cApp; label: "App Memory"; value: Model.fmtBytes(root.mem.app) }
  Row_ { dot: root.cWired; label: "Wired Memory"; value: Model.fmtBytes(root.mem.wired) }
  Row_ { dot: root.cCompressed; label: "Compressed"; value: Model.fmtBytes(root.mem.compressed) }
  Row_ { dot: root.cCached; label: "Cached Files"; value: Model.fmtBytes(root.mem.cached) }
  Row_ { dot: root.cFree; label: "Free"; value: Model.fmtBytes(root.mem.free) }

  Rule {}
  Row_ { label: "Memory Used"; value: Model.fmtBytes(root.mem.used) }
  Row_ { label: "Physical Memory"; value: Model.fmtBytes(root.mem.total) }
  Row_ {
    dot: root.cSwap; label: "Swap Used"
    value: root.mem.swapTotal ? Model.fmtBytes(root.mem.swapUsed) + " of " + Model.fmtBytes(root.mem.swapTotal) : "None"
  }

  Rule {}
  Row_ {
    label: "Memory Pressure"
    value: root.pct(root.mem.usedPct) + (root.mem.pressure ? "  (PSI " + root.mem.pressure.toFixed(1) + ")" : "")
  }
  Istat.Graph {
    id: pressureGraph
    height: Style.space(40)
    onPaint: Model.paintHistory(getContext("2d"), width, height, [{ data: root.hMem, color: root.cPressure }], Model.HISTORY, root.fg)
  }

  Rule {}
  Head { text: "PROCESSES" }
  Repeater {
    model: root.procs
    Proc { name: modelData.name; value: Model.fmtBytes(modelData.rss) }
  }
}
