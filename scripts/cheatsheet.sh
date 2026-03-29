#!/usr/bin/env bash
# Hyprland keybind cheatsheet — scans hyprland.conf + keybinds (+ custom),
# human-readable actions, Nerd-style icons, filterable menu. Cached until configs change.

set -euo pipefail

HYPR="${HOME}/.config/hypr"
CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/pixel-rice"
CACHE_FILE="${CACHE_DIR}/cheatsheet_v3.cache"
MTIME_FILE="${CACHE_DIR}/cheatsheet_v3.mtime"

collect_sources() {
    local f
    for f in \
        "${HYPR}/hyprland.conf" \
        "${HYPR}/keybinds.conf" \
        "${HYPR}/custom/keybinds.conf"; do
        [[ -f "$f" ]] && printf '%s\n' "$f"
    done
}

cache_fingerprint() {
    local f sum=""
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        if stat -c %Y "$f" &>/dev/null; then
            sum+="$(stat -c %Y "$f"):$f;"
        else
            sum+="$(stat -f %m "$f"):$f;"
        fi
    done < <(collect_sources | sort -u)
    printf '%s' "$sum"
}

fingerprint="$(cache_fingerprint)"
if [[ -z "$fingerprint" ]]; then
    echo "No Hypr config found under ${HYPR}"
    exit 1
fi

