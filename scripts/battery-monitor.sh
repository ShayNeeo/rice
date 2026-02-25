#!/usr/bin/env bash

# Battery Monitor Script
# Checks battery status and suspends on low battery
# Runs in a loop

# Thresholds
LOW_BAT=15
CRITICAL_BAT=5

# Check if battery exists
BAT_PATH=""
for bat in /sys/class/power_supply/BAT*; do
    if [ -e "$bat/status" ]; then
        BAT_PATH="$bat"
        break
    fi
done

if [ -z "$BAT_PATH" ]; then
    # No battery found, exit
    exit 0
fi

LAST_NOTIFIED_LOW=0

while true; do
    STATUS=$(cat "$BAT_PATH/status")
    CAPACITY=$(cat "$BAT_PATH/capacity")
    
    if [ "$STATUS" = "Discharging" ]; then
        if [ "$CAPACITY" -le "$CRITICAL_BAT" ]; then
            # Critical Battery: Suspend immediately
            notify-send -u critical -i "battery-empty" "Critical Battery" "Suspending system..."
            sleep 2
            systemctl suspend
            # Sleep longer after suspend to avoid immediate loop on wake if still low
            sleep 60 
        elif [ "$CAPACITY" -le "$LOW_BAT" ]; then
            # Notify only if we haven't notified recently for this specific drop, 
            # or just rely on the 'replace' capability of notify-send to not spam.
            # Here we use the synchronous hint so it replaces the previous notification.
            notify-send -h string:x-canonical-private-synchronous:sys-notify-battery \
                -u critical \
                -i "battery-low" \
                "Low Battery" "${CAPACITY}% Remaining"
        fi
    fi
    
    sleep 60
done
