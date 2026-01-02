#!/bin/bash
#
# Signal Hunter - Auto-detect and decode signals
# Scans spectrum, identifies strong signals, and attempts to decode them
#
# Usage: signal_hunter.sh [OPTIONS]
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECTRUM_SCANNER="$SCRIPT_DIR/spectrum_scanner.sh"
P25_DECODER="$SCRIPT_DIR/p25_decoder.sh"
PAGER_DECODER="$SCRIPT_DIR/pager_decoder.sh"
ISM_DECODER="$SCRIPT_DIR/ism_decoder.sh"
OUTPUT_DIR="/home/static/spectrum_scans"

# Default parameters
START_FREQ=${START_FREQ:-851000000}      # 851 MHz (P25 band start)
STOP_FREQ=${STOP_FREQ:-869000000}        # 869 MHz (P25 band end)
STEP_SIZE=${STEP_SIZE:-25000}            # 25 kHz steps (P25 channel spacing)
THRESHOLD=${THRESHOLD:--60}              # Power threshold in dBm
DWELL_TIME=${DWELL_TIME:-0.2}            # Longer dwell for digital signals
NUM_PASSES=${NUM_PASSES:-5}              # More passes to catch intermittent transmissions
MODE=${MODE:-p25}                        # Decoder mode (p25, dmr, nxdn, auto)

# Help function
show_help() {
    cat << EOF
Signal Hunter - Auto-detect and decode digital radio signals

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -s, --start HZ       Start frequency in Hz (default: 851000000)
    -e, --stop HZ        Stop frequency in Hz (default: 869000000)
    -t, --step HZ        Step size in Hz (default: 25000)
    -T, --threshold DB   Power threshold in dBm (default: -60)
    -d, --dwell SEC      Dwell time per frequency (default: 0.2)
    -p, --passes NUM     Number of scan passes (default: 5)
    -m, --mode MODE      Decoder mode: p25, pager, ism, dmr, nxdn, auto (default: p25)
    -o, --output DIR     Output directory (default: ./spectrum_scans)
    -h, --help           Show this help

MODES:
    p25      - Decode as P25 Phase 1/2
    pager    - Decode POCSAG/FLEX pagers
    ism      - Decode 433 MHz ISM devices (weather, TPMS, sensors)
    dmr      - Decode as DMR
    nxdn     - Decode as NXDN
    auto     - Auto-detect modulation (future)

EXAMPLES:
    # Hunt for P25 signals in 800 MHz band
    $0 --start 851000000 --stop 869000000

    # Hunt for VHF public safety (P25)
    $0 --start 162000000 --stop 174000000 --mode p25

    # Hunt for pagers on VHF
    $0 --start 152000000 --stop 154000000 --mode pager --step 12500

    # Find ISM devices on 433 MHz
    $0 --start 433800000 --stop 434100000 --mode ism --step 50000

    # Fast scan with lower threshold
    $0 --passes 3 --threshold -55 --step 12500

WORKFLOW:
    1. Scans specified frequency range with multi-pass averaging
    2. Identifies signals above threshold
    3. Ranks by signal strength (strongest first)
    4. Attempts to decode each signal
    5. User can skip to next frequency with Ctrl+C

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--start)
            START_FREQ="$2"
            shift 2
            ;;
        -e|--stop)
            STOP_FREQ="$2"
            shift 2
            ;;
        -t|--step)
            STEP_SIZE="$2"
            shift 2
            ;;
        -T|--threshold)
            THRESHOLD="$2"
            shift 2
            ;;
        -d|--dwell)
            DWELL_TIME="$2"
            shift 2
            ;;
        -p|--passes)
            NUM_PASSES="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate decoder mode
case "$MODE" in
    p25|pager|ism|dmr|nxdn|auto)
        ;;
    *)
        echo "ERROR: Invalid mode '$MODE'"
        echo "Valid modes: p25, pager, ism, dmr, nxdn, auto"
        exit 1
        ;;
esac

# Banner
cat << EOF
========================================
  Signal Hunter - Auto-detect & Decode
========================================

