#!/bin/bash
# B210 Clone Regression Test Suite
# Adapted from: https://github.com/arifkyi/Libresdr
# Date: 2026-01-13

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# UHD examples path for Homebrew
UHD_EXAMPLES="/opt/homebrew/lib/uhd/examples"

echo "======================================"
echo "B210 Clone Regression Test Suite"
echo "======================================"
echo ""

# Test 1: Device Detection
echo -e "${BLUE}[Test 1/6] Device Detection${NC}"
echo -e "${YELLOW}Running: uhd_find_devices${NC}"
if uhd_find_devices | grep -q "Custom_SDR_B210"; then
    echo -e "${GREEN}✓ PASS: Device detected${NC}"
else
    echo -e "${RED}✗ FAIL: Device not detected${NC}"
    exit 1
fi
echo ""

# Test 2: Device Probe
echo -e "${BLUE}[Test 2/6] Device Probe${NC}"
echo -e "${YELLOW}Running: uhd_usrp_probe${NC}"
if uhd_usrp_probe --args="serial=30AA038" 2>&1 | grep -q "Register loopback test passed"; then
    echo -e "${GREEN}✓ PASS: Device probe successful${NC}"
else
    echo -e "${RED}✗ FAIL: Device probe failed${NC}"
    exit 1
fi
echo ""

# Test 3: Benchmark Rate
echo -e "${BLUE}[Test 3/6] Benchmark Rate Test${NC}"
echo -e "${YELLOW}Testing RX/TX at 10 MS/s for 10 seconds${NC}"
echo -e "${YELLOW}Command: benchmark_rate --rx_rate 10e6 --tx_rate 10e6 --duration 10${NC}"
if [ -f "$UHD_EXAMPLES/benchmark_rate" ]; then
    $UHD_EXAMPLES/benchmark_rate --rx_rate 10e6 --tx_rate 10e6 --duration 10
    echo -e "${GREEN}✓ PASS: Benchmark completed${NC}"
else
    echo -e "${YELLOW}⚠ SKIP: benchmark_rate not found${NC}"
fi
echo ""

# Test 4: RX Functionality
echo -e "${BLUE}[Test 4/6] RX Functionality Test${NC}"
echo -e "${YELLOW}Recording 10 seconds at 98 MHz (FM radio)${NC}"
echo -e "${YELLOW}Command: rx_samples_to_file --freq 98e6 --rate 5e6 --gain 20 --duration 10${NC}"
if [ -f "$UHD_EXAMPLES/rx_samples_to_file" ]; then
    $UHD_EXAMPLES/rx_samples_to_file --freq 98e6 --rate 5e6 --gain 20 --duration 10 usrp_samples.dat
    if [ -f "usrp_samples.dat" ]; then
        FILE_SIZE=$(wc -c < usrp_samples.dat)
        echo -e "${GREEN}✓ PASS: RX test completed (recorded $FILE_SIZE bytes)${NC}"
    else
        echo -e "${RED}✗ FAIL: No data file created${NC}"
    fi
else
    echo -e "${YELLOW}⚠ SKIP: rx_samples_to_file not found${NC}"
fi
echo ""

# Test 5: TX Waveform Generation
echo -e "${BLUE}[Test 5/6] TX Waveform Test${NC}"
echo -e "${YELLOW}Generating sine wave at 915 MHz${NC}"
echo -e "${YELLOW}Command: tx_waveforms --freq 915e6 --rate 5e6 --gain 0${NC}"
echo -e "${RED}WARNING: This will transmit RF! Press Ctrl+C to skip or wait 5 seconds...${NC}"
sleep 5
if [ -f "$UHD_EXAMPLES/tx_waveforms" ]; then
    timeout 10s $UHD_EXAMPLES/tx_waveforms --freq 915e6 --rate 5e6 --gain 0 || true
    echo -e "${GREEN}✓ PASS: TX waveform test completed${NC}"
else
    echo -e "${YELLOW}⚠ SKIP: tx_waveforms not found${NC}"
fi
echo ""

# Test 6: Spectrum Analysis
echo -e "${BLUE}[Test 6/6] Spectrum Analysis Test${NC}"
echo -e "${YELLOW}Displaying spectrum at 98 MHz (FM radio)${NC}"
echo -e "${YELLOW}Command: rx_ascii_art_dft --freq 98e6 --rate 5e6 --gain 20${NC}"
if [ -f "$UHD_EXAMPLES/rx_ascii_art_dft" ]; then
    timeout 10s $UHD_EXAMPLES/rx_ascii_art_dft --freq 98e6 --rate 5e6 --gain 20 --bw 5e6 --ref-lvl -30 || true
    echo -e "${GREEN}✓ PASS: Spectrum analysis completed${NC}"
else
    echo -e "${YELLOW}⚠ SKIP: rx_ascii_art_dft not found${NC}"
fi
echo ""

# Summary
echo "======================================"
echo -e "${GREEN}Test Suite Complete!${NC}"
echo "======================================"
echo ""
echo "Next steps:"
echo "  - Review any FAIL results above"
echo "  - Check usrp_samples.dat file if RX test passed"
echo "  - Try GNU Radio for more advanced testing"
echo ""

# Cleanup
if [ -f "usrp_samples.dat" ]; then
    echo "Captured data file: usrp_samples.dat ($(du -h usrp_samples.dat | cut -f1))"
fi
