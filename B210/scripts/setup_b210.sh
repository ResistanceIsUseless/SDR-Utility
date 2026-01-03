#!/bin/bash
# XC7K325T B210 Clone Setup Script for uconsole
# Date: 2025-12-10

set -e

echo "======================================"
echo "XC7K325T B210 Clone Setup"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Find UHD images directory
echo -e "${YELLOW}Finding UHD images directory...${NC}"
UHD_IMAGES_DIR=$(uhd_config_info --images-dir 2>/dev/null || echo "/usr/local/share/uhd/images")

if [ ! -d "$UHD_IMAGES_DIR" ]; then
    echo -e "${YELLOW}Creating UHD images directory: $UHD_IMAGES_DIR${NC}"
    sudo mkdir -p "$UHD_IMAGES_DIR"
fi

echo -e "${GREEN}UHD images directory: $UHD_IMAGES_DIR${NC}"
echo ""

# Backup existing firmware if it exists
if [ -f "$UHD_IMAGES_DIR/usrp_b210_fpga.bin" ]; then
    echo -e "${YELLOW}Backing up existing firmware...${NC}"
    sudo cp "$UHD_IMAGES_DIR/usrp_b210_fpga.bin" "$UHD_IMAGES_DIR/usrp_b210_fpga.bin.backup_$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}Backup created${NC}"
fi

# Copy XC7K325T firmware
echo ""
echo -e "${YELLOW}Installing XC7K325T firmware...${NC}"
if [ -f ~/sdr_files/firmware/usrp_b210_fpga.bin ]; then
    sudo cp ~/sdr_files/firmware/usrp_b210_fpga.bin "$UHD_IMAGES_DIR/usrp_b210_fpga.bin"
    echo -e "${GREEN}Firmware installed successfully${NC}"
    ls -lh "$UHD_IMAGES_DIR/usrp_b210_fpga.bin"
else
    echo -e "${RED}Error: Firmware file not found at ~/sdr_files/firmware/usrp_b210_fpga.bin${NC}"
    exit 1
fi

# Check USB devices
echo ""
echo -e "${YELLOW}Checking for connected USB devices...${NC}"
lsusb | grep -i "2500\|cypress\|ettus" || echo "No USRP device detected yet"

echo ""
echo "======================================"
echo -e "${GREEN}Setup Complete!${NC}"
echo "======================================"
echo ""
echo "Files installed:"
echo "  - Firmware: $UHD_IMAGES_DIR/usrp_b210_fpga.bin"
echo "  - XDC constraints: ~/sdr_files/b210.xdc"
echo "  - Schematic: ~/sdr_files/docs/USRP_B210.pdf"
echo ""
echo "Next steps:"
echo "  1. Connect the B210 board via USB"
echo "  2. Run: uhd_find_devices"
echo "  3. Run: uhd_usrp_probe"
echo "  4. Test RX: uhd_rx_samples_to_file --freq 100e6 --rate 1e6 --duration 1 --file test.dat"
echo ""
