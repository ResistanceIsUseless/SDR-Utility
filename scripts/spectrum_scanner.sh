#!/bin/bash
#####################################################################
# Wideband Spectrum Scanner - USRP B210
#
# Scans entire frequency range supported by B210 (70 MHz - 6 GHz)
# or custom ranges with configurable step size
#####################################################################

# USRP B210 Specifications
MIN_FREQ=70000000      # 70 MHz
MAX_FREQ=6000000000    # 6 GHz
SAMPLE_RATE=20000000   # 20 MS/s (safe for USB 3.0)

# Default scan parameters
START_FREQ=${START_FREQ:-70000000}      # 70 MHz
STOP_FREQ=${STOP_FREQ:-6000000000}      # 6 GHz
STEP_SIZE=${STEP_SIZE:-1000000}         # 1 MHz steps
DWELL_TIME=${DWELL_TIME:-0.1}           # 0.1 seconds per frequency
GAIN=${GAIN:-50}                        # RX gain in dB
ANTENNA=${ANTENNA:-RX2}                 # Antenna port (RX2 or TX/RX)
FFT_SIZE=${FFT_SIZE:-2048}              # FFT size
NUM_PASSES=${NUM_PASSES:-3}             # Number of scan passes (for averaging)
OUTPUT_DIR=${OUTPUT_DIR:-/home/static/spectrum_scans}

# Create output directory
mkdir -p "$OUTPUT_DIR"

# UHD environment
export UHD_IMAGES_DIR=/usr/share/uhd/4.9.0/images

#####################################################################
# Functions
#####################################################################

print_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Wideband spectrum scanner for USRP B210

OPTIONS:
    -s, --start FREQ     Start frequency in Hz (default: 70000000 = 70 MHz)
    -e, --stop FREQ      Stop frequency in Hz (default: 6000000000 = 6 GHz)
    -t, --step SIZE      Step size in Hz (default: 1000000 = 1 MHz)
    -d, --dwell TIME     Dwell time per frequency in seconds (default: 0.1)
    -g, --gain GAIN      RX gain in dB (default: 50)
    -a, --antenna ANT    Antenna port: RX2 or TX/RX (default: RX2)
    -p, --passes NUM     Number of scan passes for averaging (default: 3)
    -o, --output DIR     Output directory (default: ./spectrum_scans)
    -r, --rate RATE      Sample rate in Hz (default: 20000000 = 20 MS/s)
    -h, --help           Show this help

EXAMPLES:
    # Full B210 range (70 MHz - 6 GHz) in 1 MHz steps
    $0

    # FM broadcast band (88-108 MHz) in 100 kHz steps
    $0 -s 88000000 -e 108000000 -t 100000

    # Cell phone bands (700 MHz - 2.7 GHz) in 1 MHz steps
    $0 -s 700000000 -e 2700000000 -t 1000000

    # LTE Band 2 (1930-1990 MHz) in 100 kHz steps - DETAILED
    $0 -s 1930000000 -e 1990000000 -t 100000 -d 0.5

    # Quick scan (10 MHz steps, fast)
    $0 -s 70000000 -e 6000000000 -t 10000000 -d 0.05

    # ISM bands (2.4 GHz + 5.8 GHz)
    $0 -s 2400000000 -e 2500000000 -t 1000000  # 2.4 GHz
    $0 -s 5725000000 -e 5875000000 -t 1000000  # 5.8 GHz

FREQUENCY RANGES OF INTEREST:
    FM Broadcast:      88-108 MHz
    Civilian Air:      108-137 MHz
    VHF Marine:        156-162 MHz
    UHF TV:            470-890 MHz
    GSM 850:           824-894 MHz
    GSM 900:           880-960 MHz
    GPS L1:            1575.42 MHz
    LTE Band 2:        1930-1990 MHz (DL)
    LTE Band 4:        2110-2155 MHz (DL)
    WiFi 2.4 GHz:      2401-2495 MHz
    LTE Band 7:        2620-2690 MHz (DL)
    WiFi 5 GHz:        5150-5850 MHz

OUTPUT:
    - CSV file with power measurements per frequency
    - Waterfall plot (if gnuplot available)
    - Peak detection report
    - Activity heatmap

EOF
}

# Parse command line arguments
parse_args() {
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
            -d|--dwell)
                DWELL_TIME="$2"
                shift 2
                ;;
            -g|--gain)
                GAIN="$2"
                shift 2
                ;;
            -a|--antenna)
                ANTENNA="$2"
                shift 2
                ;;
            -p|--passes)
                NUM_PASSES="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                mkdir -p "$OUTPUT_DIR"
                shift 2
                ;;
            -r|--rate)
                SAMPLE_RATE="$2"
                shift 2
                ;;
            -h|--help)
                print_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                print_help
                exit 1
                ;;
        esac
    done
}

