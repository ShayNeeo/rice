#!/usr/bin/env bash
# SwayNC Notification Status for Waybar (icon + state)

if ! command -v swaync-client >/dev/null 2>&1; then
    printf '%s\n' '{"text":"  --","class":"disabled"}'
    exit 0
fi

count=$(swaync-client -c 2>/dev/null || echo "0")
dnd=$(swaync-client -D 2>/dev/null)

if [ "$dnd" = "true" ]; then
    printf '%s\n' '{"text":"  DND","class":"dnd"}'
elif [ "$count" -gt 0 ]; then
    printf '%s\n' "{\"text\":\"  ${count}\",\"class\":\"has-notifications\"}"
else
    printf '%s\n' '{"text":"","class":"empty"}'
fi
