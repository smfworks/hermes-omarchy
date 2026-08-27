import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "smf.hermes"
  ipcTarget: "smf.hermes"
  manageIpc: false

  property var anchorItem: null
  property bool openedFromHotkey: false
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  property string label: "H"
  property bool desktopRunning: false
  property var usage: null

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string usagePath: Quickshell.env("HOME") + "/.local/state/omarchy/agents/usage/hermes.json"
  readonly property string statusLine: desktopRunning ? "Desktop running" : "Desktop idle"
  readonly property string usageLine: usageMeta()

  function open() {
    openedFromHotkey = false
    setCenterHoverRevealSuppressed(false)
    root.controller.show()
    root.refresh()
  }

  function openFromHotkey() {
    openedFromHotkey = true
    root.controller.show()
    root.refresh()
    Qt.callLater(function() {
      if (root.opened) setCenterHoverRevealSuppressed(true)
    })
  }

  function close() {
    setCenterHoverRevealSuppressed(false)
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.openFromHotkey()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  function setCenterHoverRevealSuppressed(value) {
    if (root.bar && "centerHoverRevealSuppressed" in root.bar)
      root.bar.centerHoverRevealSuppressed = value
  }

  function refresh() {
    usageFile.reload()
    desktopProbe.running = false
    desktopProbe.running = true
  }

  function launchHermes() {
    if (root.bar) root.bar.run("uwsm-app -- hermes")
    root.close()
  }

  function refreshUsage() {
    if (root.bar) root.bar.run("omarchy agent usage-update hermes")
    Qt.callLater(root.refresh)
  }

  function parseUsage(text) {
    try {
      var parsed = JSON.parse(text)
      if (!parsed || typeof parsed !== "object") return null
      return parsed
    } catch (e) {
      return null
    }
  }

  function usageMeta() {
    if (!usage) return "No local usage record yet"
    var tokens = Number(usage.todayTotalTokens || 0)
    var tier = String(usage.tierLabel || "")
    var ready = usage.ready === true ? "ready" : "idle"
    var bits = [ready]
    if (tier !== "") bits.push(tier)
    if (tokens > 0) bits.push(tokens + " tokens today")
    return bits.join(" · ")
  }

  FileView {
    id: usageFile
    path: root.usagePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.usage = root.parseUsage(text())
    onLoadFailed: root.usage = null
  }

  Process {
    id: desktopProbe
    command: ["pgrep", "-f", "hermes desktop"]
    stdout: StdioCollector { waitForEnd: true }
    onExited: function(code) { root.desktopRunning = code === 0 }
  }

  Timer {
    interval: 1500
    running: true
    onTriggered: root.refresh()
  }

  IpcHandler {
    enabled: true
    target: "smf.hermes"
    function open(): void { root.openFromHotkey() }
    function close(): void { root.close() }
    function show(): void { root.openFromHotkey() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(body.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: root.launchHermes()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "r" || t === "R") root.refreshUsage()
        if (t === "l" || t === "L") root.launchHermes()
      }

      Column {
        id: body
        width: parent.width
        spacing: Style.space(12)
        leftPadding: Style.space(16)
        rightPadding: Style.space(16)
        topPadding: Style.space(14)
        bottomPadding: Style.space(14)

        Text {
          text: "Hermes"
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          font.bold: true
        }

        Text {
          text: root.statusLine
          color: root.desktopRunning ? root.foreground : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }

        Text {
          width: parent.width - Style.space(32)
          wrapMode: Text.Wrap
          text: root.usageLine
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Text {
          text: "Enter / L  launch    R  refresh usage    Esc  close"
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }
    }
  }
}
