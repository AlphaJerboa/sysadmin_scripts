#!/bin/bash

echo "= CPU overview ="
ps -eo pcpu,thcount,pid,args | sort -k 1 -gr | head -n5
echo
echo "= Memory overview ="
ps -eo rss,pid,args | sort -k 1 -gr | head -n5 | while read rss pid args
do
    [[ $pid =~ ^[0-9]+$ ]] || continue
    [[ $rss =~ ^[0-9]+$ ]] || continue
    oom_score=$(choom -p $pid | sed -n "/current OOM score:/ s/^.*:\s\([0-9]\+\)$/\1/p")
    [[ $oom_score =~ ^[0-9]+$ ]] || continue
    grep -i ^pss /proc/$pid/smaps 2>/dev/null |  awk -v p=$pid -v oom=$oom_score -v rss=$rss -v args="$args" '{Total+=$2} END {print p ": MEM=" Total/1024"MB RSS="rss/1024"MB OOM=" oom " ARGS=" args}'

done
