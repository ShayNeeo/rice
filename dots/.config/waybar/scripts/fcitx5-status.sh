#!/usr/bin/env bash
# Fcitx5 Status for Waybar

if ! command -v fcitx5-remote >/dev/null 2>&1; then
    echo "N/A"
    exit 0
fi

status=$(fcitx5-remote)

case "$status" in
    1) echo "EN" ;;      # Inactive
    2) echo "VI" ;;      # Active (Unikey/Vietnamese)
    *) echo "IM" ;;      # Other state
esac
