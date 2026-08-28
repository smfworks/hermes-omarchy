-- While smf.scene-card is up, Super+W and Escape dismiss the overlay.
-- They must NOT close Hermes underneath (the card is layer-shell, not a window).
-- SUPER+W is rebound only for the life of the layer; Close window is restored after.

local scene_layers = 0
local scene_binds = {}

local function hide_scene()
  return hl.dsp.exec_cmd("omarchy-shell -q shell hide smf.scene-card")
end

hl.on("layer.opened", function(layer)
  if layer.namespace ~= "smf-scene-card" then
    return
  end
  scene_layers = scene_layers + 1
  if scene_layers ~= 1 then
    return
  end
  -- Was: Close window. Restored on layer.closed.
  hl.unbind("SUPER + W")
  scene_binds = {
    hl.bind("SUPER + W", hide_scene(), { description = "Dismiss scene card" }),
    hl.bind("ESCAPE", hide_scene(), { description = "Dismiss scene card" }),
  }
end)

hl.on("layer.closed", function(layer)
  if layer.namespace ~= "smf-scene-card" or scene_layers <= 0 then
    return
  end
  scene_layers = scene_layers - 1
  if scene_layers ~= 0 then
    return
  end
  for _, keybind in ipairs(scene_binds) do
    keybind:unbind()
  end
  scene_binds = {}
  o.bind("SUPER + W", "Close window", hl.dsp.window.close())
end)
