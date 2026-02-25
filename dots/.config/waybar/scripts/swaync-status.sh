#!/usr/bin/env bash
# SwayNC Notification Status for Waybar

if ! command -v swaync-client >/dev/null 2>&1; then
    echo '{"text":"N/A","class":"disabled"}'
    exit 0
fi

# Get notification count and DND status
count=$(swaync-client -c 2>/dev/null || echo "0")
dnd=$(swaync-client -D 2>/dev/null)

# Format output
if [ "$dnd" = "true" ]; then
    echo "{\"text\":\"DND\",\"class\":\"dnd\"}"
elif [ "$count" -gt 0 ]; then
    echo "{\"text\":\"$count\",\"class\":\"has-notifications\"}"
else
    echo "{\"text\":\"\",\"class\":\"empty\"}"
fi
