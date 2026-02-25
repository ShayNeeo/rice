#!/usr/bin/env bash

# OSD Script using notify-send and swaync
# Usage: osd.sh <type> <value_or_action>

# Type: volume, brightness, power, custom
TYPE="$1"
ACTION="$2"

get_volume_icon() {
    # $1 is volume percent, $2 is mute status
    if [ "$2" == "yes" ] || [ "$2" == "true" ] || [ "$2" == "on" ] || [ "$2" == "1" ]; then
        echo "audio-volume-muted"
        return
    fi
    
    if [ "$1" -ge 66 ]; then
        echo "audio-volume-high"
    elif [ "$1" -ge 33 ]; then
        echo "audio-volume-medium"
    else
        echo "audio-volume-low"
    fi
}

get_brightness_icon() {
    # $1 is percent
    if [ "$1" -ge 66 ]; then
        echo "display-brightness-high"
    elif [ "$1" -ge 33 ]; then
        echo "display-brightness-medium"
    else
        echo "display-brightness-low"
    fi
}

case "$TYPE" in
    "volume")
        # ACTION: up, down, mute
        case "$ACTION" in
            "up")
                wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.5
                ;;
            "down")
                wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
                ;;
            "mute")
                wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
                ;;
        esac
        
        VOL=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d'.' -f1)
        MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o "MUTED")
        
        if [ -n "$MUTED" ]; then
            ICON="audio-volume-muted"
            TEXT="Muted"
            VAL=0
        else
            ICON=$(get_volume_icon "$VOL" "no")
            TEXT="$VOL%"
            VAL=$VOL
        fi
        
        notify-send -h string:x-canonical-private-synchronous:sys-notify \
            -h int:value:"$VAL" \
            -i "$ICON" \
            "Volume" "$TEXT"
        ;;
        
    "brightness")
        # ACTION: up, down
        case "$ACTION" in
            "up")
                brightnessctl set 5%+
                ;;
            "down")
                brightnessctl set 5%-
                ;;
        esac
        
        BRIGHTNESS=$(brightnessctl -m | cut -d, -f4 | tr -d %)
        ICON=$(get_brightness_icon "$BRIGHTNESS")
        
        notify-send -h string:x-canonical-private-synchronous:sys-notify \
            -h int:value:"$BRIGHTNESS" \
            -i "$ICON" \
            "Brightness" "$BRIGHTNESS%"
        ;;
        
    "power")
        # ACTION: performance, balanced, power-saver
        powerprofilesctl set "$ACTION"
        
        case "$ACTION" in
            "performance")
                ICON="power-profile-performance"
                TEXT="Performance"
                ;;
            "balanced")
                ICON="power-profile-balanced"
                TEXT="Balanced"
                ;;
            "power-saver")
                ICON="power-profile-power-saver"
                TEXT="Power Saver"
                ;;
        esac
        
        notify-send -h string:x-canonical-private-synchronous:sys-notify \
            -i "$ICON" \
            "Power Profile" "$TEXT"
        ;;
        
    "wlsunset")
        # ACTION: status text
        MODE="$ACTION"
        ICON="weather-clear-night"
        case "$MODE" in
            "Auto") ICON="weather-clear-night" ;; 
            "Manual") ICON="weather-overcast" ;; 
            "Off") ICON="weather-clear" ;; 
        esac
        
        notify-send -h string:x-canonical-private-synchronous:sys-notify \
            -i "$ICON" \
            "Eye Protection" "$MODE"
        ;;

    "kbd_backlight")
        # ACTION: cycle, up, down
        # Device pattern for keyboard backlight
        DEVICE="*::kbd_backlight"
        
        # Get max brightness and current brightness
        MAX=$(brightnessctl --device="$DEVICE" max)
        CURRENT=$(brightnessctl --device="$DEVICE" get)
        
        # Calculate levels (Off, Low, High, Max)
        # Using approximated thresholds
        LOW=$((MAX / 3))
        HIGH=$((MAX * 2 / 3))
        
        case "$ACTION" in
            "cycle")
                # Off -> Low -> High -> Max -> Off
                if [ "$CURRENT" -eq 0 ]; then
                    brightnessctl --device="$DEVICE" set "$LOW"
                    TEXT="Low"
                elif [ "$CURRENT" -le "$LOW" ]; then
                    brightnessctl --device="$DEVICE" set "$HIGH"
                    TEXT="High"
                elif [ "$CURRENT" -le "$HIGH" ]; then
                    brightnessctl --device="$DEVICE" set "$MAX"
                    TEXT="Max"
                else
                    brightnessctl --device="$DEVICE" set 0
                    TEXT="Off"
                fi
                ;;
            "up")
                brightnessctl --device="$DEVICE" set +10%
                TEXT="Up"
                ;;
            "down")
                brightnessctl --device="$DEVICE" set 10%-
                TEXT="Down"
                ;;
        esac
        
        # Get new value for notification
        NEW_VAL=$(brightnessctl --device="$DEVICE" get)
        PERCENT=$((NEW_VAL * 100 / MAX))
        
        notify-send -h string:x-canonical-private-synchronous:sys-notify \
            -h int:value:"$PERCENT" \
            -i "keyboard-brightness-symbolic" \
            "Keyboard Light" "$TEXT ($PERCENT%)"
        ;;
        
    "custom")
        # Usage: osd.sh custom "Title" "Body" "Icon"
        TITLE="$2"
        BODY="$3"
        ICON="$4"
        notify-send -h string:x-canonical-private-synchronous:sys-notify \
            -i "$ICON" \
            "$TITLE" "$BODY"
        ;;
esac
