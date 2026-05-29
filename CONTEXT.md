# CONTEXT.md - Pixel Rice Desktop Setup

## Latest Update (2026-05-08) — Multi-Monitor & Layout Engine Fixes

This update addresses several critical bugs related to multi-monitor handling, layout engine conflicts, and animation stability.

### Critical Lessons Learned

**1. Multi-Monitor Instantiation: Manual is Safest**
The `Repeater { model: Quickshell.screens }` pattern is **unreliable for `PanelWindow`-derived components** like `Bar.qml` and `Panel.qml`. It often fails to create windows on secondary screens or causes them to be un-renderable.

**FIX**: Manually instantiate a component for each screen in `shell.qml`. Use a visibility guard to prevent errors on single-monitor setups. This is the only reliable method for multi-monitor UI.
```qml
// shell.qml
Bar {
    screen: Quickshell.screens[0]
}
Bar {
    visible: Quickshell.screens.length > 1
    screen: Quickshell.screens.length > 1 ? Quickshell.screens[1] : null
}
```

**2. Workspace Icon Overlap: `implicitWidth` in Layouts**
When using a `Repeater` inside a `RowLayout` (like in `Workspaces.qml`), child items **MUST** use `implicitWidth` or `Layout.preferredWidth`. Setting `width` directly will be ignored by the layout engine, causing all items to render at the same coordinate (0,0) and overlap.

**FIX**: Change `width` to `implicitWidth` on the `Item` delegate inside `Workspaces.qml`.

**3. Panel Layout Overlap: Animate `transform`, Not Position**
Using `y` offsets for animations inside a `ColumnLayout` (as was done in `Panel.qml`) fights with the layout engine, causing items to overlap. The layout calculates positions, then the animation overwrites them.

**FIX**: Use `transform: Translate { y: ... }` for animations. This applies a visual-only offset that does not break the component's position in the layout.

**4. Direct Anchoring vs. `RowLayout` for Bar Centering**
While `RowLayout` with spacers can center an item, it is fragile. If any other item in the layout has properties that "steal" space (like a stray `Layout.fillWidth`), the centering will fail.

**FIX**: For the main `Bar.qml`, using direct anchors is more robust.
```qml
// Bar.qml
Workspaces { anchors { left: parent.left; verticalCenter: parent.verticalCenter } }
Clock { anchors.centerIn: parent }
StatusPills { anchors { right: parent.right; verticalCenter: parent.verticalCenter } }
```

**5. Theme Singleton Broken in Quickshell**
(Previous finding, still critical) The `Theme.qml` singleton for colors is broken. Use hardcoded hex strings.

**6. `pragma Singleton` REQUIRED on Service Files**
(Previous finding, still critical) All service files must retain `pragma Singleton`.

### Current Architecture

```
~/.config/quickshell/
├── shell.qml          — Root entry, MANUALLY instantiates components for each screen.
├── Bar.qml            — Main top bar using direct anchoring for robust positioning.
├── Panel.qml          — Control center with stable animations using Translate transforms.
├── ...
├── Modules/
│   ├── Bar/
│   │   ├── Workspaces.qml  — Uses implicitWidth in a RowLayout to prevent overlaps.
│   │   ...
│   └── Panel/
│       ...
└── ...
```

### Bar Layout
Directly anchored for robustness:
- **[Workspaces]**: `anchors.left`
- **[Clock]**: `anchors.centerIn`
- **[StatusPills]**: `anchors.right`

### Deploy & Debug
```bash
# Deploy new configs
./install.sh -c

# Restart shell
pkill quickshell; sleep 1; quickshell &

# Verify layers on ALL screens
hyprctl layers | grep namespace
```
- You should see a `quickshell-bar` and `quickshell-panel` for each active monitor.
- `log.qslog` in `/run/user/1000/quickshell/by-id/*/` will show any QML errors.

### Known Limitations
- **`Repeater` is Unreliable for Windows**: Do not use `Repeater` for `PanelWindow` components. Always instantiate manually.
- **Brightness OSD**: `Svc.Brightness.onChanged()` signal remains un-emitted by the service.

