# Notch prototypes from an M3 MacBook Air

These are prototypes for the notch design discussion. They are not a pull request.

We built them as user plugins and patches on an M3 MacBook Air (J613, 13.6"), before #14431 merged. That machine
ran the `maralcbr/omarchy-mx-mac` 4.0.4 shell, which has none of #14431's cutout code. **Nothing here has been run on
`quattro` yet.** "Verified" below means on that machine, with screenshots and `hyprctl` output.

## The panel

- 2560x1664 at scale 2. The notch covers **columns 1125–1434** (310 px, centred) and **rows 0–55** (56 px, which is 28
  logical px).
- Measured by eye with a test pattern of numbered rows and columns drawn over the strip. Two runs agreed.
- The 56 rows match omarchy-mac-pkgs' `eDP 2560x1664 top 56`. The 64 rows that m1n1/appledrm crop are the 16:10 crop,
  not the notch.
- The radius of the bottom corners was not measured.
- For comparison, omarchy-mac#569 gives the 16" M2 Max as columns 1543–1913 of 3456, 64 rows, from macOS's
  `NSScreen` auxiliary areas.

`data/display-cutouts.proposed.json` is the J613 entry with an optional horizontal span, `x`/`w` in panel pixels.
`BarModel.parseCutouts` drops unknown keys today, so adding them is backward compatible. A width would let the bar
apply an overflow rule: a crowded right section or a long left section must not run under the notch.

## What's here

### `satchlj.notch/`, `bin/notch-reserve-toggle`, `hypr/notch-snippets.lua`: a "windows below the notch" switch

- **The switch.** `notch-reserve-toggle` flips a global flag that persists across restarts:
  `~/.local/state/omarchy/toggles/notch-reserve`. Run it from whatever key or menu entry you like; no binding is
  proposed.
- **Flag off:** windows may use the strips beside the notch. This is the default.
- **Flag on, bar not covering the strip:** the service plugin maps an empty black layer surface,
  `omarchy-notch-guard`, along the top edge. The layer is on Bottom, as tall as the cutout, and has an exclusive zone.
  "Not covering" means the bar is hidden or on another edge. Hyprland then tiles and maximizes windows below the notch.
  The plugin uses no Hyprland config, so the guard would work on other compositors too.
- **Fullscreen follows the switch.** Hyprland ignores reserved areas for fullscreen windows. So while the flag is on,
  `fullscreen-sync.sh` converts fullscreen windows to internal state 1 (maximized) while keeping their client state.
  The app still believes it is fullscreen, but it is sized below the notch. When the flag goes off, the script turns
  those windows back into true fullscreen. It runs on each toggle and on Hyprland's `fullscreen` and `openwindow`
  events.
- **The cap.** Full-screen scrims (the menu, clipboard, pickers, polkit) used to dim the black strip grey. To stop
  that, the plugin also maps a click-through black cap, `omarchy-notch-cap`, on the Overlay layer. A layer rule with
  `order -1000` keeps it above the other overlays.
- **Verified:** with the flag on, Hyprland reserved `0 28 0 0` and `foot -F` was fullscreen at (0,28) 1280x804.
  With the flag off, it was (0,0) 1280x832. Super+F still left and re-entered fullscreen in both forms.
- **Limits:**
  - The cutout height (56 rows) is hardcoded, and the panel is found by the name prefix `eDP`.
  - The cap shows about 2 frames of grey when an overlay first maps, before Hyprland re-sorts the layers.
  - The plugin reads the `bar-peek` flag directly, because `PluginBarStateApi` has no peek state.
  - The sync is a shell script driven by events. A native Hyprland option, "fullscreen respects reserved areas", would
    be the clean fix.

### `patches/satchlj.bar-notch-strip.patch`

- This is against our fork of the bar, not against Omarchy's.
- With the flag on and the bar hidden on top, a peeking bar paints itself black with light text, so it reads as part
  of the strip whatever the theme is.

### `patches/popup-anchor-by-section.patch`

- The clock and weather panels hardcoded `centerOnBar: true`. Once the center section moved to the right (#14431's
  `centerBesideRight`), their popups therefore opened in the middle of the screen, under the notch.
- This mx-mac version passes the widget's bar section down to the panel. The calendar opening under the clock was
  verified by screenshot.
- The quattro version is the branch
  [`notch-panel-under-widget`](https://github.com/omacom/omarchy/compare/quattro...satchlj:omarchy:notch-panel-under-widget).
  It reads `anchorWindow.centerBesideRight` in `KeyboardPanel` and was not run in a UI. It overlaps the open #14715.

### `patches/overlays-respect-exclusive-zones.patch`

- The menu, clipboard, emoji picker and image picker were changed to use `ExclusionMode.Normal`, so their scrims sit
  inside the work area: below the guard strip, and below a visible bar.
- Verified for the clipboard and the emoji picker.
- Side effect: the bar is no longer dimmed while one of them is open.
- **This does not apply to quattro as is.** These overlays now share `Ui/OverlayWindow.qml`, which reveals content only
  once the surface is screen-sized (`contentReady` compares the window with `targetScreen`). A surface sized to the
  work area would never show.
- There are two ways to adapt it:
  1. **Keep `Ignore` and inset the scrim and content by a safe top.** The safe top is the cutout height while the
     guard is active, or the bar thickness. This is one change in `OverlayWindow.qml` and keeps today's dimmed-bar
     look. We would pick this one.
  2. **Use `Normal`, and have `contentReady` compare against the work area** (the screen minus the monitor's reserved
     area) instead of the full screen.

## How this maps to the open question

The open question: on a notched panel, may windows use the strips beside the notch, and what does fullscreen do
there? We found three options:

- **(a) macOS-like.** Fullscreen sits below the notch, using `fullscreen_state` internal 1 and client 2, and the strip
  stays black.
- **(b) True fullscreen under the notch.** Leave it and document it. Video is usually letterboxed there anyway.
- **(c) A setting.** For example `[notch] windows = "beside" | "below"`. This is what
  these prototypes do, with fullscreen following the setting.
  - This matters most with quattro's "Full screen desktop" (Super+Ctrl+Alt+F: bar off and no gaps). Today that mode
    puts tiled windows under the notch.

Longer term, `xx-cutouts-v1` would let apps decide for themselves. Hyprland doesn't implement it.
