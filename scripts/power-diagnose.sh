#!/usr/bin/env bash
# power-diagnose.sh — diagnose why CPU is hot/boosting in a given profile.
# Usage: power-diagnose.sh [profile]   # profile = balanced | power-saver | performance
#        power-diagnose.sh             # uses current profile
#
# Prints:
#   1. Effective power profile (powerprofilesctl + ACPI platform_profile)
#   2. CPU governor + EPP per-core
#   3. Current vs max frequency
#   4. amd-pstate EPP/hw_prefcore settings
#   5. Package + per-core temps
#   6. AMD GPU DPM state
#   7. Whether ryzenadj is actually applying TDP limits
#   8. Top 5 CPU consumers
#
# Exit 0 = healthy, 1 = TDP override not effective, 2 = thermals over 85°C

set -uo pipefail

PROFILE="${1:-$(powerprofilesctl get 2>/dev/null || echo unknown)}"
EXIT=0
red()   { printf '\033[0;31m%s\033[0m\n' "$*"; }
green() { printf '\033[0;32m%s\033[0m\n' "$*"; }
yel()   { printf '\033[1;33m%s\033[0m\n' "$*"; }
hdr()   { printf '\n\033[0;36m━━━ %s ━━━\033[0m\n' "$*"; }

hdr "Profile requested: $PROFILE"
echo "  powerprofilesctl : $(powerprofilesctl get 2>&1 || echo N/A)"
echo "  ACPI platform    : $(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo N/A)"

hdr "CPU governor / EPP"
GOVS=$(cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort -u | tr '\n' ' ')
EPPS=$(cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference 2>/dev/null | sort -u | tr '\n' ' ')
echo "  governors    : $GOVS"
echo "  EPP values   : $EPPS   (0=performance, 255=power-save; balance_performance=128, balance_power=192)"

hdr "amd-pstate knobs"
for f in amd_pstate_highest_perf amd_pstate_lowest_nonlinear_freq \
         amd_pstate_hw_prefcore energy_performance_available_preferences; do
    v=$(cat /sys/devices/system/cpu/cpu0/cpufreq/$f 2>/dev/null || echo N/A)
    printf "  %-50s %s\n" "$f" "$v"
done

hdr "Frequency (per-core, current vs max)"
CURR_MHZ=$(awk '{printf "%d\n", $1/1000}' /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq 2>/dev/null | sort -n | uniq -c | awk '{print $2, "MHz ×", $1, "cores"}' | head -3)
echo "  Cores @ freq :"
echo "$CURR_MHZ" | sed 's/^/    /'
# cpuinfo_max_freq = true hardware cap; scaling_max_freq = current (possibly user-capped)
HWMAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)
MIN=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null)
echo "  cpuinfo_max  : $((HWMAX/1000)) MHz   (true hardware cap)"
echo "  scaling_max  : $((MAX/1000)) MHz     (current — may be capped)"
if [ "$MAX" -lt "$HWMAX" ]; then
    echo "  $(yel CPU IS CAPPED: at $((MAX/1000)) MHz, $((100 - MAX*100/HWMAX))% below hardware max)"
elif [ "$MAX" -gt "$HWMAX" ]; then
    echo "  $(red CPU ABOVE hardware max? check cpuinfo_max_freq reading)"
fi
echo "  scaling_min  : $((MIN/1000)) MHz"

# Boost status
BOOST_PATH="/sys/devices/system/cpu/cpufreq/boost"
if [ -f "$BOOST_PATH" ]; then
    BOOST_NOW=$(cat "$BOOST_PATH" 2>/dev/null)
    if [ "$BOOST_NOW" = "0" ]; then
        echo "  boost        : $(red DISABLED) (single-core turbo off)"
    else
        echo "  boost        : enabled (turbo up to $((HWMAX/1000)) MHz)"
    fi
fi

hdr "Temperatures"
for f in /sys/class/hwmon/hwmon*/temp*_input; do
    [ -r "$f" ] || continue
    name=$(dirname "$f" | xargs -I{} cat {}/name 2>/dev/null)
    label=$(basename "$f")
    raw=$(cat "$f" 2>/dev/null)
    [[ "$raw" -gt 0 ]] || continue
    deg=$((raw / 1000))
    tenth=$((raw % 1000 / 100))
    flag=""
    if [ "$deg" -ge 85 ]; then flag="  $(red HOT)"; EXIT=2
    elif [ "$deg" -ge 75 ]; then flag="  $(yel WARM)"; fi
    printf "  %-25s %3s%-3s °C %s\n" "$name/$label" "$deg" ".$tenth" "$flag"
done

hdr "AMD GPU DPM (card0=IGP, card1=dGPU if present)"
for card in /sys/class/drm/card*/device; do
    [ -d "$card" ] || continue
    name=$(basename "$(dirname "$card")")
    dpm=$(cat "$card/power_dpm_force_performance_level" 2>/dev/null || echo N/A)
    sclk=$(grep -E '^\s*[0-9]+:' "$card/pp_dpm_sclk" 2>/dev/null | grep '\*' | head -1 | tr -s ' ')
    echo "  $name  force_level=$dpm  ${sclk:-}"
done

hdr "ryzenadj TDP override"
if ! command -v ryzenadj >/dev/null 2>&1; then
    echo "  $(red ryzenadj not installed — TDP limits are NOT being applied)"
    EXIT=1
else
    if ryzenadj -i 2>&1 | grep -q "Unable to get os_access"; then
        echo "  $(red ryzenadj cannot talk to SMU — permission/kernel module issue)"
        echo "  Current ryzen_smu driver: $(lsmod 2>/dev/null | awk '/^ryzen_smu/ {print "loaded"}' || echo 'not loaded')"
        echo "  Fix: sudo modprobe ryzen_smu  OR  add sudoers NOPASSWD for /usr/bin/ryzenadj"
        EXIT=1
    else
        ryzenadj -i 2>/dev/null | grep -E "STAPM LIMIT|FAST LIMIT|SLOW LIMIT|TCTL TEMP|APU SKIN|POWER SAVING" | head -8
    fi
fi

hdr "Top 5 CPU consumers"
ps -eo pid,ppid,pcpu,pmem,etime,comm --sort=-pcpu 2>/dev/null | awk 'NR>1 && $3+0 > 0.3' | head -6 | sed 's/^/  /'

hdr "Verdict"
case "$EXIT" in
    0) green "  ✓ Profile is being applied AND thermals are healthy." ;;
    1) red    "  ✗ TDP override is not effective — CPU runs unboosted-uncapped." ;;
    2) red    "  ✗ Temperatures exceed 85°C — thermal throttling or shutdown imminent." ;;
esac
exit "$EXIT"
