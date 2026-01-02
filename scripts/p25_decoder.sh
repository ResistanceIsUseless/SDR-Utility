#!/bin/bash
#
# P25 Decoder for USRP B210
# Decodes P25 Phase 1/2 signals using OP25
#
# Usage: p25_decoder.sh [OPTIONS]
#

# Default parameters
FREQ=${FREQ:-851000000}              # Default frequency (851 MHz - P25 band)
SAMPLE_RATE=${SAMPLE_RATE:-1000000}  # 1 MS/s
GAIN=${GAIN:-50}                     # RX gain in dB
OFFSET=${OFFSET:-0}                  # Frequency offset in Hz
PPM=${PPM:-0}                        # Clock correction in PPM
SQUELCH=${SQUELCH:-50}               # Squelch level
AUDIO_OUT=${AUDIO_OUT:-default}      # Audio output device
NAC=${NAC:-0x000}                    # Network Access Code (0x000 = any)
OP25_DIR="/home/static/op25/op25/gr-op25_repeater/apps"

# Help function
show_help() {
    cat << EOF
P25 Decoder - USRP B210 Interface to OP25

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -f, --freq HZ        Center frequency in Hz (default: 851000000)
    -r, --rate HZ        Sample rate in Hz (default: 1000000)
    -g, --gain DB        RX gain in dB (default: 50)
    -o, --offset HZ      Frequency offset in Hz (default: 0)
    -p, --ppm PPM        Clock correction PPM (default: 0)
    -s, --squelch NUM    Squelch level (default: 50)
    -n, --nac HEX        Network Access Code in hex (default: 0x000)
    -a, --audio DEV      Audio output device (default: default)
    -t, --trunking       Enable trunking mode
    -v, --verbose        Verbose output
    -h, --help           Show this help

EXAMPLES:
    # Decode P25 on 851 MHz
    $0 --freq 851000000

    # Decode with high gain and custom NAC
    $0 --freq 851000000 --gain 60 --nac 0x293

    # Trunking mode
    $0 --freq 851000000 --trunking

BANDS:
    700 MHz:  763-775 MHz, 793-805 MHz (Public Safety)
    800 MHz:  851-869 MHz (Public Safety - most common)
    VHF:      162-174 MHz (Fire/EMS)

EOF
}

# Parse arguments
TRUNKING=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--freq)
            FREQ="$2"
            shift 2
            ;;
        -r|--rate)
            SAMPLE_RATE="$2"
            shift 2
            ;;
        -g|--gain)
            GAIN="$2"
            shift 2
            ;;
        -o|--offset)
            OFFSET="$2"
            shift 2
            ;;
        -p|--ppm)
            PPM="$2"
            shift 2
            ;;
        -s|--squelch)
            SQUELCH="$2"
            shift 2
            ;;
        -n|--nac)
            NAC="$2"
            shift 2
            ;;
        -a|--audio)
            AUDIO_OUT="$2"
            shift 2
            ;;
        -t|--trunking)
            TRUNKING=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
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

# Banner
echo "========================================"
echo "  P25 Decoder - USRP B210"
echo "========================================"
echo ""
echo "Decoder Parameters:"
echo "  Frequency: $(awk "BEGIN {printf \"%.3f MHz\", $FREQ/1000000}")"
echo "  Rate:      $(awk "BEGIN {printf \"%.2f MS/s\", $SAMPLE_RATE/1000000}")"
echo "  Gain:      $GAIN dB"
echo "  Squelch:   $SQUELCH"
echo "  NAC:       $NAC"
echo "  Mode:      $([ "$TRUNKING" = true ] && echo "Trunking" || echo "Conventional")"
echo ""

# Check if OP25 is installed
if [ ! -d "$OP25_DIR" ]; then
    echo "ERROR: OP25 not found at $OP25_DIR"
    echo "Please install OP25 first"
    exit 1
fi

# Build OP25 command
cd "$OP25_DIR" || exit 1

if [ "$TRUNKING" = true ]; then
    echo "Starting OP25 in trunking mode..."
    exec ./multi_rx.py \
        --args "type=b200" \
        --freq "$FREQ" \
        --gain "$GAIN" \
        --offset "$OFFSET" \
        --sample-rate "$SAMPLE_RATE" \
        --ppm "$PPM" \
        --squelch "$SQUELCH" \
        --nac "$NAC" \
        $([ "$VERBOSE" = true ] && echo "--verbose 10")
else
    echo "Starting OP25 in conventional mode..."
    echo "Press Ctrl+C to stop"
    echo ""
    exec ./rx.py \
        --args "type=b200" \
        --freq "$FREQ" \
        --gains "$GAIN" \
        --offset "$OFFSET" \
        --sample-rate "$SAMPLE_RATE" \
        --ppm "$PPM" \
        --fine-tune 0 \
        --squelch "$SQUELCH" \
        --nac "$NAC" \
        $([ "$VERBOSE" = true ] && echo "-v 10") \
        -V \
        -2
fi
