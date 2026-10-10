-- The toggle (notch-reserve-toggle + the satchlj.notch shell plugin) is a global, persistent flag. Bind it to a key
-- of your choice; no binding is proposed here.

-- Excerpt from rubra ~/.config/hypr/looknfeel.lua (end).
-- rubra: with the notch-reserve toggle on, fullscreen windows become maximized below the notch
-- (satchlj.notch). Nothing else maximizes now, so a workspace with a maximized window = fullscreen: no gaps,
-- border or rounding. See notch-prototypes/README.md.
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0, border_size = 0, no_rounding = true })

-- rubra notch (satchlj.notch): the black guard and the overlay cap appear without fades, and the cap stays above
-- every other overlay (menu, clipboard, emoji scrims) so the strip beside the notch stays black.
hl.layer_rule({ match = { namespace = "^omarchy-notch-(guard|cap)$" }, no_anim = true, animation = "none" })
hl.layer_rule({ match = { namespace = "omarchy-notch-cap" }, order = -1000 })
