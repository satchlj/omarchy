#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
// Comments stripped: a wiring assertion that a commented-out line can satisfy
// passes while the widget is broken.
const read = (path) => fs.readFileSync(root + '/' + path, 'utf8').replace(/^\s*\/\/.*$/gm, '')

const bar = read('shell/plugins/bar/Bar.qml')
const base = read('shell/Ui/BarWidget.qml')

// ---- the bar tells each widget which section it sits in
assert(/property string barRegion: ""/.test(base), 'bar widgets declare the barRegion they are given')
assert(/if \("barRegion" in target\) target\.barRegion = region/.test(bar), 'the bar injects each slot\'s region as barRegion')
assert(/onRegionChanged: injectProps\(\)/.test(bar), 'a widget moved to another section is told its new region')

// ---- calendar and weather center only from the center section
for (const name of ['clock', 'weather']) {
  const widget = read(`shell/plugins/panels/${name}/BarWidget.qml`)
  const panel = read(`shell/plugins/panels/${name}/Panel.qml`)
  assert(/property bool centerOnBar: true/.test(panel), `${name} panel takes centerOnBar as a property`)
  assert(/centerOnBar: root\.centerOnBar/.test(panel), `${name} panel positions its card from that property`)
  assert(!/centerOnBar: true\s*\n\s*focusTarget/.test(panel), `${name} panel no longer hardcodes a centered card`)
  assert(/target\.centerOnBar = root\.barRegion === "" \|\| root\.barRegion === "center"/.test(widget),
    `${name} widget centers its popup only from the bar's center section`)
  assert(/onBarRegionChanged: injectPanel\(\)/.test(widget), `${name} widget re-anchors its popup when it changes section`)
}
JS
