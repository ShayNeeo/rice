#!/bin/bash

# Power profile switcher for ThinkBook 14p Gen 2 (AMD Ryzen)
# Applies TDP limits via ryzenadj + system-wide power tuning
# Called by ryzen-power.path on platform_profile change or manually
# Usage: manage_power.sh [low-power|balanced|performance]
#   If no arg, reads from powerprofilesctl get

set -euo pipefail

PROFILE="${1:-}"

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

# Map to platform_profile (kernel interface)
case "$PROFILE" in
    low-power)  PP="low-power" ;;
    balanced)   PP="balanced" ;;
    performance) PP="performance" ;;
    *)          PP="balanced" ;;
esac

# Also set kernel platform_profile if available
if [ -w /sys/firmware/acpi/platform_profile ]; then
    echo "$PP" | sudo tee /sys/firmware/acpi/platform_profile >/dev/null 2>&1 || true
fi

echo "[$(date '+%H:%M:%S')] Switching to: $PROFILE"

# ---- CPU TDP via ryzenadj ----
if command -v ryzenadj >/dev/null 2>&1; then
    case "$PROFILE" in
        low-power)
            # 3W STAPM, 7W fast boost, 5W sustained, 55C temp limit
            sudo ryzenadj \
                --stapm-limit=3000 \
                --fast-limit=7000 \
                --slow-limit=5000 \
                --tctl-temp=55 \
                --apu-skin-temp=40 \
                --power-saving
            ;;
        balanced)
            # 25W STAPM, 32W fast, 28W sustained, 78C
            sudo ryzenadj \
                --stapm-limit=25000 \
                --fast-limit=32000 \
                --slow-limit=28000 \
                --tctl-temp=78 \
                --apu-skin-temp=50 \
                --balanced
            ;;
        performance)
            # 45W STAPM, 54W fast, 43.5W sustained, 95C
            sudo ryzenadj \
                --stapm-limit=45000 \
                --fast-limit=54000 \
                --slow-limit=43500 \
                --tctl-temp=95 \
                --apu-skin-temp=60 \
                --max-performance
            ;;
    esac
    echo "  ryzenadj: TDP applied"
fi

# ---- AMD GPU power management ----
GPU="/sys/class/drm/card0/device"
if [ -d "$GPU" ]; then
    case "$PROFILE" in
        low-power)
            echo "manual" | sudo tee "$GPU/power_dpm_force_performance_level" 2>/dev/null || true
            echo "1" | sudo tee "$GPU/pp_dpm_sclk" 2>/dev/null || true
            echo "auto" | sudo tee "$GPU/device/power_method" 2>/dev/null || true
            ;;
        balanced)
            echo "auto" | sudo tee "$GPU/power_dpm_force_performance_level" 2>/dev/null || true
            ;;
        performance)
            echo "auto" | sudo tee "$GPU/power_dpm_force_performance_level" 2>/dev/null || true
            ;;
    esac
    echo "  amdgpu: profile set"
fi

# ---- PCIe ASPM ----
case "$PROFILE" in
    low-power)
        # Force PCIe Active State Power Management to deepest state
        if [ -w /sys/module/pcie_aspm/parameters/policy ]; then
            echo "powersupersave" | sudo tee /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
        fi
        ;;
    balanced)
        if [ -w /sys/module/pcie_aspm/parameters/policy ]; then
            echo "powersave" | sudo tee /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
        fi
        ;;
    performance)
        if [ -w /sys/module/pcie_aspm/parameters/policy ]; then
            echo "performance" | sudo tee /sys/module/pcie_aspm/parameters/policy 2>/dev/null || true
        fi
        ;;
esac

# ---- USB autosuspend ----
case "$PROFILE" in
    low-power)
        echo "2" | sudo tee /sys/module/usbcore/parameters/autosuspend 2>/dev/null || true
        ;;
    balanced)
        echo "2" | sudo tee /sys/module/usbcore/parameters/autosuspend 2>/dev/null || true
        ;;
    performance)
        echo "-1" | sudo tee /sys/module/usbcore/parameters/autosuspend 2>/dev/null || true
        ;;
esac

# ---- SATA link power management ----
for host in /sys/class/scsi_host/host*/link_power_management_policy; do
    if [ -w "$host" ]; then
        case "$PROFILE" in
            low-power|balanced)
                echo "min_power" | sudo tee "$host" 2>/dev/null || true
                ;;
            performance)
                echo "max_performance" | sudo tee "$host" 2>/dev/null || true
                ;;
        esac
    fi
done

# ---- Runtime PM for PCI devices ----
for pci_dev in /sys/bus/pci/devices/*/power/control; do
    if [ -w "$pci_dev" ]; then
        case "$PROFILE" in
            low-power|balanced)
                echo "auto" | sudo tee "$pci_dev" 2>/dev/null || true
                ;;
            performance)
                echo "on" | sudo tee "$pci_dev" 2>/dev/null || true
                ;;
        esac
    fi
done

# ---- I2C controller power (touchpad) ----
for i2c in /sys/bus/i2c/devices/i2c-*/device/power/control; do
    if [ -w "$i2c" ]; then
        case "$PROFILE" in
            low-power)
                echo "auto" | sudo tee "$i2c" 2>/dev/null || true
                ;;
            *)
                echo "on" | sudo tee "$i2c" 2>/dev/null || true
                ;;
        esac
    fi
done

# ---- Sound power management ----
# Enable codec runtime PM
for codec in /sys/bus/hdaudio/devices/*/power/control; do
    if [ -w "$codec" ]; then
        echo "auto" | sudo tee "$codec" 2>/dev/null || true
    fi
done

# PulseAudio/PipeWire suspend on idle (handled by pipewire config, not here)

# ---- WiFi power saving ----
WIFI_IFACE=$(iw dev 2>/dev/null | grep -o 'Interface \S*' | head -1 | awk '{print $2}')
if [ -n "$WIFI_IFACE" ]; then
    case "$PROFILE" in
        low-power)
            iw dev "$WIFI_IFACE" set power_save on 2>/dev/null || true
            ;;
        *)
            iw dev "$WIFI_IFACE" set power_save off 2>/dev/null || true
            ;;
    esac
fi

# ---- NMI watchdog (saves ~0.5W on idle) ----
case "$PROFILE" in
    low-power)
        echo "0" | sudo tee /proc/sys/kernel/nmi_watchdog 2>/dev/null || true
        ;;
    *)
        echo "1" | sudo tee /proc/sys/kernel/nmi_watchdog 2>/dev/null || true
        ;;
esac

# ---- Laptop mode (writeback throttling) ----
case "$PROFILE" in
    low-power)
        echo "5" | sudo tee /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null || true
        echo "6000" | sudo tee /proc/sys/vm/dirty_expire_centisecs 2>/dev/null || true
        ;;
    balanced)
        echo "5" | sudo tee /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null || true
        echo "3000" | sudo tee /proc/sys/vm/dirty_expire_centisecs 2>/dev/null || true
        ;;
    performance)
        echo "5" | sudo tee /proc/sys/vm/dirty_writeback_centisecs 2>/dev/null || true
        echo "500" | sudo tee /proc/sys/vm/dirty_expire_centisecs 2>/dev/null || true
        ;;
esac

echo "[$(date '+%H:%M:%S')] Profile $PROFILE applied — all tunables set"
