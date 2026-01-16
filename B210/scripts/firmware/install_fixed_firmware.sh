#!/bin/bash
# Install fixed firmware after Vivado compilation

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "======================================"
echo "B210 Fixed Firmware Installer"
echo "======================================"
echo ""

BITSTREAM="B210/firmware/Kintex-7 USRP_B210/固件源工程/B210_Project_Firmwire/B210_Project_Firmwire.runs/impl_1/b200.bit"
UHD_IMAGES="/opt/homebrew/share/uhd/images"

if [ ! -f "$BITSTREAM" ]; then
    echo -e "${RED}ERROR: Bitstream not found!${NC}"
    echo "Expected: $BITSTREAM"
    echo ""
    echo "Make sure you've run Vivado synthesis and implementation first."
    exit 1
fi

# Check UHD images directory
if [ ! -d "$UHD_IMAGES" ]; then
    UHD_IMAGES="/opt/homebrew/Cellar/uhd/4.9.0.1_1/share/uhd/images"
fi

if [ ! -d "$UHD_IMAGES" ]; then
    echo -e "${RED}ERROR: UHD images directory not found!${NC}"
    exit 1
fi

echo "Found bitstream: $BITSTREAM"
echo "UHD images dir: $UHD_IMAGES"
echo ""

# Backup original firmware
if [ -f "$UHD_IMAGES/usrp_b210_fpga.bin" ]; then
    if [ ! -f "$UHD_IMAGES/usrp_b210_fpga.bin.ORIGINAL" ]; then
        echo -e "${YELLOW}Backing up original firmware...${NC}"
        cp "$UHD_IMAGES/usrp_b210_fpga.bin" "$UHD_IMAGES/usrp_b210_fpga.bin.ORIGINAL"
        echo -e "${GREEN}✓ Backup created${NC}"
    fi
fi

# Convert .bit to .bin (simplified - may need Vivado tools)
echo ""
echo -e "${YELLOW}Converting bitstream to binary format...${NC}"

# Option 1: If you have Vivado's promgen or write_cfgmem
if command -v promgen &> /dev/null; then
    promgen -w -b -p bin -u 0 "$BITSTREAM" -o b200.bin
    cp b200.bin "$UHD_IMAGES/usrp_b210_fpga.bin"
    echo -e "${GREEN}✓ Converted and installed${NC}"
# Option 2: Direct copy if .bit can be used (some UHD versions support it)
else
    echo -e "${YELLOW}Note: promgen not found, trying direct copy...${NC}"
    echo -e "${YELLOW}This may not work - you may need to convert .bit to .bin manually${NC}"
    echo ""
    echo "To convert manually, in Vivado TCL console run:"
    echo "  write_cfgmem -format bin -interface spix4 -size 16 \\"
    echo "    -loadbit \"up 0x0 b200.bit\" -file b200.bin"
    echo ""
    read -p "Continue with direct copy anyway? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$BITSTREAM" "$UHD_IMAGES/usrp_b210_fpga.bin"
        echo -e "${GREEN}✓ Copied (may need proper conversion)${NC}"
    else
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "To test the fix:"
echo "  1. Unplug and replug your B210"
echo "  2. Run: uhd_find_devices"
echo "  3. Test float32:"
echo "     rx_samples_to_file --freq 93.7e6 --rate 2e6 --gain 50 \\"
echo "       --ant RX2 --duration 2 --file test.dat"
echo "  4. Analyze: python3 B210/scripts/analyze_float32_fix.py test.dat"
echo ""
echo "To restore original firmware if needed:"
echo "  cp $UHD_IMAGES/usrp_b210_fpga.bin.ORIGINAL \\"
echo "     $UHD_IMAGES/usrp_b210_fpga.bin"
echo ""
