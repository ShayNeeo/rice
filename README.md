# Pixel Rice

Pixel Rice is an Arch Linux desktop configuration built around Hyprland, Quickshell, and a performance-conscious workflow. It provides a complete Wayland desktop for laptops: compositor configuration, panel and launcher utilities, input-method setup, power management, suspend/resume handling, and theme switching.

Repository: <https://github.com/ShayNeeo/rice>

## Scope

Pixel Rice is intended for:

- Fresh or minimal Arch Linux installs
- Laptop-first Hyprland desktops
- Users who want a working Wayland setup with sane defaults
- AMD Ryzen / integrated Radeon laptops that benefit from explicit power tuning
- Multi-monitor setups that need predictable panel placement

This is not a universal desktop theme. It is a complete local desktop stack with hardware-aware installer logic.

## Current Architecture

```text
.
├── install.sh                         # Full installer and configs-only sync
├── INSTALL_GUIDE.md                   # Minimal Arch installation guide
├── CONTEXT.md                         # Design notes and troubleshooting history
├── AGENTS.md                          # Local agent workflow rules
├── dots/                              # cartoon-shell theme tree
├── dots-power-saver/                  # power-saver theme tree
├── scripts/                           # User utilities and power tooling
├── systemd/                           # System and user systemd units
├── etc/                               # Polkit and sudoers drop-ins
└── sddm-theme/                        # SDDM login theme
```

## What is included

### Desktop and shell

- Hyprland Wayland compositor
- Quickshell Qt/QML panels and widgets
- Fuzzel application launcher
- Hyprpaper, Hyprlock, Hypridle
- wlogout power menu
- wl-clipboard, cliphist, grim, slurp, swappy, wl-screenrec
- fcitx5-lotus for Vietnamese input

### Applications

Default applications are configured in `dots/.config/hypr/hyprland.conf`:

| Role | Default |
|------|---------|
| Terminal | Ghostty |
| Browser | Floorp |
| File manager | Dolphin |
| Text editor | NotepadNext |
| IDE | Zed |
| Launcher | Fuzzel |

The installer can optionally install Zen Browser or Thorium, but the default Hyprland variables point to Floorp.

### Power management

Pixel Rice includes several layers of power control:

- `powerprofilesctl` profile switching
- Dynamic theme switching based on the active power profile
- `manage_power.sh` for AMD Ryzen tuning
- `power-diagnose.sh` for profile verification
- `power-profile-test.sh` for low-power / balanced / performance comparison
- Optional sudoers drop-in for kernel sysfs power writes
- Polkit rule for passwordless suspend from user session
- `hypridle` idle lock and conditional suspend
- SSH/AI-session-aware suspend guard

The Ryzen path uses native `amd-pstate` EPP controls first, then `ryzenadj` when available. The installer detects Lenovo ThinkBook 14p Gen 2 / Ryzen Cezanne hardware and applies the corresponding profile.

### Theme system

Pixel Rice uses two theme trees:

| Theme | Purpose |
|-------|---------|
| `cartoon-shell` | Balanced / performance desktop with full Quickshell UI |
| `power-saver` | Minimal, low-effect profile for battery saving |

Theme files are installed into:

```text
~/.local/share/pixel-rice/themes/
```

The active config is switched with atomic symlink swaps by `theme-switcher.sh`. This avoids copying the full config tree on every profile change.

### Suspend and resume

The project includes explicit suspend/resume hardening:

- `quickshell.service` is enabled as a user service
- `quickshell-resume.service` restarts Quickshell after suspend via `sleep.target`
- The duplicate `suspend.target.wants` quickshell restart hook is removed by the installer
- `9router-wal-checkpoint.timer` keeps the local SQLite database from accumulating a large WAL file
- `conditional-suspend.timer` is installed but not enabled by default; `hypridle` handles normal idle suspend

## Installation

### Prerequisites

- Arch Linux or an Arch-based system
- A non-root user with `sudo`
- Network access
- `base-devel` and `git`

### Quick install

```bash
git clone https://github.com/ShayNeeo/rice.git
cd rice
chmod +x install.sh
./install.sh
```

The installer supports two modes:

```bash
./install.sh                 # Full install: packages + configs
./install.sh --configs-only  # Sync configs and apply current theme only
```

During a full install, the installer:

1. Runs Arch pre-flight checks
2. Updates the system and keyring
3. Installs `base-devel`, `git`, and an AUR helper if needed
4. Installs Hyprland, Wayland, Quickshell, input, audio, Bluetooth, network, GTK, Qt, and developer packages
5. Installs Floorp by default, with optional Zen / Thorium prompts
6. Configures fcitx5-lotus and required Wayland input permissions
7. Preserves `~/.config/hypr/custom/` on re-runs
8. Installs user scripts and systemd units
9. Installs the SDDM theme
10. Installs both theme trees and applies the theme matching the current power profile

See [INSTALL_GUIDE.md](INSTALL_GUIDE.md) for a clean minimal Arch walkthrough.

## Configuration layout

### Hyprland

Main files:

- `dots/.config/hypr/hyprland.conf`
- `dots/.config/hypr/keybinds.conf`
- `dots/.config/hypr/hypridle.conf`
- `dots/.config/hypr/hyprlock.conf`
- `dots-power-saver/.config/hypr/*`

User overrides are preserved in:

```text
~/.config/hypr/custom/
```

Recommended custom files:

| File | Purpose |
|------|---------|
| `monitors.conf` | Monitor layout, resolution, scale |
| `keybinds.conf` | Extra keybinds |
| `autostart.conf` | User programs started with Hyprland |
| `env.conf` | User environment variables |

