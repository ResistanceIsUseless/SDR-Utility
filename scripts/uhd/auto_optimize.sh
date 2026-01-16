#!/bin/bash
# Auto-Optimizer for B210 Clone
# Scans frequencies and finds optimal settings

export PATH="/opt/homebrew/Cellar/uhd/4.9.0.1_1/lib/uhd/examples:$PATH"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

RESULTS_FILE="/tmp/b210_optimization_results.txt"
> "$RESULTS_FILE"

echo "======================================"
echo "B210 Auto-Optimizer & Frequency Scanner"
echo "======================================"
echo ""

# Test frequencies with known traffic
# Format: FREQ|DESCRIPTION
TEST_FREQS=(
    "88.5e6|88.5 MHz FM"
    "93.7e6|93.7 MHz FM (The River)"
    "98.1e6|98.1 MHz FM"
    "100.3e6|100.3 MHz FM"
    "102.7e6|102.7 MHz FM"
    "107.7e6|107.7 MHz FM"
    "746e6|746 MHz (LTE Band 13)"
    "751e6|751 MHz (LTE Band 13)"
    "869e6|869 MHz (Cellular)"
    "894e6|894 MHz (Cellular)"
    "1930e6|1930 MHz (PCS/LTE)"
    "1960e6|1960 MHz (LTE Band 2)"
    "2110e6|2110 MHz (AWS/LTE)"
    "2132.5e6|2132.5 MHz (LTE Band 4)"
    "2437e6|2437 MHz (WiFi Ch 6)"
    "2462e6|2462 MHz (WiFi Ch 11)"
)

echo -e "${CYAN}Scanning Known Frequencies...${NC}"
echo "Testing gain levels and antenna ports"
echo ""

# Test both antennas at multiple gains
ANTENNAS=("RX2" "TX/RX")
GAINS=(40 50 60 70)

BEST_OVERALL_SCORE=0
BEST_CONFIG=""

