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
o.bind("ALT + SPACE", "Voxtype", "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- SUPER+SHIFT+A was the ChatGPT webapp; use the terminal agent instead.
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "Agent", "omarchy-agent --pick")

-- Webapps I don't use. Freeing SUPER+SHIFT+E also lets it reach apps (VS Code
-- maps it to Focus Explorer, like CTRL+SHIFT+E).
hl.unbind("SUPER + SHIFT + E") -- HEY Email
hl.unbind("SUPER + SHIFT + ALT + E") -- HEY New email
hl.unbind("SUPER + SHIFT + C") -- HEY Calendar
hl.unbind("SUPER + SHIFT + X") -- X
hl.unbind("SUPER + SHIFT + ALT + X") -- X Post
hl.unbind("SUPER + SHIFT + ALT + G") -- WhatsApp
hl.unbind("SUPER + SHIFT + CTRL + G") -- Google Messages
hl.unbind("SUPER + SHIFT + P") -- Google Photos
hl.unbind("SUPER + SHIFT + S") -- Google Maps

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

-- Does a window carry an Omarchy window tag? Dynamic tags carry a trailing
-- "*", so strip it before comparing.
local function window_has_tag(window, name)
  for _, tag in ipairs(window.tags or {}) do
    if tag:gsub("%*$", "") == name then
      return true
    end
  end

  return false
end

local function active_window_has_tag(name)
  local window = hl.get_active_window()
  return window ~= nil and window_has_tag(window, name)
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
-- macOS-style Command shortcuts forwarded to specific apps
-- ===========================================================================
-- forward_in_app(apps, chord): while one of the listed apps is focused, the
-- chord is sent to the window with SUPER swapped for CTRL (Command+W becomes
-- Ctrl+W), so it behaves as it does on macOS. Everywhere else the chord keeps
-- its Omarchy default untouched.
--
-- Nothing about the default is restated here: hypr/keybind-registry.lua hands
-- back the keybind object Omarchy registered for the chord, and on every focus
-- change the default and the forwarding keybind are toggled against each
-- other with keybind:set_enabled. Chords with no default are simply no-ops
-- outside the listed apps.
--
-- Apps are matched by window class (exact) or by an Omarchy window tag. The
-- "chromium-based-browser" tag comes from default/hypr/apps/browser.lua, so
-- there is one definition of what counts as a Chrome-family browser. Webapp
-- windows (chrome-<site>__-Default) do not carry that tag, and that is the
-- behaviour we want: they have no tab bar, so SUPER + W closes them outright.
--
-- An app marked raw gets the chord re-sent unchanged instead of translated.
-- Zed needs this: its vim mode takes over many CTRL chords (CTRL+V is visual
-- block, CTRL+A increments, CTRL+W deletes a word, CTRL+C leaves insert mode),
-- so ~/.config/zed/keymap.json binds super-v, super-a, etc. directly and the
-- SUPER chord just has to get past Omarchy's default.
local vscode = { class = "code" }
local zed = { class = "dev.zed.Zed", raw = true } -- stable channel app id (Preview is dev.zed.Zed-Preview)
local chrome = { tag = "chromium-based-browser" }

local function matching_app(window, apps)
  if not window then
    return nil
  end

  for _, app in ipairs(apps) do
    if app.tag and window_has_tag(window, app.tag) then
      return app
    end
    if app.class and window.class == app.class then
      return app
    end
  end

  return nil
end

-- "SUPER + SHIFT + P" -> mods "SUPER SHIFT", key "P"; SUPER becomes CTRL
-- unless `raw`.
local function split_chord(chord, raw)
  local tokens = {}
  for token in chord:upper():gmatch("[^%s+]+") do
    table.insert(tokens, token)
  end
  local key = table.remove(tokens)
  if not raw then
    for index, token in ipairs(tokens) do
      if token == "SUPER" then
        tokens[index] = "CTRL"
      end
    end
  end

  return table.concat(tokens, " "), key
end

local forwards = {}
local forwarded_chords = {}

