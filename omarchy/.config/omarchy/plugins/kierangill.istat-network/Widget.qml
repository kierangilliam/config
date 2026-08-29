import QtQuick
import qs.Commons
import "../istat-common" as Istat
import "../istat-common/Model.js" as Model

// iStat Menus-style network widget. The bar shows two stacked lines, the
// current upload and download rate of the primary interface:
//   ↑ 12.3 KB/s
//   ↓ 1.2 MB/s
// The drop-down shows a shared throughput history graph, current and peak
// rates, session totals, and every interface with its address.
Istat.IstatPanel {
  id: root
  moduleName: "kierangill.istat-network"
  ipcTarget: "kierangill.istat-network"
  section: "net"
  interval: setting("interval", 1000)
  openInterval: 1000

  readonly property string wantedIface: String(setting("interface", "") || "")

  readonly property color cUp: "#ff615c"
  readonly property color cDown: "#4a9eff"

  property string iface: ""
  property real up: 0
  property real down: 0
  property real peakUp: 0
  property real peakDown: 0
  property var hUp: []
  property var hDown: []
  property var ifaces: []
  property string gateway: ""
  property real graphPeak: 0

  verticalText: "↑" + Model.fmtRate(up, true) + "\n↓" + Model.fmtRate(down, true)
  tooltipText: (iface || "Network") + " · ↑ " + Model.fmtRate(up, true) + " · ↓ " + Model.fmtRate(down, true)

  onSnapshot: function(snap, dtSec) {
    var next = Model.pickIface(snap, wantedIface)
    if (next !== iface) { peakUp = 0; peakDown = 0; hUp = []; hDown = [] }
    if (prevSnap && next === iface) {
      var d = Model.netDelta(prevSnap, snap, next, dtSec)
      up = d.up; down = d.down
      peakUp = Math.max(peakUp, up); peakDown = Math.max(peakDown, down)
      hUp = Model.push(hUp, up, Model.HISTORY)
      hDown = Model.push(hDown, down, Model.HISTORY)
    } else {
      up = 0; down = 0
    }
    iface = next
    ifaces = Model.ifaceList(snap, next)
    gateway = snap.route.gateway
    netGraph.requestPaint()
  }

  function primary() {
    for (var i = 0; i < ifaces.length; i++) if (ifaces[i].name === iface) return ifaces[i]
    return null
  }

  // ---------------------------------------------------------------- bar
  // Reserve the width of the widest plausible label so the button doesn't
  // jitter as rates change.
  readonly property real rateSize: Math.round(Style.font.caption * 0.92)
  readonly property TextMetrics rateMetrics: TextMetrics { font.family: root.family; font.pixelSize: root.rateSize; text: "↓ 999 KB/s" }

  barContent: Column {
    spacing: 0

    RateLine { arrow: "↑"; rate: root.up }
    RateLine { arrow: "↓"; rate: root.down }
  }

  component RateLine: Item {
    property string arrow: ""
    property real rate: 0
    width: root.rateMetrics.advanceWidth + Style.space(2)
    height: root.rateMetrics.height
    Text {
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      text: arrow
      color: rate > 0 ? root.buttonForeground : Qt.rgba(root.buttonForeground.r, root.buttonForeground.g, root.buttonForeground.b, 0.45)
      font.family: root.family
      font.pixelSize: root.rateSize
    }
    Text {
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      text: Model.fmtRate(rate, true)
      color: root.buttonForeground
      font.family: root.family
      font.pixelSize: root.rateSize
    }
  }

  // -------------------------------------------------------------- panel
  component Title: Istat.SectionTitle { fg: root.fg; family: root.family }
  component Row_: Istat.InfoRow { fg: root.fg; family: root.family }
  component Head: Istat.SubHead { foreground: root.fg; fontFamily: root.family }
  component Rule: Istat.Rule { foreground: root.fg }

  Title { title: "Network"; value: root.iface }

  Istat.Graph {
    id: netGraph
    height: Style.space(60)
    onPaint: root.graphPeak = Model.paintLines(getContext("2d"), width, height,
      [{ data: root.hDown, color: root.cDown }, { data: root.hUp, color: root.cUp }], Model.HISTORY, root.fg)
  }
  Row_ { label: "Graph scale"; value: Model.fmtRate(root.graphPeak); dimValue: true }

  Row_ { dot: root.cUp; label: "Upload"; value: Model.fmtRate(root.up) }
  Row_ { dot: root.cDown; label: "Download"; value: Model.fmtRate(root.down) }

  Rule {}
  Row_ { label: "Peak Upload"; value: Model.fmtRate(root.peakUp) }
  Row_ { label: "Peak Download"; value: Model.fmtRate(root.peakDown) }
  Row_ { label: "Total Sent"; value: root.primary() ? Model.fmtBytes(root.primary().tx) : "--" }
  Row_ { label: "Total Received"; value: root.primary() ? Model.fmtBytes(root.primary().rx) : "--" }

  Rule {}
  Row_ { label: "Local IP"; value: root.primary() ? (root.primary().ip.split("/")[0] || "--") : "--" }
  Row_ { label: "Gateway"; value: root.gateway || "--" }
  Row_ { visible: !!(root.primary() && root.primary().ssid); label: "Wi-Fi"; value: root.primary() ? root.primary().ssid : "" }

  Rule {}
  Head { text: "INTERFACES" }
  Repeater {
    model: root.ifaces
    Row_ {
      label: modelData.name + (modelData.name === root.iface ? "  •" : "")
      value: modelData.ip ? modelData.ip.split("/")[0] : "no address"
      dimValue: !modelData.ip
    }
  }
}
