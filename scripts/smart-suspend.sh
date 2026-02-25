#!/usr/bin/env bash
# Smart Suspend: Suspends only if discharging (on battery)

# Check for battery status
if [ -d /sys/class/power_supply ]; then
    for bat in /sys/class/power_supply/BAT*; do
        if [ -f "$bat/status" ]; then
            STATUS=$(cat "$bat/status")
            if [ "$STATUS" = "Discharging" ]; then
                systemctl suspend
                exit 0
            fi
        fi
    done
fi