-- The optional third argument sends a different chord instead of the
-- SUPER-to-CTRL translation, for shortcuts whose macOS and Linux forms don't
-- line up that way (Command+[ is Alt+Left in Chrome). Raw apps ignore it.
local function forward_in_app(apps, chord, send_chord)
  -- The forwarding keybind takes over the chord's registry slot, so a second
  -- call for the same chord would find this forward instead of the Omarchy
  -- default and leave the default enabled in-app. List every app in one call.
  assert(not forwarded_chords[chord], "forward_in_app: " .. chord .. " is already forwarded; list all apps in one call")
  forwarded_chords[chord] = true

  local mods, key = split_chord(send_chord or chord, send_chord ~= nil)
  local raw_mods, raw_key = split_chord(chord, true)

  local names = {}
  for _, app in ipairs(apps) do
    table.insert(names, app.class or app.tag)
  end

  -- Decided per press, since one chord can serve a translated app and a raw
  -- app at once.
  local function dispatch()
    local app = matching_app(hl.get_active_window(), apps)
    if app and app.raw then
      send_shortcut_once(raw_mods, raw_key)()
    else
      send_shortcut_once(mods, key)()
    end
  end

  -- Look up the default before binding: the forwarding keybind takes over the
  -- chord's registry slot.
  local default = hl.find_keybind(chord)
  local forward = hl.bind(chord, dispatch, {
    description = mods:gsub(" ", "+") .. "+" .. key .. " (" .. table.concat(names, ", ") .. ")",
  })
  forward:set_enabled(false)

  table.insert(forwards, { apps = apps, default = default, forward = forward })
end

local function refresh_forwards()
  local window = hl.get_active_window()

  for _, entry in ipairs(forwards) do
    local in_app = matching_app(window, entry.apps) ~= nil
    entry.forward:set_enabled(in_app)
    if entry.default then
      entry.default:set_enabled(not in_app)
    end
  end
end

hl.on("window.active", refresh_forwards)

forward_in_app({ chrome, vscode, zed }, "SUPER + T") -- new tab / new file / project symbols
forward_in_app({ chrome, vscode, zed }, "SUPER + W") -- close tab / close editor (SUPER + Q still closes the window)
forward_in_app({ chrome }, "SUPER + R") -- reload page
-- Back/forward. ALT + arrows are window focus in Hyprland, but injecting them
-- straight into the window bypasses those bindings, so Chrome still sees them.
forward_in_app({ chrome }, "SUPER + BRACKETLEFT", "ALT + Left")
forward_in_app({ chrome }, "SUPER + BRACKETRIGHT", "ALT + Right")
-- Tab switching. Chrome has no native Command+Shift+[/] binding, so these go
-- to its Ctrl+Shift+Tab / Ctrl+Tab equivalents instead.
forward_in_app({ chrome }, "SUPER + SHIFT + BRACKETLEFT", "CTRL + SHIFT + Tab") -- previous tab
forward_in_app({ chrome }, "SUPER + SHIFT + BRACKETRIGHT", "CTRL + Tab") -- next tab
forward_in_app({ vscode, zed }, "SUPER + S") -- save
forward_in_app({ vscode, zed }, "SUPER + N") -- new file
forward_in_app({ vscode, zed }, "SUPER + P") -- quick open
forward_in_app({ vscode, zed }, "SUPER + SHIFT + P") -- command palette
forward_in_app({ vscode, zed }, "SUPER + SHIFT + X") -- extensions
-- Omarchy's universal copy/paste/cut send CTRL+C/V/X, which vim mode hijacks,
-- so Zed gets these raw too. SUPER + SHIFT + E is already unbound above and
-- reaches Zed without help.
forward_in_app({ zed }, "SUPER + C") -- copy
forward_in_app({ zed }, "SUPER + V") -- paste
forward_in_app({ zed }, "SUPER + X") -- cut

refresh_forwards()

-- ===========================================================================
-- macOS-style select all and jump to document start/end
-- ===========================================================================
-- Command+A and Command+Up/Down in every app, not just editors. Most apps get
-- the Linux equivalent; Zed gets the SUPER chord unchanged, since
-- ~/.config/zed/keymap.json binds super-a / super-up / super-down itself.
-- Terminals skip select all: CTRL+A there is readline's beginning-of-line.
local function document_shortcut(chord, mods, key, skip_in_terminal)
  local raw_mods, raw_key = split_chord(chord, true)

  return function()
    if matching_app(hl.get_active_window(), { zed }) then
      send_shortcut_once(raw_mods, raw_key)()
    elseif not (skip_in_terminal and active_window_is_terminal()) then
      send_shortcut_once(mods, key)()
    end
  end
end

o.bind("SUPER + A", "Select all", document_shortcut("SUPER + A", "CTRL", "A", true))
o.bind("SUPER + UP", "Jump to start of document", document_shortcut("SUPER + UP", "CTRL", "Home"))
o.bind("SUPER + DOWN", "Jump to end of document", document_shortcut("SUPER + DOWN", "CTRL", "End"))
o.bind("SUPER + SHIFT + UP", "Select to start of document", document_shortcut("SUPER + SHIFT + UP", "CTRL SHIFT", "Home"))
o.bind("SUPER + SHIFT + DOWN", "Select to end of document", document_shortcut("SUPER + SHIFT + DOWN", "CTRL SHIFT", "End"))

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

-- ===========================================================================
-- Reset window split
-- ===========================================================================
-- After dragging a split with SUPER + right-drag, snap the focused window's
-- split back to 50/50. 0 as in "reset"; SUPER + 0 is workspace 10 but the
-- CTRL variant is free. Argument order: Hyprland 0.56's Lua layout parser wants
-- "splitratio <ratio> exact", not the wiki's "exact <ratio>".
o.bind("SUPER + CTRL + 0", "Reset window split", hl.dsp.layout("splitratio 1 exact"))
