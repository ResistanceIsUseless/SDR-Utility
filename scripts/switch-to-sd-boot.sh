#!/bin/bash
# Switch boot to SD card (mmcblk1p2 - reformsdroot)

set -e

echo "=========================================="
echo "Switch Boot Device to SD Card"
echo "=========================================="
echo ""

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

echo "Checking SD card filesystem..."
SDCARD_ROOT="/dev/mmcblk1p2"

# Mount and check the SD card root
TEMP_MNT=$(mktemp -d)
mount "$SDCARD_ROOT" "$TEMP_MNT"

# Check if it looks like a valid root filesystem
if [ ! -d "$TEMP_MNT/etc" ] || [ ! -d "$TEMP_MNT/bin" ] || [ ! -d "$TEMP_MNT/boot" ]; then
    echo "ERROR: $SDCARD_ROOT doesn't appear to have a valid root filesystem"
    echo "Contents:"
    ls -la "$TEMP_MNT"
    umount "$TEMP_MNT"
    rmdir "$TEMP_MNT"
    exit 1
fi

echo "✓ Valid root filesystem found on $SDCARD_ROOT"
echo ""
echo "Root filesystem details:"
df -h "$TEMP_MNT"
echo ""
echo "Kernel version:"
ls "$TEMP_MNT/boot" | grep vmlinuz || echo "No kernel found - may need to copy from /boot"

umount "$TEMP_MNT"
rmdir "$TEMP_MNT"

echo ""
echo "Updating /etc/fstab to boot from SD card..."

# Backup current fstab
cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d-%H%M%S)

# Update fstab to use the SD card labeled partition
# Comment out the current nvme root
sed -i 's|^/dev/nvme0n1p2|#/dev/nvme0n1p2|' /etc/fstab

# Uncomment or add the reformsdroot line
if grep -q "^##LABEL=reformsdroot" /etc/fstab; then
    sed -i 's|^##LABEL=reformsdroot|LABEL=reformsdroot|' /etc/fstab
elif grep -q "^#LABEL=reformsdroot" /etc/fstab; then
    sed -i 's|^#LABEL=reformsdroot|LABEL=reformsdroot|' /etc/fstab
else
    # Add it if it doesn't exist
    echo "LABEL=reformsdroot / auto errors=remount-ro 0 1" >> /etc/fstab
fi

echo "✓ Updated /etc/fstab"
echo ""
echo "New /etc/fstab configuration:"
cat /etc/fstab
echo ""

echo "=========================================="
echo "✓ Boot device switched to SD card!"
echo "=========================================="
echo ""
echo "Current configuration:"
echo "  Boot partition: /dev/mmcblk0p1 (SD card)"
echo "  Root partition: LABEL=reformsdroot (/dev/mmcblk1p2)"
echo ""
echo "Next steps:"
echo "  1. Reboot: sudo reboot"
echo "  2. After reboot, verify you're on SD card: df -h /"
echo "  3. Then run the encryption script: sudo ./setup-encrypted-nvme-fido2.sh"
echo ""
echo "To revert to NVMe boot, restore: /etc/fstab.backup.*"
echo ""
