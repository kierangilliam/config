#!/bin/sh
# One-shot system snapshot for the iStat widgets. Each section starts with "@name".
# Usage: collect.sh cpu|mem|net   (no argument = everything)
what="${1:-all}"

want() { [ "$what" = all ] || [ "$what" = "$1" ]; }

procs() {
  echo "@procs"
  # pid starttime cputicks rss(pages) name
  cat /proc/[0-9]*/stat 2>/dev/null | awk '{
    l = index($0, "(")
    if (l == 0 || !match($0, /\)[^)]*$/)) next
    r = RSTART
    pid = substr($0, 1, l - 2)
    comm = substr($0, l + 1, r - l - 1)
    n = split(substr($0, r + 2), t, " ")
    if (n < 22) next
    name = comm
    f = "/proc/" pid "/cmdline"
    if ((getline line < f) > 0) {
      argv0 = line
      sub(/\0.*/, "", argv0)
      sub(/ .*/, "", argv0)
      sub(/.*\//, "", argv0)
      if (argv0 != "" && index(argv0, comm) == 1) name = argv0
    }
    close(f)
    print pid, t[20], t[12] + t[13], t[22], name
  }'
}

if want cpu || want mem; then
  echo "@const"
  echo "clk_tck $(getconf CLK_TCK)"
  echo "pagesize $(getconf PAGESIZE)"
fi

if want cpu; then
  echo "@stat"
  grep '^cpu' /proc/stat
  echo "@load"
  cat /proc/loadavg
  echo "@uptime"
  cat /proc/uptime
fi

if want mem; then
  echo "@mem"
  cat /proc/meminfo
  echo "@zram"
  for d in /sys/block/zram*; do [ -r "$d/mm_stat" ] && cut -d' ' -f1 "$d/mm_stat"; done
  echo "@psi"
  cat /proc/pressure/memory 2>/dev/null
fi

if want cpu || want mem; then procs; fi

if want net; then
  echo "@net"
  # iface rx_bytes tx_bytes
  awk -F'[: ]+' 'NR > 2 { sub(/^ +/, ""); print $1, $2, $10 }' /proc/net/dev
  echo "@addr"
  # iface ip/prefix
  ip -o -4 addr 2>/dev/null | awk '{ print $2, $4 }'
  echo "@route"
  # iface gateway
  ip route show default 2>/dev/null | awk '{ for (i = 1; i <= NF; i++) if ($i == "dev") d = $(i+1); else if ($i == "via") g = $(i+1); print d, g; exit }'
  echo "@wifi"
  # iface ssid (best-effort, iw only)
  for d in /sys/class/net/*/wireless; do
    [ -d "$d" ] || continue
    i=$(basename "$(dirname "$d")")
    s=$(iw dev "$i" link 2>/dev/null | awk -F'SSID: ' '/SSID/ { print $2; exit }')
    [ -n "$s" ] && echo "$i $s"
  done
fi
