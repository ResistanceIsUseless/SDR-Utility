#!/bin/bash
# Install SoapyUHD module for B210 support in SDR++

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "======================================"
echo "SoapyUHD Module Installer"
echo "======================================"
echo ""
echo "This will install SoapyUHD so SDR++ can"
echo "use your B210 via SoapySDR"
echo ""

# Check if SoapySDR is installed
if ! command -v SoapySDRUtil &> /dev/null; then
    echo -e "${RED}SoapySDR not found! Installing...${NC}"
    brew install soapysdr
fi

# Check if UHD is installed
if ! command -v uhd_find_devices &> /dev/null; then
    echo -e "${RED}UHD not found! Installing...${NC}"
    brew install uhd
fi

echo -e "${YELLOW}Installing SoapyUHD module...${NC}"
echo ""

# Clone SoapyUHD
cd /tmp
if [ -d "SoapyUHD" ]; then
    rm -rf SoapyUHD
fi

git clone https://github.com/pothosware/SoapyUHD.git
cd SoapyUHD

# Build and install
mkdir build
cd build

echo -e "${YELLOW}Configuring...${NC}"
cmake .. -DCMAKE_INSTALL_PREFIX=/opt/homebrew

echo -e "${YELLOW}Building...${NC}"
make -j$(sysctl -n hw.ncpu)

echo -e "${YELLOW}Installing...${NC}"
sudo make install

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""

# Test
echo -e "${YELLOW}Testing SoapyUHD installation...${NC}"
SoapySDRUtil --info

echo ""
echo -e "${YELLOW}Searching for B210...${NC}"
SoapySDRUtil --find

echo ""
if SoapySDRUtil --find | grep -q "uhd"; then
    echo -e "${GREEN}✓ SUCCESS! B210 found via SoapySDR${NC}"
    echo ""
    echo "You can now use SDR++ with your B210:"
    echo "  1. Launch SDR++"
    echo "  2. Select 'SoapySDR' as source"
    echo "  3. Choose driver: uhd"
    echo "  4. Set antenna: RX2"
    echo "  5. Set sample rate: 2000000"
else
    echo -e "${YELLOW}Testing UHD directly...${NC}"
    uhd_find_devices

    echo ""
    echo -e "${YELLOW}If UHD finds device but SoapySDR doesn't:${NC}"
    echo "  1. Restart terminal"
    echo "  2. Run: SoapySDRUtil --find"
    echo "  3. Check for 'driver = uhd'"
fi

echo ""