# Format frequency for display
format_freq() {
    local freq=$1
    if (( freq >= 1000000000 )); then
        echo "scale=3; $freq / 1000000000" | bc | sed 's/$/\ GHz/'
    elif (( freq >= 1000000 )); then
        echo "scale=2; $freq / 1000000" | bc | sed 's/$/\ MHz/'
    elif (( freq >= 1000 )); then
        echo "scale=1; $freq / 1000" | bc | sed 's/$/\ kHz/'
    else
        echo "${freq} Hz"
    fi
}

# Calculate scan parameters
calculate_scan_params() {
    local num_steps=$(( (STOP_FREQ - START_FREQ) / STEP_SIZE + 1 ))
    local total_time=$(echo "$num_steps * $DWELL_TIME" | bc)
    local total_time_min=$(echo "scale=1; $total_time / 60" | bc)

    echo "Scan Parameters:"
    echo "  Start: $(format_freq $START_FREQ)"
    echo "  Stop:  $(format_freq $STOP_FREQ)"
    echo "  Step:  $(format_freq $STEP_SIZE)"
    echo "  Dwell: ${DWELL_TIME}s per step"
    echo "  Gain:  ${GAIN} dB"
    echo "  Rate:  $(format_freq $SAMPLE_RATE)"
    echo ""
    echo "  Steps: $num_steps"
    echo "  Time:  ${total_time_min} minutes"
    echo ""
}

# Scan using rx_power
scan_rx_power() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$OUTPUT_DIR/scan_${timestamp}.csv"
    local log_file="$OUTPUT_DIR/scan_${timestamp}.log"

    echo "Starting scan at $(date)"
    echo "Output: $output_file"
    echo ""

    # CSV header
    echo "frequency_hz,power_db,timestamp" > "$output_file"

    local freq=$START_FREQ
    local count=0
    local total_steps=$(( (STOP_FREQ - START_FREQ) / STEP_SIZE + 1 ))

    while (( freq <= STOP_FREQ )); do
        count=$((count + 1))
        local progress=$(echo "scale=1; $count * 100 / $total_steps" | bc)

        # Measure power at this frequency
        local power=$(timeout 5 uhd_power_spectrum_single_freq \
            --freq "$freq" \
            --rate "$SAMPLE_RATE" \
            --gain "$GAIN" \
            --duration "$DWELL_TIME" 2>&1 | \
            grep -oP 'Power:\s*\K[-\d.]+' | head -1)

        # If uhd_power_spectrum_single_freq doesn't exist, use rx_power
        if [ -z "$power" ]; then
            power=$(timeout 5 rx_power \
                --freq "$freq" \
                --rate "$SAMPLE_RATE" \
                --gain "$GAIN" 2>&1 | \
                grep -oP '[-\d.]+\s*dB' | head -1 | grep -oP '[-\d.]+')
        fi

        # If still no power reading, use rxpy_power or skip
        if [ -z "$power" ]; then
            power="-999"  # Marker for no data
        fi

        local ts=$(date -Iseconds)
        echo "$freq,$power,$ts" >> "$output_file"

        # Progress display
        printf "\r[%3d%%] %s: %s dB     " "$progress" "$(format_freq $freq)" "$power"

        freq=$((freq + STEP_SIZE))
    done

    echo ""
    echo ""
    echo "Scan complete!"
    echo "Results: $output_file"

    # Generate report
    generate_report "$output_file"
}

# Alternative: Scan using uhd_fft (faster but less accurate)
scan_uhd_fft() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$OUTPUT_DIR/scan_${timestamp}.csv"

    echo "Starting FFT sweep scan..."
    echo "Output: $output_file"

    # This requires a custom python script that uses UHD to sweep
    # For now, we'll use the rx_power method
    scan_rx_power
}

