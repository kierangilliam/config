import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "../istat-common" as Istat
import "../istat-common/Model.js" as Model

// iStat Menus-style disk widget: usage ring + used % of "/" in the bar; the
// drop-down shows the used/free bar, totals, the physical disk behind "/",
// a read/write activity graph, the largest top-level directories (scanned with
// `du` when the panel opens, at most every 5 minutes; click a directory to
// drill into it, click the breadcrumb to go back up), and every other volume.
Istat.IstatPanel {
  id: root
  moduleName: "kierangill.istat-disk"
  ipcTarget: "kierangill.istat-disk"
  section: "disk"

  readonly property bool showText: setting("showText", true)

  readonly property color cUsed: "#4a9eff"
  readonly property color cFree: Qt.rgba(fg.r, fg.g, fg.b, 0.22)
  readonly property color cRead: "#5cd675"
  readonly property color cWrite: "#ff615c"

  property var vols: []
  readonly property var rootVol: vols.length ? vols[0] : ({ mount: "/", fstype: "", total: 0, used: 0, free: 0, usedPct: 0 })
  property string kind: "SSD"
  property string diskModel: ""
  property var io: ({ read: 0, write: 0, readTotal: 0, writeTotal: 0 })
  property var hRead: []
  property var hWrite: []
  property real graphPeak: 0
  property int topDirs: setting("topDirs", 6)
  readonly property string home: Quickshell.env("HOME") || ""

  onSnapshot: function(snap, dtSec) {
    vols = Model.volumes(snap)
    kind = Model.diskKind(snap)
    diskModel = snap.disk.model
    io = Model.diskDelta(prevSnap, snap, dtSec)
    if (prevSnap) {
      hRead = Model.push(hRead, io.read, Model.HISTORY)
      hWrite = Model.push(hWrite, io.write, Model.HISTORY)
    }
    miniRing.requestPaint()
    diskSegments.requestPaint()
    ioGraph.requestPaint()
  }

  // ------------------------------------------------------ largest dirs
  // scans[dir] = { list, at }; "" is the top level (/ and ~ merged).
  property var scans: ({})
  property string dir: ""
  property string scanningDir: ""
  readonly property var largest: (scans[dir] ? scans[dir].list : []).slice(0, topDirs)
  readonly property bool scanning: scanningDir === dir && duScan.running

  // Declared as a property: the panel's default property only takes Items.
  readonly property Process duScan: Process {
    command: root.scanningDir ? ["sh", root.collectPath, "du", root.scanningDir] : ["sh", root.collectPath, "du"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var snap = Model.parseSnapshot(text)
        var next = Object.assign({}, root.scans)
        next[root.scanningDir] = { list: snap.du, at: Date.now() }
        root.scans = next
      }
    }
  }

  function scan(path, force) {
    if (duScan.running) return
    var cached = scans[path]
    if (cached && !force && Date.now() - cached.at < 300000) return
    scanningDir = path
    duScan.running = true
  }

  function enter(path) { dir = path; scan(path, false) }

  function up() {
    if (!dir) return
    var i = dir.lastIndexOf("/")
    var parent = i > 0 ? dir.slice(0, i) : ""
    // The top level lists / and ~ side by side, so stop there rather than at "/" or ~ itself.
    if (parent === "/" || parent === home || parent === "") parent = ""
    enter(parent)
  }

  onOpenedChanged: if (opened) scan(dir, false)

  function shortPath(p) {
    return home && p.indexOf(home) === 0 ? "~" + p.slice(home.length) : p
  }

  function baseName(p) {
    var i = p.lastIndexOf("/")
    return i >= 0 ? p.slice(i + 1) : p
  }

  // ---------------------------------------------------------------- bar
  barContent: Row {
    spacing: Style.space(4)

    Canvas {
      id: miniRing
      width: 12
      height: 12
      anchors.verticalCenter: parent.verticalCenter
      onPaint: {
        var ctx = getContext("2d")
        var w = width, h = height
        var c = root.buttonForeground
        var t = 2.5
        var r = Math.min(w, h) / 2 - t / 2
        ctx.clearRect(0, 0, w, h)
        ctx.lineWidth = t
        ctx.lineCap = "round"
        ctx.strokeStyle = Model.rgba(c, 0.2)
        ctx.beginPath()
        ctx.arc(w / 2, h / 2, r, 0, 2 * Math.PI)
        ctx.stroke()
        var frac = Math.min(1, Math.max(0.02, root.rootVol.usedPct / 100))
        ctx.strokeStyle = Model.rgba(root.rootVol.usedPct > 90 ? root.warn : c, 0.95)
        ctx.beginPath()
        ctx.arc(w / 2, h / 2, r, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * frac)
        ctx.stroke()
      }
    }

    Text {
      visible: root.showText
      anchors.verticalCenter: parent.verticalCenter
      text: root.pct(root.rootVol.usedPct)
      color: root.rootVol.usedPct > 90 ? root.warn : root.buttonForeground
      font.family: root.family
      font.pixelSize: Style.font.caption
      width: 30
    }
  }

  // -------------------------------------------------------------- panel
  component Title: Istat.SectionTitle { fg: root.fg; family: root.family }
  component Row_: Istat.InfoRow { fg: root.fg; family: root.family }
  component Head: Istat.SubHead { foreground: root.fg; fontFamily: root.family }
  component Rule: Istat.Rule { foreground: root.fg }

  // InfoRow that can be clicked (directories), with a hover highlight.
  component DirRow: Istat.InfoRow {
    id: dirRow
    property bool clickable: false
    signal clicked()
    fg: root.fg
    family: root.family
    opacity: clickable || dimValue ? 1 : 0.7
    Rectangle {
      anchors.fill: parent
      anchors.leftMargin: -Style.space(6)
      anchors.rightMargin: -Style.space(6)
      z: -1
      radius: Style.space(5)
      color: root.fg
      opacity: mouse.containsMouse && dirRow.clickable ? 0.08 : 0
    }
    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      enabled: dirRow.clickable
      cursorShape: Qt.PointingHandCursor
      onClicked: dirRow.clicked()
    }
  }

  Title { title: root.kind; value: root.pct(root.rootVol.usedPct) }

  Istat.Graph {
    id: diskSegments
    height: Style.space(14)
    onPaint: {
      var t = root.rootVol.total || 1
      var used = root.rootVol.used / t
      Model.paintSegments(getContext("2d"), width, height, [
        { frac: used, color: root.cUsed },
        { frac: Math.max(0, 1 - used), color: root.cFree }
      ], root.fg)
    }
  }

  Row_ { dot: root.cUsed; label: "Used"; value: Model.fmtBytes(root.rootVol.used) }
  Row_ { dot: root.cFree; label: "Free"; value: Model.fmtBytes(root.rootVol.free) }
  Row_ { label: "Total"; value: Model.fmtBytes(root.rootVol.total) }

  Rule {}
  Row_ { label: "Volume"; value: root.rootVol.fstype ? root.rootVol.mount + "  (" + root.rootVol.fstype + ")" : "--"; dimValue: true }
  Row_ { label: "Model"; value: root.diskModel || "--"; dimValue: true }

  Rule {}
  Row_ { label: "Activity"; value: "↓ " + Model.fmtRate(root.io.read) + "   ↑ " + Model.fmtRate(root.io.write) }
  Istat.Graph {
    id: ioGraph
    height: Style.space(40)
    onPaint: root.graphPeak = Model.paintLines(getContext("2d"), width, height,
      [{ data: root.hRead, color: root.cRead }, { data: root.hWrite, color: root.cWrite }], Model.HISTORY, root.fg)
  }
  Row_ { label: "Graph scale"; value: Model.fmtRate(root.graphPeak); dimValue: true }
  Row_ { dot: root.cRead; label: "Read"; value: Model.fmtRate(root.io.read) + "   (" + Model.fmtBytes(root.io.readTotal) + ")" }
  Row_ { dot: root.cWrite; label: "Write"; value: Model.fmtRate(root.io.write) + "   (" + Model.fmtBytes(root.io.writeTotal) + ")" }

  Rule {}
  Head { text: root.dir ? "LARGEST IN" : "LARGEST" }
  DirRow {
    visible: !!root.dir
    label: "‹  " + root.shortPath(root.dir)
    value: root.scans[root.dir] ? Model.fmtBytes(root.scans[root.dir].list.reduce(function(a, e) { return a + e.bytes }, 0)) : ""
    dimValue: true
    clickable: true
    onClicked: root.up()
  }
  Row_ { visible: root.scanning && !root.largest.length; label: "Scanning…"; value: ""; dimValue: true }
  Row_ { visible: !root.scanning && !root.largest.length && !!root.scans[root.dir]; label: "Empty"; value: ""; dimValue: true }
  Repeater {
    model: root.largest
    DirRow {
      label: (root.dir ? "    " + root.baseName(modelData.path) : root.shortPath(modelData.path)) + (modelData.isDir ? "/" : "")
      value: Model.fmtBytes(modelData.bytes)
      dimValue: !modelData.isDir
      clickable: modelData.isDir
      onClicked: root.enter(modelData.path)
    }
  }

  Rule { visible: root.vols.length > 1 }
  Head { visible: root.vols.length > 1; text: "VOLUMES" }
  Repeater {
    model: root.vols.slice(1)
    Row_ {
      label: modelData.mount
      value: Model.fmtBytes(modelData.used) + " of " + Model.fmtBytes(modelData.total) + "  (" + Math.round(modelData.usedPct) + "%)"
    }
  }
}
