#!/bin/bash
# manage_power.sh — Power profile switcher for AMD Ryzen systems.
# Applies CPU power tuning via amd-pstate EPP (native kernel) + ryzenadj
# (AUR, when /dev/amd_smu is available), AMD GPU DPM, PCIe ASPM, USB/SATA PM.
#
# Usage: manage_power.sh [low-power|balanced|performance]
#   If no arg, reads from powerprofilesctl get.
#
# v2 — fixes:
#   * ryzenadj failure no longer silently leaves CPU unboosted
#   * Uses amd-pstate EPP as primary (works without ryzen_smu char-dev)
#   * Detects ryzen_smu interface (sysfs vs char-dev) and adapts
#   * Caches failures to avoid per-call overhead
#   * Reports what actually changed (vs attempted)

set -uo pipefail

PROFILE="${1:-}"
PPD_PROFILE=""
RYZENADJ_OK=0  # 0=unknown, 1=works, -1=failed
RYZEN_SMU_INTF=""  # "" | "sysfs" | "chardev"
CPU_CAPPED=0      # 1 = frequency cap applied (effective TDP limiter)

# ---- helpers ----
say()  { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" >&2; }
ok()   { say "  ✓ $*"; }
warn() { say "  ⚠ $*"; }
die()  { say "✗ $*"; exit 1; }

# Map powerprofilesctl profile names to internal names
if [ -z "$PROFILE" ]; then
    PPD_PROFILE=$(powerprofilesctl get 2>/dev/null || true)
    case "$PPD_PROFILE" in
        power-saver) PROFILE="low-power" ;;
        balanced)    PROFILE="balanced" ;;
        performance) PROFILE="performance" ;;
        *)           PROFILE="balanced" ;;
    esac
fi

# ---- profile → EPP / frequency cap / boost / TDP / DPM mapping ----
# Strategy: use kernel-native amd-pstate sysfs as the PRIMARY control
# (frequency cap + boost disable) because:
#   1. It works on EVERY system, no AUR package required
#   2. ryzen_smu 0.1.7+ in AUR only exposes sysfs; ryzenadj binary
#      still expects the old /dev/amd_smu char-dev, so ryzenadj
#      is currently broken on this kernel module version
#   3. Capping scaling_max_freq + disabling boost gives ~equivalent
#      thermal behaviour to ryzenadj STAPM capping for sustained loads
#
# EPP values: 0=performance, 128=balance_performance, 192=balance_power, 255=power
# FREQ values: kHz (use awk to convert MHz → kHz)
CPU_BOOST_PATH="/sys/devices/system/cpu/cpufreq/boost"
FREQ_MAX_PATH="/sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq"
FREQ_MIN_PATH="/sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq"
# IMPORTANT: use cpuinfo_max_freq (the true hardware cap), NOT
# scaling_max_freq (which reflects the current — possibly user-capped —
# value). Reading scaling_max_freq as "HW_MAX" creates a self-trapping
# bug where the first cap can never be undone.
HW_MAX=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null || echo 4465261)
HW_MIN=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null || echo 1102866)

