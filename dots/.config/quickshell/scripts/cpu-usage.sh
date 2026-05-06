#!/usr/bin/env bash
# Output CPU usage percentage
awk '/^cpu / {
    idle=$5; total=0;
    for(i=2;i<=NF;i++) total+=$i;
    if(prev_total) {
        diff_total=total-prev_total;
        diff_idle=idle-prev_idle;
        if(diff_total>0) printf "%.0f%%\n", (1-diff_idle/diff_total)*100
        else print "0%"
    } else { print "--" }
    prev_total=total; prev_idle=idle
}' /proc/stat | tail -1
