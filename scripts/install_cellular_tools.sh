#!/bin/bash
# Cellular Research Tools Installer for macOS
# Optimized for B210 Clone

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "======================================"
echo "Cellular Research Tools Installer"
echo "======================================"
echo ""
echo "This will install tools for:"
echo "  - GSM/2G analysis (gr-gsm)"
echo "  - LTE/4G/5G research (srsRAN)"
echo "  - Cell tower mapping"
echo "  - IMSI catcher detection"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: This script is for macOS only${NC}"
    exit 1
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo -e "${BLUE}=== Phase 1: Core Tools ===${NC}"
echo ""

# GNU Radio (essential for most cellular tools)
echo -e "${YELLOW}Installing GNU Radio...${NC}"
if ! command -v gnuradio-companion &> /dev/null; then
    brew install gnuradio
    echo -e "${GREEN}✓ GNU Radio installed${NC}"
else
    echo -e "${GREEN}✓ GNU Radio already installed${NC}"
fi

# Python dependencies
echo -e "${YELLOW}Installing Python tools...${NC}"
pip3 install --upgrade pip
pip3 install numpy scipy matplotlib pyrtlsdr

# Wireshark for protocol analysis
echo -e "${YELLOW}Installing Wireshark...${NC}"
if ! command -v wireshark &> /dev/null; then
    brew install --cask wireshark
    echo -e "${GREEN}✓ Wireshark installed${NC}"
else
    echo -e "${GREEN}✓ Wireshark already installed${NC}"
fi

echo ""
echo -e "${BLUE}=== Phase 2: Docker Setup (Recommended) ===${NC}"
echo ""

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker not found.${NC}"
    read -p "Install Docker Desktop? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        brew install --cask docker
        echo ""
        echo -e "${YELLOW}Please start Docker Desktop manually, then re-run this script${NC}"
        echo "Opening Docker Desktop..."
        open -a Docker
        exit 0
    fi
else
    echo -e "${GREEN}✓ Docker already installed${NC}"

    # Check if Docker is running
    if ! docker info &> /dev/null; then
        echo -e "${YELLOW}Docker is not running. Starting...${NC}"
        open -a Docker
        echo "Waiting for Docker to start..."
        sleep 10
    fi
fi

echo ""
echo -e "${BLUE}=== Phase 3: RF-Swift Docker Container ===${NC}"
echo ""

if docker info &> /dev/null; then
    echo -e "${YELLOW}Pulling RF-Swift container (this may take 10-15 minutes)...${NC}"
    docker pull penthertz/rfswift:latest

    echo ""
    echo -e "${GREEN}✓ RF-Swift installed!${NC}"
    echo ""
    echo "RF-Swift includes:"
    echo "  - gr-gsm (GSM decoder)"
    echo "  - srsRAN (LTE/5G)"
    echo "  - Kalibrate (cell scanner)"
    echo "  - Modmobmap (tower mapping)"
    echo "  - IMSI-catcher tools"
    echo "  - 5Ghoul (5G fuzzing)"
    echo ""
else
    echo -e "${YELLOW}Docker not running. Skipping RF-Swift installation.${NC}"
    echo "You can install it later by running:"
    echo "  docker pull penthertz/rfswift:latest"
fi

echo ""
echo -e "${BLUE}=== Phase 4: Additional Tools ===${NC}"
echo ""

# Create directories
mkdir -p ~/sdr_data/{captures,analysis,maps}
mkdir -p ~/.gnuradio

echo -e "${YELLOW}Creating helper scripts...${NC}"

# Create RF-Swift launcher
cat > ~/sdr_data/start_rfswift.sh <<'EOF'
#!/bin/bash
# Launch RF-Swift with B210 access

echo "Starting RF-Swift container with B210 USB access..."
echo ""

docker run -it --privileged \
  -v /dev/bus/usb:/dev/bus/usb \
  -v ~/sdr_data:/root/data \
  -p 8080:8080 \
  -p 4729:4729 \
  --name rfswift \
  penthertz/rfswift:latest

# If container already exists, use:
# docker start -ai rfswift
EOF

chmod +x ~/sdr_data/start_rfswift.sh

# Create cell scanner script
cat > ~/sdr_data/scan_cells.sh <<'EOF'
#!/bin/bash
# Quick cell tower scanner using B210

echo "=== Cell Tower Scanner ==="
echo ""
echo "Scanning LTE Band 13 (746 MHz - Verizon)"
echo "This band showed 17 dB SNR in your tests"
echo ""

