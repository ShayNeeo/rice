#!/usr/bin/env bash
# install-power-tuning.sh — install the passwordless sudoers drop-in
# required for the rice's power management to actually work.
#
# Run once:  sudo ./install-power-tuning.sh
# Then test: power-diagnose.sh

set -euo pipefail

SUDOERS_SRC="/home/shayneeo/Downloads/Rice/shayneeo-rice/etc/sudoers.d/pixel-rice-power"
SUDOERS_DST="/etc/sudoers.d/pixel-rice-power"

[[ -f "$SUDOERS_SRC" ]] || { echo "✗ Missing $SUDOERS_SRC"; exit 1; }
[[ $EUID -eq 0 ]] || { echo "✗ Run as root:  sudo $0"; exit 1; }

# visudo -c checks the file BEFORE installing it. Never install
# an unvalidated sudoers file — typos here = lockout.
if ! visudo -c -f "$SUDOERS_SRC" >/dev/null 2>&1; then
    echo "✗ sudoers file fails validation. Refusing to install."
    visudo -c -f "$SUDOERS_SRC"
    exit 1
fi

install -m 0440 -o root -g root "$SUDOERS_SRC" "$SUDOERS_DST"
visudo -c -f "$SUDOERS_DST" >/dev/null 2>&1
echo "✓ Installed $SUDOERS_DST (mode 0440, validated)"
echo
echo "Next steps:"
echo "  1. power-diagnose.sh balanced    # should now show EPP+ryzenadj OK"
echo "  2. manage_power.sh low-power     # should cap CPU at 3W STAPM"
echo "  3. power-diagnose.sh power-saver # verify temp drops"
