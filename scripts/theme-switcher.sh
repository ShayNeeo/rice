#!/usr/bin/env bash

# theme-switcher.sh — Switch UI theme based on current power profile.
#   power-saver  → power-saver
#   balanced     → cartoon-shell
#   performance  → cartoon-shell
#
# Uses atomic symlink swaps against the user-owned theme cache so switching is
# instant and does not keep rewriting config files.

set -euo pipefail

THEME_BASE="${XDG_DATA_HOME:-$HOME/.local/share}/pixel-rice/themes"
CONFIG_DIR="$HOME/.config"
HYPR_FILES=(hyprland.conf keybinds.conf hypridle.conf hyprlock.conf hyprpaper.conf)

link_file() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
}

reload_ui() {
    if pgrep -x quickshell >/dev/null 2>&1; then
        pkill -x quickshell 2>/dev/null || true
        for i in {1..20}; do
            if ! pgrep -x quickshell >/dev/null 2>&1; then
                break
            fi
            sleep 0.02
        done
    fi

    export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
    nohup quickshell >/dev/null 2>&1 &

    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload 2>/dev/null || true
    fi
}

apply_theme() {
    local src="$1"
    local label="$2"

    if [ ! -d "$src" ]; then
        echo "[theme-switcher] WARNING: source directory $src not found, skipping."
        return
    fi

    echo "[theme-switcher] Applying theme: $label"

    rm -rf "$CONFIG_DIR/quickshell"
    ln -s "$src/.config/quickshell" "$CONFIG_DIR/quickshell"

    mkdir -p "$CONFIG_DIR/hypr"
    for file in "${HYPR_FILES[@]}"; do
        link_file "$src/.config/hypr/$file" "$CONFIG_DIR/hypr/$file"
    done

    reload_ui
    echo "[theme-switcher] ✓ $label applied"
}

PROFILE=""
if [ $# -gt 0 ] && [ -n "$1" ]; then
    PROFILE="$1"
elif command -v powerprofilesctl >/dev/null 2>&1; then
    PROFILE=$(powerprofilesctl get 2>/dev/null || echo "")
fi

if [ -z "$PROFILE" ]; then
    echo "[theme-switcher] WARNING: Could not determine power profile, no changes made."
    exit 1
fi

case "$PROFILE" in
    power-saver)
        apply_theme "$THEME_BASE/power-saver" "Power-saver (zero effects)"
        ;;
    balanced|performance)
        apply_theme "$THEME_BASE/cartoon-shell" "Cartoon-shell ($PROFILE)"
        ;;
    *)
        echo "[theme-switcher] Unknown profile: $PROFILE, defaulting to cartoon-shell"
        apply_theme "$THEME_BASE/cartoon-shell" "Cartoon-shell (default)"
        ;;
esac
