-- Hermes owns workspace 1.
-- Other apps that would open there (agent or system) go to workspace 2+.
-- Dialogs, pinned overlays (PiP / webcam), and the screensaver stay put.

local HERMES_WS = 1
local OVERFLOW_WS = "2"

local function class_of(w)
  if type(w) ~= "table" then
    return ""
  end
  return tostring(w.class or w.initial_class or w.initialClass or "")
end

local function title_of(w)
  if type(w) ~= "table" then
    return ""
  end
  return tostring(w.title or w.initial_title or w.initialTitle or "")
end

local function ws_id(w)
  if type(w) ~= "table" then
    return nil
  end
  local ws = w.workspace
  if type(ws) == "number" then
    return ws
  end
  if type(ws) == "table" then
    return tonumber(ws.id)
  end
  return tonumber(ws)
end

local function truthy(v)
  return v == true or v == 1
end

local function is_hermes(w)
  return class_of(w):match("^Hermes$") ~= nil
end

local function is_special(w)
  local id = ws_id(w)
  return id ~= nil and id < 0
end

local function is_overlay_or_dialog(w)
  if type(w) ~= "table" then
    return false
  end
  if truthy(w.modal) or truthy(w.pin) then
    return true
  end
  local class = class_of(w)
  if class:match("xdg%-desktop%-portal") then
    return true
  end
  if class:match("^WebcamOverlay") then
    return true
  end
  if class == "org.omarchy.screensaver" then
    return true
  end
  local title = title_of(w)
  if title:match("^[Oo]pen") or title:match("^[Ss]ave") or title:match("wants to") or title:match("^[Cc]hoose") then
    return true
  end
  return false
end

-- follow=true only for newly opened apps so the camera tracks them.
local function place(w, follow)
  if type(w) ~= "table" then
    return
  end
  if is_hermes(w) then
    if ws_id(w) ~= HERMES_WS then
      hl.dispatch(hl.dsp.window.move({ workspace = tostring(HERMES_WS), follow = false, window = w }))
    end
    return
  end
  if is_special(w) or is_overlay_or_dialog(w) then
    return
  end
  if ws_id(w) == HERMES_WS then
    hl.dispatch(hl.dsp.window.move({
      workspace = OVERFLOW_WS,
      follow = follow and true or false,
      window = w,
    }))
  end
end

o.window("^Hermes$", { workspace = "1" })

-- Tiled clients at map time. Floats include file pickers; window.open handles those.
o.window({
  class = "negative:^Hermes$",
  workspace = "1",
  float = false,
  modal = false,
  pin = false,
}, { workspace = "2" })

hl.on("window.open", function(w)
  place(w, true)
end)

local function sweep()
  local windows = hl.get_windows()
  if type(windows) ~= "table" then
    return
  end
  for _, w in ipairs(windows) do
    place(w, false)
  end
end

hl.on("hyprland.start", sweep)
hl.on("config.reloaded", sweep)
