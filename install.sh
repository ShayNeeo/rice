#!/usr/bin/env bash

# Pixel Rice Installer for Clean Minimal Arch Linux
# Optimized for fresh installations on minimal Arch systems
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure script runs from its directory and remember base path
cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

# --- Mode flags ---
MODE="full"  # "full" = packages + configs, "configs" = configs only (fast iteration)
for arg in "$@"; do
    case "$arg" in
        --configs-only|--configs|-c)
            MODE="configs"
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --configs-only, -c   Install configs only (skip packages, fast iteration)"
            echo "  --help, -h           Show this help"
            echo ""
            echo "Modes:"
            echo "  full     Install/update all packages + configs (default)"
            echo "  configs  Only sync configs to ~/.config and switch theme"
            exit 0
            ;;
        *)
            echo -e "${YELLOW}⚠️  Unknown option: $arg${NC}"
            ;;
    esac
done

echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Pixel Rice Installer for Arch               ║${NC}"
echo -e "${GREEN}║   Mode: ${BLUE}$(printf '%-35s' "$MODE")${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"

if [ "$MODE" = "full" ]; then
    # 0. Pre-flight Checks
    echo -e "\n${BLUE}[0/6] Pre-flight System Checks...${NC}"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Please run as your normal user (not sudo).${NC}"
    echo "   The script will request sudo when needed."
    exit 1
fi

# Check if on Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo -e "${RED}❌ This script is designed for Arch Linux only.${NC}"
    exit 1
fi

# Check internet connectivity
echo -n "   Checking internet connectivity... "
if ping -c 1 8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗${NC}"
    echo -e "${RED}❌ No internet connection. Please connect to the internet and try again.${NC}"
    exit 1
fi

# Check if pacman is not locked
if [ -f /var/lib/pacman/db.lck ]; then
    echo -e "${YELLOW}⚠️  Pacman database is locked. Attempting to remove lock...${NC}"
    sudo rm /var/lib/pacman/db.lck
fi

echo -e "${GREEN}✓ Pre-flight checks passed!${NC}"

# Detect laptop model for hardware-specific setup (GPU, power management)
LAPTOP_PROFILE="generic"
if [ -r /sys/class/dmi/id/product_name ]; then
    PRODUCT_NAME=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
    case "${PRODUCT_NAME}" in
        *[iI]dea[pP]ad*500*|*500*15*[iI][sS][kK]*|*80EC*|*80NT*)
            LAPTOP_PROFILE="ideapad500"
            echo -e "   ${GREEN}✓${NC} Detected: Lenovo Ideapad 500-15ISK (Intel i7 + AMD Radeon R7 M360/M370)"
            ;;
        *[tT]hink[Bb]ook*14[pP]*|*14[pP]*[gG]2*|*20YM*)
            LAPTOP_PROFILE="thinkbook14p"
            echo -e "   ${GREEN}✓${NC} Detected: Lenovo ThinkBook 14p Gen 2 (AMD Ryzen, no dGPU)"
            ;;
        *)
            echo "   Laptop: $PRODUCT_NAME (using generic profile)"
            ;;
    esac
fi

# 1. System Update
echo -e "\n${BLUE}[1/6] Updating System...${NC}"
# Initialize pacman keyring if needed
if [ ! -d /etc/pacman.d/gnupg ]; then
    echo "   Initializing pacman keyring..."
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
fi

# Update keyring first
sudo pacman -Sy --needed --noconfirm archlinux-keyring

# Full system update
sudo pacman -Syu --noconfirm

# 2. Install Base Dependencies
echo -e "\n${BLUE}[2/6] Installing Base Dependencies...${NC}"
echo "   Installing base-devel, git, and essential tools..."

# Detect kernel and install appropriate headers
if pacman -Qq linux-zen >/dev/null 2>&1; then
    echo "   Detected linux-zen kernel, installing linux-zen-headers..."
    KERNEL_HEADERS="linux-zen-headers"
elif pacman -Qq linux >/dev/null 2>&1; then
    echo "   Detected linux kernel, installing linux-headers..."
    KERNEL_HEADERS="linux-headers"
else
    echo -e "   ${YELLOW}⚠️  No standard kernel detected, defaulting to linux-headers${NC}"
    KERNEL_HEADERS="linux-headers"
fi

sudo pacman -S --needed --noconfirm \
    base-devel \
    $KERNEL_HEADERS \
    git \
    wget \
    curl \
    rsync \
    jq \
    unzip \
    tar \
    nano \
    vim \
    which \
    man-db \
    man-pages

# 3. Setup AUR Helper
echo -e "\n${BLUE}[3/6] Setting up AUR Helper...${NC}"
if command -v yay >/dev/null; then
    echo "   yay is already installed."
    AUR_HELPER="yay"
elif command -v paru >/dev/null; then
    echo "   paru is already installed."
    AUR_HELPER="paru"
else
    echo "   Installing yay-bin from AUR..."
    cd /tmp
    rm -rf yay-bin
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    # Always return to installer directory (SCRIPT_DIR), not /tmp
    cd "$SCRIPT_DIR"
    AUR_HELPER="yay"
    echo -e "   ${GREEN}✓ yay installed successfully${NC}"
fi

# 4. Remove Conflicts
echo -e "\n${BLUE}[4/6] Removing Conflicting Packages...${NC}"
CONFLICTS=(dunst mako sway i3 dwm)
for pkg in "${CONFLICTS[@]}"; do
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
        echo "   Removing $pkg..."
        sudo pacman -Rns --noconfirm "$pkg" || true
    fi
done

# 5. Install Rice Packages
echo -e "\n${BLUE}[5/6] Installing Rice Packages...${NC}"
echo "   This may take a while on first installation..."

# Core Hyprland and Wayland
$AUR_HELPER -S --needed --noconfirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    qt5-wayland \
    qt6-wayland \
    polkit-kde-agent \
    polkit-gnome

# Terminal and Shell (Ghostty with safe fallbacks)
echo "   Installing terminal (Ghostty, with fallback)..."
if ! sudo pacman -S --needed --noconfirm ghostty 2>/dev/null; then
    echo -e "   ${YELLOW}⚠️  ghostty (repo) not available, trying AUR ghostty-git...${NC}"
    $AUR_HELPER -S --needed --noconfirm ghostty-git || {
        echo -e "   ${YELLOW}⚠️  ghostty install failed, installing alacritty as fallback terminal${NC}"
        sudo pacman -S --needed --noconfirm alacritty || true
    }
fi

sudo pacman -S --needed --noconfirm bash-completion

# Input Method (fcitx5 with Vietnamese support)
# Switched to fcitx5-lotus-git (Vietnamese IME, same author as VMK fork)
$AUR_HELPER -S --needed --noconfirm \
    fcitx5 \
    fcitx5-gtk \
    fcitx5-qt \
    fcitx5-configtool \
    fcitx5-lotus-git

# Wayland Utilities
$AUR_HELPER -S --needed --noconfirm \
    waybar \
    rofi-wayland \
    wofi \
    wl-clipboard \
    cliphist \
    grim \
    slurp \
    swappy \
    wl-screenrec

# Fonts (repo + AUR via yay/paru)
$AUR_HELPER -S --needed --noconfirm \
    ttf-terminus-nerd \
    ttf-font-awesome \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji \
    noto-fonts-cjk \
    ebgaramond-otf \
    ttf-wps-fonts \
    ttf-ms-fonts

# LaTeX Support (User Request)
echo "   Installing LaTeX/XeLaTeX packages (TexLive)..."
sudo pacman -S --needed --noconfirm \
    texlive-bin \
    texlive-basic \
    texlive-latexextra \
    texlive-fontsextra \
    texlive-bibtexextra \
    texlive-binextra \
    texlive-langother

# Hypr Ecosystem
$AUR_HELPER -S --needed --noconfirm \
    hyprpaper \
    hyprlock \
    hypridle \
    wlogout \
    hyprpicker \
    wlsunset

# Audio
$AUR_HELPER -S --needed --noconfirm \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    pavucontrol \
    pamixer

# Bluetooth
$AUR_HELPER -S --needed --noconfirm \
    bluez \
    bluez-utils \
    blueman

# Network
$AUR_HELPER -S --needed --noconfirm \
    networkmanager \
    network-manager-applet

# File Manager and GTK
$AUR_HELPER -S --needed --noconfirm \
    thunar \
    thunar-archive-plugin \
    thunar-volman \
    tumbler \
    ffmpegthumbnailer \
    gvfs \
    file-roller \
    qt6ct \
    kvantum

# Theming
$AUR_HELPER -S --needed --noconfirm \
    gtk-engine-murrine \
    gnome-themes-extra \
    papirus-icon-theme \
    gsettings-desktop-schemas

# Browser (default: Floorp — Firefox-based, rectangular UI, GTK dark theme support)
CHOSEN_BROWSER_BIN=""
echo "   Installing Floorp (default browser)..."
if $AUR_HELPER -S --needed --noconfirm floorp-bin; then
    CHOSEN_BROWSER_BIN="floorp"