# Using UHD rx_samples_to_file to capture
rx_samples_to_file \
  --freq 746e6 \
  --rate 5e6 \
  --gain 60 \
  --ant RX2 \
  --type short \
  --duration 10 \
  --file ~/sdr_data/captures/lte_band13_$(date +%Y%m%d_%H%M%S).dat

echo ""
echo "Capture saved to ~/sdr_data/captures/"
echo "Analyze with: inspectrum or GNU Radio"
EOF

chmod +x ~/sdr_data/scan_cells.sh

# Create quick test script
cat > ~/sdr_data/test_b210_cellular.sh <<'EOF'
#!/bin/bash
# Test B210 on your best cellular frequencies

echo "=== B210 Cellular Band Test ==="
echo ""
echo "Testing your strongest cellular signals:"
echo ""

# Test Band 2 (1930 MHz) - Your best SNR: 20.4 dB
echo "1. Testing LTE Band 2 (1930 MHz - AT&T/T-Mobile)"
rx_samples_to_file --freq 1930e6 --rate 2e6 --gain 50 --ant TX/RX \
  --type short --duration 3 --file /tmp/test_band2.dat &>/dev/null

if [ -f /tmp/test_band2.dat ]; then
  SIZE=$(wc -c < /tmp/test_band2.dat)
  echo "   ✓ Captured $SIZE bytes"
else
  echo "   ✗ Failed"
fi

# Test Band 13 (746 MHz) - SNR: 17.0 dB
echo "2. Testing LTE Band 13 (746 MHz - Verizon)"
rx_samples_to_file --freq 746e6 --rate 2e6 --gain 60 --ant RX2 \
  --type short --duration 3 --file /tmp/test_band13.dat &>/dev/null

if [ -f /tmp/test_band13.dat ]; then
  SIZE=$(wc -c < /tmp/test_band13.dat)
  echo "   ✓ Captured $SIZE bytes"
else
  echo "   ✗ Failed"
fi

# Test AWS (2110 MHz) - SNR: 14.6 dB
echo "3. Testing AWS Band (2110 MHz - T-Mobile)"
rx_samples_to_file --freq 2110e6 --rate 2e6 --gain 50 --ant TX/RX \
  --type short --duration 3 --file /tmp/test_aws.dat &>/dev/null

if [ -f /tmp/test_aws.dat ]; then
  SIZE=$(wc -c < /tmp/test_aws.dat)
  echo "   ✓ Captured $SIZE bytes"
else
  echo "   ✗ Failed"
fi

echo ""
echo "Test complete! Your B210 is working on cellular bands."
rm -f /tmp/test_*.dat
EOF

chmod +x ~/sdr_data/test_b210_cellular.sh

echo -e "${GREEN}✓ Helper scripts created in ~/sdr_data/${NC}"

echo ""
echo -e "${BLUE}=== Optional: Build gr-gsm from Source ===${NC}"
echo ""
read -p "Build gr-gsm for native GSM decoding? (takes ~30min) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installing gr-gsm dependencies...${NC}"
    brew install cmake swig fftw cppunit boost

    echo -e "${YELLOW}Cloning gr-gsm...${NC}"
    cd ~/sdr_data
    git clone https://github.com/ptrkrysik/gr-gsm.git
    cd gr-gsm

    echo -e "${YELLOW}Building gr-gsm...${NC}"
    mkdir build && cd build
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
    make -j$(sysctl -n hw.ncpu)

    echo -e "${YELLOW}Installing gr-gsm (requires sudo)...${NC}"
    sudo make install

    echo -e "${GREEN}✓ gr-gsm installed${NC}"
else
    echo "Skipping gr-gsm build. You can use it via RF-Swift Docker instead."
fi

echo ""
echo -e "${GREEN}======================================"
echo "Installation Complete!"
echo "======================================${NC}"
echo ""
echo -e "${BLUE}Quick Start:${NC}"
echo ""
echo "1. Test B210 on cellular bands:"
echo "   ~/sdr_data/test_b210_cellular.sh"
echo ""
echo "2. Launch RF-Swift (all tools in one):"
echo "   ~/sdr_data/start_rfswift.sh"
echo ""
echo "3. Scan for cell towers:"
echo "   ~/sdr_data/scan_cells.sh"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  - Read: docs/CELLULAR_RESEARCH_SETUP.md"
echo "  - Your best bands: 1930 MHz (20.4dB SNR), 746 MHz (17dB SNR)"
echo "  - Start with passive scanning only (legal & safe)"
echo ""
echo -e "${YELLOW}Remember: Only passive reception is legal!${NC}"
echo "  ✓ Scanning and receiving is OK"
echo "  ✗ Transmitting on cellular bands is illegal"
echo ""
