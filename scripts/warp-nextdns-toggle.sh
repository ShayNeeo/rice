#!/usr/bin/env bash

# Toggle between:
# - WARP Zero Trust (owns DNS) when connecting
# - NextDNS over TLS via systemd-resolved when WARP is disconnected
#
# Behaviour:
# - If WARP is Connected / Connecting  -> disconnect + enable NextDNS
# - If WARP is Unable / Disconnected   -> disable NextDNS + connect WARP
#
# This script assumes:
# - systemd-resolved is in stub mode (/etc/resolv.conf -> stub-resolv.conf)
# - /etc/systemd/resolved.conf has a single [Resolve] section

set -euo pipefail

NEXTDNS_LINE='DNS=45.90.28.0#dns.nextdns.io 2a07:a8c0::#dns.nextdns.io 45.90.30.0#dns.nextdns.io 2a07:a8c1::#dns.nextdns.io'
RESOLVED_CONF="/etc/systemd/resolved.conf"

has_cmd() { command -v "$1" >/dev/null 2>&1; }

notify() {
    # Use Pixel Rice OSD helper for consistency with other scripts
    if [ -x "$HOME/.local/bin/osd.sh" ]; then
        # TYPE: dns, ACTION: short mode label
        "$HOME/.local/bin/osd.sh" dns "$1"
    elif has_cmd notify-send; then
        notify-send "DNS Mode" "$1"
    fi
}

ensure_resolve_section() {
    if ! grep -q '^\[Resolve\]' "$RESOLVED_CONF" 2>/dev/null; then
        printf '\n[Resolve]\n' | sudo tee -a "$RESOLVED_CONF" >/dev/null
    fi
}

enable_nextdns() {
    ensure_resolve_section

    # Remove any existing DNS= lines for safety, then add our unified line
    sudo sed -i '/^DNS=/d' "$RESOLVED_CONF"
    if ! grep -qF "$NEXTDNS_LINE" "$RESOLVED_CONF"; then
        sudo sed -i "s/^\[Resolve\]/[Resolve]\n$NEXTDNS_LINE/" "$RESOLVED_CONF"
    fi

    # Force DNSOverTLS=yes (only one line)
    if grep -q '^DNSOverTLS=' "$RESOLVED_CONF"; then
        sudo sed -i 's/^DNSOverTLS=.*/DNSOverTLS=yes/' "$RESOLVED_CONF"
    else
        sudo sed -i 's/^\[Resolve\]/[Resolve]\nDNSOverTLS=yes/' "$RESOLVED_CONF"
    fi

    sudo systemctl restart systemd-resolved
}

disable_nextdns() {
    if [ ! -f "$RESOLVED_CONF" ]; then
        return
    fi
    sudo sed -i '/^DNS=.*dns\.nextdns\.io/d' "$RESOLVED_CONF"
    sudo sed -i '/^DNSOverTLS=yes$/d' "$RESOLVED_CONF"
    sudo systemctl restart systemd-resolved
}

get_warp_state() {
    if ! has_cmd warp-cli; then
        echo "unknown"
        return
    fi
    local line
    line=$(warp-cli status 2>/dev/null | grep -m1 'Status update:' || true)
    case "$line" in
        *Connected*)  echo "connected" ;;
        *Connecting*) echo "connecting" ;;
        *Unable*)     echo "unable" ;;
        *)            echo "unknown" ;;
    esac
}

main() {
    local state
    state=$(get_warp_state)

    case "$state" in
        connected|connecting)
            # Turn WARP off, switch to NextDNS
            warp-cli disconnect || true
            enable_nextdns
            notify "NextDNS"
            ;;
        unable|unknown)
            # Try to re-establish WARP: clear NextDNS override and connect
            disable_nextdns
            warp-cli connect || true
            notify "WARP"
            ;;
    esac
}

main "$@"

