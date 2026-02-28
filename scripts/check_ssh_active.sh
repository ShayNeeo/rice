#!/usr/bin/env bash
# Check for active SSH (sshd) sessions.
# Exit 0 = SSH active (do NOT suspend)
# Exit 1 = no SSH (safe to suspend)
#
# Used by hypridle to avoid suspending when remote Cursor IDE / SSH is connected.

SSH_PORT="${SSH_PORT:-22}"

# Method 1: ss - established TCP connections to SSH port (no root needed)
if command -v ss &>/dev/null; then
    if ss -tn state established "( dport = :${SSH_PORT} )" 2>/dev/null | tail -n +2 | grep -q .; then
        exit 0  # SSH active
    fi
fi

# Method 2: loginctl - remote sessions (fallback)
if command -v loginctl &>/dev/null; then
    while IFS= read -r session; do
        [ -z "$session" ] && continue
        if loginctl show-session "$session" -p Remote --value 2>/dev/null | grep -q yes; then
            exit 0  # SSH active
        fi
    done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
fi

exit 1  # No active SSH
