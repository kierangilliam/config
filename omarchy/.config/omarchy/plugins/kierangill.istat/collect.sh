#!/bin/sh
# One-shot system snapshot for the iStat panel. Each section starts with "@name".
echo "@const"
echo "clk_tck $(getconf CLK_TCK)"
echo "pagesize $(getconf PAGESIZE)"
echo "@stat"
grep '^cpu' /proc/stat
echo "@mem"
cat /proc/meminfo
echo "@load"
cat /proc/loadavg
echo "@uptime"
cat /proc/uptime
echo "@zram"
for d in /sys/block/zram*; do [ -r "$d/mm_stat" ] && cut -d' ' -f1 "$d/mm_stat"; done
echo "@psi"
cat /proc/pressure/memory 2>/dev/null
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
