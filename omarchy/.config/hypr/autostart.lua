-- Extra autostart processes.
-- o.launch_on_start("my-service")

-- macOS-style hot corner: bottom-right locks the screen (~/.local/bin/hot-corner-lock).
o.launch_on_start("env HOT_CORNER_POLL_MS=100 hot-corner-lock")

-- Reopen last session's windows on their workspaces, then keep snapshotting (~/.local/bin/omarchy-window-session).
o.launch_on_start("omarchy-window-session daemon")