# Generate analysis report
generate_report() {
    local csv_file=$1
    local report_file="${csv_file%.csv}_report.txt"
    local peaks_file="${csv_file%.csv}_peaks.csv"

    echo "Generating report..."

    # Find peak signals (power > -60 dBm)
    # Handle both old format (power_db) and new format (power_db_avg)
    awk -F',' 'NR>1 && $2 > -60 && $2 != -999 {print $1 "," $2}' "$csv_file" | \
        sort -t',' -k2 -rn > "$peaks_file"

    local num_peaks=$(wc -l < "$peaks_file")

    # Generate text report
    cat > "$report_file" << EOF
Spectrum Scan Report
Generated: $(date)
================================================================================

SCAN PARAMETERS:
  Frequency Range: $(format_freq $START_FREQ) - $(format_freq $STOP_FREQ)
  Step Size:       $(format_freq $STEP_SIZE)
  Dwell Time:      ${DWELL_TIME}s
  RX Gain:         ${GAIN} dB

RESULTS:
  Data File:       $csv_file
  Peaks Detected:  $num_peaks (power > -60 dBm)

TOP 20 STRONGEST SIGNALS:
================================================================================
  Frequency          Power (dBm)    Band/Service (estimated)
--------------------------------------------------------------------------------
EOF

    # Add top 20 peaks with band identification
    head -20 "$peaks_file" | while IFS=',' read freq power; do
        local freq_mhz=$(echo "scale=3; $freq / 1000000" | bc)
        local band=$(identify_band $freq)
        printf "  %-18s %-14s %s\n" "$(format_freq $freq)" "$power" "$band" >> "$report_file"
    done

    echo "" >> "$report_file"
    echo "Full peak list: $peaks_file" >> "$report_file"

    # Display report
    cat "$report_file"

    # Generate plot if gnuplot available
    if command -v gnuplot &> /dev/null; then
        generate_plot "$csv_file"
    fi
}

# Identify band/service from frequency
identify_band() {
    local freq=$1
    local freq_mhz=$(echo "scale=0; $freq / 1000000" | bc)

    if (( freq_mhz >= 88 && freq_mhz <= 108 )); then
        echo "FM Broadcast"
    elif (( freq_mhz >= 108 && freq_mhz <= 137 )); then
        echo "Civilian Aviation"
    elif (( freq_mhz >= 156 && freq_mhz <= 162 )); then
        echo "VHF Marine"
    elif (( freq_mhz >= 470 && freq_mhz <= 890 )); then
        echo "UHF TV"
    elif (( freq_mhz >= 698 && freq_mhz <= 806 )); then
        echo "LTE Band 12/13/14/17"
    elif (( freq_mhz >= 824 && freq_mhz <= 894 )); then
        echo "GSM 850 / LTE Band 5"
    elif (( freq_mhz >= 880 && freq_mhz <= 960 )); then
        echo "GSM 900"
    elif (( freq_mhz >= 1575 && freq_mhz <= 1576 )); then
        echo "GPS L1"
    elif (( freq_mhz >= 1710 && freq_mhz <= 1880 )); then
        echo "LTE Band 3/4/66 (partial)"
    elif (( freq_mhz >= 1930 && freq_mhz <= 1990 )); then
        echo "LTE Band 2 (PCS)"
    elif (( freq_mhz >= 2110 && freq_mhz <= 2200 )); then
        echo "LTE Band 4/66 (AWS)"
    elif (( freq_mhz >= 2400 && freq_mhz <= 2500 )); then
        echo "WiFi 2.4 GHz / Bluetooth"
    elif (( freq_mhz >= 2620 && freq_mhz <= 2690 )); then
        echo "LTE Band 7"
    elif (( freq_mhz >= 5150 && freq_mhz <= 5850 )); then
        echo "WiFi 5 GHz"
    else
        echo "Unknown/Other"
    fi
}

# Generate gnuplot visualization
generate_plot() {
    local csv_file=$1
    local plot_file="${csv_file%.csv}_plot.png"

    echo "Generating plot: $plot_file"

    gnuplot << EOF
set terminal png size 1920,1080
set output '$plot_file'
set title 'Spectrum Scan: $(format_freq $START_FREQ) - $(format_freq $STOP_FREQ)'
set xlabel 'Frequency (MHz)'
set ylabel 'Power (dBm)'
set grid
set datafile separator ","
set key off

# Filter out -999 (no data) values
plot '$csv_file' using (\$1/1e6):(\$2 == -999 ? 1/0 : \$2) with lines lw 2 lc rgb "blue"
EOF

    echo "Plot saved: $plot_file"
}

#####################################################################
# Python-based Fast Scanner (if UHD Python available)
#####################################################################

