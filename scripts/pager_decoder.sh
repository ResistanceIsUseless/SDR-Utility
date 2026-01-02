#!/bin/bash
#
# Pager Decoder for USRP B210
# Decodes POCSAG, FLEX, and other paging protocols using multimon-ng
#
# Usage: pager_decoder.sh [OPTIONS]
#

# Default parameters
FREQ=${FREQ:-152007500}              # 152.0075 MHz (common fire/EMS paging)
SAMPLE_RATE=${SAMPLE_RATE:-250000}   # 250 kS/s
GAIN=${GAIN:-40}                     # RX gain in dB
PROTOCOL=${PROTOCOL:-POCSAG512}      # Default to POCSAG 512 baud
LOG_FILE=${LOG_FILE:-}               # Optional log file

# Help function
show_help() {
    cat << EOF
Pager Decoder - USRP B210 Interface to multimon-ng

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -f, --freq HZ        Center frequency in Hz (default: 152007500)
    -r, --rate HZ        Sample rate in Hz (default: 250000)
    -g, --gain DB        RX gain in dB (default: 40)
    -p, --protocol TYPE  Paging protocol (default: POCSAG512)
    -l, --log FILE       Log decoded messages to file
    -h, --help           Show this help

PROTOCOLS:
    POCSAG512    - POCSAG 512 baud (most common)
    POCSAG1200   - POCSAG 1200 baud
    POCSAG2400   - POCSAG 2400 baud
    FLEX         - FLEX paging
    ALL          - Decode all pager types

COMMON FREQUENCIES:
    152.0075 MHz - Fire/EMS paging (very common)
    152.2400 MHz - Hospital paging
    152.8400 MHz - Commercial paging
    157.4500 MHz - Regional paging
    163.2500 MHz - Wide area paging
    453.xxxx MHz - UHF paging
    462.xxxx MHz - UHF paging

EXAMPLES:
    # Decode fire/EMS pages on 152.0075 MHz
    $0 --freq 152007500

    # Decode FLEX paging
    $0 --freq 152007500 --protocol FLEX

    # Decode all pager types with logging
    $0 --freq 152007500 --protocol ALL --log pager.log

    # Scan UHF paging
    $0 --freq 453750000 --protocol POCSAG1200

TYPICAL OUTPUT:
    POCSAG512: Address: 1234567  Function: 0  Alpha: "STATION 5 RESPOND TO 123 MAIN ST"
    POCSAG512: Address: 2345678  Function: 3  Numeric: "555-1234"

EOF
}

# Parse arguments
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
        -p|--protocol)
            PROTOCOL="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
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

# Build protocol list
case "$PROTOCOL" in
    ALL)
        PROTOCOLS="-a POCSAG512 -a POCSAG1200 -a POCSAG2400 -a FLEX"
        ;;
    *)
        PROTOCOLS="-a $PROTOCOL"
        ;;
esac

# Banner
echo "========================================"
echo "  Pager Decoder - USRP B210"
echo "========================================"
echo ""
echo "Decoder Parameters:"
echo "  Frequency: $(awk "BEGIN {printf \"%.4f MHz\", $FREQ/1000000}")"
echo "  Rate:      $(awk "BEGIN {printf \"%.0f kS/s\", $SAMPLE_RATE/1000}")"
echo "  Gain:      $GAIN dB"
echo "  Protocol:  $PROTOCOL"
[ -n "$LOG_FILE" ] && echo "  Log File:  $LOG_FILE"
echo ""
echo "Listening for pages... (Press Ctrl+C to stop)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Build rx_sdr command for USRP
RX_CMD="rx_sdr -d driver=uhd,type=b200 -s $SAMPLE_RATE -f $FREQ -g $GAIN -F CF32 -"

# Build multimon-ng command
if [ -n "$LOG_FILE" ]; then
    # With logging
    MULTIMON_CMD="multimon-ng -t raw -c $PROTOCOLS - 2>&1 | tee -a \"$LOG_FILE\""
else
    # Without logging
    MULTIMON_CMD="multimon-ng -t raw -c $PROTOCOLS -"
fi

# Run the pipeline
eval "$RX_CMD | $MULTIMON_CMD"