Scan Parameters:
  Range:     $(awk "BEGIN {printf \"%.3f - %.3f MHz\", $START_FREQ/1000000, $STOP_FREQ/1000000}")
  Step:      $(awk "BEGIN {printf \"%.2f kHz\", $STEP_SIZE/1000}")
  Threshold: ${THRESHOLD} dBm
  Passes:    $NUM_PASSES
  Mode:      $MODE

EOF

# Step 1: Scan the spectrum
echo "=== STEP 1: Scanning Spectrum ==="
echo ""

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCAN_CSV="$OUTPUT_DIR/hunter_${TIMESTAMP}.csv"

"$SPECTRUM_SCANNER" \
    --start "$START_FREQ" \
    --stop "$STOP_FREQ" \
    --step "$STEP_SIZE" \
    --dwell "$DWELL_TIME" \
    --passes "$NUM_PASSES" \
    --output "$OUTPUT_DIR" > /dev/null

# Get the most recent scan file
SCAN_CSV=$(ls -t "$OUTPUT_DIR"/scan_*.csv 2>/dev/null | head -1)

if [ ! -f "$SCAN_CSV" ]; then
    echo "ERROR: Scan failed, no CSV file generated"
    exit 1
fi

echo "Scan complete: $SCAN_CSV"
echo ""

# Step 2: Find signals above threshold
echo "=== STEP 2: Analyzing Results ==="
echo ""

# Extract frequencies above threshold (skip header, use avg power column)
SIGNALS=$(awk -F',' -v threshold="$THRESHOLD" \
    'NR>1 && $2 > threshold && $2 != -999 {print $1 "," $2}' "$SCAN_CSV" | \
    sort -t',' -k2 -rn)

NUM_SIGNALS=$(echo "$SIGNALS" | wc -l)

if [ -z "$SIGNALS" ] || [ "$NUM_SIGNALS" -eq 0 ]; then
    echo "No signals found above $THRESHOLD dBm"
    exit 0
fi

echo "Found $NUM_SIGNALS signal(s) above $THRESHOLD dBm:"
echo ""
echo "  Frequency          Power      Std Dev"
echo "  ----------------   --------   --------"

# Read original CSV to get std dev too
while IFS=',' read -r freq power_avg power_min power_max power_std num_passes; do
    if [ "$power_avg" != "power_db_avg" ] && \
       [ "$power_avg" != "-999" ] && \
       awk "BEGIN {exit !($power_avg > $THRESHOLD)}"; then
        freq_mhz=$(awk "BEGIN {printf \"%.6f MHz\", $freq/1000000}")
        printf "  %-18s %-10s %-8s\n" "$freq_mhz" "${power_avg} dBm" "${power_std} dB"
    fi
done < "$SCAN_CSV"

echo ""

# Step 3: Decode each signal
echo "=== STEP 3: Attempting Decode ==="
echo ""

signal_num=1
echo "$SIGNALS" | while IFS=',' read -r freq power; do
    freq_mhz=$(awk "BEGIN {printf \"%.6f\", $freq/1000000}")

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Signal $signal_num/$NUM_SIGNALS: $freq_mhz MHz ($power dBm)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    case "$MODE" in
        p25)
            echo "Starting P25 decoder..."
            echo "(Press Ctrl+C to skip to next frequency)"
            echo ""
            "$P25_DECODER" --freq "$freq" --gain 50 || true
            ;;
        pager)
            echo "Starting POCSAG/FLEX pager decoder..."
            echo "(Press Ctrl+C to skip to next frequency)"
            echo ""
            "$PAGER_DECODER" --freq "$freq" --gain 40 --protocol ALL || true
            ;;
        ism)
            echo "Starting ISM device decoder..."
            echo "(Press Ctrl+C to skip to next frequency)"
            echo ""
            "$ISM_DECODER" --freq "$freq" --gain 40 || true
            ;;
        dmr)
            echo "DMR decoding not yet implemented"
            echo "Install dsdcc and create DMR decoder wrapper"
            ;;
        nxdn)
            echo "NXDN decoding not yet implemented"
            echo "Install dsdcc and create NXDN decoder wrapper"
            ;;
        auto)
            echo "Auto-detection not yet implemented"
            echo "Defaulting to P25..."
            "$P25_DECODER" --freq "$freq" --gain 50 || true
            ;;
    esac

    echo ""
    signal_num=$((signal_num + 1))
done

echo "Signal hunting complete!"