create_python_scanner() {
    cat > "$OUTPUT_DIR/fast_scanner.py" << 'PYEOF'
#!/usr/bin/env python3
"""
Fast wideband scanner using UHD Python API
Much faster than calling uhd tools repeatedly
"""
import uhd
import numpy as np
import sys
import time
import csv
from datetime import datetime

def scan_spectrum(start_freq, stop_freq, step_size, sample_rate, gain, antenna, dwell_time, num_passes, output_file):
    """Scan spectrum and save results with multiple passes for averaging"""

    # Initialize USRP
    usrp = uhd.usrp.MultiUSRP("type=b200")
    usrp.set_rx_rate(sample_rate)
    usrp.set_rx_gain(gain)
    usrp.set_rx_antenna(antenna)  # Antenna port configurable via -a option
    usrp.set_rx_bandwidth(sample_rate)

    # Stream args
    st_args = uhd.usrp.StreamArgs("fc32", "sc16")
    rx_streamer = usrp.get_rx_stream(st_args)

    # Calculate number of samples
    num_samps = int(dwell_time * sample_rate)
    recv_buffer = np.zeros(num_samps, dtype=np.complex64)

    # Dictionary to store accumulated power measurements for averaging
    power_accumulator = {}

    # Perform multiple passes
    for pass_num in range(num_passes):
        print(f"\n=== Pass {pass_num + 1}/{num_passes} ===")

        freq = start_freq
        total_steps = int((stop_freq - start_freq) / step_size) + 1
        step_count = 0

        while freq <= stop_freq:
            step_count += 1
            progress = (step_count / total_steps) * 100

            # Tune to frequency
            usrp.set_rx_freq(uhd.libpyuhd.types.tune_request(freq))
            time.sleep(0.01)  # Allow tuning to settle

            # Start streaming
            stream_cmd = uhd.types.StreamCMD(uhd.types.StreamMode.num_done)
            stream_cmd.num_samps = num_samps
            stream_cmd.stream_now = True
            rx_streamer.issue_stream_cmd(stream_cmd)

            # Receive samples
            metadata = uhd.types.RXMetadata()
            rx_streamer.recv(recv_buffer, metadata)

            # Calculate power (dBFS then convert to dBm estimate)
            power_linear = np.mean(np.abs(recv_buffer)**2)
            if power_linear > 0:
                power_dbfs = 10 * np.log10(power_linear)
                # Rough conversion to dBm (calibrate for your setup)
                power_dbm = power_dbfs - 20  # Approximate
            else:
                power_dbm = -999

            # Accumulate power for averaging
            if freq not in power_accumulator:
                power_accumulator[freq] = []
            power_accumulator[freq].append(power_dbm)

            # Progress
            print(f"\r[{progress:3.0f}%] {freq/1e6:.3f} MHz: {power_dbm:.1f} dBm     ", end='')
            sys.stdout.flush()

            freq += step_size

    # Calculate averages and write to CSV
    print("\n\nAveraging results across passes...")
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['frequency_hz', 'power_db_avg', 'power_db_min', 'power_db_max', 'power_db_std', 'num_passes'])

        for freq in sorted(power_accumulator.keys()):
            powers = [p for p in power_accumulator[freq] if p != -999]
            if powers:
                avg_power = np.mean(powers)
                min_power = np.min(powers)
                max_power = np.max(powers)
                std_power = np.std(powers)
                writer.writerow([freq, f"{avg_power:.2f}", f"{min_power:.2f}",
                               f"{max_power:.2f}", f"{std_power:.2f}", len(powers)])
            else:
                writer.writerow([freq, "-999", "-999", "-999", "0", "0"])

    print("Scan complete!")

if __name__ == "__main__":
    if len(sys.argv) != 10:
        print("Usage: fast_scanner.py START STOP STEP RATE GAIN ANTENNA DWELL PASSES OUTPUT")
        sys.exit(1)

    scan_spectrum(
        int(sys.argv[1]),    # start_freq
        int(sys.argv[2]),    # stop_freq
        int(sys.argv[3]),    # step_size
        float(sys.argv[4]),  # sample_rate
        float(sys.argv[5]),  # gain
        sys.argv[6],         # antenna
        float(sys.argv[7]),  # dwell_time
        int(sys.argv[8]),    # num_passes
        sys.argv[9]          # output_file
    )
PYEOF

    chmod +x "$OUTPUT_DIR/fast_scanner.py"
}

#####################################################################
# Main
#####################################################################

main() {
    parse_args "$@"

    echo "========================================"
    echo "  Wideband Spectrum Scanner - USRP B210"
    echo "========================================"
    echo ""

    calculate_scan_params

    # Check for Python scanner
    if [ -f "$OUTPUT_DIR/fast_scanner.py" ] && python3 -c "import uhd" 2>/dev/null; then
        echo "Using fast Python scanner..."
        timestamp=$(date +%Y%m%d_%H%M%S)
        output_file="$OUTPUT_DIR/scan_${timestamp}.csv"

        python3 "$OUTPUT_DIR/fast_scanner.py" \
            "$START_FREQ" "$STOP_FREQ" "$STEP_SIZE" \
            "$SAMPLE_RATE" "$GAIN" "$ANTENNA" \
            "$DWELL_TIME" "$NUM_PASSES" \
            "$output_file"

        generate_report "$output_file"
    else
        # Create Python scanner for future use
        create_python_scanner

        # Fall back to bash method
        echo "Python UHD not available, using slower method..."
        echo "Install python3-uhd for faster scanning"
        echo ""
        scan_rx_power
    fi
}

# Run
main "$@"
