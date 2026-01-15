#!/bin/bash
# B210 RX Signal Optimization Script
# Tests different settings to maximize signal strength

export PATH="/opt/homebrew/lib/uhd/examples:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "======================================"
echo "B210 RX Signal Optimization"
echo "======================================"
echo ""

# Test frequency (93.7 MHz - The River)
FREQ="93.7e6"
STATION="93.7 MHz (The River)"

echo "Target: $STATION"
echo ""

# Test 1: Antenna Port Selection
echo -e "${BLUE}[Test 1/5] Antenna Port Comparison${NC}"
echo "Testing both antenna ports at gain 50..."
echo ""

for ANT in "TX/RX" "RX2"; do
    echo -e "${YELLOW}Testing port: $ANT${NC}"
    rx_samples_to_file \
        --freq "$FREQ" \
        --rate 2e6 \
        --gain 50 \
        --ant "$ANT" \
        --duration 1 \
        --file "/tmp/test_${ANT//\//_}.dat" 2>&1 | grep -E "Actual"

    if [ -f "/tmp/test_${ANT//\//_}.dat" ]; then
        python3 - <<EOF
import struct
import math

with open("/tmp/test_${ANT//\//_}.dat", 'rb') as f:
    data = f.read()
    samples = len(data) // 8

    # Calculate average power
    total_power = 0
    count = 0
    for i in range(0, min(len(data), 800000), 8):
        i_val, q_val = struct.unpack('ff', data[i:i+8])
        power = i_val * i_val + q_val * q_val
        if not math.isnan(power) and not math.isinf(power):
            total_power += power
            count += 1

    if count > 0:
        avg_power = total_power / count
        power_db = 10 * math.log10(avg_power) if avg_power > 0 else -100
        print(f"  Power: {power_db:.1f} dB")
    else:
        print("  Power: Invalid data")
EOF
    fi
    echo ""
done

# Test 2: Gain Sweep
echo -e "${BLUE}[Test 2/5] Gain Sweep (RX2 port)${NC}"
echo "Testing gains from 0 to 76 dB..."
echo ""

BEST_GAIN=0
BEST_POWER=-200

for GAIN in 0 20 40 50 60 70 76; do
    echo -e "${YELLOW}Gain: $GAIN dB${NC}"
    rx_samples_to_file \
        --freq "$FREQ" \
        --rate 2e6 \
        --gain $GAIN \
        --ant "RX2" \
        --duration 1 \
        --file "/tmp/test_gain_$GAIN.dat" 2>&1 | grep -q "Done"

    if [ -f "/tmp/test_gain_$GAIN.dat" ]; then
        POWER=$(python3 - <<EOF
import struct
import math

with open("/tmp/test_gain_$GAIN.dat", 'rb') as f:
    data = f.read()

    total_power = 0
    count = 0
    for i in range(0, min(len(data), 800000), 8):
        try:
            i_val, q_val = struct.unpack('ff', data[i:i+8])
            power = i_val * i_val + q_val * q_val
            if not math.isnan(power) and not math.isinf(power):
                total_power += power
                count += 1
        except:
            pass

    if count > 0:
        avg_power = total_power / count
        power_db = 10 * math.log10(avg_power) if avg_power > 0 else -100
        print(f"{power_db:.1f}")
    else:
        print("-100.0")
EOF
)
        echo "  Power: $POWER dB"

        # Track best gain
        if (( $(echo "$POWER > $BEST_POWER" | bc -l) )); then
            BEST_POWER=$POWER
            BEST_GAIN=$GAIN
        fi
    fi
    echo ""
done

echo -e "${GREEN}Best gain setting: $BEST_GAIN dB (Power: $BEST_POWER dB)${NC}"
echo ""

# Test 3: Sample Rate Test
echo -e "${BLUE}[Test 3/5] Sample Rate Test${NC}"
echo "Testing different sample rates..."
echo ""

for RATE in "200e3" "1e6" "2e6" "5e6"; do
    echo -e "${YELLOW}Rate: $RATE S/s${NC}"
    rx_samples_to_file \
        --freq "$FREQ" \
        --rate "$RATE" \
        --gain $BEST_GAIN \
        --ant "RX2" \
        --duration 1 \
        --file "/tmp/test_rate_$RATE.dat" 2>&1 | grep -E "Actual.*Rate"
    echo ""
done

# Test 4: Frequency Offset Test
echo -e "${BLUE}[Test 4/5] Frequency Offset Test${NC}"
echo "Testing nearby frequencies for offset calibration..."
echo ""

for OFFSET in "-100e3" "-50e3" "0" "50e3" "100e3"; do
    TEST_FREQ=$(python3 -c "print(int(93.7e6 + $OFFSET))")
    echo -e "${YELLOW}Frequency: $(python3 -c "print($TEST_FREQ/1e6)") MHz${NC}"
    rx_samples_to_file \
        --freq "$TEST_FREQ" \
        --rate 2e6 \
        --gain $BEST_GAIN \
        --ant "RX2" \
        --duration 1 \
        --file "/tmp/test_offset_$OFFSET.dat" 2>&1 > /dev/null

    if [ -f "/tmp/test_offset_$OFFSET.dat" ]; then
        python3 - <<EOF
import struct
import math

with open("/tmp/test_offset_$OFFSET.dat", 'rb') as f:
    data = f.read()

    total_power = 0
    count = 0
    for i in range(0, min(len(data), 400000), 8):
        try:
            i_val, q_val = struct.unpack('ff', data[i:i+8])
            power = i_val * i_val + q_val * q_val
            if not math.isnan(power) and not math.isinf(power):
                total_power += power
                count += 1
        except:
            pass

    if count > 0:
        avg_power = total_power / count
        power_db = 10 * math.log10(avg_power) if avg_power > 0 else -100
        print(f"  Power: {power_db:.1f} dB")
EOF
    fi
    echo ""
done

# Test 5: LED Status Check
echo -e "${BLUE}[Test 5/5] LED Indicator Check${NC}"
echo ""
echo "While receiving, check these LEDs on your B210:"
echo "  - POWER LED (red): Should be ON"
echo "  - STATUS LED (blue): Should be ON"
echo "  - RX2 LED (blue): Should turn BLUE when receiving on RX2"
echo ""
echo "Press Ctrl+C after checking LEDs..."
rx_ascii_art_dft --freq "$FREQ" --rate 2e6 --gain $BEST_GAIN --ant RX2 2>/dev/null || true

echo ""
echo "======================================"
echo "Optimization Results"
echo "======================================"
echo ""
echo -e "${GREEN}Recommended Settings:${NC}"
echo "  Antenna: RX2 (ANT500 connected)"
echo "  Frequency: 93.7 MHz"
echo "  Gain: $BEST_GAIN dB"
echo "  Sample Rate: 2 MS/s"
echo ""
echo "To visualize:"
echo "  rx_ascii_art_dft --freq 93.7e6 --rate 2e6 --gain $BEST_GAIN --ant RX2"
echo ""
echo "Troubleshooting if signal still weak:"
echo "  1. Move antenna near window"
echo "  2. Check antenna connection is tight"
echo "  3. Verify 93.7 MHz is broadcasting in your area"
echo "  4. Try different frequencies (88-108 MHz)"
echo "  5. Check RX2 LED turns blue during reception"
echo ""
