#!/bin/bash
# satchlj.notch helper: make fullscreen follow the notch-reserve toggle.
#   fullscreen-sync.sh on   fullscreen windows (Hyprland internal state 2) become maximized (state 1) below the
#                           notch; the app's own fullscreen state is kept. Converted windows are listed in
#                           $XDG_RUNTIME_DIR/notch-fullscreen.
#   fullscreen-sync.sh off  windows on that list that are still maximized go back to fullscreen.
# Super+F (neo-fullscreen-toggle) treats state 1 as fullscreen, so it can leave either form.
list=${XDG_RUNTIME_DIR:-/tmp}/notch-fullscreen
touch "$list"
clients=$(hyprctl clients -j) || exit 0

set_state() { hyprctl dispatch "hl.dsp.window.fullscreen_state({ internal = $2, client = $3, window = \"address:$1\" })" >/dev/null; }

if [[ $1 == on ]]; then
  # Keep only entries that are still maximized, then convert every fullscreen window.
  jq -r --rawfile l "$list" '($l | split("\n")) as $a | .[] | select(.fullscreen == 1 and (.address as $x | $a | index($x))) | .address' \
    <<<"$clients" >"$list.new"
  while read -r address client; do
    set_state "$address" 1 "$client"
    echo "$address" >>"$list.new"
  done < <(jq -r '.[] | select(.fullscreen == 2) | "\(.address) \(.fullscreenClient)"' <<<"$clients")
  mv "$list.new" "$list"
else
  while read -r address client; do
    set_state "$address" 2 "$client"
  done < <(jq -r --rawfile l "$list" '($l | split("\n")) as $a | .[] | select(.fullscreen == 1 and (.address as $x | $a | index($x))) | "\(.address) \(.fullscreenClient)"' <<<"$clients")
  : >"$list"
fi
