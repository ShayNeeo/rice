#!/usr/bin/env bash
# Check for active SSH or AI agent sessions.
# Exit 0 = active session (do NOT suspend)
# Exit 1 = nothing active (safe to suspend)
#
# SSH: always block sleep while connection is established.
# AI agents (opencode, droid, kilo, hermes, antigravity-ide):
#   busy     = R/D CPU threads OR network send/recv within AI_BUSY_TIMEOUT
#   waiting  = has live TCP connection (may be awaiting slow API response up to AI_WAIT_TIMEOUT)
#   idle     = no active threads + no live connections -> allow sleep

SSH_PORT="${SSH_PORT:-22}"
AI_BUSY_TIMEOUT="${AI_BUSY_TIMEOUT:-30}"    # seconds: recent send/recv = actively working
AI_WAIT_TIMEOUT="${AI_WAIT_TIMEOUT:-300}"   # seconds: connection alive but idle = maybe waiting

thread_state() {
    local pid=$1 tid=$2
    cut -d' ' -f3 "/proc/$pid/task/$tid/stat" 2>/dev/null
}

pid_has_active_thread() {
    local pid=$1 tid state
    for tid_path in /proc/"$pid"/task/*/; do
        [ -d "$tid_path" ] || continue
        tid=${tid_path%/}; tid=${tid##*/}
        state=$(thread_state "$pid" "$tid")
        [ "$state" = "R" ] || [ "$state" = "D" ] && return 0
    done
    local child
    for child in $(pgrep -P "$pid" 2>/dev/null); do
        pid_has_active_thread "$child" && return 0
    done
    return 1
}

# Returns: 0=busy, 1=waiting, 2=idle
pid_network_status() {
    local pid=$1 busy_ms=$((AI_BUSY_TIMEOUT * 1000)) wait_ms=$((AI_WAIT_TIMEOUT * 1000))
    ss -tnpi 2>/dev/null | awk -v pid="$pid" -v busy="$busy_ms" -v wait="$wait_ms" '
        BEGIN { idle = 99999999 }
        /ESTAB/ {
            if (index($0, "pid=" pid)) {
                getline details
                match(details, /lastsnd:([0-9]+)/, a)
                match(details, /lastrcv:([0-9]+)/, b)
                snd = (a[1] != "") ? a[1] + 0 : 9999999
                rcv = (b[1] != "") ? b[1] + 0 : 9999999
                least = (snd < rcv) ? snd : rcv
                if (least < idle) idle = least
                if (least < busy) { found = 1; exit }
            }
        }
        END {
            if (found) exit 0
            if (idle < 9999999 && idle < wait) exit 1
            exit 2
        }
    ' 2>/dev/null
    return $?
}

# --- 1. SSH: established TCP connections ---
if command -v ss &>/dev/null; then
    if ss -tn state established "( dport = :${SSH_PORT} )" 2>/dev/null | tail -n +2 | grep -q .; then
        exit 0
    fi
fi

# --- 2. SSH: loginctl remote sessions (fallback) ---
if command -v loginctl &>/dev/null; then
    while IFS= read -r session; do
        [ -z "$session" ] && continue
        if loginctl show-session "$session" -p Remote --value 2>/dev/null | grep -q yes; then
            exit 0
        fi
    done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
fi

# --- 3. AI agents: busy or waiting-for-response -> block sleep ---
check_agent() {
    local pid
    for pid in $(pgrep -x "$1" 2>/dev/null); do
        pid_has_active_thread "$pid" && return 0
        pid_network_status "$pid"; local net=$?
        [ "$net" -le 1 ] && return 0
    done
    return 1
}

for agent in opencode droid kilo hermes; do
    check_agent "$agent" && exit 0
done

for pid in $(pgrep -x 'antigravity-id' 2>/dev/null; pgrep -f 'antigravity-ide' 2>/dev/null); do
    pid_has_active_thread "$pid" && exit 0
    pid_network_status "$pid"; [ "$?" -le 1 ] && exit 0
done

exit 1
