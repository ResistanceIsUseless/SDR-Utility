#!/bin/bash

set -e

echo "========================================="
echo "B210 SDR Setup Script for Debian"
echo "========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "Please do NOT run this script as root. Run it as a normal user with sudo privileges."
    exit 1
fi

# Update package lists
echo "[1/6] Updating package lists..."
sudo apt update

# Install UHD and dependencies
echo ""
echo "[2/6] Installing UHD (USRP Hardware Driver) and dependencies..."
sudo apt install -y uhd-host libuhd4.9.0 libuhd-dev

# Verify installation
if ! command -v uhd_find_devices &> /dev/null; then
    echo "ERROR: UHD installation failed!"
    exit 1
fi

echo "UHD installed successfully: $(uhd_find_devices --version 2>&1 | head -1)"

# Configure USB permissions
echo ""
echo "[3/6] Configuring USB permissions..."

# Create udev rules for USRP devices
sudo tee /etc/udev/rules.d/uhd-usrp.rules > /dev/null << 'EOF'
# USRP B200/B210/B200mini
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0020", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0021", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0022", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="3923", ATTR{idProduct}=="7813", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="3923", ATTR{idProduct}=="7814", MODE="0666"

# Ettus Research (general)
SUBSYSTEM=="usb", ATTR{idVendor}=="fffe", MODE="0666"
EOF

echo "USB rules created at /etc/udev/rules.d/uhd-usrp.rules"

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Add user to plugdev group (if it exists)
if getent group plugdev > /dev/null 2>&1; then
    sudo usermod -a -G plugdev $USER
    echo "Added $USER to plugdev group"
fi

# Download and install FPGA/firmware images
echo ""
echo "[4/6] Downloading and installing FPGA/firmware images..."
sudo uhd_images_downloader -t b2xx

# Verify images were downloaded
UHD_IMAGES_DIR=$(uhd_images_dir 2>/dev/null || echo "/usr/share/uhd/images")
if [ -d "$UHD_IMAGES_DIR" ]; then
    echo "Images installed to: $UHD_IMAGES_DIR"
    ls -lh "$UHD_IMAGES_DIR" | grep -i b2 | head -5 || echo "No B2xx images found (this might be normal)"
else
    echo "Warning: Could not verify images directory"
fi

# Install GNU Radio and additional SDR software
echo ""
echo "[5/6] Installing GNU Radio and additional SDR tools..."
echo "This may take a while as GNU Radio has many dependencies..."

# Core GNU Radio packages
sudo apt install -y \
    gnuradio \
    gnuradio-dev \
    python3-gnuradio \
    gr-osmosdr \
    libgnuradio-osmosdr0.2.0

# Additional SDR applications
echo ""
echo "Installing SDR applications (GQRX, CubicSDR, etc.)..."
sudo apt install -y \
    gqrx-sdr \
    cubicsdr \
    inspectrum \
    rtl-sdr \
    soapysdr-tools \
    soapysdr-module-uhd \
    dump1090-mutability

# Verify GNU Radio installation
if command -v gnuradio-companion &> /dev/null; then
    echo "GNU Radio installed successfully: $(gnuradio-config-info --version)"
else
    echo "Warning: GNU Radio installation may have issues"
fi

# Final instructions
echo ""
echo "[6/6] Setup complete!"
echo ""
echo "========================================="
echo "Next Steps:"
echo "========================================="
echo "1. If you were added to the plugdev group, you may need to log out and back in"
echo "   or run: newgrp plugdev"
echo ""
echo "2. Connect your B210 SDR device via USB 3.0"
echo ""
echo "3. Test the connection with:"
echo "   uhd_find_devices"
echo ""
echo "4. Get device info with:"
echo "   uhd_usrp_probe"
echo ""
echo "5. Test transmission/reception:"
echo "   uhd_fft -f 100e6 -s 10e6"
echo ""
echo "========================================="
echo "Installed SDR Applications:"
echo "========================================="
echo ""
echo "GNU Radio Companion (Graphical flowgraph editor):"
echo "   gnuradio-companion"
echo ""
echo "GQRX (Popular SDR receiver with waterfall display):"
echo "   gqrx"
echo ""
echo "CubicSDR (Cross-platform SDR application):"
echo "   CubicSDR"
echo ""
echo "Inspectrum (Offline signal analyzer):"
echo "   inspectrum <filename.cfile>"
echo ""
echo "UHD Spectrum Analyzer:"
echo "   uhd_fft"
echo ""
echo "Dump1090 (ADS-B decoder for aircraft tracking):"
echo "   dump1090-mutability --interactive --net"
echo ""
echo "========================================="
echo "Useful GNU Radio Example Flowgraphs:"
echo "========================================="
echo "Find example flowgraphs in:"
echo "   /usr/share/gnuradio/examples/"
echo ""
echo "Quick start with GNU Radio:"
echo "   1. Launch: gnuradio-companion"
echo "   2. Create a new flowgraph or open an example"
echo "   3. Set your USRP source to use the B210"
echo "   4. Run the flowgraph!"
echo ""
echo "========================================="
