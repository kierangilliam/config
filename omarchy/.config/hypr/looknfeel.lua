-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- macOS-style corners (trial)
hl.config({
  decoration = {
    rounding = 12,
    rounding_power = 4.0,

    shadow = {
      enabled = true,
      range = 24,
      render_power = 3,
      color = "rgba(00000055)",
    },
  },
})

-- Extra breathing room between the bar and the top of windows.
-- gaps_out order: top, right, bottom, left
hl.config({
  general = {
    gaps_out = { top = 10, right = 10, bottom = 10, left = 10 },
  },
})

-- Focus is shown by shadow depth and a slight dim, not a colored border.
-- Borders are a neutral hairline so they do not change with the theme accent.
local hairline_active = "rgba(ffffff22)"
local hairline_inactive = "rgba(ffffff12)"
hl.config({
  general = {
    border_size = 1,
    col = {
      active_border = hairline_active,
      inactive_border = hairline_inactive,
    },
  },
  group = {
    col = {
      border_active = hairline_active,
      border_inactive = hairline_inactive,
      border_locked_active = hairline_active,
      border_locked_inactive = hairline_inactive,
    },
  },
  decoration = {
    shadow = {
      enabled = true,
      range = 30,
      render_power = 3,
      color = "rgba(00000077)",
      color_inactive = "rgba(00000030)",
    },
    dim_inactive = true,
    dim_strength = 0.08,
  },
})
