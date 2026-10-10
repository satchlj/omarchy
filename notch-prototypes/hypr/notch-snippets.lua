-- Excerpt from rubra ~/.config/hypr/bindings.lua (after the Super+F block).
-- Super+Alt+F: toggle keeping windows out of the strip beside the notch while the bar is hidden (Caps edge-to-edge
-- mode). Global, persistent flag; ~/.local/bin/notch-reserve-toggle + the satchlj.notch shell plugin.
hl.unbind("SUPER + ALT + F")
o.bind("SUPER + ALT + F", "Windows below the notch (toggle)", "notch-reserve-toggle")

-- Excerpt from rubra ~/.config/hypr/looknfeel.lua (end).
-- rubra: with the notch-reserve toggle on (Super+Alt+F), fullscreen windows become maximized below the notch
-- (satchlj.notch). Nothing else maximizes now, so a workspace with a maximized window = fullscreen: no gaps,
-- border or rounding. See notch-prototypes/README.md.
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0, border_size = 0, no_rounding = true })

-- rubra notch (satchlj.notch): the black guard and the overlay cap appear without fades, and the cap stays above
-- every other overlay (menu, clipboard, emoji scrims) so the strip beside the notch stays black.
hl.layer_rule({ match = { namespace = "^omarchy-notch-(guard|cap)$" }, no_anim = true, animation = "none" })
hl.layer_rule({ match = { namespace = "omarchy-notch-cap" }, order = -1000 })
