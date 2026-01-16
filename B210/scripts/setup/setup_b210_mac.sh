#!/bin/bash
# XC7K325T B210 Clone Setup Script for macOS
# Date: 2026-01-13

set -e

echo "======================================"
echo "XC7K325T B210 Clone Setup (macOS)"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Determine script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FIRMWARE_DIR="$SCRIPT_DIR/../firmware"

# Find UHD images directory
echo -e "${YELLOW}Finding UHD images directory...${NC}"
UHD_IMAGES_DIR_RAW=$(uhd_config_info --images-dir 2>/dev/null | grep -v "Images directory" | grep -v "^$" | head -1)

# If empty or not found, use default Homebrew locations
if [ -z "$UHD_IMAGES_DIR_RAW" ] || [ "$UHD_IMAGES_DIR_RAW" = ":" ]; then
    # Try common macOS Homebrew locations
    if [ -d "/opt/homebrew/share/uhd/images" ]; then
        UHD_IMAGES_DIR="/opt/homebrew/share/uhd/images"
    elif [ -d "/usr/local/share/uhd/images" ]; then
        UHD_IMAGES_DIR="/usr/local/share/uhd/images"
    else
        UHD_IMAGES_DIR="/opt/homebrew/share/uhd/images"
        echo -e "${YELLOW}Creating UHD images directory: $UHD_IMAGES_DIR${NC}"
        mkdir -p "$UHD_IMAGES_DIR"
    fi
else
    UHD_IMAGES_DIR="$UHD_IMAGES_DIR_RAW"
fi

echo -e "${GREEN}UHD images directory: $UHD_IMAGES_DIR${NC}"
echo ""

# Check if firmware directory exists
if [ ! -d "$FIRMWARE_DIR" ]; then
    echo -e "${RED}Error: Firmware directory not found at $FIRMWARE_DIR${NC}"
    exit 1
fi

# List available firmware files
echo -e "${YELLOW}Available firmware files:${NC}"
ls -lh "$FIRMWARE_DIR"/*.bin 2>/dev/null || echo "No firmware files found"
echo ""

# Backup existing firmware if it exists
if [ -f "$UHD_IMAGES_DIR/usrp_b210_fpga.bin" ]; then
    echo -e "${YELLOW}Backing up existing firmware...${NC}"
    cp "$UHD_IMAGES_DIR/usrp_b210_fpga.bin" "$UHD_IMAGES_DIR/usrp_b210_fpga.bin.backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}Backup created${NC}"
fi

# Copy XC7K325T firmware
echo ""
echo -e "${YELLOW}Installing XC7K325T firmware...${NC}"
if [ -f "$FIRMWARE_DIR/usrp_b210_fpga.bin" ]; then
    cp "$FIRMWARE_DIR/usrp_b210_fpga.bin" "$UHD_IMAGES_DIR/usrp_b210_fpga.bin"
    echo -e "${GREEN}Firmware installed successfully${NC}"
    ls -lh "$UHD_IMAGES_DIR/usrp_b210_fpga.bin"
else
    echo -e "${RED}Error: Firmware file not found at $FIRMWARE_DIR/usrp_b210_fpga.bin${NC}"
    exit 1
fi

# Check USB devices
echo ""
echo -e "${YELLOW}Checking for connected USB devices...${NC}"
system_profiler SPUSBDataType 2>/dev/null | grep -A 5 -i "2500\|cypress\|ettus" || echo "No USRP device details found"

echo ""
echo "======================================"
echo -e "${GREEN}Setup Complete!${NC}"
echo "======================================"
echo ""
echo "Files installed:"
echo "  - Firmware: $UHD_IMAGES_DIR/usrp_b210_fpga.bin"
echo "  - Source: $FIRMWARE_DIR/usrp_b210_fpga.bin"
echo ""
echo "Board detected:"
echo "  - Vendor ID: 0x2500"
echo "  - Serial: 0000000004BE"
echo "  - Package: XC7K325T-2FFG676C"
echo ""
echo "Next steps:"
echo "  1. Device is already connected"
echo "  2. Run: uhd_find_devices"
echo "  3. Run: uhd_usrp_probe"
echo "  4. Test RX: uhd_rx_samples_to_file --freq 100e6 --rate 1e6 --duration 1 --file test.dat"
echo ""
