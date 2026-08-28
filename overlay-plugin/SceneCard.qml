import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false
  property string kicker: "HERMES"
  property string title: ""
  property string subtitle: ""
  property int duration: 5000

  readonly property int pad: Style.space(20)
  readonly property int gap: Style.space(6)
  readonly property int maxCardWidth: Math.min(Style.space(720), panel.width - Style.gapsOut * 2)

  function applyPayload(payloadJson) {
    var payload = ({})
    try { payload = JSON.parse(payloadJson || "{}") } catch (e) { payload = ({}) }
    root.kicker = payload.kicker !== undefined ? String(payload.kicker) : "HERMES"
    root.title = payload.title !== undefined ? String(payload.title) : ""
    root.subtitle = payload.subtitle !== undefined ? String(payload.subtitle) : ""
    if (payload.duration !== undefined && payload.duration !== null && payload.duration !== "")
      root.duration = parseInt(payload.duration, 10) || 0
    else
      root.duration = 5000
  }

  function open(payloadJson) {
    applyPayload(payloadJson)
    if (root.title === "" && root.subtitle === "")
      root.title = "Hermes"
    root.opened = true
    if (root.duration > 0)
      hideTimer.restart()
    else
      hideTimer.stop()
  }

  function close() {
    hideTimer.stop()
    root.opened = false
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide((root.manifest && root.manifest.id) || "smf.scene-card")
  }

  function toggle() {
    if (root.opened)
      root.dismiss()
    else
      root.open("{}")
  }

  Timer {
    id: hideTimer
    interval: Math.max(0, root.duration)
    onTriggered: root.dismiss()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "smf-scene-card"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    BorderSurface {
      id: card
      width: Math.min(root.maxCardWidth, card.borderLeft + root.pad + inner.implicitWidth + root.pad + card.borderRight)
      height: card.borderTop + root.pad + inner.implicitHeight + root.pad + card.borderBottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Style.space(72)
      color: Util.alpha(Color.background, 0.97)
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius
      opacity: root.opened ? 1 : 0

      Column {
        id: inner
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: card.borderTop + root.pad
        anchors.leftMargin: card.borderLeft + root.pad
        anchors.rightMargin: card.borderRight + root.pad
        spacing: root.gap

        Text {
          visible: root.kicker !== ""
          width: Math.min(root.maxCardWidth - root.pad * 2, 640)
          text: root.kicker
          color: Color.menu.text
          opacity: 0.62
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.letterSpacing: 1.4
          font.bold: true
          wrapMode: Text.NoWrap
          elide: Text.ElideRight
        }

        Text {
          visible: root.title !== ""
          width: Math.min(root.maxCardWidth - root.pad * 2, 640)
          text: root.title
          color: Color.menu.text
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          font.bold: true
          wrapMode: Text.WordWrap
        }

        Text {
          visible: root.subtitle !== ""
          width: Math.min(root.maxCardWidth - root.pad * 2, 640)
          text: root.subtitle
          color: Color.menu.text
          opacity: 0.72
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          wrapMode: Text.WordWrap
        }
      }
    }
  }
}