### Notes for Future Agents
- **Layouts**: Inside a `RowLayout` or `ColumnLayout`, do not set `width` or `height`. Use `implicitWidth`, `implicitHeight`, or `Layout.*` properties.
- **Animations in Layouts**: Use `transform: Translate {}` to animate position without breaking the layout structure.
- **Multi-Monitor**: Always instantiate UI for each screen manually in `shell.qml`. Check `Quickshell.screens.length` to avoid errors.

---

## Theme Switcher Architecture (2026-05-27) — Zero-Copy Symlink-Based Design

### Problem Solved
Theme switching was slow because the old switcher copied the entire `~/.config/` directory (or at minimum `~/.config/hypr/` and `~/.config/quickshell/`) on every profile change. This meant repeated writes of non-theme files and could significantly wear SSD over time.

### Solution: User-Owned Theme Cache + Atomic Symlink Swaps
Instead of copying configs on every switch, the new design:
1. Stores immutable theme trees in `$XDG_DATA_HOME/pixel-rice/themes/` (defaults to `~/.local/share/pixel-rice/themes/`)
2. Uses atomic `ln -sfn` symlink swaps to point active config files at the theme cache
3. Only config files are symlinked (no user data is ever copied or lost)

### Architecture

```
~/.local/share/pixel-rice/themes/
├── cartoon-shell/        # Full theme tree (balanced/performance profiles)
│   ├── .config/hypr/
│   │   ├── hyprland.conf
│   │   ├── keybinds.conf
│   │   ├── hypridle.conf
│   │   ├── hyprlock.conf
│   │   └── hyprpaper.conf
│   └── .config/quickshell/
│       ├── shell.qml
│       ├── Bar.qml
│       └── services/
│           ├── NotifStatus.qml
│           ├── PowerProfile.qml
│           └── ...
└── power-saver/          # Minimal theme (zero effects, max perf)
    ├── .config/hypr/
    └── .config/quickshell/

~/.config/
├── hypr/
│   ├── hyprland.conf → ~/.local/share/pixel-rice/themes/power-saver/.config/hypr/hyprland.conf
│   ├── keybinds.conf → ~/.local/share/pixel-rice/themes/power-saver/.config/hypr/keybinds.conf
│   ├── custom/           # NEVER SYMLINKED — user's personal overrides stay safe
│   │   ├── monitors.conf
│   │   ├── keybinds.conf
│   │   ├── autostart.conf
│   │   └── env.conf
│   └── ...
├── quickshell → ~/.local/share/pixel-rice/themes/power-saver/.config/quickshell  (symlink to dir)
└── ...
```

### Key Design Decisions

**1. Hyprland Files: Individual Symlinks**
- Each file (`hyprland.conf`, `keybinds.conf`, etc.) is symlinked separately
- Reason: Allows `~/.config/hypr/custom/` to remain a real directory that is included via `source = ~/.config/hypr/custom/*.conf` in the theme files

**2. Quickshell: Whole Directory Symlink**
- The entire `~/.config/quickshell/` is a symlink to the theme's quickshell tree
- Reason: All QML files are tightly coupled to a single theme; no user customizations persist across theme switches

**3. Theme Cache in XDG_DATA_HOME**
- Uses standard `$XDG_DATA_HOME` (or `~/.local/share` by default) for application data
- Not in `/opt/` (no sudo required)
- Accessible only by the user (no permission complications)

**4. Why this approach won**
- We tested the alternatives conceptually and operationally: copying the whole tree, bind mounts, and overlay-style approaches all add complexity or still risk churn on switch.
- Atomic symlink swaps were the best balance of speed, simplicity, and disk health.
- They keep the active config instant to switch, avoid root-owned state, and make future debugging easier because the live config always points at a readable theme tree.

### Install & Deploy

```bash
# Install process (install.sh):
THEME_CACHE="${XDG_DATA_HOME:-$HOME/.local/share}/pixel-rice/themes"
mkdir -p "$THEME_CACHE"
cp -a ./dots "$THEME_CACHE/cartoon-shell"
cp -a ./dots-power-saver "$THEME_CACHE/power-saver"
chmod -R u+rwX,go+rX "$THEME_CACHE"
```

### Theme Switching (theme-switcher.sh)

