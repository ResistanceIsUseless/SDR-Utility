#!/bin/bash
#
# APRS Reception Script for USRP B210 + Dire Wolf
# Captures APRS frequency and pipes audio to Dire Wolf decoder
#

# Configuration
APRS_FREQ="${1:-144390000}"  # Default: 144.390 MHz (North America)
                             # Europe: use 144800000 (144.800 MHz)
SAMPLE_RATE=250000          # 250 kHz sample rate (good for NBFM)
GAIN=40                     # RF gain (adjust if needed)
AUDIO_RATE=48000            # Audio sample rate for Dire Wolf
UHD_IMAGES_DIR="/usr/share/uhd/4.9.0/images"

# Check if Dire Wolf is installed
if ! command -v direwolf &> /dev/null; then
    echo "ERROR: Dire Wolf is not installed"
    echo "Install with: sudo apt install direwolf"
    exit 1
fi

# Check if required tools are available
if ! command -v sox &> /dev/null; then
    echo "ERROR: sox is not installed (needed for FM demodulation)"
    echo "Install with: sudo apt install sox"
    exit 1
fi

echo "=========================================="
echo "APRS Reception via USRP B210"
echo "=========================================="
echo "Frequency: $(echo "scale=3; $APRS_FREQ/1000000" | bc) MHz"
echo "Sample Rate: $(echo "scale=0; $SAMPLE_RATE/1000" | bc) kHz"
echo "Audio Rate: $(echo "scale=0; $AUDIO_RATE/1000" | bc) kHz"
echo "Gain: $GAIN dB"
echo "=========================================="
echo ""
echo "Starting reception..."
echo "Press Ctrl+C to stop"
echo ""

# Create named pipe for IQ data
FIFO_IQ=$(mktemp -u)
mkfifo "$FIFO_IQ"

# Cleanup on exit
cleanup() {
    echo ""
    echo "Stopping APRS reception..."
    rm -f "$FIFO_IQ"
    pkill -P $$
    exit 0
}
trap cleanup SIGINT SIGTERM

# Method 1: Using GNU Radio (if available)
if command -v gnuradio-companion &> /dev/null; then
    echo "Using GNU Radio for FM demodulation"

    # Start UHD capture to FIFO
    UHD_IMAGES_DIR="$UHD_IMAGES_DIR" uhd_rx_cfile \
        -f "$APRS_FREQ" \
        -r "$SAMPLE_RATE" \
        -g "$GAIN" \
        "$FIFO_IQ" &

    # TODO: Add GNU Radio FM demodulation flowgraph
    echo "ERROR: GNU Radio flowgraph not implemented yet"
    cleanup

# Method 2: Using csdr (if available)
elif command -v csdr &> /dev/null; then
    echo "Using csdr for FM demodulation"

    # Start UHD capture and pipe through csdr to Dire Wolf
    UHD_IMAGES_DIR="$UHD_IMAGES_DIR" uhd_rx_cfile \
        -f "$APRS_FREQ" \
        -r "$SAMPLE_RATE" \
        -g "$GAIN" \
        - 2>/dev/null | \
    csdr convert_u8_f | \
    csdr fmdemod_quadri_cf | \
    csdr limit_ff | \
    csdr convert_f_s16 | \
    direwolf -c /home/static/direwolf.conf -r $AUDIO_RATE -

# Method 3: Using Python (our decode_fm.py)
else
    echo "Using Python FM demodulator"
    echo "WARNING: This method captures to file first (not real-time)"

    # Capture 10 seconds to file
    TEMP_FILE=$(mktemp --suffix=.cfile)
    echo "Capturing 10 seconds of APRS..."

    UHD_IMAGES_DIR="$UHD_IMAGES_DIR" uhd_rx_cfile \
        -f "$APRS_FREQ" \
        -r "$SAMPLE_RATE" \
        -g "$GAIN" \
        -N $((SAMPLE_RATE * 10)) \
        "$TEMP_FILE" 2>/dev/null

    echo "Demodulating and decoding..."

    # Demodulate FM and pipe to Dire Wolf
    python3 /home/static/sdr-utility/scripts/decode_fm.py \
        "$TEMP_FILE" "$SAMPLE_RATE" "$APRS_FREQ" | \
    direwolf -c /home/static/direwolf.conf -r $AUDIO_RATE -

    rm -f "$TEMP_FILE"
fi

cleanup
