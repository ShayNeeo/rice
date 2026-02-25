#!/bin/bash

# TDP Profiles for Ryzen 7 5800H (Milliwatts)
# -------------------------------------------
# Power Saver: 7W - Extreme efficiency, fanless experience.
PS_LIMITS="--stapm-limit=7000 --fast-limit=10000 --slow-limit=8500 --tctl-temp=55"

# Balanced: 25W - Ideal for daily use.
BAL_LIMITS="--stapm-limit=25000 --fast-limit=32000 --slow-limit=28000 --tctl-temp=78"

# Performance: 45W-54W - Max power for heavy tasks.
PERF_LIMITS="--stapm-limit=45000 --fast-limit=54000 --slow-limit=43500 --tctl-temp=95"

apply_profile() {
    local profile=$1
    echo "[$(date '+%H:%M:%S')] Mode Switch -> $profile"
    
    case $profile in
        "low-power")
            sudo ryzenadj $PS_LIMITS
            ;;
        "balanced")
            sudo ryzenadj $BAL_LIMITS
            ;;
        "performance")
            sudo ryzenadj $PERF_LIMITS
            ;;
    esac
}

# Initial apply
CURRENT_PROFILE=$(cat /sys/firmware/acpi/platform_profile)
apply_profile "$CURRENT_PROFILE"

# Monitor for changes (requires inotify-tools or a simple loop)
while true; do
    NEW_PROFILE=$(cat /sys/firmware/acpi/platform_profile)
    if [ "$NEW_PROFILE" != "$CURRENT_PROFILE" ]; then
        apply_profile "$NEW_PROFILE"
        CURRENT_PROFILE="$NEW_PROFILE"
    fi
    sleep 2
done