build_lines() {
    local files=()
    while IFS= read -r f; do
        [[ -f "$f" ]] && files+=("$f")
    done < <(collect_sources | sort -u)
    ((${#files[@]})) || return 1
    awk -f /dev/stdin "${files[@]}" <<'AWKEOF' | LC_ALL=C sort -t "$(printf '\t')" -k2,2 -f | awk -F '\t' '{ printf "%s  %-44s  %s\n", $1, $2, $3 }'
function trim(s) {
    sub(/^[ \t]+/, "", s)
    sub(/[ \t]+$/, "", s)
    return s
}
function icon_for(action) {
    if (action ~ /[Tt]erminal|[Tt]mux|[Gg]hostty|[Aa]lacritty/) return ""
    if (action ~ /[Bb]rowser|[Ww]eb/) return ""
    if (action ~ /[Ff]ile [Mm]anager|[Tt]hunar/) return ""
    if (action ~ /[Ee]ditor|[Nn]otepad|[Cc]ursor/) return ""
    if (action ~ /[Cc]alculat/) return ""
    if (action ~ /[Cc]olor [Pp]ick|[Pp]icker/) return ""
    if (action ~ /[Aa]pp [Ll]auncher|[Ll]auncher|[Ww]ofi|[Rr]ofi/) return ""
    if (action ~ /[Cc]heatsheet|[Hh]elp/) return ""
    if (action ~ /[Cc]lipboard/) return ""
    if (action ~ /[Cc]lose|[Qq]uit active/) return ""
    if (action ~ /[Ff]loating/) return ""
    if (action ~ /[Ff]ullscreen/) return ""
    if (action ~ /[Pp]seudo|[Ss]plit/) return ""
    if (action ~ /[Ee]xit [Hh]yprland/) return ""
    if (action ~ /[Ff]ocus/) return ""
    if (action ~ /[Mm]ove window/) return ""
    if (action ~ /[Ww]orkspace/) return "󰨇"
    if (action ~ /[Rr]esize/) return ""
    if (action ~ /[Ll]ock/) return ""
    if (action ~ /[Ss]leep|[Ss]uspend/) return ""
    if (action ~ /[Rr]eload/) return ""
    if (action ~ /[Vv]olume|[Mm]ute|[Aa]udio/) return ""
    if (action ~ /[Bb]rightness/) return ""
    if (action ~ /[Kk]eyboard [Bb]ack|[Bb]acklight.*kbd/) return ""
    if (action ~ /[Pp]ower|[Pp]erformance|[Bb]alanced|[Pp]ower-saver/) return ""
    if (action ~ /[Nn]etwork|[Nn]mtui|[Mm]anager GUI/) return ""
    if (action ~ /[Bb]luetooth/) return ""
    if (action ~ /[Ww]ARP|[Dd]NS|[Nn]extDNS/) return ""
    if (action ~ /[Rr]ecord/) return ""
    if (action ~ /[Ss]creenshot/) return ""
    if (action ~ /[Ss]cratchpad/) return ""
    if (action ~ /[Ee]ye|[Pp]rotect/) return ""
    if (action ~ /[Dd]rag window/) return ""
    if (action ~ /[Ss]croll.*wheel|[Ww]orkspace scroll/) return ""
    return ""
}
function map_exec(cmd) {
    if (cmd ~ /osd\.sh[[:space:]]+volume[[:space:]]+up/) return "Volume up"
    if (cmd ~ /osd\.sh[[:space:]]+volume[[:space:]]+down/) return "Volume down"
    if (cmd ~ /osd\.sh[[:space:]]+volume[[:space:]]+mute/) return "Mute / unmute audio"
    if (cmd ~ /osd\.sh[[:space:]]+brightness[[:space:]]+up/) return "Brightness up"
    if (cmd ~ /osd\.sh[[:space:]]+brightness[[:space:]]+down/) return "Brightness down"
    if (cmd ~ /osd\.sh[[:space:]]+kbd_backlight/) return "Keyboard backlight"
    if (cmd ~ /osd\.sh[[:space:]]+power[[:space:]]+performance/) return "Power profile: performance"
    if (cmd ~ /osd\.sh[[:space:]]+power[[:space:]]+balanced/) return "Power profile: balanced"
    if (cmd ~ /osd\.sh[[:space:]]+power[[:space:]]+power-saver/) return "Power profile: power-saver"
    if (cmd ~ /powerprofilesctl set performance/) return "Power profile: performance"
    if (cmd ~ /powerprofilesctl set balanced/) return "Power profile: balanced"
    if (cmd ~ /powerprofilesctl set power-saver/) return "Power profile: power-saver"
    if (cmd ~ /wpctl set-mute[[:space:]]+@DEFAULT_AUDIO_SOURCE@/) return "Mute microphone"
    if (cmd ~ /blueman-manager/) return "Bluetooth settings"
    if (cmd ~ /nm-connection-editor/) return "Network connections (GUI)"
    if (cmd ~ /nmtui/) return "Network (terminal UI)"
    if (cmd ~ /thunar/) return "File manager (Thunar)"
    if (cmd ~ /galculator/) return "Calculator"
    if (cmd ~ /hyprpicker/) return "Color picker"
    if (cmd ~ /cursor/) return "Cursor IDE"
    if (cmd ~ /notepadnext/) return "Text editor"
    if (cmd ~ /zen-browser/) return "Web browser"
    if (cmd ~ /btop/) return "System monitor (btop)"
    if (cmd ~ /bluetoothctl/) return "Bluetooth (terminal)"
    if (cmd ~ /hyprlock|loginctl lock-session/) return "Lock session"
    if (cmd ~ /systemctl suspend/) return "Sleep (suspend)"
    if (cmd ~ /hyprctl reload/) return "Reload Hyprland config"
    if (cmd ~ /cliphist.*wofi.*wl-copy/) return "Clipboard history"
    if (cmd ~ /grim -g.*slurp/) return "Screenshot — select region"
    if (cmd ~ /grim[[:space:]]+\|[[:space:]]*wl-copy/) return "Screenshot — full display"
    if (cmd ~ /eyeprotect\.sh/) return "Eye protection toggle"
    if (cmd ~ /warp-nextdns-toggle/) return "WARP / NextDNS toggle"
    if (cmd ~ /screenrecord\.sh/) return "Screen recording"
    if (cmd ~ /Terminal -e nmtui/ || (cmd ~ /nmtui/ && cmd ~ /ghostty/)) return "Network (terminal UI)"
    if (cmd ~ /Terminal -e bluetoothctl/ || (cmd ~ /bluetoothctl/ && cmd ~ /ghostty/)) return "Bluetooth (terminal)"
    if (cmd ~ /\$terminal/ && cmd ~ /btop/) return "System monitor (btop)"
    if (cmd ~ /^\$terminal$/ || cmd ~ /^ghostty$/) return "Terminal"
    if (cmd ~ /\$terminal/ && cmd !~ /-e/) return "Terminal"
    if (cmd ~ /\$browser/) return "Web browser"
    if (cmd ~ /\$menu/) return "App launcher"
    if (cmd ~ /\$cheatsheet/) return "Keybind cheatsheet"
    if (cmd ~ /\$editor/) return "Text editor"
    return cmd
}
function pretty_keys(mod, key,    m, k) {
    m = trim(mod)
    k = trim(key)
    gsub(/\$mainMod/, "Super", m)
    gsub(/slash/, "/", k)
    gsub(/grave/, "`", k)
    gsub(/Backspace/, "⌫", k)
    gsub(/Return/, "Enter", k)
    gsub(/Space/, "Space", k)
    gsub(/mouse_down/, "Scroll ↓ (wheel)", k)
    gsub(/mouse_up/, "Scroll ↑ (wheel)", k)
    gsub(/mouse:272/, "Left drag", k)
    gsub(/mouse:273/, "Right drag", k)
    gsub(/KP_/, "Num·", k)
    if (m == "" || m == ",") return k
    gsub(/SHIFT/, "Shift", m)
    gsub(/CTRL/, "Ctrl", m)
    gsub(/ALT/, "Alt", m)
    gsub(/[[:space:]]+/, " ", m)
    return m " + " k
}
function describe(d, p) {
    p = trim(p)
    if (d == "exec") return map_exec(p)
    if (d == "killactive") return "Close focused window"
    if (d == "togglefloating") return "Toggle floating window"
    if (d == "fullscreen") return "Toggle fullscreen"
    if (d == "pseudo") return "Pseudo-tile branch"
    if (d == "togglesplit") return "Toggle split orientation"
    if (d == "exit") return "Exit Hyprland"
    if (d == "movefocus") {
        if (p == "l") return "Focus — left"
        if (p == "r") return "Focus — right"
        if (p == "u") return "Focus — up"
        if (p == "d") return "Focus — down"
        return "Focus — " p
    }
    if (d == "movewindow") {
        if (p ~ /^special:/) return "Move window — " p
        if (p == "l") return "Move window — left"
        if (p == "r") return "Move window — right"
        if (p == "u") return "Move window — up"
        if (p == "d") return "Move window — down"
        return "Move window — " p
    }
    if (d == "resizeactive") return "Resize window (step)"
    if (d == "workspace") {
        if (p == "e+1") return "Next workspace"
        if (p == "e-1") return "Previous workspace"
        return "Workspace " p
    }
    if (d == "movetoworkspace") return "Move window to workspace " p
    if (d == "togglespecialworkspace") return "Toggle scratchpad"
    return d (p != "" ? " — " p : "")
}
/^[[:space:]]*bindm[[:space:]]*=/ {
    line = $0
    sub(/#.*/, "", line)
    line = trim(line)
    sub(/^bindm[[:space:]]*=[[:space:]]*/, "", line)
    n = split(line, parts, ",")
    if (n < 3) next
    for (i = 1; i <= n; i++) parts[i] = trim(parts[i])
    mod = parts[1]; key = parts[2]; dispatcher = parts[3]
    keys = pretty_keys(mod, key)
    if (dispatcher == "movewindow") action = "Drag window - move"
    else if (dispatcher == "resizewindow") action = "Drag window - resize"
    else action = dispatcher
    ic = icon_for(action)
    printf "%s\t%s\t%s\n", ic, action, keys
    next
}
/^[[:space:]]*bind[[:space:]]*=/ {
    line = $0
    sub(/#.*/, "", line)
    line = trim(line)
    sub(/^bind[[:space:]]*=[[:space:]]*/, "", line)
    n = split(line, parts, ",")
    if (n < 3) next
    for (i = 1; i <= n; i++) parts[i] = trim(parts[i])
    mod = parts[1]; key = parts[2]; dispatcher = parts[3]
    params = ""
    for (i = 4; i <= n; i++) {
        if (params != "") params = params ", "
        params = params parts[i]
    }
    keys = pretty_keys(mod, key)
    action = describe(dispatcher, params)
    ic = icon_for(action)
    printf "%s\t%s\t%s\n", ic, action, keys
}
AWKEOF
}

if [[ -f "$CACHE_FILE" && -f "$MTIME_FILE" && "$(cat "$MTIME_FILE")" == "$fingerprint" ]]; then
    mapfile -t LINES < "$CACHE_FILE"
else
    mapfile -t LINES < <(build_lines)
    mkdir -p "$CACHE_DIR"
    if ((${#LINES[@]})); then
        printf '%s\n' "${LINES[@]}" > "$CACHE_FILE"
        printf '%s' "$fingerprint" > "$MTIME_FILE"
    fi
fi

if ((${#LINES[@]} == 0)); then
    echo "No keybinds parsed. Check configs under ${HYPR}."
    exit 1
fi

MENU_TEXT=$(printf '%s\n' "${LINES[@]}")

CHEATSHEET_ROFI_THEME="${HOME}/.config/rofi/cheatsheet-menu.rasi"

pick_rofi() {
    if [[ -f "$CHEATSHEET_ROFI_THEME" ]]; then
        printf '%s\n' "$MENU_TEXT" | rofi -dmenu -i -p "Keybinds" -theme "$CHEATSHEET_ROFI_THEME"
    else
        printf '%s\n' "$MENU_TEXT" | rofi -dmenu -i -p "Keybinds" \
            -theme-str "* { font: \"JetBrainsMono Nerd Font 12\"; } window { width: 840px; height: 60%; background-color: #151621; border: 2px; border-color: #2a2c3c; } listview { background-color: #151621; } element { background-color: #1e2030; text-color: #e0e2f0; } element selected { background-color: #26283a; border-color: #4fd6ff; text-color: #4fd6ff; }"
    fi
}

pick_wofi() {
    if [[ -f "${HOME}/.config/wofi/style.css" ]]; then
        printf '%s\n' "$MENU_TEXT" | wofi --dmenu -i \
            -p "Keybinds" \
            --width 840 --height 500 \
            --style "${HOME}/.config/wofi/style.css" 2>/dev/null
        return
    fi
    printf '%s\n' "$MENU_TEXT" | wofi --dmenu -i -p "Keybinds" --width 840
}

if command -v rofi &>/dev/null; then
    pick_rofi
elif command -v wofi &>/dev/null; then
    pick_wofi
elif command -v fzf &>/dev/null; then
    printf '%s\n' "$MENU_TEXT" | fzf --prompt "Keybinds > " --height 70% || true
fi