else
    echo -e "${YELLOW}   ⚠️  floorp-bin install failed, falling back to Firefox${NC}"
    sudo pacman -S --needed --noconfirm firefox && CHOSEN_BROWSER_BIN="firefox"
fi

# Optional: Zen Browser (Gecko-based, Firefox-compatible rendering)
echo ""
read -r -p "   Also install Zen Browser (zen-browser-bin)? [y/N]: " ZEN_INSTALL
if [[ "$ZEN_INSTALL" =~ ^[Yy] ]]; then
    echo "   Installing zen-browser-bin..."
    $AUR_HELPER -S --needed --noconfirm zen-browser-bin || {
        echo -e "${YELLOW}   ⚠️  zen-browser-bin install failed, continuing...${NC}"
    }
fi

# Optional: Thorium (Chromium AVX2 — fast but can't be themed to rectangular)
echo ""
read -r -p "   Also install Thorium (thorium-browser-avx2-bin, Chromium AVX2)? [y/N]: " THORIUM_INSTALL
if [[ "$THORIUM_INSTALL" =~ ^[Yy] ]]; then
    echo "   Installing thorium-browser-avx2-bin..."
    $AUR_HELPER -S --needed --noconfirm thorium-browser-avx2-bin || {
        echo -e "${YELLOW}   ⚠️  thorium-browser-avx2-bin install failed, continuing...${NC}"
    }
fi

# Developer CLIs (GitHub, Copilot)
echo "   Installing developer CLIs: github-cli and github-copilot-cli-bin..."
sudo pacman -S --needed --noconfirm github-cli || {
    echo -e "${YELLOW}   WARNING: github-cli install failed, continuing...${NC}"
}
$AUR_HELPER -S --needed --noconfirm github-copilot-cli-bin || {
    echo -e "${YELLOW}   WARNING: github-copilot-cli-bin install failed, continuing...${NC}"
}

# Install antigravity-bin
echo "   Installing antigravity-bin..."
$AUR_HELPER -S --needed --noconfirm antigravity-bin || {
    echo -e "${YELLOW}   WARNING: antigravity-bin install failed, continuing...${NC}"
}

# Install Zed Editor (main editor)
echo "   Installing Zed Editor..."
$AUR_HELPER -S --needed --noconfirm zed || {
    echo -e "${YELLOW}   WARNING: Zed install failed, continuing...${NC}"
}

# Text Editor (notepadnext - kept as alternative)
echo "   Installing notepadnext..."
$AUR_HELPER -S --needed --noconfirm notepadnext-bin || {
    echo -e "${YELLOW}   ⚠️  notepadnext not found, using nano as fallback${NC}"
}

# Note-taking (Obsidian)
echo "   Installing Obsidian..."
$AUR_HELPER -S --needed --noconfirm obsidian-bin || {
    echo -e "${YELLOW}   ⚠️  obsidian-bin not found, continuing...${NC}"
}