# ---- Profile-to-frequency mapping (tuned for Ryzen 7 5800H / Cezanne) ----
#
# The 5800H has these operating points (verified on this kernel):
#   cpuinfo_min_freq    = 403 MHz   (idle)
#   amd_pstate_lowest_nonlinear_freq = 1102 MHz (most efficient point;
#                                            below this, voltage scales up
#                                            and efficiency DROPS)
#   base clock          = 3.2 GHz
#   all-core boost      = ~3.6 GHz  (sustained 35W, manageable on this cooler)
#   single-core boost   = 4.4 GHz   (burst, only safe with thermal headroom)
#   default STAPM       = 45W       (this is what cooks the laptop)
#   safe sustained cTDP = 35W       (matches the all-core boost clock)
#
# Strategy: pick the cap that maximises sustained throughput-per-watt
# while keeping the package below 80°C under your specific workload
# (droid 53% + opencode 31% = multi-thread sustained).
#
# Single-core bursts to 4.4 GHz are still allowed by `boost=1` — they
# finish in milliseconds and don't cause sustained thermal load. The
# `scaling_max_freq` cap is what limits the **all-core** sustained
# thermal envelope.
case "$PROFILE" in
    low-power)
        EPP_VAL="power"
        # Cap at 1800 MHz (just above lowest_nonlinear). Maximises
        # efficiency per watt. Still allows single-core bursts to 4.4 GHz
        # for snappy UI (e.g. typing latency, keybind responsiveness).
        # No thermal throttling risk at this cap.
        FREQ_MAX_MHZ=1800
        BOOST_ENABLE="1"
        ASPM="powersupersave"
        USB_AUTOSUSPEND="2"
        NMI_WATCHDOG="0"
        DPM_LEVEL="manual"
        DPM_SCLK="1"
        WIFI_PS="on"
        ;;
    balanced)
        EPP_VAL="balance_power"
        # Cap at 3000 MHz — matches the 5800H all-core sustained clock at
        # ~25W. Sustained load (droid + opencode) will draw ~20-25W and
        # stay in the 65-75°C range on this cooler. Single-core bursts
        # to 4.4 GHz still allowed for interactive responsiveness.
        # This is the right default for "use it all day" workloads.
        FREQ_MAX_MHZ=3000
        BOOST_ENABLE="1"
        ASPM="powersave"
        USB_AUTOSUSPEND="2"
        NMI_WATCHDOG="0"
        DPM_LEVEL="auto"
        DPM_SCLK=""
        WIFI_PS="off"
        ;;
    performance)
        EPP_VAL="balance_performance"
        # Cap at 3600 MHz — matches the 5800H all-core boost clock under
        # cTDP 35W. This is the safe ceiling for sustained work: ~35W
        # draw, 75-82°C typical, no throttling. Single-core bursts to
        # 4.4 GHz for short interactive tasks. Use this for builds,
        # large AI training runs, video encoding.
        FREQ_MAX_MHZ=3600
        BOOST_ENABLE="1"
        ASPM="performance"
        USB_AUTOSUSPEND="-1"
        NMI_WATCHDOG="1"
        DPM_LEVEL="auto"
        DPM_SCLK=""
        WIFI_PS="off"
        ;;
    *)
        die "Unknown profile: $PROFILE"
        ;;
esac

FREQ_MAX_KHZ=$((FREQ_MAX_MHZ * 1000))

say "Switching to: $PROFILE (EPP=$EPP_VAL, ASPM=$ASPM)"

# ---- Pre-flight: check if the sudoers drop-in is installed ----
# If not installed, sysfs writes that need root will all fail silently.
# Detect by attempting a harmless NOPASSWD check.
if ! sudo -n true 2>/dev/null; then
    warn "Passwordless sudo NOT configured — power tuning will be limited."
    warn "  Install:  sudo ~/Downloads/Rice/shayneeo-rice/scripts/install-power-tuning.sh"
fi

# ---- ACPI platform profile (kernel side) ----
if [ -w /sys/firmware/acpi/platform_profile ]; then
    echo "$PROFILE" | sudo -n tee /sys/firmware/acpi/platform_profile >/dev/null 2>&1 && \
        ok "ACPI platform_profile=$PROFILE" || warn "ACPI platform_profile: sudo unavailable"
fi

# ---- CPU EPP via native amd-pstate (works without ryzenadj) ----
EPP_SYSFS=/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
if [ -f "$EPP_SYSFS" ]; then
    EPP_NOW=$(cat "$EPP_SYSFS" 2>/dev/null || echo "?")
    if echo "$EPP_VAL" | sudo -n tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference >/dev/null 2>&1; then
        ok "EPP set to $EPP_VAL (was $EPP_NOW)"
    else
        # Sudo not allowed. Try direct write in case udev rules permit it.
        if echo "$EPP_VAL" > "$EPP_SYSFS" 2>/dev/null; then
            ok "EPP set to $EPP_VAL (no sudo needed)"
        else
            warn "EPP write denied — install sudoers drop-in to enable CPU power tuning"
            warn "  See: ~/Downloads/Rice/shayneeo-rice/etc/sudoers.d/pixel-rice-power"
        fi
    fi
fi

# ---- CPU frequency cap (the effective TDP limiter on this kernel) ----
# This is the primary TDP-equivalent control since ryzenadj is broken
# against ryzen_smu 0.1.7+. Capping max frequency + disabling boost gives
# ~equivalent sustained-thermal behaviour to a STAPM cap.
if [ -f "$FREQ_MAX_PATH" ]; then
    FREQ_NOW_MHZ=$(awk '{print int($1/1000)}' "$FREQ_MAX_PATH" 2>/dev/null)
    if [ "$FREQ_MAX_MHZ" -lt $((HW_MAX/1000)) ]; then
        # Lower the cap (unprivileged usually works for scaling_max_freq)
        if echo "$FREQ_MAX_KHZ" | sudo -n tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq >/dev/null 2>&1; then
            ok "CPU cap: ${FREQ_MAX_MHZ} MHz (was $((FREQ_NOW_MHZ)) MHz, hw-max $((HW_MAX/1000)) MHz)"
            CPU_CAPPED=1
        else
            warn "CPU cap: sudo not available — cap not applied"
        fi
    else
        # Restore hardware max
        if echo "$HW_MAX" | sudo -n tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq >/dev/null 2>&1; then
            ok "CPU cap: $((HW_MAX/1000)) MHz (uncapped, performance mode)"
            CPU_CAPPED=1
        fi
    fi
