import QtQuick
import qs.Commons

// "● Label ........ value" row; the dot is hidden when `dot` is transparent.
Item {
  property string label: ""
  property string value: ""
  property color dot: "transparent"
  property bool dimValue: false
  property color fg: Color.foreground
  property string family: Style.font.family
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
    color: parent.fg
    font.family: parent.family
    font.pixelSize: Style.font.bodySmall
    elide: Text.ElideRight
  }
  Text {
    id: v
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    text: parent.value
    color: parent.fg
    opacity: parent.dimValue ? 0.55 : 0.85
    font.family: parent.family
    font.pixelSize: Style.font.bodySmall
  }
}
