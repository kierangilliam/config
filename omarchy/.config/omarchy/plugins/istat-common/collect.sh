#!/bin/sh
# One-shot system snapshot for the iStat widgets. Each section starts with "@name".
# Usage: collect.sh cpu|mem|net|disk   (no argument = everything); collect.sh du [dir] for the slow scan
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

if want disk; then
  echo "@df"
  # source fstype size used avail mount   (block-device filesystems only; bytes)
  df -B1 --output=source,fstype,size,used,avail,target 2>/dev/null | awk 'NR > 1 && $1 ~ /^\/dev\//'
  echo "@diskio"
  # disk sectors_read sectors_written   (whole physical disks only, 512-byte sectors)
  for d in /sys/block/*; do
    n=$(basename "$d")
    case "$n" in loop*|ram*|zram*|dm-*|md*|sr*) continue ;; esac
    [ -r "$d/stat" ] && awk -v n="$n" '{ print n, $3, $7 }' "$d/stat"
  done
  echo "@disk"
  # physical disk behind /: name rotational model
  src=$(findmnt -no SOURCE / 2>/dev/null | sed "s/\[.*//")
  if [ -b "$src" ]; then
    p=$(readlink -f "/sys/dev/block/$(stat -Lc '%Hr:%Lr' "$src")" 2>/dev/null)
    i=0
    while [ -n "$p" ] && [ $i -lt 8 ]; do
      i=$((i + 1))
      s=$(ls "$p/slaves" 2>/dev/null | head -1)
      if [ -n "$s" ]; then p=$(readlink -f "$p/slaves/$s"); continue; fi
      if [ -e "$p/partition" ]; then p=$(dirname "$p"); continue; fi
      break
    done
    n=$(basename "$p")
    rot=$(cat "$p/queue/rotational" 2>/dev/null)
    model=$(cat "$p/device/model" 2>/dev/null || cat "$p/device/name" 2>/dev/null)
    echo "$n ${rot:--} $model"
  fi
fi

# Slow (seconds): largest entries. No dir = top-level directories of / and $HOME;
# with a dir = its immediate children (files included), for drilling down.
if [ "$what" = du ]; then
  echo "@du"
  # bytes d|f path
  tag() { while IFS="$(printf '\t')" read -r b p; do if [ -d "$p" ]; then echo "$b d $p"; else echo "$b f $p"; fi; done; }
  if [ -n "$2" ]; then
    du -x -a -d1 -B1 -- "$2" 2>/dev/null | awk -v d="$2" '$2 != d'
  else
    du -x -d1 -B1 / 2>/dev/null | awk -v h="$HOME" '$2 != "/" && $2 != "/home" && $2 != h'
    du -x -d1 -B1 "$HOME" 2>/dev/null | awk -v h="$HOME" '$2 != h'
  fi | sort -rn | head -15 | tag
fi
