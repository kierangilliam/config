-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- LG ULTRAWIDE (3840x1600 native; it also advertises 3840x2160 over HDMI, which "preferred" wrongly picks).
-- Sits directly above the laptop panel, horizontally centered.
-- Logical sizes: ultrawide 3840x1600 @ scale 1.25 = 3072x1280; laptop 3456x2234 @ scale 2 = 1728x1117.
hl.monitor({ output = "HDMI-A-1", mode = "3840x1600@60", position = "0x0", scale = 1.25 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "672x1280", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
