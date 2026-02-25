#!/usr/bin/env bash

# Cheatsheet Script
# Extracts binds from hyprland.conf and displays them in Rofi/Wofi
# Uses the Ocean Sorbet pixel-perfect aesthetic

set -euo pipefail

CONF="$HOME/.config/hypr/hyprland.conf"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/pixel-rice"
CACHE_FILE="$CACHE_DIR/cheatsheet.cache"
MTIME_FILE="$CACHE_DIR/cheatsheet.mtime"

if [ ! -f "$CONF" ]; then
    echo "Config file not found: $CONF"
    exit 1
fi

get_mtime() {
    if stat -c %Y "$CONF" >/dev/null 2>&1; then
        stat -c %Y "$CONF"
    else
        stat -f %m "$CONF"
    fi
}

CONF_MTIME="$(get_mtime)"

if [ -f "$CACHE_FILE" ] && [ -f "$MTIME_FILE" ] && [ "$(cat "$MTIME_FILE")" = "$CONF_MTIME" ]; then
    KEYBINDS="$(cat "$CACHE_FILE")"
else
    KEYBINDS="$(
        awk '
        function trim(s) {
            sub(/^[ \t]+/, "", s)
            sub(/[ \t]+$/, "", s)
            return s
        }
        function map_exec(cmd, out) {
            gsub(/\$terminal/, "Terminal", cmd)
            gsub(/\$browser/, "Browser", cmd)
            gsub(/\$menu/, "App Launcher", cmd)
            gsub(/\$cheatsheet/, "Cheatsheet", cmd)

            if (cmd ~ /^powerprofilesctl set performance$/) return "Performance Mode"
            if (cmd ~ /^powerprofilesctl set balanced$/) return "Balanced Mode"
            if (cmd ~ /^powerprofilesctl set power-saver$/) return "Power-saver Mode"
            if (cmd ~ /blueman-manager/ || cmd ~ /blueberry/) return "Bluetooth GUI"
            if (cmd ~ /^Terminal -e bluetuith$/) return "Bluetooth TUI"
            if (cmd ~ /^nm-connection-editor$/) return "Network Manager GUI"
            if (cmd ~ /^Terminal -e nmtui$/) return "Network Manager TUI"
            if (cmd ~ /^thunar$/) return "File Manager"
            if (cmd ~ /yazi/) return "TUI File Manager"
            if (cmd ~ /^Terminal -e ranger$/) return "Ranger (Terminal)"
            if (cmd ~ /^Terminal -e btop$/) return "System Monitor"
            if (cmd ~ /^Terminal -e htop$/) return "htop"
            if (cmd ~ /^Terminal -e nvtop$/) return "GPU Monitor"
            if (cmd ~ /^cursor --new-window$/) return "Cursor IDE (New Window)"
            if (cmd ~ /^cursor$/) return "Cursor IDE"
            if (cmd ~ /^Terminal -e tmux new-session$/) return "Terminal + New tmux Session"
            if (cmd ~ /^Terminal -e tmux$/) return "Terminal + tmux"
            if (cmd ~ /hyprlock/ || cmd ~ /loginctl lock-session/) return "Lock Screen"
            if (cmd ~ /systemctl suspend/) return "Sleep"
            if (cmd ~ /wlogout/ || cmd ~ /hyprctl dispatch exit/) return "Logout Menu"
            if (cmd ~ /wpctl set-volume/ && cmd ~ /DEFAULT_AUDIO_SINK/ && cmd ~ /\+$/) return "Volume Up"
            if (cmd ~ /wpctl set-volume/ && cmd ~ /DEFAULT_AUDIO_SINK/ && cmd ~ /-$/) return "Volume Down"
            if (cmd ~ /wpctl set-mute/ && cmd ~ /DEFAULT_AUDIO_SINK/) return "Mute Output"
            if (cmd ~ /wpctl set-mute/ && cmd ~ /DEFAULT_AUDIO_SOURCE/) return "Mute Mic"
            if (cmd ~ /brightnessctl set/ && cmd ~ /\+$/) return "Brightness Up"
            if (cmd ~ /brightnessctl set/ && cmd ~ /-$/) return "Brightness Down"
            if (cmd ~ /^hyprctl reload$/) return "Reload Hyprland"
            if (cmd ~ /^Terminal -e sudo systemctl poweroff$/) return "Poweroff"
            if (cmd ~ /^Terminal -e sudo systemctl reboot$/) return "Reboot"
            if (cmd ~ /^hyprpicker -a$/) return "Color Picker"
            if (cmd ~ /cliphist list/ && cmd ~ /wl-copy/) return "Clipboard Manager"
            if (cmd ~ /hyprshot/ && cmd ~ /region/ && cmd ~ /silent/) return "Screenshot Region"
            if (cmd ~ /hyprshot/ && cmd ~ /output/ && cmd ~ /silent/) return "Screenshot Output"
            if (cmd ~ /hyprshot/ && cmd ~ /window/ && cmd ~ /silent/) return "Screenshot Window"

            return cmd
        }
        /^bind = / {
            line = $0
            sub(/^bind = /, "", line)
            n = split(line, parts, ",")
            for (i = 1; i <= n; i++) parts[i] = trim(parts[i])

            mod = parts[1]
            key = parts[2]
            dispatcher = parts[3]
            params = ""
            for (i = 4; i <= n; i++) {
                if (params != "") params = params ", "
                params = params parts[i]
            }

            keys = mod " + " key
            gsub(/\$mainMod/, "SUPER", keys)
            gsub(/slash/, "/", keys)
            gsub(/grave/, "`", keys)

            if (dispatcher == "exec") {
                action = map_exec(params)
            } else if (dispatcher == "killactive") {
                action = "Close Window"
            } else if (dispatcher == "togglefloating") {
                action = "Toggle Floating"
            } else if (dispatcher == "fullscreen") {
                action = "Toggle Fullscreen"
            } else if (dispatcher == "pseudo") {
                action = "Pseudo Tiling"
            } else if (dispatcher == "togglesplit") {
                action = "Toggle Split"
            } else if (dispatcher == "togglegroup") {
                action = "Toggle Group"
            } else if (dispatcher == "exit") {
                action = "Exit Hyprland"
            } else if (dispatcher == "movefocus") {
                if (params == "l") action = "Focus Left"
                else if (params == "r") action = "Focus Right"
                else if (params == "u") action = "Focus Up"
                else if (params == "d") action = "Focus Down"
                else action = "Focus " params
            } else if (dispatcher == "movewindow") {
                if (params == "l") action = "Move Window Left"
                else if (params == "r") action = "Move Window Right"
                else if (params == "u") action = "Move Window Up"
                else if (params == "d") action = "Move Window Down"
                else action = "Move Window " params
            } else if (dispatcher == "workspace") {
                action = "Workspace " params
            } else if (dispatcher == "movetoworkspace") {
                action = "Move to Workspace " params
            } else {
                action = dispatcher
                if (params != "") action = action " " params
            }

            print keys " -> " action
        }
        ' "$CONF" | LC_ALL=C sort
    )"

    mkdir -p "$CACHE_DIR"
    printf '%s\n' "$CONF_MTIME" > "$MTIME_FILE"
    printf '%s\n' "$KEYBINDS" > "$CACHE_FILE"
fi

# Display in Rofi with Ocean Sorbet pixel-perfect theme
printf '%s\n' "$KEYBINDS" | rofi -dmenu -i -p "KEYBINDS" -theme-str '
    * {
        font: "Terminus 12";
    }
    window {
        width: 50%;
        height: 60%;
        border: 2px;
        border-color: #46658C;
        background-color: #2D2D2D;
        padding: 10px;
    }
    mainbox {
        background-color: #2D2D2D;
    }
    inputbar {
        background-color: #46658C;
        text-color: #F2E9E9;
        padding: 8px;
    margin: 0px 0px 10px 0px;
        children: [ prompt, entry ];
    }
    prompt {
        background-color: #46658C;
        text-color: #F2E9E9;
        padding: 5px;
    }
    entry {
        background-color: #46658C;
        text-color: #F2E9E9;
        padding: 5px;
    }
    listview {
        background-color: #2D2D2D;
        scrollbar: false;
    }
    element {
        padding: 8px;
        background-color: #2D2D2D;
        text-color: #F2E9E9;
    }
    element selected {
        background-color: #46658C;
        text-color: #F2E9E9;
    }
    element-text {
        background-color: inherit;
        text-color: inherit;
    }
'
