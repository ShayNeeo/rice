# Installation Guide for Clean Minimal Arch

Complete guide to install Pixel Rice on a fresh Arch Linux system.

## Prerequisites

- **Arch Linux** (or Arch-based) with a non-root user and sudo
- **Network** connected (e.g. `nmtui` or `nmcli` for Wi‑Fi)
- **Base packages** (if needed): `sudo pacman -Syu && sudo pacman -S --needed base-devel git`

## Installation Steps

### 1. Clone the repository

```bash
cd ~
git clone https://github.com/YOUR_USERNAME/pixel-rice.git
cd pixel-rice
```

Replace `YOUR_USERNAME` with the repo owner (or your fork URL).

### 2. Run the installer

```bash
chmod +x install.sh
./install.sh
```

The installer will:
- Run pre-flight checks and update the system
- Install base deps and set up yay (AUR) if not present
- Remove conflicting packages (dunst, mako, sway, i3, dwm)
- Install all rice packages (Hyprland, Waybar, Ghostty, Wofi, etc.)
- **Auto-detect hardware:** Ideapad 500-15ISK (Intel+AMD), ThinkBook 14p (Ryzen), or generic; install matching GPU/power tools
- Enable NetworkManager, Bluetooth, power-profiles-daemon, SDDM
- Deploy dotfiles and create `~/.config/hypr/custom/` (preserved on re-runs)
- Back up existing configs to `~/.config_backup_TIMESTAMP`

**Duration:** about 15–30 minutes.

### 3. Post-installation

```bash
sudo reboot
```

After reboot, select **Hyprland** at the login screen, or run `Hyprland` from a TTY.

## Hardware detection (installer)

| Detected | Behaviour |
|----------|-----------|
| **Ideapad 500-15ISK** (Intel + AMD R7 M360/M370) | intel-gpu-tools + amdgpu_top; no ryzenadj; power keybinds use powerprofilesctl; hint in `~/.config/hypr/custom/env.conf` for `DRI_PRIME=1` |
| **ThinkBook 14p Gen 2** (Ryzen, no dGPU) | amdgpu_top + ryzenadj; ryzen-power service; power keybinds |
| **Other** | GPU tools by lspci; power keybinds via powerprofilesctl only |

## Arch-based with existing WM/DE

The installer removes conflicting packages (dunst, mako, sway, i3, dwm) and backs up configs to `~/.config_backup_TIMESTAMP`. You can keep other desktop environments; choose Hyprland at login when you want to use the rice.

## Minimal Arch from scratch

After base install and arch-chroot (before first reboot):

```bash
pacman -S base linux linux-firmware networkmanager sudo
systemctl enable NetworkManager
useradd -m -G wheel -s /bin/bash yourusername
passwd yourusername
EDITOR=nano visudo   # uncomment: %wheel ALL=(ALL:ALL) ALL
exit
reboot
```

After reboot, as your user:

```bash
nmtui   # connect network
sudo pacman -Syu
sudo pacman -S git
git clone https://github.com/YOUR_USERNAME/pixel-rice.git
cd pixel-rice
chmod +x install.sh
./install.sh
sudo reboot
```

Then choose Hyprland at login or run `Hyprland` from TTY.

## Display manager

The main installer already installs and enables **SDDM** with the pixel theme. If you skipped it or use a minimal install, enable manually:

```bash
sudo pacman -S sddm qt6-svg qt6-declarative
sudo systemctl enable sddm
sudo reboot
```

## Verification checklist

- [ ] Hyprland starts; `Super + T` opens Ghostty, `Super + W` opens browser
- [ ] Waybar at top; `Super + /` shows cheatsheet
- [ ] Audio: `speaker-test`; Bluetooth: `Super + B`; Network: `Super + N`
- [ ] Power profiles: `Super + Shift/Ctrl/Alt + P` (performance / balanced / power-saver)

## Troubleshooting

| Issue | What to try |
|-------|-------------|
| Hyprland won’t start | `cat ~/.hyprland.log`; install drivers: Intel `mesa vulkan-intel`, AMD `mesa vulkan-radeon`, NVIDIA `nvidia-dkms nvidia-utils` |
| No AUR helper | `git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si` |
| Services not up | `systemctl status NetworkManager bluetooth power-profiles-daemon`; start with `sudo systemctl start <service>` |
| Ghostty / Zen Browser missing | `yay -S ghostty zen-browser-bin` (or use Firefox and change `$browser` in `~/.config/hypr/hyprland.conf`) |

## Next steps

- **Custom configs:** `~/.config/hypr/custom/` (monitors, keybinds, autostart, env)
- **Wallpapers:** `~/Pictures/wallpapers/`
- **Keybinds:** `Super + /` in-session for full cheatsheet

---

**Need help?** See [README.md](README.md) or open an issue.
