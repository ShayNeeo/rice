#!/usr/bin/env bash
# Output current fcitx5 input method status
STATUS=$(fcitx5-remote 2>/dev/null)
case "$STATUS" in
    1) echo "EN" ;;
    2) echo "VI" ;;
    *) echo "--" ;;
esac