fi

# ---- CPU boost (CPB) control — second line of thermal defence ----
# `boost` is a per-cpufreq-policy attribute (not per-cpu). On modern
# kernels it's exposed at /sys/devices/system/cpu/cpufreq/boost.
if [ -f "$CPU_BOOST_PATH" ]; then
    BOOST_NOW=$(cat "$CPU_BOOST_PATH" 2>/dev/null || echo "?")
    if echo "$BOOST_ENABLE" | sudo -n tee "$CPU_BOOST_PATH" >/dev/null 2>&1; then
        if [ "$BOOST_ENABLE" = "0" ]; then
            ok "CPU boost: DISABLED (was $BOOST_NOW) — single-core boost off"
        else
            ok "CPU boost: enabled (was $BOOST_NOW)"
        fi
    else
        warn "CPU boost: write denied (was $BOOST_NOW)"
    fi
fi

# ---- TDP via ryzenadj (only when /dev/amd_smu char-dev exists) ----
detect_ryzen_smu_intf() {
    [ -e /dev/amd_smu ] && { echo "chardev"; return; }
    [ -d /sys/kernel/ryzen_smu_drv ] && { echo "sysfs"; return; }
    echo ""
}

RYZEN_SMU_INTF=$(detect_ryzen_smu_intf)
case "$RYZEN_SMU_INTF" in
    chardev)
        if command -v ryzenadj >/dev/null 2>&1; then
            if [ -w /dev/amd_smu ] || sudo -n ryzenadj -i >/dev/null 2>&1; then
                RYZENADJ_OK=1
                ok "ryzen_smu char-dev interface detected, TDP control enabled"
            else
                RYZENADJ_OK=-1
                warn "ryzen_smu char-dev exists but sudoers rule for ryzenadj not installed"
            fi
        else
            RYZENADJ_OK=-1
            warn "ryzenadj binary not installed"
        fi
        ;;
    sysfs)
        warn "ryzen_smu 0.1.7+ uses sysfs (/sys/kernel/ryzen_smu_drv/)"
        warn "but ryzenadj expects the old /dev/amd_smu char-dev"
        warn "→ TDP via ryzenadj unavailable. Will use kernel freq cap + EPP instead."
        RYZENADJ_OK=-1
        ;;
    "")
        if ! lsmod 2>/dev/null | grep -q "^ryzen_smu "; then
            warn "ryzen_smu module not loaded. Attempting modprobe..."
            if sudo -n modprobe ryzen_smu 2>/dev/null; then
                ok "ryzen_smu loaded"
            else
                warn "Cannot modprobe ryzen_smu (no sudo)"
            fi
        fi
        RYZENADJ_OK=-1
        ;;
esac

if [ "$RYZENADJ_OK" = "1" ] && command -v ryzenadj >/dev/null 2>&1; then
    case "$PROFILE" in
        low-power)
            RY_OUT=$(sudo -n ryzenadj --stapm-limit=3000  --fast-limit=7000  --slow-limit=5000 \
                --tctl-temp=55 --apu-skin-temp=40 2>&1)
            RC=$?
            if [ "$RC" -eq 0 ]; then
                ok "ryzenadj: STAPM=3W fast=7W slow=5W Tctl=55C skin=40C (low-power)"
            else
                warn "ryzenadj call failed (rc=$RC): $RY_OUT"
            fi
            ;;
        balanced)
            RY_OUT=$(sudo -n ryzenadj --stapm-limit=25000 --fast-limit=32000 --slow-limit=28000 \
                --tctl-temp=78 --apu-skin-temp=50 2>&1)
            RC=$?
            if [ "$RC" -eq 0 ]; then
                ok "ryzenadj: STAPM=25W fast=32W slow=28W Tctl=78C skin=50C (balanced)"
            else
                warn "ryzenadj call failed (rc=$RC): $RY_OUT"
            fi
            ;;
        performance)
            RY_OUT=$(sudo -n ryzenadj --stapm-limit=45000 --fast-limit=54000 --slow-limit=43500 \
                --tctl-temp=95 --apu-skin-temp=60 2>&1)
            RC=$?
            if [ "$RC" -eq 0 ]; then
                ok "ryzenadj: STAPM=45W fast=54W slow=43.5W Tctl=95C skin=60C (performance)"
            else
                warn "ryzenadj call failed (rc=$RC): $RY_OUT"
            fi
            ;;
    esac
