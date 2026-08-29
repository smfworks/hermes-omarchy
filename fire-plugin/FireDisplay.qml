import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false
  property var windows: []
  property string fireBin: Quickshell.env("HOME") + "/.local/bin/hermes-omarchy-fire"

  readonly property int pad: Style.space(16)
  readonly property int cardWidth: Math.min(Style.space(420), panel.width - Style.gapsOut * 2)

  function open(payloadJson) {
    root.opened = true
    listProc.running = false
    listProc.running = true
  }

  function close() { root.opened = false }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "smf.fire-display")
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function bindClass(cls) {
    Quickshell.execDetached([root.fireBin, "bind", cls])
    root.dismiss()
  }

  function bindDesktop() {
    Quickshell.execDetached([root.fireBin, "desktop"])
    root.dismiss()
  }

  Process {
    id: listProc
    command: [root.fireBin, "windows", "--json"]
    running: false
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try { root.windows = JSON.parse(text || "[]") }
        catch (e) { root.windows = [] }
      }
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "smf-fire-display"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
      MouseArea { anchors.fill: parent; onClicked: root.dismiss() }
    }

    BorderSurface {
      id: card
      width: root.cardWidth
      height: Math.min(inner.implicitHeight + root.pad * 2 + card.borderTop + card.borderBottom, panel.height - Style.gapsOut * 2)
      anchors.centerIn: parent
      color: Util.alpha(Color.background, 0.97)
      borderSpec: Border.surfaceSpec("menu", "border", Color.menu.border, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius

      MouseArea { anchors.fill: parent; onClicked: {} }

      Column {
        id: inner
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: card.borderTop + root.pad
        anchors.leftMargin: card.borderLeft + root.pad
        anchors.rightMargin: card.borderRight + root.pad
        spacing: Style.space(8)

        Text {
          text: "FIRE DISPLAY"
          color: Color.menu.text
          opacity: 0.62
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 1.2
        }

        Text {
          text: "Window on the tablet this session"
          color: Color.menu.text
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          font.bold: true
          wrapMode: Text.WordWrap
          width: parent.width
        }

        Repeater {
          model: root.windows
          Rectangle {
            required property var modelData
            width: inner.width
            height: Style.space(36)
            color: Util.alpha(Color.menu.selectedBackground, ma.containsMouse ? 1 : 0)
            radius: 4
            MouseArea {
              id: ma
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.bindClass(modelData.address)
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.margins: 8
              text: modelData.class + "  ·  ws " + modelData.workspace + "  ·  " + (modelData.title || "")
              color: Color.menu.text
              font.family: Style.font.family
              font.pixelSize: Style.font.title
              elide: Text.ElideRight
            }
          }
        }

        Rectangle {
          width: inner.width
          height: Style.space(36)
          color: Util.alpha(Color.menu.selectedBackground, deskMa.containsMouse ? 1 : 0)
          radius: 4
          MouseArea {
            id: deskMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.bindDesktop()
          }
          Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.margins: 8
            text: "Whole laptop screen"
            color: Color.menu.text
            font.family: Style.font.family
            font.pixelSize: Style.font.title
            font.bold: true
          }
        }
      }
    }
  }
}
