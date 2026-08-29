-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- SUPER+SHIFT+A was the ChatGPT webapp; use the terminal agent instead.
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "Agent", "omarchy-agent --pick")

-- ===========================================================================
-- macOS-style text navigation on the Command (SUPER) key
-- ===========================================================================
-- Injects a real chord into the focused surface. Same approach Omarchy uses
-- for its universal clipboard bindings; see:
--   /usr/share/omarchy/default/hypr/bindings/clipboard.lua
-- Mods are passed explicitly and the window target is omitted so the chord
-- reaches layer-shell surfaces (Omarchy panels) too, not just normal windows.
-- The down/up split works around Hyprland send_key_state sometimes leaving
-- synthetic key state stuck/repeating.
--   https://github.com/hyprwm/Hyprland/discussions/14099
local function send_shortcut_once(mods, key)
  return function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))

    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
end

-- Send several chords in order, 100ms apart, so the focused app processes them
-- as distinct keystrokes rather than one mashed chord. Each entry is
-- { mods, key }; mods may be "" for a bare key.
local function send_shortcut_sequence(chords)
  return function()
    for index, chord in ipairs(chords) do
      local function press()
        hl.dispatch(hl.dsp.send_key_state({ mods = chord[1], key = chord[2], state = "down" }))

        hl.timer(function()
          hl.dispatch(hl.dsp.send_key_state({ mods = chord[1], key = chord[2], state = "up" }))
        end, { timeout = 50, type = "oneshot" })
      end

      if index == 1 then
        press()
      else
        hl.timer(press, { timeout = (index - 1) * 100, type = "oneshot" })
      end
    end
  end
end

-- Does the focused window carry an Omarchy window tag? Dynamic tags carry a
-- trailing "*", so strip it before comparing.
local function active_window_has_tag(name)
  local window = hl.get_active_window()
  if not window then
    return false
  end

  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == name then
      return true
    end
  end

  return false
end

-- --- Rehome the window-management bindings that sit on the arrows ----------

-- Was: directional window focus. Moves to SUPER + CTRL + arrows below.
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")

-- Was: swap window. Moves to SHIFT + ALT + arrows below.
hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
hl.unbind("SUPER + SHIFT + UP")
hl.unbind("SUPER + SHIFT + DOWN")

-- Was: grouped window focus. Moves to SUPER + SHIFT + CTRL + arrows below.
hl.unbind("SUPER + CTRL + LEFT")
hl.unbind("SUPER + CTRL + RIGHT")

-- Was: move window to group. Moves to SUPER + CTRL + arrows below, trading
-- places with window focus.
hl.unbind("SUPER + ALT + LEFT")
hl.unbind("SUPER + ALT + RIGHT")
hl.unbind("SUPER + ALT + UP")
hl.unbind("SUPER + ALT + DOWN")

-- Was: toggle window transparency. Moves to SUPER + SHIFT + CTRL + BACKSPACE
-- below, freeing Command+Backspace for delete-to-start-of-line.
-- Toggle window gaps keeps its default SUPER + SHIFT + BACKSPACE.
hl.unbind("SUPER + BACKSPACE")

-- --- New homes for the displaced window-management bindings ----------------

