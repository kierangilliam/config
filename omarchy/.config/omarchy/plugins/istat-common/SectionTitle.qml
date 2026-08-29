import QtQuick
import qs.Commons

// Bold "CPU ........ 12%" panel heading.
Item {
  property string title: ""
  property string value: ""
  property color fg: Color.foreground
  property string family: Style.font.family

  width: parent.width
  implicitHeight: Math.max(t.implicitHeight, v.implicitHeight) + Style.space(6)

  Text {
    id: t
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    text: parent.title
    color: parent.fg
    font.family: parent.family
    font.pixelSize: Style.font.title
    font.bold: true
  }
  Text {
    id: v
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    text: parent.value
    color: parent.fg
    font.family: parent.family
    font.pixelSize: Style.font.title
    font.bold: true
  }
}
