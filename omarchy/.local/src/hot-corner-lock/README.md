# hot-corner-lock

Move the cursor into the bottom-right corner of any monitor to lock (via `omarchy-system-lock`).
Talks to Hyprland's IPC socket directly, so it idles at ~0% CPU.

Build/install: `cargo install --path . --root ~/.local`
Autostarted from `~/.config/hypr/autostart.lua`.

Env: `HOT_CORNER_MARGIN` (px, default 2), `HOT_CORNER_POLL_MS` (default 150).
