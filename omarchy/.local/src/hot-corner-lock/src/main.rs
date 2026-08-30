//! macOS-style hot corner for Hyprland: park the cursor in the bottom-right
//! corner of any monitor and the screen locks via `omarchy-system-lock`.
//!
//! Polls Hyprland's IPC socket directly (no forking per poll).

use std::env;
use std::io::{Read, Write};
use std::os::unix::net::UnixStream;
use std::process::Command;
use std::thread::sleep;
use std::time::{Duration, Instant};

const MONITOR_REFRESH: Duration = Duration::from_secs(5);

struct Monitor {
    x0: i64,
    y0: i64,
    right: i64,
    bottom: i64,
}

fn socket_path() -> String {
    let runtime = env::var("XDG_RUNTIME_DIR").expect("XDG_RUNTIME_DIR not set");
    let sig = env::var("HYPRLAND_INSTANCE_SIGNATURE").expect("HYPRLAND_INSTANCE_SIGNATURE not set");
    format!("{runtime}/hypr/{sig}/.socket.sock")
}

fn query(path: &str, cmd: &str) -> std::io::Result<String> {
    let mut s = UnixStream::connect(path)?;
    s.write_all(cmd.as_bytes())?;
    let mut out = String::new();
    s.read_to_string(&mut out)?;
    Ok(out)
}

/// Pull a numeric field out of Hyprland's JSON without a JSON dependency.
/// Fields we need are all top-level scalars per monitor object.
fn field(obj: &str, key: &str) -> Option<f64> {
    let needle = format!("\"{key}\":");
    let start = obj.find(&needle)? + needle.len();
    let rest = obj[start..].trim_start();
    let end = rest.find(|c: char| c == ',' || c == '}' || c == '\n').unwrap_or(rest.len());
    rest[..end].trim().parse().ok()
}

fn monitors(path: &str) -> std::io::Result<Vec<Monitor>> {
    let json = query(path, "j/monitors")?;
    // Split on the per-monitor object boundary `},{` at the top level. Nested
    // objects (activeWorkspace etc.) end with `}` followed by `,\n    "` not `{`.
    let mons = json
        .split("},{")
        .filter_map(|obj| {
            let x = field(obj, "x")?;
            let y = field(obj, "y")?;
            let mut w = field(obj, "width")?;
            let mut h = field(obj, "height")?;
            let scale = field(obj, "scale").unwrap_or(1.0);
            let transform = field(obj, "transform").unwrap_or(0.0) as i64;
            if transform % 2 == 1 {
                std::mem::swap(&mut w, &mut h);
            }
            Some(Monitor {
                x0: x as i64,
                y0: y as i64,
                right: x as i64 + (w / scale) as i64,
                bottom: y as i64 + (h / scale) as i64,
            })
        })
        .collect();
    Ok(mons)
}

fn cursor(path: &str) -> Option<(i64, i64)> {
    let s = query(path, "cursorpos").ok()?;
    let (x, y) = s.trim().split_once(',')?;
    Some((x.trim().parse().ok()?, y.trim().parse().ok()?))
}

fn locked() -> bool {
    Command::new("omarchy-hyprland-session-locked")
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}

fn main() {
    let margin: i64 = env::var("HOT_CORNER_MARGIN").ok().and_then(|v| v.parse().ok()).unwrap_or(2);
    let poll = Duration::from_millis(
        env::var("HOT_CORNER_POLL_MS").ok().and_then(|v| v.parse().ok()).unwrap_or(150),
    );
    let path = socket_path();

    let mut mons: Vec<Monitor> = Vec::new();
    let mut mons_at: Option<Instant> = None;
    let mut in_corner = false;

    loop {
        sleep(poll);

        if mons_at.map_or(true, |t| t.elapsed() > MONITOR_REFRESH) {
            if let Ok(m) = monitors(&path) {
                mons = m;
                mons_at = Some(Instant::now());
            }
        }
        let Some((cx, cy)) = cursor(&path) else { continue };

        let hit = mons.iter().any(|m| {
            cx >= m.x0
                && cx < m.right
                && cy >= m.y0
                && cy < m.bottom
                && cx >= m.right - margin
                && cy >= m.bottom - margin
        });

        if hit && !in_corner && !locked() {
            let _ = Command::new("omarchy-system-lock").spawn();
        }
        in_corner = hit;
    }
}
