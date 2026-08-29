.pragma library

// Parsing, deltas, formatting, and canvas painters for the iStat panel.
// Ported from istat-mon's sysinfo.py / graphs.py.

var HISTORY = 90

// ------------------------------------------------------------ snapshot
function parseSnapshot(text) {
  var snap = { clk: 100, page: 4096, stat: {}, mem: {}, load: [0, 0, 0], uptime: 0, zram: 0, psi: 0, procs: [] }
  var section = ""
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    if (line.charAt(0) === "@") { section = line.slice(1).trim(); continue }
    if (!line.trim()) continue
    var parts = line.trim().split(/\s+/)
    switch (section) {
      case "const":
        if (parts[0] === "clk_tck") snap.clk = Number(parts[1]) || 100
        else if (parts[0] === "pagesize") snap.page = Number(parts[1]) || 4096
        break
      case "stat":
        snap.stat[parts[0]] = parts.slice(1).map(Number)
        break
      case "mem": {
        var m = line.match(/^(\w+):\s+(\d+)/)
        if (m) snap.mem[m[1]] = Number(m[2]) * 1024
        break
      }
      case "load":
        snap.load = parts.slice(0, 3).map(Number)
        break
      case "uptime":
        snap.uptime = Number(parts[0]) || 0
        break
      case "zram":
        snap.zram += Number(parts[0]) || 0
        break
      case "psi":
        if (parts[0] === "some") {
          var p = line.match(/avg10=([\d.]+)/)
          if (p) snap.psi = Number(p[1])
        }
        break
      case "procs":
        if (parts.length >= 5)
          snap.procs.push({ pid: Number(parts[0]), start: Number(parts[1]), ticks: Number(parts[2]),
                            rss: Number(parts[3]), name: parts.slice(4).join(" ") })
        break
    }
  }
  return snap
}

// ----------------------------------------------------------------- CPU
function splitCpu(v) {
  v = (v || []).slice()
  while (v.length < 10) v.push(0)
  var user = v[0] - v[8], nice = v[1] - v[9]
  var system = v[2] + v[5] + v[6] + v[7]
  var idle = v[3] + v[4]
  return { user: user, nice: nice, system: system, idle: idle, total: user + nice + system + idle }
}

function clamp(x) { return Math.max(0, Math.min(100, x)) }

function cpuDelta(prevStat, curStat) {
  function pct(key) {
    var a = splitCpu(prevStat[key]), b = splitCpu(curStat[key])
    var dt = b.total - a.total
    if (dt <= 0) return { user: 0, nice: 0, system: 0, idle: 100 }
    return { user: 100 * (b.user - a.user) / dt, nice: 100 * (b.nice - a.nice) / dt,
             system: 100 * (b.system - a.system) / dt, idle: 100 * (b.idle - a.idle) / dt }
  }
  var all = pct("cpu")
  var keys = Object.keys(curStat).filter(function(k) { return k !== "cpu" })
    .sort(function(a, b) { return Number(a.slice(3)) - Number(b.slice(3)) })
  var cores = keys.map(function(k) { return clamp(100 - pct(k).idle) })
  return { user: all.user, nice: all.nice, system: all.system, idle: all.idle, busy: clamp(100 - all.idle), cores: cores }
}

// -------------------------------------------------------------- Memory
function memStats(snap) {
  var m = snap.mem
  function g(k) { return m[k] || 0 }
  var shmem = g("Shmem")
  var total = g("MemTotal"), available = g("MemAvailable")
  var used = Math.max(0, total - available)
  return {
    total: total, free: g("MemFree"), available: available,
    app: g("AnonPages") + shmem,
    wired: g("Unevictable") + g("SUnreclaim") + g("KernelStack") + g("PageTables"),
    compressed: g("Zswapped") + snap.zram,
    cached: Math.max(0, g("Cached") + g("Buffers") + g("SReclaimable") - shmem),
    swapTotal: g("SwapTotal"), swapUsed: g("SwapTotal") - g("SwapFree"),
    pressure: snap.psi,
    used: used, usedPct: total ? 100 * used / total : 0
  }
}

