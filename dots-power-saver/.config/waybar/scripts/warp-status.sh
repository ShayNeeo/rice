#!/usr/bin/env bash

# WARP / NextDNS status indicator for Waybar
# Outputs JSON: {"text":"...","class":"..."}

set -euo pipefail

has_cmd() { command -v "$1" >/dev/null 2>&1; }

get_warp_state() {
    if ! has_cmd warp-cli; then
        echo "missing"
        return
    fi
    local line
    line=$(warp-cli status 2>/dev/null | grep -m1 'Status update:' || true)
    case "$line" in
        *Connected*)  echo "connected" ;;
        *Connecting*) echo "connecting" ;;
        *Unable*)     echo "unable" ;;
        *)            echo "unknown" ;;
    esac
}

state=$(get_warp_state)

case "$state" in
    connected)
        printf '%s\n' '{"text":"  WARP","class":"connected"}'
        ;;
    connecting)
        printf '%s\n' '{"text":"  ...","class":"connecting"}'
        ;;
    unable)
        printf '%s\n' '{"text":"  ERR","class":"error"}'
        ;;
    missing)
        printf '%s\n' '{"text":"  N/A","class":"disabled"}'
        ;;
    *)
        printf '%s\n' '{"text":"  SYS","class":"idle"}'
        ;;
esac
