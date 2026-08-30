-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- macOS-style hot corner: bottom-right locks the screen (~/.local/bin/hot-corner-lock).
o.launch_on_start("env HOT_CORNER_POLL_MS=100 hot-corner-lock")