# Optional: Obsidian Vault + Community Plugins Setup
echo ""
read -r -p "   Set up Obsidian vault with community plugins? [y/N]: " OBSIDIAN_SETUP
if [[ "$OBSIDIAN_SETUP" =~ ^[Yy]$ ]]; then
    echo ""
    echo "   🔷 Obsidian Vault Setup"
    echo ""

    # Ask for vault directory
    read -r -p "   Vault directory (default: ~/Obsidian): " VAULT_INPUT
    OBSIDIAN_VAULT="${VAULT_INPUT:-$HOME/Obsidian}"

    # Create vault structure
    echo "   Creating vault at: $OBSIDIAN_VAULT"
    mkdir -p "$OBSIDIAN_VAULT/.obsidian/plugins"
    for dir in Dashboard Inbox Knowledge "Daily Notes" Templates Attachments Archive Meta "Excalidraw/Scripts" Projects Areas Resources; do
        mkdir -p "$OBSIDIAN_VAULT/$dir"
    done

    # Plugin list: "plugin_id|owner/repo"
    OBSIDIAN_PLUGINS=(
        "obsidian-agent-client|RAIT-09/obsidian-agent-client"
        "katmer-code|hkcanan/katmer-code"
        "smart-connections|brianpetro/obsidian-smart-connections"
        "file-hider|Eldritch-Oliver/file-hider"
        "cmdr|phibr0/obsidian-commander"
        "file-explorer-note-count|ozntel/file-explorer-note-count"
        "file-explorer-plus-plus|kelszo/obsidian-file-explorer-plus"
        "notebook-navigator|johansan/notebook-navigator"
        "homepage|mirnovov/obsidian-homepage"
        "omnisearch|scambier/obsidian-omnisearch"
        "obsidian-icon-folder|FlorianWoelki/obsidian-iconize"
        "obsidian-file-color|ecustic/obsidian-file-color"
        "colored-tags|code-of-chaos/obsidian-colored_tags_wrangler"
        "calendar|liamcain/obsidian-calendar-plugin"
        "tag-wrangler|pjeby/tag-wrangler"
        "ninja-cursor|vrtmrz/ninja-cursor"
        "code-styler|mayurankv/obsidian-code-styler"
        "obsidian-admonition|valentine195/obsidian-admonition"
        "obsidian-advanced-uri|Vinzent03/obsidian-advanced-uri"
        "better-codeblock|stargrey/obsidian-better-codeblock"
        "obsidian-outliner|vslinko/obsidian-outliner"
        "update-time-on-edit|beaussan/update-time-on-edit-obsidian"
        "obsidian-linter|platers/obsidian-linter"
        "meta-bind|mProjectsCode/obsidian-meta-bind-plugin"
        "dataview|blacksmithgu/obsidian-dataview"
        "obsidian-tasks-plugin|obsidian-tasks-group/obsidian-tasks"
        "obsidian-excalidraw-plugin|zsviczian/obsidian-excalidraw-plugin"
        "obsidian-mind-map|lynchjames/obsidian-mind-map"
        "heatmap-tracker|mokkiebear/heatmap-tracker"
        "obsidian-git|denolehov/obsidian-git"
        "remotely-save|remotely-save/remotely-save"
        "obsidian42-brat|TfTHacker/obsidian42-brat"
        "agentfiles|Railly/agentfiles"
    )

    PLUGIN_DIR="$OBSIDIAN_VAULT/.obsidian/plugins"
    TOTAL=${#OBSIDIAN_PLUGINS[@]}
    INSTALLED=0
    FAILED=0

    echo ""
    echo "   📦 Installing $TOTAL community plugins..."
    echo ""

    for entry in "${OBSIDIAN_PLUGINS[@]}"; do
        IFS='|' read -r plugin_id repo <<< "$entry"
        plugin_dir="$PLUGIN_DIR/$plugin_id"

        if [ -d "$plugin_dir" ] && [ -f "$plugin_dir/main.js" ] && [ -s "$plugin_dir/main.js" ]; then
            echo "     ✅ $plugin_id (already installed)"
            ((INSTALLED++))
            continue
        fi

        echo -n "     ⬇️  $plugin_id... "
        mkdir -p "$plugin_dir"

        # Try GitHub releases first
        release_json=$(curl -sL "https://api.github.com/repos/$repo/releases/latest" 2>/dev/null || echo "{}")
        main_url=$(echo "$release_json" | python3 -c "
import sys,json
try:
    for a in json.load(sys.stdin).get('assets',[]):
        if a['name']=='main.js': print(a['browser_download_url']); break
except: pass
" 2>/dev/null)

        # Fallback: raw from default branch
        if [ -z "$main_url" ]; then
            branch="master"
            curl -sI "https://raw.githubusercontent.com/$repo/main/main.js" 2>/dev/null | head -1 | grep -q "200" && branch="main"
            # Special case: agentfiles uses refs/heads/main
            if [ "$plugin_id" = "agentfiles" ]; then
                branch="refs/heads/main"
            fi
            main_url="https://raw.githubusercontent.com/$repo/$branch/main.js"
            manifest_url="https://raw.githubusercontent.com/$repo/$branch/manifest.json"
            styles_url="https://raw.githubusercontent.com/$repo/$branch/styles.css"
        fi

        ok=true
        curl -sL -o "$plugin_dir/main.js" "$main_url" 2>/dev/null || ok=false
        [ -n "$manifest_url" ] && curl -sL -o "$plugin_dir/manifest.json" "$manifest_url" 2>/dev/null || true
        [ -n "$styles_url" ] && curl -sL -o "$plugin_dir/styles.css" "$styles_url" 2>/dev/null || true

        if [ "$ok" = true ] && [ -s "$plugin_dir/main.js" ] && ! head -1 "$plugin_dir/main.js" | grep -qi "404"; then
            echo "✅"
            ((INSTALLED++))
        else
            echo "❌"
            rm -rf "$plugin_dir"
            ((FAILED++))
        fi
    done

    echo ""
    echo "   📊 Plugins: $INSTALLED installed, $FAILED failed"

    if [ "$FAILED" -gt 0 ]; then
        echo -e "   ${YELLOW}⚠️  Some plugins failed. Install them manually in Obsidian Settings → Community Plugins.${NC}"
    fi

    # Write community-plugins.json
    plugin_ids=()
    for entry in "${OBSIDIAN_PLUGINS[@]}"; do
        IFS='|' read -r pid _ <<< "$entry"
        if [ -d "$PLUGIN_DIR/$pid" ] && [ -f "$PLUGIN_DIR/$pid/main.js" ]; then
            plugin_ids+=("\"$pid\"")
        fi
    done
    printf '[\n  %s\n]\n' "$(IFS=', '; echo "${plugin_ids[*]}")" | python3 -c "
import sys, json
plugins = json.loads(sys.stdin.read())
json.dump(plugins, open('$OBSIDIAN_VAULT/.obsidian/community-plugins.json', 'w'), indent=2)
"

    # Copy config files from obsidian-vault template
    if [ -d "$SCRIPT_DIR/obsidian-vault/.obsidian" ]; then
        for f in app.json appearance.json core-plugins.json hotkeys.json templates.json daily-notes.json bookmarks.json plugins-config.json; do
            if [ -f "$SCRIPT_DIR/obsidian-vault/.obsidian/$f" ]; then
                cp "$SCRIPT_DIR/obsidian-vault/.obsidian/$f" "$OBSIDIAN_VAULT/.obsidian/$f"
            fi
        done
    fi

    # Copy vault content
    for f in "Dashboard/DASHBOARD.md" "Life Starts Here.md" "README.md" "AUDIT.md" ".gitignore"; do
        if [ -f "$SCRIPT_DIR/obsidian-vault/$f" ]; then
            mkdir -p "$(dirname "$OBSIDIAN_VAULT/$f")"
            cp "$SCRIPT_DIR/obsidian-vault/$f" "$OBSIDIAN_VAULT/$f"
        fi
    done
    for f in "Templates/Daily Note.md" "Templates/Meeting Note.md" "Templates/Technical Spec.md"; do
        if [ -f "$SCRIPT_DIR/obsidian-vault/$f" ]; then
            cp "$SCRIPT_DIR/obsidian-vault/$f" "$OBSIDIAN_VAULT/$f"
        fi
    done

    # Init git repo to prevent warning
    if [ ! -d "$OBSIDIAN_VAULT/.git" ]; then
        echo ""
        echo "   🔧 Initializing git repo in vault (removes 'not a git repo' warning)..."
        (cd "$OBSIDIAN_VAULT" && git init && git add -A && git commit -m "init: obsidian vault" >/dev/null 2>&1)
        echo -e "   ${GREEN}✓${NC} Git repo initialized"
    fi

    # Configure Agent Client for user's AI tools
    echo ""
    echo "   🤖 Configuring AI agents:"
    echo "      - Qwen Code:      $(command -v qwen 2>/dev/null || echo 'not found')"
    echo "      - Gemini CLI:     $(command -v gemini 2>/dev/null || echo 'not found')"
    echo "      - Copilot CLI:    $(command -v github-copilot-cli 2>/dev/null || echo 'not found')"
    echo ""
    echo "   To use AI agents in Obsidian:"
    echo "   1. Open vault → Settings → Agent Client"
    echo "   2. Set path for Qwen: $(command -v qwen 2>/dev/null || echo '~/.npm-global/bin/qwen')"
    echo "   3. Set path for Gemini: $(command -v gemini 2>/dev/null || echo '~/.local/bin/gemini')"
    echo "   4. Add --experimental-acp to Arguments field for both"

    echo ""
    echo -e "   ${GREEN}✓${NC} Obsidian vault setup complete at: $OBSIDIAN_VAULT"
    echo "   Open Obsidian → File → Open folder as vault → $OBSIDIAN_VAULT"
fi

# Optional: Office suite (LibreOffice or WPS 365)
echo ""
read -r -p "   Choose office suite: [L]ibreOffice fresh / [W]PS Office 365 / [N]one (default N): " OFFICE_SUITE
if [[ "$OFFICE_SUITE" =~ ^[Ll]$ ]]; then
    echo "   Installing LibreOffice Fresh..."
    sudo pacman -S --needed --noconfirm libreoffice-fresh || {
        echo -e "${YELLOW}   ⚠️  libreoffice-fresh install failed, continuing...${NC}"
    }
elif [[ "$OFFICE_SUITE" =~ ^[Ww]$ ]]; then
    echo "   Installing WPS Office 365..."
    $AUR_HELPER -S --needed --noconfirm wps-office-365 || {
        echo -e "${YELLOW}   ⚠️  wps-office-365 install failed, skipping WPS setup${NC}"
    }

    if command -v wps >/dev/null 2>&1; then
        echo "   Applying WPS document-open compatibility fix..."

        # Ensure user-owned config paths so WPS wrappers can write Office.conf and MIME defaults.
        [ -d "$HOME/.config" ] && sudo chown -R "$(whoami):$(whoami)" "$HOME/.config" || true
        mkdir -p "$HOME/.local/share"
        sudo chown -R "$(whoami):$(whoami)" "$HOME/.local/share" || true
        chmod u+rwX "$HOME/.config" "$HOME/.local/share" 2>/dev/null || true

        # Backup WPS config if already created.
        if [ -f "$HOME/.config/Kingsoft/Office.conf" ]; then
            cp -a "$HOME/.config/Kingsoft/Office.conf" "$HOME/.config/Kingsoft/Office.conf.bak.$(date +%F-%H%M%S)" || true
        fi

        # Force fusion mode and disable cloud/startpage auto-routing (qingbangong).
        python3 - <<'PY' || true
from pathlib import Path
import re
home = Path.home()
p = home / ".config" / "Kingsoft" / "Office.conf"
p.parent.mkdir(parents=True, exist_ok=True)
s = p.read_text(errors="ignore") if p.exists() else ""
if "[6.0]" not in s:
    s += "\n[6.0]\n"
def set_key(text, key, value):
    pat = rf"(?m)^{re.escape(key)}=.*$"
    line = f"{key}={value}"
    if re.search(pat, text):
        return re.sub(pat, line, text)
    return text + ("\n" if not text.endswith("\n") else "") + line + "\n"
s = set_key(s, r"wpsoffice\Application%20Settings\AppComponentMode", "prome_fushion")
s = set_key(s, r"common\startFrom", "local")
s = set_key(s, r"common\useCloud", "false")
s = set_key(s, r"common\silentautologin", "false")
s = set_key(s, r"common\AutoLogin", "false")
s = set_key(s, r"common\kstartpage", "false")
p.write_text(s)
print(f"Updated {p}")
PY

        # Re-assert desktop associations for WPS.
        xdg-mime default wps-office-prometheus.desktop application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document application/wps-office.docx
        xdg-mime default wps-office-pdf.desktop application/pdf
        update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
        update-mime-database "$HOME/.local/share/mime" 2>/dev/null || true

        echo -e "   ${GREEN}✓${NC} WPS Office 365 setup complete (DOCX/PDF open fix applied)"
    fi
fi

# Node.js, Bun and Development Tools
echo "   Installing Node.js, Bun, and development tools..."
sudo pacman -S --needed --noconfirm nodejs npm bun

# Gemini CLI (AI assistant)
echo "   Installing Gemini CLI..."
if ! command -v gemini >/dev/null 2>&1; then
    # Install globally without sudo to avoid permission issues
    bun install -g @google/gemini-cli
    echo -e "   ${GREEN}✓${NC} Installed Gemini CLI"
else
    echo "   Gemini CLI already installed"
fi

# System Tools
$AUR_HELPER -S --needed --noconfirm \
    galculator \
    brightnessctl \
    playerctl \
    power-profiles-daemon \
    udiskie \
    tmux \
    yazi \
    ueberzugpp \
    poppler \
    fd \
    ripgrep \
    fzf \
    zoxide \
    blesh-git \
    btop \
    htop \
    neofetch

# Shell Enhancement (Command Prediction)
echo "   Installing Atuin for intelligent command history..."
# Use official repo package 'atuin' instead of AUR 'atuin-bin'
$AUR_HELPER -S --needed --noconfirm atuin || {
    echo -e "${YELLOW}   ⚠️  atuin install failed; you can also install it later with 'sudo pacman -S atuin'${NC}"
}

# GPU Monitoring and Power Management (Auto-detect)
# Distinguish: Intel+AMD hybrid (Ideapad 500-15ISK) vs AMD-only Ryzen (ThinkBook 14p)
echo "   Detecting GPU for monitoring and power tools..."
HAS_INTEL_GPU=0
HAS_AMD_GPU=0
HAS_NVIDIA_GPU=0
lspci | grep -iE 'VGA|3D' | grep -iq 'Intel' && HAS_INTEL_GPU=1
lspci | grep -iE 'VGA|3D' | grep -iq 'AMD\|ATI' && HAS_AMD_GPU=1
lspci | grep -iE 'VGA|3D' | grep -iq 'NVIDIA' && HAS_NVIDIA_GPU=1

# AMD CPU check (ryzenadj only useful on Ryzen APU, not Intel+AMD dGPU)
CPU_IS_AMD=0
grep -q 'AuthenticAMD' /proc/cpuinfo 2>/dev/null && CPU_IS_AMD=1

if [ "$HAS_INTEL_GPU" -eq 1 ] && [ "$HAS_AMD_GPU" -eq 1 ]; then
    echo "   Intel + AMD hybrid (e.g. Ideapad 500-15ISK): Installing drivers & monitoring tools..."
    
    # Drivers for Hardware Acceleration and Vulkan
    # Note: libva-mesa-driver is now provided by the 'mesa' package
    sudo pacman -S --needed --noconfirm \
        intel-media-driver \
        libva-intel-driver \
        libvdpau-va-gl \
        vulkan-intel \
        vulkan-radeon \
        vulkan-icd-loader \
        libva-utils \
        vdpauinfo \
        vulkan-tools \
        intel-gpu-tools

    $AUR_HELPER -S --needed --noconfirm amdgpu_top-bin || {
        echo -e "   ${YELLOW}⚠️  amdgpu_top install failed, continuing...${NC}"
    }
elif [ "$HAS_AMD_GPU" -eq 1 ] && [ "$CPU_IS_AMD" -eq 1 ]; then
    echo "   AMD GPU + AMD CPU (e.g. ThinkBook 14p Ryzen): amdgpu_top and ryzenadj..."
    $AUR_HELPER -S --needed --noconfirm amdgpu_top-bin ryzenadj || {
        echo -e "   ${YELLOW}⚠️  amdgpu_top/ryzenadj install failed, continuing...${NC}"
    }
elif [ "$HAS_NVIDIA_GPU" -eq 1 ]; then
    echo "   NVIDIA GPU detected, installing nvtop..."
    $AUR_HELPER -S --needed --noconfirm nvtop || {
        echo -e "   ${YELLOW}⚠️  nvtop install failed, continuing...${NC}"
    }
elif [ "$HAS_INTEL_GPU" -eq 1 ]; then
    echo "   Intel GPU only, installing intel-gpu-tools..."
    sudo pacman -S --needed --noconfirm intel-gpu-tools || true
else
    echo -e "   ${YELLOW}⚠️  No specific GPU detected, skipping GPU monitoring tools${NC}"
fi

# Notification (SwayNotificationCenter; prefer repo, fallback to AUR git)
echo "   Installing notification center (swaync)..."
if ! sudo pacman -S --needed --noconfirm swaync 2>/dev/null; then
    echo -e "   ${YELLOW}⚠️  swaync (repo) not available, trying AUR swaync-git...${NC}"
    $AUR_HELPER -S --needed --noconfirm swaync-git || {
        echo -e "   ${YELLOW}⚠️  swaync install failed, notifications will be limited until you install it manually${NC}"
    }
fi

# Display Manager (SDDM)
echo "   Installing SDDM display manager..."
# Note: SDDM >= 0.20.0 required to avoid Hyprland bug 1476 (90s shutdown times)
sudo pacman -S --needed --noconfirm \
    sddm \
    qt6-svg \
    qt6-declarative \
    qt5-quickcontrols2 \
    qt5-graphicaleffects \
    qt5-svg \
    qt5-wayland \
    qt6-wayland \
    qt6-5compat

# Install layer-shell-qt (optional, for better Wayland support)
sudo pacman -S --needed --noconfirm layer-shell-qt 2>/dev/null || {
    echo -e "   ${YELLOW}⚠️  layer-shell-qt not found, continuing...${NC}"
}

echo -e "${GREEN}✓ All packages installed successfully!${NC}"

# 6. Enable System Services
echo -e "\n${BLUE}[6/6] Enabling System Services...${NC}"

# Enable NetworkManager
if ! systemctl is-enabled NetworkManager >/dev/null 2>&1; then
    echo "   Enabling NetworkManager..."
    sudo systemctl enable NetworkManager
    sudo systemctl start NetworkManager
fi

# Enable Bluetooth
if ! systemctl is-enabled bluetooth >/dev/null 2>&1; then
    echo "   Enabling Bluetooth..."
    sudo systemctl enable bluetooth
    sudo systemctl start bluetooth
fi

# Enable fcitx5 Lotus server (backend for Vietnamese input)
echo "   Enabling fcitx5-lotus server..."
if ! systemctl is-enabled "fcitx5-lotus-server@$(whoami).service" >/dev/null 2>&1; then
    sudo systemctl enable --now "fcitx5-lotus-server@$(whoami).service" 2>/dev/null || {
        echo "   fcitx5-lotus server user not found or not ready, running systemd-sysusers..."
        sudo systemd-sysusers || true
        sudo systemctl enable --now "fcitx5-lotus-server@$(whoami).service" 2>/dev/null || \
            echo -e "   ${YELLOW}⚠️  Failed to enable fcitx5-lotus-server. Please check manually with: systemctl status fcitx5-lotus-server@$(whoami).service${NC}"
    }
fi

# Enable Power Profiles Daemon
if ! systemctl is-enabled power-profiles-daemon >/dev/null 2>&1; then
    echo "   Enabling Power Profiles..."
    sudo systemctl enable power-profiles-daemon
    sudo systemctl start power-profiles-daemon
fi

# Install Ryzen Power Management Service if ryzenadj is installed
if command -v ryzenadj >/dev/null 2>&1; then
    echo "   Installing Ryzen Power Management (manage_power.sh + systemd path trigger)..."
    sudo cp "$SCRIPT_DIR/scripts/manage_power.sh" /usr/local/bin/manage_power.sh
    sudo chmod +x /usr/local/bin/manage_power.sh

    # Remove old polling-based service if it exists
    sudo systemctl disable --now ryzen-power.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/ryzen-power.service

    # Install new oneshot service + PathChanged trigger
    if [ -f "$SCRIPT_DIR/systemd/ryzen-power.service" ]; then
        sudo cp "$SCRIPT_DIR/systemd/ryzen-power.service" /etc/systemd/system/ryzen-power.service
    fi
    if [ -f "$SCRIPT_DIR/systemd/ryzen-power.path" ]; then
        sudo cp "$SCRIPT_DIR/systemd/ryzen-power.path" /etc/systemd/system/ryzen-power.path
    fi

    sudo systemctl daemon-reload
    sudo systemctl enable --now ryzen-power.path
    echo -e "   ${GREEN}✓${NC} Ryzen Power Management: oneshot service + PathChanged trigger enabled"
    echo "   (triggers on /sys/firmware/acpi/platform_profile change — no polling)"
fi

# Disable conflicting display managers
echo "   Disabling conflicting display managers..."
for dm in gdm lightdm lxdm; do
    if systemctl is-enabled "$dm" >/dev/null 2>&1; then
        echo "   Disabling $dm..."
        sudo systemctl disable "$dm" 2>/dev/null || true
    fi
done

# Kernel-level power tuning (applied at boot via modprobe/sysctl)
echo "   Installing kernel power tuning configs..."

# AMDGPU power saving at driver level
sudo tee /etc/modprobe.d/amdgpu-powersave.conf > /dev/null <<'EOF'
# AMDGPU: Force DPM, enable ASPM, reduce power
options amdgpu ppfeaturemask=0xffffffff dpm=1 aspm=1 bapm=1
EOF
echo -e "   ${GREEN}✓${NC} amdgpu-powersave.conf"

# USB autosuspend at boot
sudo tee /etc/modprobe.d/usb-autosuspend.conf > /dev/null <<'EOF'
options usbcore autosuspend=2
EOF
echo -e "   ${GREEN}✓${NC} usb-autosuspend.conf"

# VM tuning for power saving (less frequent disk writes)
sudo tee /etc/sysctl.d/99-power-saving.conf > /dev/null <<'EOF'
# Dirty writeback: batch writes, reduce disk spin-ups
vm.dirty_writeback_centisecs = 500
vm.dirty_expire_centisecs = 6000
# NMI watchdog: disable to save ~0.5W idle
kernel.nmi_watchdog = 0
# Laptop mode
vm.laptop_mode = 5
EOF
echo -e "   ${GREEN}✓${NC} 99-power-saving.conf"

# udev rules for PCIe runtime PM
sudo mkdir -p /etc/udev/rules.d
sudo tee /etc/udev/rules.d/81-pm-powersave.rules > /dev/null <<'EOF'
# Enable runtime PM for all PCI devices
ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
# Enable USB autosuspend
ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
# I2C controllers (touchpad)
ACTION=="add", SUBSYSTEM=="i2c", ATTR{power/control}="auto"
# Sound codecs
ACTION=="add", SUBSYSTEM=="sound", ATTR{power/control}="auto"
ACTION=="add", SUBSYSTEM=="snd", ATTR{power/control}="auto"
EOF
echo -e "   ${GREEN}✓${NC} 81-pm-powersave.rules"

# ThinkBook 14p Gen 2 ACH (AMD Ryzen 7 5800H) — verified power tuning
if [ "$LAPTOP_PROFILE" = "thinkbook14p" ]; then
    echo "   Applying ThinkBook 14p Gen 2 ACH verified power tuning..."

    # Add pcie_aspm.policy=powersupersave to bootloader entries
    if [ -d /boot/loader/entries ]; then
        for entry in /boot/loader/entries/*.conf; do
            [ -f "$entry" ] || continue
            if ! grep -q 'pcie_aspm' "$entry" 2>/dev/null; then
                sudo sed -i 's/^options /&pcie_aspm.policy=powersupersave /' "$entry"
                echo -e "   ${GREEN}✓${NC} Added pcie_aspm.policy=powersupersave to $(basename "$entry")"
            fi
        done
    fi

    # AMDGPU specific power management for integrated Radeon graphics
    if [ -d /sys/class/drm/card0/device ]; then
        # Force lowest DPM state in power-saver mode
        if [ -w /sys/class/drm/card0/device/power_dpm_force_performance_level ]; then
            echo "manual" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
            echo "1" | sudo tee /sys/class/drm/card0/device/pp_dpm_sclk 2>/dev/null || true
            echo -e "   ${GREEN}✓${NC} AMDGPU: locked to lowest DPM state"
        fi
    fi
fi

# Ensure sddm user exists with correct permissions
if ! id sddm >/dev/null 2>&1; then
    echo "   Creating sddm user..."
    sudo useradd -r -M -d /var/lib/sddm -s /usr/bin/nologin sddm
fi
sudo mkdir -p /var/lib/sddm
sudo chown -R sddm:sddm /var/lib/sddm

# Configure SDDM to auto-restart on logout
echo "   Configuring SDDM service..."
sudo mkdir -p /etc/systemd/system/sddm.service.d
sudo tee /etc/systemd/system/sddm.service.d/override.conf > /dev/null <<EOF
[Service]
Restart=always
RestartSec=1
EOF

# Reload systemd to apply changes
sudo systemctl daemon-reload

# Enable SDDM Display Manager
if ! systemctl is-enabled sddm >/dev/null 2>&1; then
    echo "   Enabling SDDM..."
    sudo systemctl enable sddm
fi

    echo -e "${GREEN}✓ System services enabled!${NC}"
fi  # end MODE=full block

# 7. Configuration Installation (always runs)
if [ "$MODE" = "full" ]; then
    echo -e "\n${BLUE}[7/7] Installing Configurations...${NC}"
else
    echo -e "\n${BLUE}Installing Configurations (--configs-only)...${NC}"
fi
mkdir -p "$HOME/.config"
BACKUP_DIR="$HOME/.config_backup_previous"

# Function to backup and install config
install_config() {
    SRC="$1"
    DEST="$2"
    BASE_NAME=$(basename "$DEST")

    if [ ! -d "$SRC" ]; then
        echo -e "   ${YELLOW}⚠️  Source $SRC not found, skipping...${NC}"
        return
    fi

    if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
        # Single rotating backup: keep only the previous version
        mkdir -p "$BACKUP_DIR"
        rm -rf "$BACKUP_DIR/$BASE_NAME"
        cp -a "$DEST" "$BACKUP_DIR/$BASE_NAME"
    fi

    mkdir -p "$(dirname "$DEST")"

    if command -v rsync >/dev/null 2>&1; then
        # Removed --delete to respect user's existing files (like Thunar favorites)
        # Exclude bookmarks to prevent overwriting GTK file dialog favorites
        rsync -a --exclude='bookmarks' --exclude='uca.xml' "$SRC"/ "$DEST"/
    else
        rm -rf "$DEST"
        cp -a "$SRC" "$DEST"
    fi

    echo -e "   ${GREEN}✓${NC} Installed $BASE_NAME"
}

# Install all configs
echo "   Installing Hyprland configs..."

# Create custom configs directory BEFORE installing
mkdir -p "$HOME/.config/hypr/custom"

# Create template custom configs if they don't exist (before rsync)
if [ ! -f "$HOME/.config/hypr/custom/monitors.conf" ]; then
    cat > "$HOME/.config/hypr/custom/monitors.conf" <<'CUSTOM_EOF'
# Custom Monitor Configuration
# Uncomment and modify for your setup
# Examples:
#   monitor=DP-1,1920x1080@144,0x0,1
#   monitor=HDMI-A-1,2560x1440@60,1920x0,1
#   monitor=eDP-1,preferred,auto,1.5  # Laptop with scaling
# 
# List your monitors: hyprctl monitors
CUSTOM_EOF
fi

if [ ! -f "$HOME/.config/hypr/custom/keybinds.conf" ]; then
    cat > "$HOME/.config/hypr/custom/keybinds.conf" <<'CUSTOM_EOF'
# Custom Keybinds
# Add your personal keybinds here
# Examples:
#   bind = $mainMod, V, exec, pavucontrol
#   bind = $mainMod ALT, L, exec, swaylock
#   bind = $mainMod SHIFT, G, exec, gimp
#
#   # Toggle WARP ↔ NextDNS (requires warp-nextdns-toggle.sh)
#   bind = $mainMod SHIFT, W, exec, warp-nextdns-toggle.sh
CUSTOM_EOF
fi

if [ ! -f "$HOME/.config/hypr/custom/autostart.conf" ]; then
    cat > "$HOME/.config/hypr/custom/autostart.conf" <<'CUSTOM_EOF'
# Custom Autostart Programs
# Add programs to launch on startup
# Examples:
#   exec-once = discord
#   exec-once = telegram-desktop
#   exec-once = flameshot
CUSTOM_EOF
fi

if [ ! -f "$HOME/.config/hypr/custom/env.conf" ]; then
    cat > "$HOME/.config/hypr/custom/env.conf" <<'CUSTOM_EOF'
# Custom Environment Variables
# Add your custom environment variables here
# Examples:
#   env = MY_CUSTOM_VAR,value
#   env = PATH,$HOME/bin:$PATH
CUSTOM_EOF
fi

# Ideapad 500-15ISK (Intel + AMD R7 M360/M370): iGPU-first, dGPU on demand (best for both)
if [ "$LAPTOP_PROFILE" = "ideapad500" ] && ! grep -q 'Ideapad 500-15ISK' "$HOME/.config/hypr/custom/env.conf" 2>/dev/null; then
    cat >> "$HOME/.config/hypr/custom/env.conf" <<'IDPAD_EOF'

# --- Ideapad 500-15ISK: Hybrid Graphics & Hardware Accel ---
# Desktop/Compositor runs on Intel iGPU (better battery/stability)
# Run heavy apps on AMD dGPU with: DRI_PRIME=1 <program>

# Hardware Video Acceleration (Intel iGPU default)
env = LIBVA_DRIVER_NAME,iHD
env = VDPAU_DRIVER,va_gl

# To use AMD for hardware encoding/decoding (e.g. in OBS or Video Editors):
# Launch with: LIBVA_DRIVER_NAME=radeonsi VDPAU_DRIVER=radeonsi <program>

# Vulkan Selection
# Default: Intel. For AMD: VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
IDPAD_EOF
    echo -e "   ${GREEN}✓${NC} Added Ideapad 500-15ISK hybrid GPU & Hardware Accel hints to custom/env.conf"
fi

echo -e "   ${GREEN}✓${NC} Custom configs directory: $HOME/.config/hypr/custom/"

# Now install Hyprland configs (excluding custom directory to preserve user configs)
if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude='custom' "$SCRIPT_DIR/dots/.config/hypr"/ "$HOME/.config/hypr"/
else
    # Manual copy excluding custom directory
    for item in "$SCRIPT_DIR"/dots/.config/hypr/*; do
        basename_item=$(basename "$item")
        if [ "$basename_item" != "custom" ]; then
            cp -a "$item" "$HOME/.config/hypr/"
        fi
    done
fi

echo -e "   ${GREEN}✓${NC} Installed Hyprland configs (preserved custom/)"

# Match Hyprland $browser and keybinds to chosen browser (Floorp default, Zen/Thorium optional)
if [ -n "$CHOSEN_BROWSER_BIN" ] && [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
    echo "   Setting Hyprland browser to: $CHOSEN_BROWSER_BIN"
    sed -i "s|^\$browser = .*|\$browser = $CHOSEN_BROWSER_BIN|" "$HOME/.config/hypr/hyprland.conf"
    if [ -f "$HOME/.config/hypr/keybinds.conf" ]; then
        sed -i "s|^bind = Super, W, exec, .*|bind = Super, W, exec, $CHOSEN_BROWSER_BIN|" "$HOME/.config/hypr/keybinds.conf"
    fi
    echo -e "   ${GREEN}✓${NC} Updated hyprland.conf (and keybinds.conf) for $CHOSEN_BROWSER_BIN"
fi

echo "   Installing Waybar config..."
install_config "$SCRIPT_DIR/dots/.config/waybar" "$HOME/.config/waybar"

# Make waybar scripts executable
if [ -d "$HOME/.config/waybar/scripts" ]; then
    chmod +x "$HOME/.config/waybar/scripts/"*.sh 2>/dev/null || true
    echo -e "   ${GREEN}✓${NC} Made waybar scripts executable"
fi

echo "   Installing Ghostty config..."
install_config "$SCRIPT_DIR/dots/.config/ghostty" "$HOME/.config/ghostty"

echo "   Installing Wofi config..."
install_config "$SCRIPT_DIR/dots/.config/wofi" "$HOME/.config/wofi"

echo "   Installing Rofi config..."
install_config "$SCRIPT_DIR/dots/.config/rofi" "$HOME/.config/rofi"

echo "   Installing Wlogout config..."
install_config "$SCRIPT_DIR/dots/.config/wlogout" "$HOME/.config/wlogout"

echo "   Installing SwayNC config..."
install_config "$SCRIPT_DIR/dots/.config/swaync" "$HOME/.config/swaync"

echo "   Installing GTK configs..."
install_config "$SCRIPT_DIR/dots/.config/gtk-3.0" "$HOME/.config/gtk-3.0"
install_config "$SCRIPT_DIR/dots/.config/gtk-4.0" "$HOME/.config/gtk-4.0"

echo "   Installing Qt6ct config..."
install_config "$SCRIPT_DIR/dots/.config/qt6ct" "$HOME/.config/qt6ct"

# Install Scripts
echo "   Installing user scripts..."
mkdir -p "$HOME/.local/bin"
if [ -f "$SCRIPT_DIR/scripts/cheatsheet.sh" ]; then
    cp "$SCRIPT_DIR/scripts/cheatsheet.sh" "$HOME/.local/bin/cheatsheet.sh"
    chmod +x "$HOME/.local/bin/cheatsheet.sh"
    echo -e "   ${GREEN}✓${NC} Installed cheatsheet.sh"
fi

if [ -f "$SCRIPT_DIR/scripts/warp-nextdns-toggle.sh" ]; then
    cp "$SCRIPT_DIR/scripts/warp-nextdns-toggle.sh" "$HOME/.local/bin/warp-nextdns-toggle.sh"
    chmod +x "$HOME/.local/bin/warp-nextdns-toggle.sh"
    echo -e "   ${GREEN}✓${NC} Installed warp-nextdns-toggle.sh"

    echo ""
    read -r -p "   Configure passwordless WARP/NextDNS DNS toggle (sudoers + optional NextDNS profile)? [y/N]: " WARP_DNS_SETUP
    if [[ "$WARP_DNS_SETUP" =~ ^[Yy] ]]; then
        # Optional NextDNS profile customization
        echo "   Default: generic NextDNS endpoint (no profile ID)."
        read -r -p "   Enter NextDNS profile ID to use (leave blank to keep generic): " NEXTDNS_PROFILE_ID
        if [ -n "$NEXTDNS_PROFILE_ID" ]; then
            sed -i "s/dns.nextdns.io/$NEXTDNS_PROFILE_ID.dns.nextdns.io/g" "$HOME/.local/bin/warp-nextdns-toggle.sh"
            echo -e "   ${GREEN}✓${NC} Updated warp-nextdns-toggle.sh to use profile ID: $NEXTDNS_PROFILE_ID"
        else
            echo "   Keeping generic NextDNS endpoint (no profile ID) in warp-nextdns-toggle.sh"
        fi

        # Create sudoers drop-in to allow DNS toggle without password prompt
        SUDOERS_FILE="/etc/sudoers.d/pixel-rice-warp-dns"
        echo "   Adding sudoers rule for passwordless DNS toggle..."
        sudo bash -c "cat > '$SUDOERS_FILE' <<EOF
$(whoami) ALL=(root) NOPASSWD: /usr/bin/systemctl restart systemd-resolved, /usr/bin/sed
EOF"
        sudo chmod 440 "$SUDOERS_FILE" || true
        if sudo visudo -cf "$SUDOERS_FILE" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✓${NC} Sudoers rule valid: $SUDOERS_FILE"
        else
            echo -e \"   ${YELLOW}⚠️${NC} visudo reported an issue with $SUDOERS_FILE. Please check it manually.\"
        fi
    else
        echo "   Skipping sudoers / profile setup for warp-nextdns-toggle.sh (you can configure it later)."
    fi
fi

if [ -f "$SCRIPT_DIR/scripts/eyeprotect.sh" ]; then
    cp "$SCRIPT_DIR/scripts/eyeprotect.sh" "$HOME/.local/bin/eyeprotect.sh"
    chmod +x "$HOME/.local/bin/eyeprotect.sh"
    echo -e "   ${GREEN}✓${NC} Installed eyeprotect.sh"
fi

if [ -f "$SCRIPT_DIR/scripts/screenrecord.sh" ]; then
    cp "$SCRIPT_DIR/scripts/screenrecord.sh" "$HOME/.local/bin/screenrecord.sh"
    chmod +x "$HOME/.local/bin/screenrecord.sh"
    echo -e "   ${GREEN}✓${NC} Installed screenrecord.sh"
fi

if [ -f "$SCRIPT_DIR/scripts/osd.sh" ]; then
    cp "$SCRIPT_DIR/scripts/osd.sh" "$HOME/.local/bin/osd.sh"
    chmod +x "$HOME/.local/bin/osd.sh"
    echo -e "   ${GREEN}✓${NC} Installed osd.sh"
fi

if [ -f "$SCRIPT_DIR/scripts/smart-suspend.sh" ]; then
    cp "$SCRIPT_DIR/scripts/smart-suspend.sh" "$HOME/.local/bin/smart-suspend.sh"
    chmod +x "$HOME/.local/bin/smart-suspend.sh"
    echo -e "   ${GREEN}✓${NC} Installed smart-suspend.sh"
fi

if [ -f "$SCRIPT_DIR/scripts/battery-monitor.sh" ]; then
    cp "$SCRIPT_DIR/scripts/battery-monitor.sh" "$HOME/.local/bin/battery-monitor.sh"
    chmod +x "$HOME/.local/bin/battery-monitor.sh"
    echo -e "   ${GREEN}✓${NC} Installed battery-monitor.sh"
fi

if [ -f "$SCRIPT_DIR/scripts/check_ssh_active.sh" ]; then
    cp "$SCRIPT_DIR/scripts/check_ssh_active.sh" "$HOME/.local/bin/check_ssh_active.sh"
    chmod +x "$HOME/.local/bin/check_ssh_active.sh"
    echo -e "   ${GREEN}✓${NC} Installed check_ssh_active.sh (SSH-aware idle suspend)"
fi

if [ -f "$SCRIPT_DIR/scripts/conditional-suspend.sh" ]; then
    cp "$SCRIPT_DIR/scripts/conditional-suspend.sh" "$HOME/.local/bin/conditional-suspend.sh"
    chmod +x "$HOME/.local/bin/conditional-suspend.sh"
    echo -e "   ${GREEN}✓${NC} Installed conditional-suspend.sh (idle + SSH check)"
fi

# Conditional suspend timer (polls every 2min to catch SSH drop after 15min idle)
if [ -d "$SCRIPT_DIR/systemd/user" ]; then
    mkdir -p "$HOME/.config/systemd/user"
    for unit in "$SCRIPT_DIR/systemd/user"/*.service "$SCRIPT_DIR/systemd/user"/*.timer; do
        [ -f "$unit" ] && cp "$unit" "$HOME/.config/systemd/user/" && echo -e "   ${GREEN}✓${NC} Installed $(basename "$unit")"
    done
    systemctl --user daemon-reload 2>/dev/null || true
    if systemctl --user enable conditional-suspend.timer 2>/dev/null; then
        systemctl --user start conditional-suspend.timer 2>/dev/null || true
        echo -e "   ${GREEN}✓${NC} Enabled conditional-suspend.timer (polls every 2min)"
    else
        echo -e "   ${YELLOW}⚠️${NC}  Enable conditional-suspend.timer manually: systemctl --user enable --now conditional-suspend.timer"
    fi
fi

# Polkit: allow suspend without password (for conditional-suspend from user timer)
if [ -f "$SCRIPT_DIR/etc/polkit-1/rules.d/50-allow-suspend.rules" ]; then
    sudo mkdir -p /etc/polkit-1/rules.d
    sudo cp "$SCRIPT_DIR/etc/polkit-1/rules.d/50-allow-suspend.rules" /etc/polkit-1/rules.d/
    echo -e "   ${GREEN}✓${NC} Installed polkit rule for passwordless suspend (power/wheel)"
fi

# Dynamic Theme Switching (power-saver vs cartoon-shell based on power profile)
echo "   Installing dynamic theme switching..."
if [ -f "$SCRIPT_DIR/scripts/theme-switcher.sh" ]; then
    cp "$SCRIPT_DIR/scripts/theme-switcher.sh" "$HOME/.local/bin/theme-switcher.sh"
    chmod +x "$HOME/.local/bin/theme-switcher.sh"
    echo -e "   ${GREEN}✓${NC} Installed theme-switcher.sh"
fi

# Install both theme trees to /opt/pixel-rice/themes/
if [ -d "$SCRIPT_DIR/dots" ] && [ -d "$SCRIPT_DIR/dots-power-saver" ]; then
    echo "   Installing theme trees to /opt/pixel-rice/themes/..."
    sudo mkdir -p /opt/pixel-rice/themes

    # cartoon-shell (balanced / performance)
    sudo rm -rf /opt/pixel-rice/themes/cartoon-shell
    sudo cp -a "$SCRIPT_DIR/dots" /opt/pixel-rice/themes/cartoon-shell

    # power-saver (zero effects, max performance)
    sudo rm -rf /opt/pixel-rice/themes/power-saver
    sudo cp -a "$SCRIPT_DIR/dots-power-saver" /opt/pixel-rice/themes/power-saver

    sudo chmod -R 755 /opt/pixel-rice/themes
    echo -e "   ${GREEN}✓${NC} Installed cartoon-shell and power-saver theme trees"
fi

# Apply theme matching current power profile on first boot
if [ -f "$HOME/.local/bin/theme-switcher.sh" ] && command -v powerprofilesctl >/dev/null 2>&1; then
    echo "   Applying theme for current power profile..."
    "$HOME/.local/bin/theme-switcher.sh" 2>/dev/null && \
        echo -e "   ${GREEN}✓${NC} Applied theme for profile: $(powerprofilesctl get)" || \
        echo -e "   ${YELLOW}⚠️${NC}  Theme switcher ran but couldn't apply (will trigger on next profile change)"
fi

# Install SDDM Theme
if [ -d "$SCRIPT_DIR/sddm-theme" ]; then
    echo "   Installing SDDM theme..."
    sudo mkdir -p /usr/share/sddm/themes/pixel
    sudo cp -r "$SCRIPT_DIR/sddm-theme/"* /usr/share/sddm/themes/pixel/
    
    # Create default background if not exists
    if [ ! -f "/usr/share/sddm/themes/pixel/background.png" ]; then
        # Create a simple gradient background
        sudo convert -size 1920x1080 \
            gradient:"#0F0F0F-#1A1A1A" \
            /usr/share/sddm/themes/pixel/background.png 2>/dev/null || \
        sudo cp /usr/share/pixmaps/archlinux-logo.png /usr/share/sddm/themes/pixel/background.png 2>/dev/null || true
    fi
    
    # Configure SDDM to use the theme
    sudo mkdir -p /etc/sddm.conf.d
    sudo tee /etc/sddm.conf.d/theme.conf > /dev/null <<EOF
[Theme]
Current=pixel
CursorTheme=Adwaita
CursorSize=24

[General]
Numlock=on
DefaultSession=hyprland.desktop

[Wayland]
CompositorCommand=Hyprland
EnableHiDPI=true

[X11]
# Use X11 for SDDM greeter (more stable)
DisplayServer=x11
EOF
    
    # Set correct permissions on theme directory
    sudo chown -R sddm:sddm /usr/share/sddm/themes/pixel
    sudo chmod -R 755 /usr/share/sddm/themes/pixel
    
    echo -e "   ${GREEN}✓${NC} Installed SDDM theme"
fi

# Install wallpapers if exist
if [ -d "$SCRIPT_DIR/wallpapers" ]; then
    mkdir -p "$HOME/Pictures/wallpapers"
    cp -r "$SCRIPT_DIR/wallpapers/"* "$HOME/Pictures/wallpapers/" 2>/dev/null || true
    echo -e "   ${GREEN}✓${NC} Installed wallpapers"
fi

# Bash Configuration
echo "   Configuring bash..."
BASHRC="$HOME/.bashrc"
if ! grep -q "PIXEL-RICE" "$BASHRC" 2>/dev/null; then
    cat <<'EOF' >> "$BASHRC"

# --- PIXEL-RICE ---

# Guard against accidental double-sourcing in the same shell process.
if [[ -n "${__PIXEL_BASHRC_GUARD:-}" ]]; then
    return
fi
__PIXEL_BASHRC_GUARD=1

# --- AI / CI / editor agents (minimal shell; no ble/atuin — avoids hangs) ---
is_agent_env=0
[[ -n "${ANTIGRAVITY_AGENT:-}" ]] && is_agent_env=1
[[ -n "${AGENT_ENVIRONMENT:-}" ]] && is_agent_env=1
[[ -n "${CI:-}" ]] && is_agent_env=1
[[ "${TERM_PROGRAM:-}" =~ (copilot|github|agent) ]] && is_agent_env=1
[[ -n "${GITHUB_ACTIONS:-}" ]] && is_agent_env=1

if [[ "$is_agent_env" -eq 1 ]]; then
    unset PROMPT_COMMAND
    [[ -z "${TERM:-}" || "$TERM" == "dumb" ]] && export TERM=xterm-256color
    unset NO_COLOR
    export CLICOLOR=1
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    export PS1='\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ '
    set +H
    [[ -f "$HOME/.agent_profile" ]] && source "$HOME/.agent_profile"
    return
fi

# Non-interactive (scripts, scp): no prompt, no keybindings
[[ $- != *i* ]] && return

# --- Session: local desktop vs SSH ---
is_remote_session=0
[[ -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" || -n "${SSH_CONNECTION:-}" ]] && is_remote_session=1

# --- History (readline; atuin may add its own when loaded) ---
shopt -s histappend
HISTCONTROL="ignoreboth:erasedups"
HISTSIZE=50000
HISTFILESIZE=100000
HISTIGNORE="&:ls:ll:la:cd:exit:clear:history"

# --- Defaults ---
umask 022
if [[ -z "${EDITOR:-}" ]]; then
    command -v nvim >/dev/null && export EDITOR=nvim
    [[ -z "${EDITOR:-}" ]] && command -v vim >/dev/null && export EDITOR=vim
    [[ -z "${EDITOR:-}" ]] && command -v nano >/dev/null && export EDITOR=nano
fi
[[ -z "${VISUAL:-}" && -n "${EDITOR:-}" ]] && export VISUAL="$EDITOR"
export LESS="-R -F -X"

# --- Colors & PATH ---
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias ll='ls -alh --color=auto'
alias la='ls -A --color=auto'

export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/.bun/bin" ]] && {
    export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
    export PATH="$BUN_INSTALL/bin:$PATH"
}

# Ghostty reports xterm-ghostty; many TUI expect xterm-256color for colors
[[ "${TERM:-}" == "xterm-ghostty" ]] && export TERM=xterm-256color

# GnuPG pinentry on the current tty (interactive)
command -v gpg >/dev/null 2>&1 && export GPG_TTY="${GPG_TTY:-$(tty 2>/dev/null)}"

# Fallback prompt (SSH or before ble); overwritten locally after ble loads
PS1='[\[\e[0;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\W\[\e[0m\]]\$ '

# Zoxide must run before ble (ble-import integration/zoxide). Do NOT run fzf --bash here:
# it hooks PROMPT_COMMAND and often causes a double prompt line with ble + Ghostty.
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init bash)"
fi

# --- Hyprland / Wayland desktop only (skip SSH to avoid broken GTK/Qt over forwarded sessions) ---
if [[ "$is_remote_session" -eq 0 ]]; then
    export QT_QPA_PLATFORMTHEME=qt6ct
    export QT_QPA_PLATFORM=wayland
    export GDK_BACKEND=wayland
    export MOZ_ENABLE_WAYLAND=1
    export XDG_CURRENT_DESKTOP=Hyprland
    export XDG_SESSION_TYPE=wayland
    export XDG_SESSION_DESKTOP=Hyprland
    export GTK_THEME=Adwaita:dark
    export GDK_THEME=Adwaita-dark

    export GTK_IM_MODULE=fcitx
    export QT_IM_MODULE=fcitx
    export XMODIFIERS=@im=fcitx
    export GLFW_IM_MODULE=ibus

    # ble → PS1 → atuin → fzf (fzf last: avoids double prompt on Ghostty / some terminals)
    if [[ -f /usr/share/blesh/ble.sh ]]; then
        source /usr/share/blesh/ble.sh
        [[ -n "${BLE_VERSION:-}" ]] && ble-import -d integration/zoxide
        [[ -n "${BLE_VERSION:-}" ]] && ble-import -d integration/fzf-completion
        [[ -n "${BLE_VERSION:-}" ]] && ble-import -d integration/fzf-key-bindings
    fi

    PS1="\[\e[0;32m\][\[\e[1;37m\]\u@\h\[\e[0;32m\]]\[\e[0;37m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "

    if command -v atuin >/dev/null 2>&1; then
        eval "$(atuin init bash)"
    fi

    if command -v fzf >/dev/null 2>&1 && [[ -z "${BLE_VERSION:-}" ]]; then
        eval "$(fzf --bash)"
    fi
fi

# SSH: no ble/atuin; still get fzf keybindings
if [[ "$is_remote_session" -eq 1 ]] && command -v fzf >/dev/null 2>&1; then
    eval "$(fzf --bash)"
fi

# Ghostty sometimes injects a prompt hook that can duplicate prompt lines
# when combined with ble/atuin/fzf stacks. Keep title/zoxide hooks, drop ghostty hook.
if [[ "${TERM_PROGRAM:-}" == "ghostty" ]]; then
    __pixel_strip_ghostty_hook() {
        local _pc_decl _pc
        _pc_decl="$(declare -p PROMPT_COMMAND 2>/dev/null || true)"
        if [[ "$_pc_decl" == "declare -a "* ]]; then
            local _pc_new=()
            for _pc in "${PROMPT_COMMAND[@]}"; do
                [[ "$_pc" == *"__ghostty_hook"* ]] && continue
                _pc_new+=("$_pc")
            done
            PROMPT_COMMAND=("${_pc_new[@]}")
            unset _pc_new
        elif [[ "${PROMPT_COMMAND:-}" == *"__ghostty_hook"* ]]; then
            PROMPT_COMMAND=""
        fi
        unset _pc_decl _pc
    }

    # Remove once immediately...
    __pixel_strip_ghostty_hook
    # ...and keep stripping on every prompt in case Ghostty re-injects it.
    if [[ "$(declare -p PROMPT_COMMAND 2>/dev/null || true)" == "declare -a "* ]]; then
        PROMPT_COMMAND+=("__pixel_strip_ghostty_hook")
    elif [[ -n "${PROMPT_COMMAND:-}" ]]; then
        PROMPT_COMMAND="${PROMPT_COMMAND};__pixel_strip_ghostty_hook"
    else
        PROMPT_COMMAND="__pixel_strip_ghostty_hook"
    fi
fi

# --- PIXEL-RICE END ---
EOF
    echo -e "   ${GREEN}✓${NC} Updated .bashrc"
else
    echo -e "   ${YELLOW}⚠️${NC}  .bashrc already configured with PIXEL-RICE block, leaving it unchanged."
fi

# Configure fcitx5
echo "   Configuring fcitx5..."
mkdir -p "$HOME/.config/fcitx5/conf"

# Create fcitx5 profile with Lotus (Vietnamese)
cat > "$HOME/.config/fcitx5/profile" <<'EOF'
[Groups/0]
Name=Default
Default Layout=us
DefaultIM=lotus

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=lotus
Layout=

[GroupOrder]
0=Default
EOF

echo -e "   ${GREEN}✓${NC} Configured fcitx5 with Lotus"

# Set default shell to bash if not already
if [ "$SHELL" != "/bin/bash" ]; then
    echo "   Setting bash as default shell..."
    chsh -s /bin/bash
    echo -e "   ${GREEN}✓${NC} Default shell set to bash"
fi

# Configure Power Button to Suspend (User Request)
echo "   Configuring power button to suspend (requires reboot)..."
sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/powerbutton.conf > /dev/null <<EOF
[Login]
HandlePowerKey=suspend
EOF

# 8. Cleanup (reclaim disk space after install/update)
echo -e "\n${BLUE}Cleaning up redundant files...${NC}"

# Pacman package cache — remove uninstalled package versions, keep last 3
if command -v paccache >/dev/null 2>&1; then
    echo -n "   Pacman cache (keeping last 3 versions)... "
    sudo paccache -rk3 >/dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}skipped${NC}"
else
    echo -n "   Pacman cache (remove uninstalled)... "
    sudo pacman -Sc --noconfirm >/dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}skipped${NC}"
fi

# Orphan packages (deps no longer required by anything)
ORPHANS=$(pacman -Qtdq 2>/dev/null || true)
if [ -n "$ORPHANS" ]; then
    echo -n "   Removing orphan packages... "
    sudo pacman -Rns --noconfirm $ORPHANS >/dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}some skipped${NC}"
else
    echo "   No orphan packages to remove"
fi

# AUR helper cache (build artifacts in ~/.cache/yay/)
if [ -d "$HOME/.cache/yay" ]; then
    YAY_SIZE=$(du -sh "$HOME/.cache/yay" 2>/dev/null | cut -f1)
    echo -n "   AUR build cache (~${YAY_SIZE})... "
    if [ "$AUR_HELPER" = "yay" ] && command -v yay >/dev/null 2>&1; then
        yay -Scc --noconfirm >/dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}skipped${NC}"
    elif [ "$AUR_HELPER" = "paru" ] && command -v paru >/dev/null 2>&1; then
        paru -Scc --noconfirm >/dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}skipped${NC}"
    else
        # Manual cleanup
        rm -rf "$HOME/.cache/yay"
        echo -e "${GREEN}✓${NC} (removed)"
    fi
fi

# Journal logs — cap at 100MB
if command -v journalctl >/dev/null 2>&1; then
    JOURNAL_SIZE=$(du -sh /var/log/journal/ 2>/dev/null | cut -f1 || echo "0")
    echo -n "   Journal logs (~${JOURNAL_SIZE}, cap 100MB)... "
    sudo journalctl --vacuum-size=100M >/dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}skipped${NC}"
fi

# Font cache
if command -v fc-cache >/dev/null 2>&1; then
    echo -n "   Rebuilding font cache... "
    fc-cache -f >/dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}skipped${NC}"
fi

# Thumbnail cache
if [ -d "$HOME/.cache/thumbnails" ]; then
    rm -rf "$HOME/.cache/thumbnails"
    echo "   Thumbnail cache cleared"
fi

# Old config backups (cleanup timestamped backups from pre-v2 installs)
OLD_BACKUPS=$(ls -d "$HOME"/.config_backup_20* 2>/dev/null | head -20)
if [ -n "$OLD_BACKUPS" ]; then
    echo -n "   Removing old timestamped backups... "
    echo "$OLD_BACKUPS" | while read -r dir; do rm -rf "$dir"; done
    echo -e "${GREEN}✓${NC}"
fi

# Summary
echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"

echo -e "\n${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          Installation Complete! 🎉            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. ${YELLOW}Reboot your system${NC} (recommended)"
echo "  2. After reboot, select ${YELLOW}Hyprland${NC} in your display manager"
echo "  3. Or start Hyprland manually with: ${YELLOW}Hyprland${NC}"
echo ""
echo -e "${BLUE}Quick Tips:${NC}"
echo "  • Super + T       → Open Terminal (Ghostty)"
echo "  • Super + W       → Open Browser"
echo "  • Super + Space   → App Launcher"
echo "  • Super + /       → Keybind Cheatsheet"
echo "  • Super + Q       → Close Window"
echo "  • Super + M       → Exit Hyprland"
echo "  • Ctrl + Space    → Toggle fcitx5 input (Vietnamese)"
echo ""
echo -e "${BLUE}Laptop Controls:${NC}"
echo "  • Fn + Brightness → Adjust screen brightness"
echo "  • Super+Shift +/- → Alternative brightness controls"
echo "  • Fn + Volume     → Audio volume controls"
echo "  • Super+Shift+P   → Performance | Super+Ctrl+P → Balanced | Super+Alt+P → Power Saver (powerprofilesctl; works on all laptops)"
echo ""
echo -e "${BLUE}Terminal Features:${NC}"
echo "  • Ctrl + R        → Atuin intelligent history search (command prediction)"
echo "  • Up Arrow        → Search command history as you type"
echo "  • z <keyword>     → Zoxide smart directory jump"
echo "  • gemini          → AI assistant (Gemini CLI)"
echo ""
echo -e "${BLUE}Custom Configs:${NC}"
echo "  • Location: ${YELLOW}~/.config/hypr/custom/${NC}"
echo "  • Add your monitor settings to: monitors.conf"
echo "  • Add custom keybinds to: keybinds.conf"
echo "  • Add autostart programs to: autostart.conf"
echo "  • Add environment variables to: env.conf"
echo ""
echo -e "${BLUE}Conditional Suspend (SSH-aware):${NC}"
echo "  • If systemctl suspend fails: ensure polkit rule installed (power/wheel group)"
echo "  • If IdleHint never 'yes': idle 1min, run: loginctl show-session \$XDG_SESSION_ID | grep IdleHint"
echo "  • State-file fallback handles hypridle not reporting idle to logind"
echo ""
echo -e "${BLUE}SDDM Theme:${NC}"
echo "  • Custom pixel theme installed"
echo "  • Will be active after reboot"
echo ""
if [ -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}Note:${NC} Your previous configs are in:"
    echo "      $BACKUP_DIR"
    echo "   (rotated — only the last version is kept)"
fi
echo ""
echo -e "${GREEN}Enjoy your Pixel Rice! 🎮${NC}"
