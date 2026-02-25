#!/usr/bin/env bash

# Eye Protection Script for Hyprland (using wlsunset)
# modes: auto -> manual -> off

STATE_FILE="$HOME/.local/state/eyeprotect.mode"
mkdir -p "$(dirname "$STATE_FILE")"

# Default settings
TEMP_LOW=4000
TEMP_HIGH=6500
LAT="0"   # Default to 0 if not found
LONG="0"
LOCATION_FILE="$HOME/.local/state/eyeprotect.location"

# Function to get location (with caching)
get_location() {
    # 1. Try to get location from ipinfo.io
    if command -v curl >/dev/null 2>&1; then
        # Use a short timeout so we don't block startup for too long
        LOC=$(curl -s --connect-timeout 3 https://ipinfo.io/loc 2>/dev/null)
        
        if [ -n "$LOC" ]; then
            LAT=$(echo "$LOC" | cut -d',' -f1)
            LONG=$(echo "$LOC" | cut -d',' -f2)
            
            # Save successful location for offline usage
            echo "$LOC" > "$LOCATION_FILE"
            return
        fi
    fi

    # 2. Fallback: Try to read from cache
    if [ -f "$LOCATION_FILE" ]; then
        LOC=$(cat "$LOCATION_FILE")
        if [ -n "$LOC" ]; then
            LAT=$(echo "$LOC" | cut -d',' -f1)
            LONG=$(echo "$LOC" | cut -d',' -f2)
        fi
    fi
}

current_mode=$(cat "$STATE_FILE" 2>/dev/null || echo "off")

# Determine target mode
if [ "$1" == "restore" ]; then
    target_mode="$current_mode"
else
    # Toggle Logic
    case "$current_mode" in
        "off") target_mode="auto" ;;
        "auto") target_mode="manual" ;;
        "manual") target_mode="off" ;;
        *) target_mode="off" ;;
    esac
    
    # Save new state
    echo "$target_mode" > "$STATE_FILE"
    
    # Show OSD (only when toggling)
    case "$target_mode" in
        "auto") ~/.local/bin/osd.sh wlsunset "Auto" ;;
        "manual") ~/.local/bin/osd.sh wlsunset "Manual" ;;
        "off") ~/.local/bin/osd.sh wlsunset "Off" ;;
    esac
fi

# Apply target_mode
pkill wlsunset 2>/dev/null

case "$target_mode" in
    "auto")
        get_location
        # Start wlsunset in background
        wlsunset -l "$LAT" -L "$LONG" -t "$TEMP_LOW" -T "$TEMP_HIGH" &
        ;;
    "manual")
        # Force warm temperature
        wlsunset -T "$TEMP_LOW" &
        ;;
    "off")
        # Do nothing (killed above)
        ;;
esac