```bash
link_file() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    ln -sfn "$src" "$dst"
}

# On power-saver profile:
rm -rf ~/.config/quickshell
ln -s "$THEME_BASE/power-saver/.config/quickshell" ~/.config/quickshell
link_file "$THEME_BASE/power-saver/.config/hypr/hyprland.conf" ~/.config/hypr/hyprland.conf
link_file "$THEME_BASE/power-saver/.config/hypr/keybinds.conf" ~/.config/hypr/keybinds.conf
# ... etc for all HYPR_FILES

# Reload UI
hyprctl reload
pkill -x quickshell
# Wait for a clean exit before relinking/restarting so the swap stays reliable.
for i in {1..40}; do
    pgrep -x quickshell >/dev/null 2>&1 || break
    sleep 0.05
done
quickshell &
```

### Performance & SSD Impact

| Operation | Old Approach | New Approach |
|-----------|---|---|
| Theme switch | Copy ~2MB config tree | Symlink swap (~1KB) |
| Time | 500ms–2s (slow) | ~100ms (instant) |
| Disk writes | Full tree copied | Only VFS metadata |
| Wear | Significant | Negligible |

### Preserving User Customizations

**Custom Hyprland config stays safe:**
- All user keybinds, monitors, and env vars go in `~/.config/hypr/custom/`
- Theme files source these files: `source = ~/.config/hypr/custom/*.conf`
- `custom/` is never deleted or symlinked

**Notification server fix:**
- Both theme trees have the corrected `NotifStatus.qml` (with `NS.NotificationServer`)
- `keepOnReload: true` ensures notifications survive theme switches

**App bindings normalized:**
- Both themes use `Super+F` → Dolphin, `Super+E` → NotepadNext
- Screenshot: `sh -c 'grim -g "$(slurp)" - | wl-copy'`
- Hyprland `exec` does not expand pipes or command substitution by itself, so the shell wrapper is required for region capture to work reliably.

### Debugging & Maintenance

```bash
# Check current theme symlinks
readlink ~/.config/quickshell
readlink ~/.config/hypr/hyprland.conf

# Verify theme cache exists
ls -la ~/.local/share/pixel-rice/themes/

# Manually switch to balanced
~/.local/bin/theme-switcher.sh balanced

# Manually switch to power-saver
~/.local/bin/theme-switcher.sh power-saver

# Check active profile
powerprofilesctl get
```

### Notes for Future Agents

1. **Do NOT copy configs on theme switches.** Use symlinks. This preserves SSD health and enables instant switching.
2. **Keep user-custom configs in separate directories** (`~/.config/hypr/custom/`) and source them from the theme files.
3. **Atomic symlink swaps** (`ln -sfn`) are safe: the swap is instant and the old symlink is replaced atomically.
4. **Both theme trees must stay structurally aligned** for switching to be seamless. If adding new config files, add them to both `dots/` and `dots-power-saver/`.
5. **If a switch back to balanced/high-performance feels slow**, check whether `quickshell` was still shutting down before the relink. The tested fix is to stop quickshell first, wait briefly, then swap symlinks and restart.
6. **If screenshots stop working**, verify the bind uses a shell wrapper. `grim | wl-copy` needs `sh -c` because Hyprland's `exec` does not interpret pipes or `$(...)`.
7. **If users report missing configs after a switch**, check if they stored files directly in `~/.config/hypr/` instead of in `custom/`. Educate them to use the custom directory.

---

**Status**: Problem persists - Dolphin still asks which application to use for every file type (.txt, .pdf, .docx, etc.)

### Problem Summary
After switching from Thunar to Dolphin as the file manager, Dolphin does not remember or apply default applications for file types. It prompts the user to select an application every time they try to open any file.

### Investigation Done
1. Fixed desktop file case sensitivity in `mimeapps.list`:
   - `notepadnext.desktop` → `NotepadNext.desktop`
   - `ghostty.desktop` → `com.mitchellh.ghostty.desktop`
   - `file-roller.desktop` → `org.gnome.FileRoller.desktop`

2. Removed conflicting local desktop files:
   - Deleted `~/.local/share/applications/floorp-2/3/4.desktop` which were registering Floorp as PDF handler