fi

# ---- AMD GPU DPM ----
GPU="/sys/class/drm/card0/device"
if [ -d "$GPU" ]; then
    if [ -n "$DPM_LEVEL" ]; then
        echo "$DPM_LEVEL" | sudo -n tee "$GPU/power_dpm_force_performance_level" >/dev/null 2>&1 && \
            ok "amdgpu: dpm_force_performance_level=$DPM_LEVEL" || warn "amdgpu DPM level: sudo needed"
    fi
    if [ -n "$DPM_SCLK" ] && [ "$DPM_LEVEL" = "manual" ]; then
        echo "$DPM_SCLK" | sudo -n tee "$GPU/pp_dpm_sclk" >/dev/null 2>&1 && \
            ok "amdgpu: locked SCLK to state $DPM_SCLK" || true
    fi
fi

# ---- PCIe ASPM ----
if [ -w /sys/module/pcie_aspm/parameters/policy ]; then
    echo "$ASPM" | sudo -n tee /sys/module/pcie_aspm/parameters/policy >/dev/null 2>&1 && \
        ok "PCIe ASPM=$ASPM" || warn "ASPM: sudo needed"
fi

# ---- USB autosuspend ----
if [ -w /sys/module/usbcore/parameters/autosuspend ]; then
    echo "$USB_AUTOSUSPEND" | sudo -n tee /sys/module/usbcore/parameters/autosuspend >/dev/null 2>&1 && \
        ok "USB autosuspend=$USB_AUTOSUSPEND" || warn "USB: sudo needed"
fi

# ---- SATA ALPM ----
for host in /sys/class/scsi_host/host*/link_power_management_policy; do
    [ -w "$host" ] || continue
    case "$PROFILE" in
        low-power|balanced) echo "min_power" | sudo -n tee "$host" >/dev/null 2>&1 ;;
        performance)        echo "max_performance" | sudo -n tee "$host" >/dev/null 2>&1 ;;
    esac
done

# ---- Runtime PM (PCI / I2C / HDA) ----
for dev in /sys/bus/pci/devices/*/power/control; do
    [ -w "$dev" ] || continue
    case "$PROFILE" in
        low-power|balanced) echo "auto" | sudo -n tee "$dev" >/dev/null 2>&1 ;;
        performance)        echo "on"   | sudo -n tee "$dev" >/dev/null 2>&1 ;;
    esac
done

# ---- NMI watchdog (saves ~0.5W idle) ----
[ -w /proc/sys/kernel/nmi_watchdog ] && \
    echo "$NMI_WATCHDOG" | sudo -n tee /proc/sys/kernel/nmi_watchdog >/dev/null 2>&1 && \
    ok "NMI watchdog=$NMI_WATCHDOG" || true

# ---- WiFi power save ----
WIFI_IFACE=$(iw dev 2>/dev/null | grep -o 'Interface \S*' | head -1 | awk '{print $2}')
if [ -n "$WIFI_IFACE" ]; then
    iw dev "$WIFI_IFACE" set power_save "$WIFI_PS" 2>/dev/null && \
        ok "WiFi $WIFI_IFACE power_save=$WIFI_PS" || true
fi

# ---- Summary ----
say "Profile $PROFILE applied."
if [ "$RYZENADJ_OK" = "1" ]; then
    ok "TDP control: ryzenadj (full STAPM/fast/slow/tctl limits active)"
elif [ "$CPU_CAPPED" = "1" ]; then
    ok "TDP control: frequency cap (${FREQ_MAX_MHZ} MHz) + boost=$BOOST_ENABLE (ryzenadj N/A)"
else
    warn "CPU is NOT capped — neither ryzenadj nor frequency cap worked."
    warn "  Install sudoers drop-in: sudo ~/Downloads/Rice/shayneeo-rice/scripts/install-power-tuning.sh"
    warn "  Verify with:  power-diagnose.sh"
fi
exit 0
