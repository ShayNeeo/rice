#!/usr/bin/env bash
# power-profile-test.sh — run all 3 power profiles in sequence and report
# CPU frequency, temperature, and current draw. Useful for verifying
# that ryzenadj is actually capping the TDP.
#
# Usage: power-profile-test.sh [seconds_per_profile]
#   defaults to 30s per profile
#
# Requires: install-power-tuning.sh to have been run first.

set -uo pipefail

DURATION="${1:-30}"
PROFILES=(low-power balanced performance)

get_freq_mhz() {
    local min=99999 max=0
    for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
        v=$(awk '{print int($1/1000)}' "$f" 2>/dev/null)
        (( v < min )) && min=$v
        (( v > max )) && max=$v
    done
    printf "min=%dMHz max=%dMHz\n" "$min" "$max"
}

get_temp() {
    local t
    t=$(cat /sys/class/hwmon/hwmon5/temp1_input 2>/dev/null)  # k10temp
    if [ -n "$t" ] && [ "$t" -gt 0 ]; then
        printf "%.1f°C" "$(echo "$t / 1000" | bc -l)"
    else
        echo "N/A"
    fi
}

get_power() {
    local p
    p=$(cat /sys/class/power_supply/BAT0/power_now 2>/dev/null)
    if [ -n "$p" ] && [ "$p" -gt 0 ]; then
        printf "%.1fW" "$(echo "$p / 1000000" | bc -l)"
    else
        echo "N/A (AC?)"
    fi
}

printf '%-15s %-25s %-10s %-10s\n' "PROFILE" "FREQ" "TEMP" "BATT_PWR"
printf '%-15s %-25s %-10s %-10s\n' "----" "----" "----" "-------"

for p in "${PROFILES[@]}"; do
    /home/shayneeo/.local/bin/manage_power.sh "$p" 2>&1 | grep -E "Switching|✓|⚠" | head -3
    sleep "$DURATION"
    printf '%-15s %-25s %-10s %-10s\n' "$p" "$(get_freq_mhz)" "$(get_temp)" "$(get_power)"
    echo ""
done

echo "Recommended profile for general use:  balanced"
echo "For battery life:                     low-power"
echo "For sustained workloads (compiles):  performance"
