-- Demo paint + presentation floats. Loaded only while `hermes-omarchy-demo on`.
-- Does not replace hermes-exclusive.lua (workspace 1 is still Hermes-only).

hl.config({
  decoration = {
    rounding = 8,
    dim_inactive = true,
    dim_strength = 0.15,
    shadow = {
      enabled = true,
      range = 16,
      render_power = 3,
    },
    blur = {
      enabled = true,
      size = 6,
      passes = 2,
    },
  },
  scrolling = {
    column_width = 0.92,
  },
})

-- Stock Omarchy float is 875x600. Camera wants a presentation card, not a dialog.
o.window({ tag = "floating-window" }, {
  size = { "(monitor_w*0.9)", "(monitor_h*0.9)" },
  center = true,
})

-- Capture strip: apps on workspace 2 scroll as nearly-full columns.
hl.workspace_rule({ workspace = "2", layout = "scrolling" })
