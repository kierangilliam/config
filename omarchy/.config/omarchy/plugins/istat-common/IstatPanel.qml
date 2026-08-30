import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Base for the iStat CPU / Memory / Network / Disk widgets: a bar button with
// widget-supplied content, a native drop-down panel, and a polling
// `collect.sh <section>` snapshot whose parsed result is emitted via
// `snapshot(snap, dtSec)`. Widgets own the state, painting, and rows.
Panel {
  id: root

  // Which collect.sh section to gather (cpu | mem | net | disk).
  property string section: ""
  property int interval: setting("interval", 2000)
  // Keep the panel refresh snappy while it's open.
  property int openInterval: 1500
  property int panelWidth: 340
  // Compact fallback for vertical bars, where the graphs don't fit.
  property string verticalText: ""
  property string tooltipText: ""

  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color warn: bar ? bar.urgent : Color.urgent
  readonly property string family: bar ? bar.fontFamily : Style.font.family
  readonly property bool vertical: bar ? bar.vertical : false
  readonly property color buttonForeground: button.foreground

  // Bar content goes in `barContent`; panel rows are the default property.
  property alias barContent: barHolder.children
  default property alias content: column.children

  signal snapshot(var snap, real dtSec)

  property var prevSnap: null
  property real prevTime: 0

  readonly property string collectPath: String(Qt.resolvedUrl("collect.sh")).replace(/^file:\/\//, "")

  function pct(v) { return Math.round(Math.min(100, Math.max(0, v))) + "%" }
  function pct1(v) { return Math.min(100, Math.max(0, v)).toFixed(1) + "%" }

  function ingest(text) {
    var snap = Model.parseSnapshot(text)
    var now = Date.now()
    root.snapshot(snap, prevSnap ? (now - prevTime) / 1000 : 0)
    prevSnap = snap
    prevTime = now
  }

  function refresh() { if (!collect.running) collect.running = true }

  Process {
    id: collect
    command: ["sh", root.collectPath, root.section]
    stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.ingest(text) }
  }

  Timer {
    interval: root.opened ? Math.min(root.openInterval, root.interval) : root.interval
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  onOpenedChanged: if (opened) refresh()

  // ---------------------------------------------------------- bar button
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property real openPanelIndicatorWidth: root.vertical ? 0 : barHolder.childrenRect.width

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.vertical ? -1 : barHolder.childrenRect.width + Style.space(16)
    fixedHeight: root.vertical ? verticalLabel.implicitHeight + Style.space(8) : -1
    tooltipText: root.tooltipText
    onPressed: function(b) { root.toggle() }

    Item {
      id: barHolder
      visible: !root.vertical
      anchors.centerIn: parent
      width: childrenRect.width
      height: childrenRect.height
    }

    Text {
      id: verticalLabel
      visible: root.vertical
      anchors.centerIn: parent
      text: root.verticalText
      color: button.foreground
      font.family: root.family
      font.pixelSize: Style.font.caption
      horizontalAlignment: Text.AlignHCenter
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
    contentWidth: panel.fittedContentWidth(Style.space(root.panelWidth))
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
        }
      }
    }
  }
}
