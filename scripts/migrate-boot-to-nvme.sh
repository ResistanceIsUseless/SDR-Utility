#!/bin/bash
# Script to migrate boot partition from SD card to NVMe

set -e

echo "=== Migrating /boot from SD card to NVMe ==="
echo ""

# 1. Create mount point and mount NVMe boot partition
echo "Step 1: Mounting NVMe boot partition..."
mkdir -p /mnt/nvme-boot
mount /dev/nvme0n1p1 /mnt/nvme-boot

# 2. Copy boot files
echo "Step 2: Copying boot files from SD card to NVMe..."
echo "(Converting symlinks to files for FAT32 compatibility)"
rsync -avL /boot/ /mnt/nvme-boot/

# 3. Verify the copy
echo ""
echo "=== Verification ==="
echo "SD Card boot contents:"
ls -la /boot/ | head -10
echo ""
echo "NVMe boot contents:"
ls -la /mnt/nvme-boot/ | head -10
echo ""
echo "Disk usage:"
df -h /boot /mnt/nvme-boot

# 4. Update /etc/fstab
echo ""
echo "Step 3: Updating /etc/fstab..."
sed -i 's|/dev/mmcblk1p1|/dev/nvme0n1p1|g' /etc/fstab
echo "New /etc/fstab:"
grep boot /etc/fstab

# 5. Remount boot from NVMe
echo ""
echo "Step 4: Remounting /boot from NVMe..."
umount /boot
umount /mnt/nvme-boot
mount /dev/nvme0n1p1 /boot

# 6. Final verification
echo ""
echo "=== Final Verification ==="
echo "Boot partition now mounted from:"
mount | grep /boot
df -h /boot
echo ""
echo "✓ Migration complete! You can now remove the SD card after rebooting."
echo "  To test, run: sudo reboot"