Do not edit generated user overrides directly from the repo. Put persistent changes in `~/.config/hypr/custom/`.

### Quickshell

Quickshell is the primary panel and widget layer. It replaces the older Waybar/Rofi/swaync stack.

Important files:

```text
dots/.config/quickshell/shell.qml
dots/.config/quickshell/Bar.qml
dots/.config/quickshell/Modules/
dots/.config/quickshell/services/
```

Architecture notes:

- Do not use `Repeater { model: Quickshell.screens }` for `PanelWindow` components.
- Multi-monitor panels are manually instantiated in `shell.qml`.
- Use `implicitWidth` / `implicitHeight` inside layouts.
- Animate layout items with `transform: Translate {}`, not `x` / `y` offsets.
- Keep `pragma Singleton` on service files.

See [CONTEXT.md](CONTEXT.md) for detailed design notes.

## Keybindings

Main keybindings are defined in `dots/.config/hypr/hyprland.conf`.

| Shortcut | Action |
|----------|--------|
| `Super + Return` | Open terminal |
| `Super + T` | Open terminal |
| `Super + W` | Open browser |
| `Super + F` | Open file manager |
| `Super + E` | Open text editor |
| `Super + O` | Open IDE |
| `Super + Space` | Open launcher |
| `Super + /` | Open cheatsheet |
| `Super + Shift + V` | Clipboard history |
| `Super + Q` | Close active window |
| `Super + Shift + F` | Toggle fullscreen |
| `Super + V` | Toggle floating |
| `Super + P` | Pseudo tile |
| `Super + H/J/K/L` | Focus windows |
| `Super + 1-9` | Switch workspace |
| `Super + Shift + 1-9` | Move window to workspace |
| `Super + Shift + P` | Performance profile |
| `Super + Ctrl + P` | Balanced profile |
| `Super + Alt + P` | Power-saver profile |
| `Super + Shift + W` | WARP / NextDNS toggle |
| `Super + Alt + R` | Screen record |
| `Super + Backspace` | Lock session |
| `Super + Shift + Backspace` | Suspend |
| `Super + Shift + M` | Reload Hyprland |

## Hardware profiles

### Lenovo Ideapad 500-15ISK

- Intel i7 + AMD Radeon R7 M360/M370 hybrid graphics
- Uses Intel iGPU as primary display
- Uses `DRI_PRIME=1 <app>` when selecting the AMD dGPU
- Does not use `ryzenadj`

### Lenovo ThinkBook 14p Gen 2

- AMD Ryzen APU / Radeon Cezanne
- Uses `amdgpu_top`, `ryzenadj`, and explicit power tuning
- Supports profile-specific CPU/GPU power limits
- Uses kernel `amd-pstate` EPP controls plus optional sudoers drop-in

### Generic

- Detects GPU with `lspci`
- Installs appropriate Mesa / AMD / NVIDIA tools
- Uses `powerprofilesctl` keybinds
- Full Ryzen tuning is enabled only when the hardware and sudoers drop-in support it

## Maintenance

Deploy config-only changes after editing the repo:

```bash
./install.sh --configs-only
```

Reload Hyprland:

```bash
hyprctl reload
```

Restart Quickshell:

```bash
systemctl --user restart quickshell.service
```

Check suspend/resume units:

```bash
systemctl --user status quickshell.service
systemctl --user status quickshell-resume.service
```

Check power profile behavior:

```bash
power-diagnose.sh
power-profile-test.sh
```

Optional full power tuning setup:

```bash
sudo scripts/install-power-tuning.sh
```

## Troubleshooting

### Hyprland will not start

```bash
cat ~/.hyprland.log
```

Install the correct GPU drivers:

```bash
sudo pacman -S --needed mesa
sudo pacman -S --needed vulkan-intel       # Intel
sudo pacman -S --needed vulkan-radeon      # AMD
sudo pacman -S --needed nvidia-dkms nvidia-utils  # NVIDIA
```

### Quickshell disappears after suspend

```bash
systemctl --user status quickshell.service
systemctl --user status quickshell-resume.service
systemctl --user restart quickshell.service
```

### Power tuning does not apply

Run diagnostics:

```bash
power-diagnose.sh
```

If EPP or sysfs writes are denied, install the optional sudoers drop-in:

```bash
sudo scripts/install-power-tuning.sh
```

### Vietnamese input does not work in some apps

Confirm fcitx5 and Lotus are running:

```bash
fcitx5-remote
systemctl --user status fcitx5-lotus-server@$(whoami).service
```

The Hyprland config sets the required GTK/Qt/X11/Wayland input variables and grants the Lotus server keyboard permission.

### Monitor layout issues

Use the preserved custom file:

```bash
~/.config/hypr/custom/monitors.conf
```

Example:

```conf
monitor=HDMI-A-1,2560x1440@60,0x0,1
monitor=eDP-1,disable
```

## Security and privacy

Do not commit local secrets, personal notes, or generated private files. The repository ignores common local files such as `.env`, `.env.local`, IDE folders, caches, and local agent settings.

The project includes `scripts/rotate-cloudflare-secret.sh` for local credential rotation. It should be treated as a local utility and should not contain live credentials.

## Credits

- [Cartoon Shell](https://github.com/mailong2401/cartoon-shell) by mailong2401
- [dots-hyprland](https://github.com/end-4/dots-hyprland) by end-4

## License

GPLv3 — see [LICENSE](LICENSE).
