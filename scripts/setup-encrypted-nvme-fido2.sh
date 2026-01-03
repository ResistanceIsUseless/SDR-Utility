#!/bin/bash
# SPDX-License-Identifier: GPL-3.0+
# Setup script for encrypted NVMe with FIDO2/YubiKey support on MNT Reform

set -e

echo "=========================================="
echo "NVMe Encryption Setup with FIDO2/YubiKey"
echo "=========================================="
echo ""
echo "This script will:"
echo "  1. Install required packages"
echo "  2. Verify FIDO2 device is connected"
echo "  3. Set up LUKS encryption on NVMe"
echo "  4. Migrate current system to encrypted volume"
echo "  5. Enroll FIDO2 token for unlock"
echo "  6. Update initramfs"
echo ""
echo "WARNING: This will ERASE ALL DATA on /dev/nvme0n1"
echo ""
read -p "Press Enter to continue or Ctrl+C to abort..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root (use sudo)"
    exit 1
fi

echo ""
echo "[Step 1/6] Installing required packages..."
echo "=========================================="
apt-get update
apt-get install -y systemd-cryptsetup fido2luks fido2-tools jq

# Verify systemd-cryptenroll is available
if ! command -v systemd-cryptenroll &> /dev/null; then
    echo "ERROR: systemd-cryptenroll not found after installation"
    exit 1
fi

echo ""
echo "✓ Packages installed successfully"
echo "  - systemd-cryptenroll version: $(systemd-cryptenroll --version | head -1)"

echo ""
echo "[Step 2/6] Verifying FIDO2 device..."
echo "=========================================="

# List FIDO2 devices
if ! fido2-token -L 2>/dev/null | grep -q "dev"; then
    echo "ERROR: No FIDO2 device detected!"
    echo "Please connect your YubiKey or FIDO2 device and try again."
    exit 1
fi

echo "✓ FIDO2 device(s) detected:"
fido2-token -L

echo ""
echo "[Step 3/6] Setting up LUKS encryption on NVMe..."
echo "=========================================="
echo ""
echo "The reform-setup-encrypted-disk script will now:"
echo "  - Create LUKS encryption on /dev/nvme0n1"
echo "  - Set up LVM with swap and root volumes"
echo "  - Copy your current system to the encrypted volume"
echo "  - Configure boot to use the encrypted root"
echo ""
echo "You will be asked to:"
echo "  1. Confirm the operation"
echo "  2. Enter a LUKS passphrase (TWICE)"
echo "  3. Confirm migration and boot configuration"
echo ""
read -p "Press Enter to continue..."

# Run the reform setup script
reform-setup-encrypted-disk ssd

echo ""
echo "[Step 4/6] Enrolling FIDO2 token to LUKS volume..."
echo "=========================================="

# Find the LUKS device UUID
LUKS_DEV="/dev/nvme0n1p2"
if [ ! -b "$LUKS_DEV" ]; then
    echo "ERROR: Expected LUKS device $LUKS_DEV not found"
    echo "The reform-setup-encrypted-disk may have failed"
    exit 1
fi

# Open the LUKS volume if not already open
if [ ! -e /dev/mapper/reform_crypt ]; then
    echo "Opening LUKS volume..."
    cryptsetup luksOpen "$LUKS_DEV" reform_crypt
    NEED_CLOSE=1
else
    NEED_CLOSE=0
fi

# Activate the volume group
vgchange -ay reformvg || true

echo ""
echo "Now enrolling your FIDO2 token..."
echo "You will need to touch your YubiKey/FIDO2 device when prompted."
echo ""

# Enroll FIDO2 device
systemd-cryptenroll "$LUKS_DEV" --fido2-device=auto

echo ""
echo "✓ FIDO2 token enrolled successfully!"

# List enrolled tokens
echo ""
echo "Enrolled authentication methods:"
systemd-cryptenroll "$LUKS_DEV"

echo ""
echo "[Step 5/6] Updating initramfs with FIDO2 support..."
echo "=========================================="

# Mount the encrypted root to update its initramfs
TEMP_MNT=$(mktemp -d)
mount /dev/reformvg/root "$TEMP_MNT"

# Update initramfs in the new root
echo "Updating initramfs in encrypted volume..."
chroot "$TEMP_MNT" update-initramfs -u -k all

# Copy updated initramfs to boot partition
echo "Copying initramfs to /boot..."
KERNEL_VERSION=$(ls "$TEMP_MNT/boot" | grep "vmlinuz-" | sed 's/vmlinuz-//' | sort -V | tail -1)
if [ -n "$KERNEL_VERSION" ]; then
    cp "$TEMP_MNT/boot/initrd.img-$KERNEL_VERSION" /boot/
    echo "✓ Initramfs updated for kernel $KERNEL_VERSION"
else
    echo "WARNING: Could not determine kernel version"
fi

umount "$TEMP_MNT"
rmdir "$TEMP_MNT"

# Clean up
vgchange -an reformvg
if [ "$NEED_CLOSE" -eq 1 ]; then
    cryptsetup luksClose reform_crypt
fi

echo ""
echo "[Step 6/6] Verifying boot configuration..."
echo "=========================================="

# Check fstab
echo "Boot partition in /etc/fstab:"
grep "/boot" /etc/fstab || echo "WARNING: /boot not found in fstab"

# Check extlinux config
echo ""
echo "Boot loader configuration:"
ls -lh /boot/extlinux/extlinux.conf

echo ""
echo "=========================================="
echo "✓ Setup Complete!"
echo "=========================================="
echo ""
echo "Your NVMe drive is now encrypted with LUKS and can be unlocked with:"
echo "  1. Your FIDO2 token (YubiKey) - touch when prompted"
echo "  2. Your LUKS passphrase - as a fallback"
echo ""
echo "Next steps:"
echo "  1. Reboot your system: sudo reboot"
echo "  2. At boot, you'll be prompted to unlock the drive"
echo "  3. Connect your YubiKey and touch it when the LED blinks"
echo "  4. Alternatively, enter your LUKS passphrase"
echo ""
echo "IMPORTANT: Keep your LUKS passphrase safe in case you lose your YubiKey!"
echo ""
