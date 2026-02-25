# Pixel Rice

A pixel-perfect, vibrant rice for Arch Linux with Hyprland. Optimized for clean minimal Arch installations with zero compromises on aesthetics and functionality.

## 🎮 Features

- **Hyprland** – Modern Wayland compositor
- **Ghostty** – Fast terminal
- **Waybar** – Status bar
- **Wofi** – Application launcher
- **Ocean Sorbet** – Blue–orange accent palette; zero rounding, zero blur
- **Power profiles** – Keybinds via `powerprofilesctl` (works on all laptops)
- **Auto hardware detection** – Ideapad 500-15ISK (Intel + AMD), ThinkBook 14p (Ryzen), and generic
- **System integration** – Bluetooth, Pipewire, NetworkManager, fcitx5 (Vietnamese input), SDDM theme

## 📋 Prerequisites

- **Arch Linux** (or Arch-based) with a non-root user and sudo
- Internet connection
- Basic terminal usage

## 🚀 Installation

### Quick install

```bash
git clone https://github.com/YOUR_USERNAME/pixel-rice.git
cd pixel-rice
chmod +x install.sh
./install.sh
```

Replace `YOUR_USERNAME` with your GitHub username (or your fork URL).

The installer will:
1. Run pre-flight checks and update the system
2. Install base deps and set up yay (AUR) if needed
3. Remove conflicting packages (dunst, mako, sway, i3, dwm)
4. Install rice packages (Hyprland, Waybar, Ghostty, Wofi, etc.)
5. Auto-detect GPU/laptop (Intel+AMD hybrid, AMD Ryzen, NVIDIA, Intel-only) and install matching tools
6. Enable services (NetworkManager, Bluetooth, power-profiles-daemon, SDDM)
7. Deploy dotfiles and create `~/.config/hypr/custom/` (preserved on re-runs)
8. Back up existing configs to `~/.config_backup_TIMESTAMP`

**Time:** about 15–30 minutes.

### After install

```bash
# Reboot (recommended)
reboot
```

Then choose **Hyprland** at the login screen, or run `Hyprland` from a TTY.

See **[INSTALL_GUIDE.md](INSTALL_GUIDE.md)** for minimal Arch from scratch, troubleshooting, and variants.

## ⌨️ Keybindings

### Core

| Keybind | Action |
|---------|--------|
| `Super + T` | Terminal (Ghostty) |
| `Super + W` | Browser (Zen Browser) |
| `Super + Space` | App launcher (Wofi) |
| `Super + /` | Keybind cheatsheet |
| `Super + Q` | Close window |
| `Super + M` | Exit Hyprland |

### Power (powerprofilesctl; all laptops)

| Keybind | Action |
|---------|--------|
| `Super + Shift + P` | Performance |
| `Super + Ctrl + P` | Balanced |
| `Super + Alt + P` | Power Saver |

### Connectivity & system

| Keybind | Action |
|---------|--------|
| `Super + B` | Bluetooth (Blueman) |
| `Super + Shift + B` | Bluetooth TUI (bluetoothctl) |
| `Super + N` | Network (nmtui) |
| `Super + Shift + N` | Network GUI (nm-connection-editor) |
| `Super + I` | btop |

### Window & workspace

| Keybind | Action |
|---------|--------|
| `Super + 1-9, 0` | Switch workspace |
| `Super + Shift + 1-9, 0` | Move window to workspace |
| `Super + P` | Pseudo (split) |
| `Super + J` | Toggle split |
| `Super + V` | Toggle floating |
| `Super + grave` | Scratchpad |

### Media & laptop

| Keybind | Action |
|---------|--------|
| `Super + Shift + S` | Screenshot region → clipboard |
| `Super + Print` | Full screenshot |
| `Super + Alt + R` | Screen record |
| `Super + Y` | Eye protection (wlsunset) |
| `Super + L` | Lock |
| `Super + Shift + Backspace` | Suspend |

Press **`Super + /`** in-session for the full cheatsheet.

## 🎨 Customization

**User configs (not overwritten by installer):** `~/.config/hypr/custom/`

| File | Purpose |
|------|--------|
| `monitors.conf` | Monitor layout, resolution, scale |
| `keybinds.conf` | Extra keybinds |
| `autostart.conf` | Programs to start with Hyprland |
| `env.conf` | Environment variables |

Edit main colors in:
- Hyprland: `dots/.config/hypr/hyprland.conf`
- Waybar: `dots/.config/waybar/style.css`
- Wofi: `dots/.config/wofi/style.css`

Default apps (in `hyprland.conf`): `$terminal = ghostty`, `$browser = zen-browser`, `$menu = wofi --show drun`.

## 🖥️ Hardware support

- **Lenovo Ideapad 500-15ISK** (Intel i7-6500U + AMD Radeon R7 M360/M370): iGPU primary; use `DRI_PRIME=1 <app>` to run selected apps on AMD. No ryzenadj (Intel CPU).
- **Lenovo ThinkBook 14p Gen 2** (AMD Ryzen, no dGPU): amdgpu_top + ryzenadj; power profile keybinds + Ryzen TDP service.
- **Generic:** Intel-only, NVIDIA, or other: appropriate GPU tools and powerprofilesctl keybinds only.

## 🔧 Troubleshooting

- **Hyprland won’t start:** `cat ~/.hyprland.log`. Install drivers: Intel `mesa vulkan-intel`, AMD `mesa vulkan-radeon`, NVIDIA `nvidia-dkms nvidia-utils`.
- **Waybar missing:** `killall waybar && waybar &`
- **Ghostty / Zen Browser:** Install from AUR: `yay -S ghostty zen-browser-bin` (installer falls back to Firefox if zen-browser fails).

More in **[INSTALL_GUIDE.md](INSTALL_GUIDE.md)**.

## 📦 What’s included

Core: Hyprland, Waybar, Ghostty, Wofi, Rofi, wlogout. System: NetworkManager, Blueman, Pipewire, power-profiles-daemon, fcitx5 (Vietnamese), SDDM theme. Scripts: cheatsheet, osd (volume/brightness/power), eyeprotect, screenrecord, battery-monitor, smart-suspend. See `install.sh` for the full list.

## 🤝 Credits

- [Cartoon Shell](https://github.com/mailong2401/cartoon-shell) (mailong2401) – pixel-art inspiration
- [dots-hyprland](https://github.com/end-4/dots-hyprland) (end-4) – Hyprland layout and patterns

## 📄 License

GPLv3 – see [LICENSE](LICENSE).

## 💬 Support

Open an issue for bugs or suggestions. Enjoy your Pixel Rice! 🎮✨
