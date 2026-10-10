import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// Notch guard (rubra prototype, 2026-10-08). With the `notch-reserve` toggle on (Super+Alt+F,
// notch-reserve-toggle), keeps windows out of the strip beside the camera notch: a black layer over the
// notch rows with an exclusive zone, so Hyprland tiles and maximizes below it. Only needed while the
// bar isn't covering the strip itself (hidden in edge-to-edge mode, or on another edge). Fullscreen
// follows the toggle too: Hyprland ignores reserved areas for fullscreen windows, so while the toggle is
// on, fullscreen-sync.sh turns them into maximized windows (the app still sees fullscreen), and turns
// them back when it goes off.
Item {
  id: root

  property var shell: null

  // J613 notch, measured 2026-10-08: rows 0-55 of the 2560x1664 panel. Upstream this comes from the
  // platform display-cutouts data (see README.md).
  readonly property int cutoutRows: 56
  readonly property string togglesDir: Quickshell.env("HOME") + "/.local/state/omarchy/toggles"

  readonly property var panelScreen: {
    var s = Quickshell.screens
    for (var i = 0; i < s.length; i++) if (String(s[i].name).indexOf("eDP") === 0) return s[i]
    return null
  }
  readonly property bool barCovers: !!(shell && shell.bar && !shell.bar.barHidden && shell.bar.position === "top")
  property bool reserveOn: false
  readonly property bool guardActive: reserveOn && !barCovers && panelScreen !== null
  readonly property string syncScript: Qt.resolvedUrl("fullscreen-sync.sh").toString().replace("file://", "")

  // One sync at a time; a request while one runs is replayed when it ends.
  property bool syncPending: false
  function syncFullscreen() {
    if (fullscreenSync.running) { syncPending = true; return }
    fullscreenSync.command = ["bash", syncScript, reserveOn ? "on" : "off"]
    fullscreenSync.running = true
  }
  onReserveOnChanged: syncFullscreen()

  Process {
    id: fullscreenSync
    onExited: if (root.syncPending) { root.syncPending = false; root.syncFullscreen() }
  }
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (root.reserveOn && (event.name === "fullscreen" || event.name === "openwindow")) root.syncFullscreen()
    }
  }

  // Same pattern as the bar's `bar-off` flag: FileView can't watch a file that doesn't exist yet, so
  // watch the toggles directory and probe; notch-reserve-toggle also nudges `sync` over IPC.
  Process {
    id: probe
    running: true
    command: ["bash", "-c", "[[ -f \"$1/notch-reserve\" ]] && r=yes || r=no; [[ -f \"$1/bar-peek\" ]] && p=yes || p=no; echo $r $p", "probe", root.togglesDir]
    stdout: SplitParser {
      onRead: function(line) {
        var parts = String(line).trim().split(" ")
        root.reserveOn = parts[0] === "yes"
        root.barPeeking = parts[1] === "yes"
      }
    }
    // A flag can change again while the probe runs (a quick Caps tap); re-probe so state isn't stale.
    property bool pending: false
    onExited: if (pending) { pending = false; running = true }
  }
  FileView {
    path: root.togglesDir
    watchChanges: true
    printErrors: false
    onFileChanged: { if (probe.running) probe.pending = true; else probe.running = true }
  }
  IpcHandler {
    target: "satchlj.notch"
    function sync(): void { probe.running = true }
  }

  // Overlays (menu, clipboard, emoji picker, dialogs) dim the whole screen with a scrim, which would turn the
  // strip grey. A click-through black cap on the Overlay layer keeps it black; a Hyprland layer rule
  // (hypr/notch-snippets.lua: order -1000, no_anim) keeps it above every other overlay. It steps aside while the bar
  // peeks (Caps hold), since the bar then draws light-on-black over the strip itself.
  // The bar view plugins get (PluginBarStateApi) has no peek state, so read the bar-peek flag directly.
  property bool barPeeking: false

  PanelWindow {
    screen: root.panelScreen
    visible: root.guardActive && !root.barPeeking
    anchors { top: true; left: true; right: true }
    implicitHeight: Math.ceil(root.cutoutRows / (root.panelScreen ? root.panelScreen.devicePixelRatio : 2))
    exclusionMode: ExclusionMode.Ignore
    color: "black"
    mask: Region {}
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omarchy-notch-cap"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  }

  PanelWindow {
    screen: root.panelScreen
    visible: root.guardActive
    anchors { top: true; left: true; right: true }
    implicitHeight: Math.ceil(root.cutoutRows / (root.panelScreen ? root.panelScreen.devicePixelRatio : 2))
    exclusiveZone: implicitHeight
    color: "black"
    // Bottom, not Top: windows never enter the reserved strip, so it still shows, and the bar (Top, or
    // Overlay while peeking) always draws above it instead of depending on map order.
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "omarchy-notch-guard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  }
}
