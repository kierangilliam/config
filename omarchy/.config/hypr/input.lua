-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- hl.config({
--   input = {
--     -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
--     kb_layout = "us,dk,eu",
--     kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",
--
--     -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
--     kb_variant = "intl",
--
--     -- Change speed of keyboard repeat.
--     repeat_rate = 40,
--     repeat_delay = 250,
--
--     -- Start with numlock on by default.
--     numlock_by_default = true,
--
--     -- Increase sensitivity for mouse/trackpad (default: 0).
--     sensitivity = 0.35,
--
--     -- Turn off mouse acceleration (default: adaptive).
--     accel_profile = "flat",
--
--     touchpad = {
--       -- Use traditional (non-inverse) scrolling.
--       natural_scroll = false,
--
--       -- Re-enable tap-to-click (one-finger tap = left, two-finger = right).
--       tap_to_click = true,
--
--       -- Use two-finger clicks for right-click instead of lower-right corner.
--       clickfinger_behavior = true,
--
--       -- Control the speed of your scrolling.
--       scroll_factor = 0.4,
--
--       -- Enable the touchpad while typing.
--       disable_while_typing = false,
--
--       -- Left-click-and-drag with three fingers.
--       drag_3fg = 1,
--     },
--   },
-- })

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })

-- Faster touchpad scrolling in agent windows (Claude Code etc.).
-- Omarchy boosts (Alacritty|kitty|foot) by 1.5, but omarchy-agent launches foot
-- under the app-id org.omarchy.agent, so that rule never matched these windows.
o.window("org.omarchy.agent", { scroll_touchpad = 1.5 })

-- Slower touchpad scrolling in Chrome only (1.0 = normal, lower = slower).
o.window("google-chrome", { scroll_touchpad = 0.25 })

-- Caps Lock acts as Escape.
-- Replaces Omarchy's default "compose:caps" (Caps Lock as the compose key).
-- Both Shifts together still toggles actual Caps Lock, cleared by a lone Shift.
hl.config({
  input = {
    kb_options = "caps:escape,shift:both_capslock_cancel",
  },
})

-- Three-finger drag: press three fingers and move to left-click-and-drag.
-- Lets you select text (and drag windows/files) without holding a click.
hl.config({
  input = {
    touchpad = {
      drag_3fg = 1,
    },
  },
})
