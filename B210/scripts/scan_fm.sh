#!/bin/bash
# FM Band Scanner for B210 Clone
# Scans common FM frequencies and records signal strength

export PATH="/opt/homebrew/lib/uhd/examples:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "======================================"
echo "FM Band Scanner"
echo "======================================"
echo ""

# Common FM stations to test
declare -A FM_STATIONS=(
    ["88.5"]="Local Station"
    ["91.3"]="Local Station"
    ["93.7"]="The River"
    ["95.5"]="Local Station"
    ["98.1"]="Local Station"
    ["100.3"]="Local Station"
    ["102.7"]="Local Station"
    ["105.9"]="Local Station"
    ["107.7"]="Local Station"
)

# Test both antenna ports
ANTENNAS=("TX/RX" "RX2")

for ANT in "${ANTENNAS[@]}"; do
    echo -e "${BLUE}Testing Antenna Port: ${ANT}${NC}"
    echo "------------------------------------"

    for FREQ in "${!FM_STATIONS[@]}"; do
        STATION="${FM_STATIONS[$FREQ]}"
        echo -e "${YELLOW}Scanning ${FREQ} MHz (${STATION}) on ${ANT}...${NC}"

        # Capture samples and check power level
        TEMP_FILE="/tmp/fm_scan_${FREQ}_${ANT}.dat"

        # Run for 2 seconds and capture
        rx_samples_to_file \
            --freq "${FREQ}e6" \
            --rate 2e6 \
            --gain 50 \
            --ant "$ANT" \
            --duration 2 \
            --file "$TEMP_FILE" 2>&1 | grep -E "(Actual|Setting)" | head -3

        if [ -f "$TEMP_FILE" ]; then
            SIZE=$(wc -c < "$TEMP_FILE")
            if [ $SIZE -gt 1000000 ]; then
                echo -e "${GREEN}  ✓ Signal captured: $SIZE bytes${NC}"
            else
                echo -e "${RED}  ✗ Weak/no signal: $SIZE bytes${NC}"
            fi
            rm "$TEMP_FILE"
        fi
        echo ""
    done
    echo ""
done

echo "======================================"
echo "Scan Complete"
echo "======================================"
echo ""
echo "Recommendations:"
echo "1. ANT500 should be connected to TX/RX or RX2 port"
echo "2. Ensure antenna is properly screwed in"
echo "3. Try positioning antenna near window"
echo "4. FM broadcasts may be weak in your area"
echo ""
echo "To test specific frequency with visualization:"
echo "  rx_ascii_art_dft --freq 93.7e6 --rate 2e6 --gain 50 --ant TX/RX"
echo ""