// ----------------------------------------------------------- Processes
function procDelta(prevProcs, curProcs, dtSec, clk, page) {
  var prev = {}
  for (var i = 0; i < prevProcs.length; i++) prev[prevProcs[i].pid] = prevProcs[i]
  return curProcs.map(function(p) {
    var q = prev[p.pid]
    var cpu = (q && q.start === p.start && dtSec > 0) ? 100 * (p.ticks - q.ticks) / clk / dtSec : 0
    return { name: p.name, cpu: Math.max(0, cpu), rss: p.rss * page }
  })
}

function topBy(list, key, n) {
  return list.slice().sort(function(a, b) { return b[key] - a[key] }).slice(0, n)
}

var ICON_ALIASES = {
  "chrome": "google-chrome", "google-chrome-stable": "google-chrome", "code": "visual-studio-code",
  "Hyprland": "preferences-desktop-display", "ghostty": "com.mitchellh.ghostty", "kitty": "kitty",
  "alacritty": "Alacritty", "python3": "python", "node": "nodejs"
}

function iconCandidates(name) {
  var out = []
  if (ICON_ALIASES[name]) out.push(ICON_ALIASES[name])
  out.push(name)
  if (name.toLowerCase() !== name) out.push(name.toLowerCase())
  return out
}

function hueFor(name) {
  var h = 0
  for (var i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0
  return (h % 1000) / 1000
}

// ------------------------------------------------------------ Formatting
function fmtBytes(n, decimals) {
  if (decimals === undefined) decimals = 1
  var units = ["B", "KB", "MB", "GB", "TB"]
  var i = 0
  n = Number(n) || 0
  while (n >= 1000 && i < units.length - 1) { n /= 1000; i++ }
  if (i === 0) return Math.round(n) + " B"
  return n.toFixed(n < 100 ? decimals : 0) + " " + units[i]
}

function fmtUptime(sec) {
  sec = Math.floor(sec)
  var d = Math.floor(sec / 86400); sec -= d * 86400
  var h = Math.floor(sec / 3600); sec -= h * 3600
  var m = Math.floor(sec / 60)
  if (d) return d + "d " + h + "h " + m + "m"
  if (h) return h + "h " + m + "m"
  return m + "m"
}

function shortModel(s) {
  s = String(s || "").replace(/\0/g, "").trim()
  var hit = s.match(/\b(M\d+(?: (?:Pro|Max|Ultra))?)\b/)
  if (hit && s.indexOf("Apple") === 0) return "Apple " + hit[1]
  s = s.replace(/\((R|TM)\)/g, "").replace(/\s+(CPU|Processor)\s+@.*$/, "")
  return s.replace(/\s{2,}/g, " ").trim()
}

function push(arr, v, max) {
  var out = arr.slice()
  out.push(v)
  while (out.length > max) out.shift()
  return out
}

// -------------------------------------------------------------- Painters
function rgba(c, a) {
  return "rgba(" + Math.round(c.r * 255) + "," + Math.round(c.g * 255) + "," + Math.round(c.b * 255) + "," + a + ")"
}

function rrect(ctx, x, y, w, h, r) {
  r = Math.max(0, Math.min(r, w / 2, h / 2))
  ctx.beginPath()
  ctx.moveTo(x + r, y)
  ctx.lineTo(x + w - r, y); ctx.arc(x + w - r, y + r, r, -Math.PI / 2, 0)
  ctx.lineTo(x + w, y + h - r); ctx.arc(x + w - r, y + h - r, r, 0, Math.PI / 2)
  ctx.lineTo(x + r, y + h); ctx.arc(x + r, y + h - r, r, Math.PI / 2, Math.PI)
  ctx.lineTo(x, y + r); ctx.arc(x + r, y + r, r, Math.PI, 3 * Math.PI / 2)
  ctx.closePath()
}

// Stacked area graph; series is bottom-to-top [{data: [...percent], color}],
// newest sample last. `fg` tints the background/grid so light themes work.
function paintHistory(ctx, w, h, series, maxlen, fg) {
  ctx.clearRect(0, 0, w, h)
  ctx.save()
  rrect(ctx, 0, 0, w, h, 6)
  ctx.fillStyle = rgba(fg, 0.05)
  ctx.fill()
  ctx.clip()
  ctx.strokeStyle = rgba(fg, 0.07)
  ctx.lineWidth = 1
  ctx.beginPath()
  var fr = [0.25, 0.5, 0.75]
  for (var k = 0; k < fr.length; k++) { var y = Math.round(h * fr[k]) + 0.5; ctx.moveTo(0, y); ctx.lineTo(w, y) }
  ctx.stroke()
  if (series.length && series[0].data.length >= 2) {
    var n = series[0].data.length
    var step = w / Math.max(1, maxlen - 1)
    var x0 = w - (n - 1) * step
    var base = new Array(n).fill(0)
    for (var s = 0; s < series.length; s++) {
      var vals = series[s].data, color = series[s].color
      var top = [], ys = [], ybs = []
      for (var i = 0; i < n; i++) {
        top[i] = base[i] + vals[i]
        ys[i] = h - (h - 1) * clamp(top[i]) / 100
        ybs[i] = h - (h - 1) * clamp(base[i]) / 100
      }
      ctx.beginPath()
      ctx.moveTo(x0, ybs[0])
      for (i = 0; i < n; i++) ctx.lineTo(x0 + i * step, ys[i])
      for (i = n - 1; i >= 0; i--) ctx.lineTo(x0 + i * step, ybs[i])
      ctx.closePath()
      ctx.fillStyle = rgba(color, 0.35)
      ctx.fill()
      ctx.beginPath()
      ctx.moveTo(x0, ys[0])
      for (i = 1; i < n; i++) ctx.lineTo(x0 + i * step, ys[i])
      ctx.strokeStyle = rgba(color, 1)
      ctx.lineWidth = 1.5
      ctx.lineJoin = "round"
      ctx.stroke()
      base = top
    }
  }
  ctx.restore()
}

// Vertical per-core bars.
function paintBars(ctx, w, h, values, color, fg) {
  ctx.clearRect(0, 0, w, h)
  var n = values.length
  if (!n) return
  var gap = 3
  var bw = (w - gap * (n - 1)) / n
  for (var i = 0; i < n; i++) {
    var x = i * (bw + gap)
    rrect(ctx, x, 0, bw, h, 2)
    ctx.fillStyle = rgba(fg, 0.07)
    ctx.fill()
    var bh = Math.max(2, h * clamp(values[i]) / 100)
    rrect(ctx, x, h - bh, bw, bh, 2)
    ctx.fillStyle = rgba(color, 1)
    ctx.fill()
  }
}

// Horizontal segmented bar; [{frac, color}], fractions sum to <= 1.
function paintSegments(ctx, w, h, segments, fg) {
  ctx.clearRect(0, 0, w, h)
  ctx.save()
  rrect(ctx, 0, 0, w, h, 4)
  ctx.fillStyle = rgba(fg, 0.08)
  ctx.fill()
  ctx.clip()
  var x = 0
  for (var i = 0; i < segments.length; i++) {
    var sw = w * Math.max(0, segments[i].frac)
    if (sw <= 0) continue
    ctx.fillStyle = rgba(segments[i].color, 1)
    ctx.fillRect(x, 0, sw, h)
    x += sw
  }
  x = 0
  ctx.strokeStyle = "rgba(0,0,0,0.35)"
  ctx.lineWidth = 1
  ctx.beginPath()
  for (i = 0; i < segments.length - 1; i++) {
    x += w * Math.max(0, segments[i].frac)
    if (x > 0 && x < w) { ctx.moveTo(Math.round(x) + 0.5, 0); ctx.lineTo(Math.round(x) + 0.5, h) }
  }
  ctx.stroke()
  ctx.restore()
}
