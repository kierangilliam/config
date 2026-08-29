import QtQuick
import Quickshell
import qs.Commons
import "Model.js" as Model

// Process row: app icon (or a coloured initial tile), name, value.
Item {
  id: prow
  property string name: ""
  property string value: ""
  property color fg: Color.foreground
  property string family: Style.font.family
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
    visible: prow.iconSource !== ""
    source: prow.iconSource
    width: prow.iconSize
    height: prow.iconSize
    sourceSize: Qt.size(width, height)
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
  }
  Rectangle {
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
    color: prow.fg
    font.family: prow.family
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
  }
  Text {
    id: v
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    text: prow.value
    color: prow.fg
    opacity: 0.8
    font.family: prow.family
    font.pixelSize: Style.font.bodySmall
  }
}