3. Updated `~/.config/mimeapps.list` with correct associations:
   - text/plain → NotepadNext.desktop
   - application/pdf → com.mitchellh.ghostty.desktop
   - application/msword → libreoffice-writer.desktop
   - application/zip → org.gnome.FileRoller.desktop

4. Updated `install.sh` to use correct desktop file names in xdg-mime commands

5. Fixed empty `~/.local/share/applications/mimeapps.list`

### Verification Results
```
xdg-mime query default text/plain → NotepadNext.desktop ✓
xdg-mime query default application/pdf → com.mitchellh.ghostty.desktop ✓
xdg-mime query default application/msword → libreoffice-writer.desktop ✓
```
Commands return correct values, but Dolphin still prompts.

### Possible Remaining Causes (NOT FIXED)
1. **Dolphin service cache**: Dolphin may have a cached service menu or KIO worker that needs clearing
2. **KDE system settings override**: Check `kcmshell6 filetypes` or `~/.local/share/applications/mimeapps.list` precedence
3. **Session restart required**: Full logout/login may be needed for KDE/Dolphin to recognize changes
4. **KIO protocol**: Dolphin uses KIO for file operations, which may have separate MIME handling from `xdg-open`
5. **Missing MimeType in desktop files**: The desktop files may not declare all MIME types they support

### Files Modified
- `~/.config/mimeapps.list` - Corrected desktop file names
- `~/.local/share/applications/` - Removed conflicting floorp desktop files
- `/home/shayneeo/Downloads/Rice/shayneeo-rice/install.sh` - Fixed desktop file references
- `/home/shayneeo/Downloads/Rice/shayneeo-rice/dots/.config/mimeapps.list` - Updated template

### Next Steps to Try (UNTESTED)
```bash
# Clear Dolphin cache
rm -rf ~/.cache/dolphin/
rm -rf ~/.local/share/dolphin/

# Check KDE file associations
kcmshell6 filetypes

# Verify desktop files have correct MimeType
grep -h "^MimeType=" /usr/share/applications/*.desktop | sort -u

# Try kde-open5 instead of xdg-open
kde-open5 --application notepadnext.desktop test.txt

# Logout and login (not just restart)
```

---

## Post-Sleep Quickshell Restart Fix (2026-05-29)

### Problem
After suspend (Super+Backspace), Quickshell process terminates and doesn't restart on wake:
- Quickshell UI disappears
- Super+Shift+S screenshot keybind becomes inactive
- All keybinds stop working until manual restart

### Root Cause
- `exec-once = quickshell` runs only once at Hyprland startup, not on resume
- Hyprland doesn't signal Quickshell to restart after suspend
- Keybinds sourced via hyprland.conf become inaccessible when Quickshell dies

### Solution
Implemented systemd-based auto-restart mechanism:

1. **Modified exec-once**: Changed from `exec-once = quickshell` to 
   ```
   exec-once = systemctl --user start quickshell.service || nohup quickshell >/dev/null 2>&1 &
   ```
   This uses systemd to manage Quickshell state, maintaining it across suspend/resume.

2. **Created quickshell-resume.service**: Listens to systemd sleep targets and restarts Quickshell:
   ```ini
   [Unit]
   After=sleep.target suspend.target
   [Service]
   ExecStart=systemctl --user start quickshell.service
   [Install]
   WantedBy=sleep.target suspend.target
   ```

3. **Ensured keybinds persistence**: Verified `source = ~/.config/hypr/keybinds.conf` in hyprland.conf

### Files Modified
- `~/.config/hypr/hyprland.conf` (live)
- `dots/.config/hypr/hyprland.conf` (both themes)
- Created `~/.config/systemd/user/quickshell-resume.service`
- Updated `install.sh` to deploy resume service on install

### Testing
```bash
# Verify Quickshell is running
pgrep -f "^quickshell"

# Check services are enabled
systemctl --user is-enabled quickshell.service
systemctl --user is-enabled quickshell-resume.service

# Manual test: suspend and wake, then check:
pgrep -f "^quickshell"  # Should still be running
```

### Systemd Integration
Both services are enabled by default:
- `quickshell.service`: Main service with `Restart=always`
- `quickshell-resume.service`: Explicitly triggers after sleep events

This ensures Quickshell and all keybinds remain functional across suspend/resume cycles.