for ANT in "${ANTENNAS[@]}"; do
    echo -e "${BLUE}Testing Antenna: $ANT${NC}"
    echo ""

    for GAIN in "${GAINS[@]}"; do
        echo -e "${YELLOW}  Gain: $GAIN dB${NC}"

        for FREQ_LINE in "${TEST_FREQS[@]}"; do
            FREQ=$(echo "$FREQ_LINE" | cut -d'|' -f1)
            DESC=$(echo "$FREQ_LINE" | cut -d'|' -f2)

            # Quick 1 second capture (use sc16 format - float32 has bugs on this clone)
            rx_samples_to_file \
                --freq "$FREQ" \
                --rate 2e6 \
                --gain $GAIN \
                --ant "$ANT" \
                --duration 1 \
                --type short \
                --file "/tmp/scan_${FREQ}_${ANT//\//_}_${GAIN}.dat" 2>&1 > /dev/null

            if [ -f "/tmp/scan_${FREQ}_${ANT//\//_}_${GAIN}.dat" ]; then
                RESULT=$(python3 - "$FREQ" "$DESC" "$ANT" "$GAIN" <<'EOF'
import struct
import math
import sys

freq = sys.argv[1]
desc = sys.argv[2]
ant = sys.argv[3]
gain = sys.argv[4]

try:
    filename = f"/tmp/scan_{freq}_{ant.replace('/', '_')}_{gain}.dat"
    with open(filename, 'rb') as f:
        data = f.read()

        # Skip if no data (sc16 uses 4 bytes per sample)
        if len(data) < 4000:
            print(f"{freq}|{desc}|{ant}|{gain}|0.0|-100.0|-100.0|0.0")
            sys.exit(0)

        # Calculate power statistics (sc16 format: 16-bit signed integers)
        powers = []
        valid_samples = 0

        for i in range(0, min(len(data), 400000), 4):
            try:
                # Little-endian signed 16-bit integers
                i_val, q_val = struct.unpack('<hh', data[i:i+4])
                power = i_val * i_val + q_val * q_val

                if power >= 0:
                    powers.append(power)
                    valid_samples += 1
            except:
                pass

        if valid_samples > 100:
            # Sort powers to find percentiles
            sorted_powers = sorted(powers)

            # Noise floor (10th percentile)
            noise_floor = sorted_powers[len(sorted_powers) // 10]

            # Signal peak (95th percentile)
            signal_peak = sorted_powers[int(len(sorted_powers) * 0.95)]

            # Average power
            avg_power = sum(powers) / len(powers)

            # Calculate metrics in dBFS (full scale = 32768 for int16)
            FULL_SCALE_POWER = 32768.0 * 32768.0 * 2  # I^2 + Q^2 at full scale

            if noise_floor > 0 and signal_peak > 0 and avg_power > 0:
                snr_db = 10 * math.log10(signal_peak / noise_floor)
                avg_dbfs = 10 * math.log10(avg_power / FULL_SCALE_POWER)
                peak_dbfs = 10 * math.log10(signal_peak / FULL_SCALE_POWER)

                # Score: prioritize SNR, penalize very weak signals
                score = snr_db + max(0, (avg_dbfs + 70)) * 0.2

                print(f"{freq}|{desc}|{ant}|{gain}|{snr_db:.1f}|{peak_dbfs:.1f}|{avg_dbfs:.1f}|{score:.1f}")
            else:
                print(f"{freq}|{desc}|{ant}|{gain}|0.0|-100.0|-100.0|0.0")
        else:
            print(f"{freq}|{desc}|{ant}|{gain}|0.0|-100.0|-100.0|0.0")

except Exception as e:
    print(f"{freq}|{desc}|{ant}|{gain}|0.0|-100.0|-100.0|0.0")
EOF
)

                echo "$RESULT" >> "$RESULTS_FILE"

                # Parse result
                SNR=$(echo "$RESULT" | cut -d'|' -f5)
                PEAK=$(echo "$RESULT" | cut -d'|' -f6)
                SCORE=$(echo "$RESULT" | cut -d'|' -f8)

                # Show result
                if (( $(echo "$SNR > 10" | bc -l) )); then
                    echo -e "    ${GREEN}✓ $DESC - SNR: $SNR dB, Peak: $PEAK dB${NC}"
                elif (( $(echo "$SNR > 5" | bc -l) )); then
                    echo -e "    ${YELLOW}~ $DESC - SNR: $SNR dB, Peak: $PEAK dB${NC}"
                fi

                # Track best overall
                if (( $(echo "$SCORE > $BEST_OVERALL_SCORE" | bc -l) )); then
                    BEST_OVERALL_SCORE=$SCORE
                    BEST_CONFIG="$FREQ|$DESC|$ANT|$GAIN|$SNR"
                fi
            fi
        done
        echo ""
    done
done

# Analyze results
echo ""
echo "======================================"
echo -e "${CYAN}Analysis Complete${NC}"
echo "======================================"
echo ""

# Show all detected signals (SNR > 5)
echo -e "${GREEN}Signals Detected (SNR > 5 dB):${NC}"
echo ""
grep -v "0.0|0.0|-100.0|0.0" "$RESULTS_FILE" | awk -F'|' '$5 > 5 {print $0}' | sort -t'|' -k8 -rn | while read line; do
    FREQ=$(echo "$line" | cut -d'|' -f1)
    DESC=$(echo "$line" | cut -d'|' -f2)
    ANT=$(echo "$line" | cut -d'|' -f3)
    GAIN=$(echo "$line" | cut -d'|' -f4)
    SNR=$(echo "$line" | cut -d'|' -f5)
    PEAK=$(echo "$line" | cut -d'|' -f6)
    AVG=$(echo "$line" | cut -d'|' -f7)

    FREQ_MHZ=$(python3 -c "print(f'{float('$FREQ')/1e6:.1f}')")
    echo "  $DESC ($FREQ_MHZ MHz)"
    echo "    Antenna: $ANT, Gain: $GAIN dB"
    echo "    SNR: $SNR dB, Peak: $PEAK dB, Avg: $AVG dB"
    echo ""
done

# Show optimal settings
if [ ! -z "$BEST_CONFIG" ]; then
    echo ""
    echo -e "${GREEN}=== OPTIMAL SETTINGS ===${NC}"
    echo ""

    BEST_FREQ=$(echo "$BEST_CONFIG" | cut -d'|' -f1)
    BEST_DESC=$(echo "$BEST_CONFIG" | cut -d'|' -f2)
    BEST_ANT=$(echo "$BEST_CONFIG" | cut -d'|' -f3)
    BEST_GAIN=$(echo "$BEST_CONFIG" | cut -d'|' -f4)
    BEST_SNR=$(echo "$BEST_CONFIG" | cut -d'|' -f5)

    FREQ_MHZ=$(python3 -c "print(f'{float('$BEST_FREQ')/1e6:.1f}')")

    echo "  Best Signal: $BEST_DESC ($FREQ_MHZ MHz)"
    echo "  Antenna: $BEST_ANT"
    echo "  Gain: $BEST_GAIN dB"
    echo "  Sample Rate: 2 MS/s"
    echo "  SNR: $BEST_SNR dB"
    echo ""
    echo -e "${CYAN}Test Command:${NC}"
    echo "  rx_samples_to_file --freq $BEST_FREQ --rate 2e6 --gain $BEST_GAIN --ant \"$BEST_ANT\" --duration 10 --file signal.dat"
    echo ""

    # Save to file
    cat > /tmp/b210_optimal_settings.txt <<EOL
# B210 Optimal Settings - $(date)
FREQUENCY=$BEST_FREQ
FREQUENCY_MHZ=$FREQ_MHZ
FREQUENCY_DESC=$BEST_DESC
ANTENNA=$BEST_ANT
GAIN=$BEST_GAIN
SAMPLE_RATE=2e6
SNR=$BEST_SNR
EOL

    echo "Settings saved to: /tmp/b210_optimal_settings.txt"

else
    echo -e "${RED}No signals detected!${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check antenna is connected to RX2 port"
    echo "  2. Move antenna near window"
    echo "  3. Verify antenna covers frequency range"
    echo "  4. Check RX2 LED turns blue during reception"
fi

echo ""
echo "Detailed results: $RESULTS_FILE"
echo ""
