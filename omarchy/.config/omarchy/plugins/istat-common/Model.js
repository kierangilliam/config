.pragma library

// Parsing, deltas, formatting, and canvas painters shared by the iStat
// CPU / Memory / Network widgets. Ported from istat-mon's sysinfo.py / graphs.py.

var HISTORY = 90

// ------------------------------------------------------------ snapshot
function parseSnapshot(text) {
  var snap = { clk: 100, page: 4096, stat: {}, mem: {}, load: [0, 0, 0], uptime: 0, zram: 0, psi: 0, procs: [],
               net: {}, addr: {}, route: { iface: "", gateway: "" }, wifi: {} }
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
      case "net":
        if (parts.length >= 3) snap.net[parts[0]] = { rx: Number(parts[1]) || 0, tx: Number(parts[2]) || 0 }
        break
      case "addr":
        if (parts.length >= 2) snap.addr[parts[0]] = parts[1]
        break
      case "route":
        snap.route = { iface: parts[0] || "", gateway: parts[1] || "" }
        break
      case "wifi":
        if (parts.length >= 2) snap.wifi[parts[0]] = parts.slice(1).join(" ")
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

// ------------------------------------------------------------- Network
// Pick the interface to report: the configured one if it exists, else the
// default route's, else the first non-loopback interface with traffic.
function pickIface(snap, wanted) {
  if (wanted && snap.net[wanted]) return wanted
  if (snap.route.iface && snap.net[snap.route.iface]) return snap.route.iface
  var best = "", bestBytes = -1
  for (var k in snap.net) {
    if (k === "lo") continue
    var b = snap.net[k].rx + snap.net[k].tx
    if (b > bestBytes) { best = k; bestBytes = b }
  }
  return best
}

// Bytes/sec for one interface between two snapshots; 0 on a counter reset.
function netDelta(prevSnap, curSnap, iface, dtSec) {
  var a = prevSnap && prevSnap.net[iface], b = curSnap.net[iface]
  if (!a || !b || dtSec <= 0) return { up: 0, down: 0 }
  return { up: Math.max(0, (b.tx - a.tx) / dtSec), down: Math.max(0, (b.rx - a.rx) / dtSec) }
}

// [{ name, ip, ssid, rx, tx }] for every interface except loopback,
// primary first, then the rest alphabetically.
function ifaceList(snap, primary) {
  var out = []
  for (var k in snap.net) {
    if (k === "lo") continue
    out.push({ name: k, ip: snap.addr[k] || "", ssid: snap.wifi[k] || "", rx: snap.net[k].rx, tx: snap.net[k].tx })
  }
  out.sort(function(x, y) {
    if (x.name === primary) return -1
    if (y.name === primary) return 1
    return x.name < y.name ? -1 : x.name > y.name ? 1 : 0
  })
  return out
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

// Throughput. `compact` keeps the bar label short and stable: at most three
// significant digits ("0 B/s", "12.3 KB/s", "980 KB/s", "1.2 MB/s").
function fmtRate(bytesPerSec, compact) {
  var n = Number(bytesPerSec) || 0
  var units = ["B/s", "KB/s", "MB/s", "GB/s"]
  var i = 0
  while (n >= 1000 && i < units.length - 1) { n /= 1000; i++ }
  var s
  if (i === 0) s = String(Math.round(n))
  else if (compact) s = n < 10 ? n.toFixed(1) : String(Math.round(n))
  else s = n.toFixed(n < 100 ? 1 : 0)
  return s + " " + units[i]
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

// Overlapping (not stacked) area lines auto-scaled to the largest sample in
// view; series is [{data: [...values], color}], newest sample last. Used for
// network throughput where the two directions share one graph.
function paintLines(ctx, w, h, series, maxlen, fg) {
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
  var peak = 1
  for (var s = 0; s < series.length; s++)
    for (var i = 0; i < series[s].data.length; i++) peak = Math.max(peak, series[s].data[i])
  for (s = 0; s < series.length; s++) {
    var vals = series[s].data, color = series[s].color, n = vals.length
    if (n < 2) continue
    var step = w / Math.max(1, maxlen - 1)
    var x0 = w - (n - 1) * step
    function yAt(v) { return h - (h - 2) * Math.min(1, v / peak) }
    ctx.beginPath()
    ctx.moveTo(x0, h)
    for (i = 0; i < n; i++) ctx.lineTo(x0 + i * step, yAt(vals[i]))
    ctx.lineTo(x0 + (n - 1) * step, h)
    ctx.closePath()
    ctx.fillStyle = rgba(color, 0.25)
    ctx.fill()
    ctx.beginPath()
    ctx.moveTo(x0, yAt(vals[0]))
    for (i = 1; i < n; i++) ctx.lineTo(x0 + i * step, yAt(vals[i]))
    ctx.strokeStyle = rgba(color, 1)
    ctx.lineWidth = 1.5
    ctx.lineJoin = "round"
    ctx.stroke()
  }
  ctx.restore()
  return peak
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
