#!/bin/bash
#
# ISM Band Decoder for USRP B210
# Decodes 433 MHz ISM band devices using rtl_433
#
# Usage: ism_decoder.sh [OPTIONS]
#

# Default parameters
FREQ=${FREQ:-433920000}              # 433.92 MHz (ISM band center)
SAMPLE_RATE=${SAMPLE_RATE:-250000}   # 250 kS/s
GAIN=${GAIN:-40}                     # RX gain in dB
HOP_TIME=${HOP_TIME:-60}             # Frequency hop interval (seconds)
LOG_FILE=${LOG_FILE:-}               # Optional log file
OUTPUT_FORMAT=${OUTPUT_FORMAT:-kv}   # Output format (kv, json, csv)

# Help function
show_help() {
    cat << EOF
ISM Band Decoder - USRP B210 Interface to rtl_433

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -f, --freq HZ        Center frequency in Hz (default: 433920000)
    -r, --rate HZ        Sample rate in Hz (default: 250000)
    -g, --gain DB        RX gain in dB (default: 40)
    -H, --hop SEC        Frequency hop interval (default: 60)
    -F, --format FMT     Output format: kv, json, csv (default: kv)
    -l, --log FILE       Log decoded messages to file
    -h, --help           Show this help

ISM BAND FREQUENCIES:
    433.920 MHz - Europe ISM band (most common)
    315.000 MHz - North America (garage doors, car remotes)
    868.000 MHz - Europe ISM band
    915.000 MHz - North America ISM band

DEVICE TYPES DECODED:
    Weather Stations:
      - Acurite, Ambient Weather, LaCrosse, Oregon Scientific
      - Fine Offset, Nexus, Prologue, Rubicson, etc.

    TPMS (Tire Pressure):
      - Schrader, Toyota, Ford, GM, Hyundai, etc.

    Temperature Sensors:
      - Wireless thermometers, pool sensors

    Remotes & Switches:
      - Garage door openers, doorbells
      - Light switches, power outlets

    Security:
      - Door/window sensors, motion detectors
      - Smoke alarms, water leak sensors

EXAMPLES:
    # Decode 433 MHz ISM devices
    $0 --freq 433920000

    # North American garage doors (315 MHz)
    $0 --freq 315000000

    # JSON output with logging
    $0 --freq 433920000 --format json --log ism_devices.log

    # Multiple frequency hopping
    $0 --freq 433920000 --hop 30

TYPICAL OUTPUT:
    time      : 2026-01-01 08:45:23
    model     : Acurite-Tower
    id        : 12345
    channel   : A
    battery   : OK
    temperature_C : 22.3
    humidity  : 45

    time      : 2026-01-01 08:45:45
    model     : LaCrosse-TX141THBv2
    id        : 234
    temperature_C : 21.1
    humidity  : 52
    battery   : OK

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
        -H|--hop)
            HOP_TIME="$2"
            shift 2
            ;;
        -F|--format)
            OUTPUT_FORMAT="$2"
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

# Banner
echo "========================================"
echo "  ISM Band Decoder - USRP B210"
echo "========================================"
echo ""
echo "Decoder Parameters:"
echo "  Frequency: $(awk "BEGIN {printf \"%.3f MHz\", $FREQ/1000000}")"
echo "  Rate:      $(awk "BEGIN {printf \"%.0f kS/s\", $SAMPLE_RATE/1000}")"
echo "  Gain:      $GAIN dB"
echo "  Format:    $OUTPUT_FORMAT"
[ -n "$LOG_FILE" ] && echo "  Log File:  $LOG_FILE"
echo ""
echo "Listening for ISM devices... (Press Ctrl+C to stop)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Build UHD rx command for USRP
RX_CMD="uhd_rx_cfile -f $FREQ -r $SAMPLE_RATE -g $GAIN --args type=b200 -"

# Build rtl_433 command
RTL433_OPTS="-F $OUTPUT_FORMAT"
[ -n "$LOG_FILE" ] && RTL433_OPTS="$RTL433_OPTS -W \"$LOG_FILE\""

# Run the pipeline
# rtl_433 expects IQ samples in CS16 format via stdin
if [ -n "$LOG_FILE" ]; then
    eval "$RX_CMD | rtl_433 -r - -s $SAMPLE_RATE -f $FREQ -H $HOP_TIME $RTL433_OPTS 2>&1 | tee -a \"$LOG_FILE.txt\""
else
    eval "$RX_CMD | rtl_433 -r - -s $SAMPLE_RATE -f $FREQ -H $HOP_TIME $RTL433_OPTS"
fi