-- Focus is the most frequent window action, so it gets the cheapest chord on
-- this keyboard: the arrow cluster sits directly beside the right Option key,
-- making bare ALT + arrows a one-handed right-side press with no left-hand
-- travel at all. Cost: ALT + LEFT/RIGHT no longer reaches apps, so browser
-- Back/Forward is gone, and CTRL + arrows word navigation stays as-is.
o.bind("ALT + LEFT", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("ALT + RIGHT", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("ALT + UP", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("ALT + DOWN", "Focus on below window", hl.dsp.focus({ direction = "d" }))

-- Moving a window into a group is rare, so it inherits the corner chord that
-- focus just vacated.
o.bind("SUPER + CTRL + LEFT", "Move window to group on left", hl.dsp.window.move({ into_group = "l" }))
o.bind("SUPER + CTRL + RIGHT", "Move window to group on right", hl.dsp.window.move({ into_group = "r" }))
o.bind("SUPER + CTRL + UP", "Move window to group on top", hl.dsp.window.move({ into_group = "u" }))
o.bind("SUPER + CTRL + DOWN", "Move window to group on bottom", hl.dsp.window.move({ into_group = "d" }))

-- Swap sits one modifier above focus: ALT + arrows moves the focus, adding
-- SHIFT moves the window itself.
o.bind("SHIFT + ALT + LEFT", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SHIFT + ALT + RIGHT", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SHIFT + ALT + UP", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SHIFT + ALT + DOWN", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

-- Group navigation is linear (prev/next), so only left/right are meaningful;
-- SUPER + SHIFT + CTRL + UP/DOWN are left free.
o.bind("SUPER + SHIFT + CTRL + LEFT", "Move grouped window focus left", hl.dsp.group.prev())
o.bind("SUPER + SHIFT + CTRL + RIGHT", "Move grouped window focus right", hl.dsp.group.next())

o.bind("SUPER + SHIFT + CTRL + BACKSPACE", "Toggle window transparency", "omarchy-hyprland-window-transparency-toggle")

-- --- The macOS text navigation itself --------------------------------------

o.bind("SUPER + LEFT", "Jump to start of line", send_shortcut_once("", "Home"))
o.bind("SUPER + RIGHT", "Jump to end of line", send_shortcut_once("", "End"))
o.bind("SUPER + SHIFT + LEFT", "Select to start of line", send_shortcut_once("SHIFT", "Home"))
o.bind("SUPER + SHIFT + RIGHT", "Select to end of line", send_shortcut_once("SHIFT", "End"))

-- macOS Command+Delete. Terminals have no text selection, so SHIFT+Home only
-- moves the cursor and the BackSpace after it deletes nothing; they need
-- readline's CTRL+U (unix-line-discard) instead. Everything else gets the
-- generic select-then-delete pair, which works in editors, browsers and
-- GTK/Qt inputs alike.
--
-- Terminal detection reuses Omarchy's own "terminal" tag, defined in
-- default/hypr/apps/terminals.lua, so there is one definition of what counts
-- as a terminal.
local function active_window_is_terminal()
  return active_window_has_tag("terminal")
end

local delete_to_line_start_text = send_shortcut_sequence({ { "SHIFT", "Home" }, { "", "BackSpace" } })
local delete_to_line_start_terminal = send_shortcut_once("CTRL", "U")

o.bind("SUPER + BACKSPACE", "Delete to start of line", function()
  if active_window_is_terminal() then
    delete_to_line_start_terminal()
  else
    delete_to_line_start_text()
  end
end)

-- ===========================================================================
-- macOS-style tab management in Chrome
-- ===========================================================================
-- SUPER + T and SUPER + W keep their Omarchy meanings everywhere except a real
-- Chrome window, where they become new tab / close tab. The browser test
-- reuses the "chromium-based-browser" tag from default/hypr/apps/browser.lua,
-- so there is one definition of what counts as a Chrome-family browser.
--
-- Webapp windows (chrome-<site>__-Default) do not carry that tag, and that is
-- the behaviour we want: they have no tab bar, so SUPER + W should close them
-- outright. SUPER + Q still closes a whole Chrome window, tabs and all.
local function in_chrome(chrome_action, default_action)
  return function()
    if active_window_has_tag("chromium-based-browser") then
      chrome_action()
    else
      hl.dispatch(default_action)
    end
  end
end

hl.unbind("SUPER + T")
o.bind(
  "SUPER + T",
  "New tab (Chrome) / toggle window floating",
  in_chrome(send_shortcut_once("CTRL", "T"), hl.dsp.window.float({ action = "toggle" }))
)

hl.unbind("SUPER + W")
o.bind(
  "SUPER + W",
  "Close tab (Chrome) / close window",
  in_chrome(send_shortcut_once("CTRL", "W"), hl.dsp.window.close())
)

-- SUPER + R is unbound by default, so it only needs to do anything in Chrome:
-- macOS Command+R reload. Outside Chrome it is a deliberate no-op.
o.bind(
  "SUPER + R",
  "Reload page (Chrome)",
  in_chrome(send_shortcut_once("CTRL", "R"), hl.dsp.exec_cmd("true"))
)

-- ===========================================================================
-- macOS-style screenshot to clipboard
-- ===========================================================================
-- Command+Ctrl+Shift+4 on macOS: pick a region, copy it to the clipboard only
-- (no file written). The default SUPER + F11 region binding still saves a file.
-- The stock "copy" mode is silent, so notify on success for feedback.
o.bind(
  "SUPER + SHIFT + CTRL + 4",
  "Screenshot region to clipboard",
  "omarchy-capture-screenshot region copy && omarchy-notification-send 'Screenshot copied to clipboard' -t 2000"
)
