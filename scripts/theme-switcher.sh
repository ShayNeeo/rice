#!/usr/bin/env bash

# theme-switcher.sh — Switch UI theme based on current power profile.
#   power-saver  → dots-power-saver  (zero rounding, zero effects, max performance)
#   balanced     → dots              (cartoon-shell: 6px rounding, subtle depth)
#   performance  → dots              (cartoon-shell)
#
# Reads the current profile via powerprofilesctl, copies the matching theme tree
# from /opt/pixel-rice/themes/ into ~/.config/, then reloads affected components.

set -euo pipefail

THEME_BASE="/opt/pixel-rice/themes"
CONFIG_DIR="$HOME/.config"

reload_ui() {
    # Waybar: kill and let exec-once restart it, or send SIGUSR2 for config reload
    if pidof waybar >/dev/null 2>&1; then
        killall -SIGUSR2 waybar 2>/dev/null || true
    fi

    # SwayNC: reload theme
    if pidof swaync >/dev/null 2>&1; then
        swaync-client -R 2>/dev/null || true
    fi

    # Hyprland: reload config (picks up decoration rounding changes)
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

    # Copy themed configs (rsync if available, else cp)
    if command -v rsync >/dev/null 2>&1; then
        rsync -a "$src/.config/" "$CONFIG_DIR/"
    else
        # cp with overwrite
        cp -a "$src/.config/." "$CONFIG_DIR/"
    fi

    # Make waybar scripts executable
    chmod +x "$CONFIG_DIR/waybar/scripts/"*.sh 2>/dev/null || true

    # Set GTK CSS — copy gtk.css into place
    # (already done by rsync/cp above)

    reload_ui
    echo "[theme-switcher] ✓ $label applied"
}

# Determine current power profile
PROFILE=""
if command -v powerprofilesctl >/dev/null 2>&1; then
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
