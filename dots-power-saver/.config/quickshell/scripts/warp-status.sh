#!/usr/bin/env bash
# Output WARP/NextDNS status as JSON: {"text":"...","class":"..."}
STATUS=$(warp-cli status 2>/dev/null || echo "Unable to connect")
case "$STATUS" in
    *"Connected"*)
        echo '{"text":"","class":"connected"}'
        ;;
    *"Connecting"*|*"Updating"*)
        echo '{"text":"","class":"connecting"}'
        ;;
    *"Disconnected"*|*"Unable"*)
        echo '{"text":"","class":"idle"}'
        ;;
    *)
        echo '{"text":"","class":"error"}'
        ;;
esac
