#!/usr/bin/env bash
# Conditional suspend: only suspend if idle >= 15min AND no active SSH.
# Used by both hypridle (one-off at 15min) and systemd timer (polling every 2min)
# to handle the edge case: SSH drops AFTER 15min timeout already passed.
#
# GOTCHAS (Arch Linux):
# 1. Polkit: systemctl suspend may be denied. Add /etc/polkit-1/rules.d/50-allow-suspend.rules
# 2. IdleHint: logind needs IdleHint from compositor. Test: idle 1min, then
#    loginctl show-session $XDG_SESSION_ID | grep IdleHint  (should be yes)
#
# Exit 0 = did not suspend (SSH active or not idle enough)
# Exits only on success of systemctl suspend (or never, since suspend blocks)

IDLE_THRESHOLD_SEC="${IDLE_THRESHOLD_SEC:-900}"  # 15 min
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/conditional-suspend-idle-at"
STATE_MAX_AGE=1800  # 30 min - state file considered valid

# --- 1. Check idle time ---
# FROM_HYPRIDLE=1: skip (hypridle fires at 15min, we know we're idle)
# Otherwise: use loginctl IdleSinceHintMonotonic, or state-file fallback
idle_ok() {
    [ "$FROM_HYPRIDLE" = "1" ] && return 0

    local idle_sec
    idle_sec=$(get_idle_seconds 2>/dev/null)
    if [ -n "$idle_sec" ]; then
        # logind reports idle: use it (reject if not idle enough)
        [ "$idle_sec" -ge "$IDLE_THRESHOLD_SEC" ] && return 0
        return 1
    fi
    # Fallback: logind not reporting; state file = "we were idle+SSH recently"
    if [ -f "$STATE_FILE" ]; then
        local age now mtime
        now=$(date +%s)
        mtime=$(stat -c %Y "$STATE_FILE" 2>/dev/null || echo 0)
        age=$((now - mtime))
        [ "$age" -lt "$STATE_MAX_AGE" ] && return 0
    fi
    return 1
}

get_idle_seconds() {
    local sid idle_since now_mono_us idle_us
    for sid in $(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}'); do
        if loginctl show-session "$sid" -p Type --value 2>/dev/null | grep -qE 'wayland|x11'; then
            idle_since=$(loginctl show-session "$sid" -p IdleSinceHintMonotonic --value 2>/dev/null)
            [ -z "$idle_since" ] || [ "$idle_since" = "0" ] && return 1
            now_mono_us=$(($(awk '{print int($1*1000000)}' /proc/uptime 2>/dev/null || echo 0)))
            [ "$now_mono_us" -le 0 ] && return 1
            idle_us=$((now_mono_us - idle_since))
            [ "$idle_us" -lt 0 ] && return 1
            echo $((idle_us / 1000000))
            return 0
        fi
    done
    return 1
}

idle_ok || { rm -f "$STATE_FILE" 2>/dev/null; exit 0; }

# --- 2. Check SSH ---
SCRIPT_DIR="${0%/*}"
CHECK_SSH="${SCRIPT_DIR}/check_ssh_active.sh"
[ -x "$CHECK_SSH" ] || CHECK_SSH="$HOME/.local/bin/check_ssh_active.sh"
[ -x "$CHECK_SSH" ] || CHECK_SSH="check_ssh_active.sh"

if "$CHECK_SSH" 2>/dev/null; then
    # SSH active: record "idle+SSH" for timer fallback (handles IdleHint not reported)
    date +%s > "$STATE_FILE" 2>/dev/null
    exit 0
fi

rm -f "$STATE_FILE" 2>/dev/null

# --- 3. Suspend (may need polkit rule if "Access denied") ---
exec systemctl suspend
