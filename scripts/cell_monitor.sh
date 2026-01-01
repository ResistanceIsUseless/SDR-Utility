#!/bin/bash
#####################################################################
# LTE Cell Monitor - Rogue Base Station Detection
#
# Purpose: Continuously monitor LTE spectrum for IMSI catchers
# and suspicious cell tower behavior
#####################################################################

# Configuration
SCAN_INTERVAL=900  # 15 minutes
BANDS="2 4 12 66"   # LTE bands to monitor
LOG_DIR="/home/static/cell_monitoring"
DB_FILE="/home/static/cell_database.json"
ALERT_LOG="$LOG_DIR/alerts.log"
SCAN_LOG="$LOG_DIR/scans.log"

# Create log directory
mkdir -p "$LOG_DIR"

# USRP configuration
export UHD_IMAGES_DIR=/usr/share/uhd/4.9.0/images

echo "==================================="
echo "LTE Cell Monitor Starting"
echo "Scan Interval: $SCAN_INTERVAL seconds"
echo "Bands: $BANDS"
echo "==================================="

# Function to scan a band
scan_band() {
    local band=$1
    local timestamp=$(date -Iseconds)
    local scan_file="$LOG_DIR/band${band}_${timestamp}.log"

    echo "[$timestamp] Scanning Band $band..." | tee -a "$SCAN_LOG"

    timeout 600 ./srsRAN_4G/build/lib/examples/cell_search -b "$band" > "$scan_file" 2>&1

    # Parse results and check for anomalies
    check_anomalies "$scan_file" "$band"
}

# Function to check for suspicious patterns
check_anomalies() {
    local scan_file=$1
    local band=$2
    local timestamp=$(date -Iseconds)

    # Extract all detected cells
    grep "Found CELL" "$scan_file" | while read -r line; do
        # Parse cell parameters
        cell_id=$(echo "$line" | grep -oP 'Id:\s*\K\d+')
        freq=$(echo "$line" | grep -oP 'Freq:\s*\K[\d.]+')
        pci=$(echo "$line" | grep -oP 'cell\s+\K\d+')
        prb=$(echo "$line" | grep -oP 'PRB:\s*\K\d+')
        ports=$(echo "$line" | grep -oP 'ports:\s*\K\d+')
        power=$(echo "$line" | grep -oP 'Power:\s*\K[-\d.]+')

        # Check if this is a known cell
        if grep -q "\"pci\": $pci" "$DB_FILE" 2>/dev/null; then
            echo "[$timestamp] Known cell: PCI=$pci, Freq=$freq MHz" >> "$SCAN_LOG"
        else
            # ALERT: Unknown cell detected!
            echo "[$timestamp] ** ALERT ** New cell detected!" | tee -a "$ALERT_LOG"
            echo "  PCI: $pci" | tee -a "$ALERT_LOG"
            echo "  Frequency: $freq MHz" | tee -a "$ALERT_LOG"
            echo "  PRB: $prb" | tee -a "$ALERT_LOG"
            echo "  Power: $power dBm" | tee -a "$ALERT_LOG"
            echo "  Band: $band" | tee -a "$ALERT_LOG"
            echo "  Scan file: $scan_file" | tee -a "$ALERT_LOG"
            echo "" | tee -a "$ALERT_LOG"

            # Send system notification (if desktop environment available)
            if command -v notify-send &> /dev/null; then
                notify-send "IMSI Catcher Alert" "New LTE cell detected: PCI=$pci @ $freq MHz"
            fi
        fi
    done

    # Check for power anomalies
    detect_power_anomalies "$scan_file"
}

# Function to detect unusual power levels
detect_power_anomalies() {
    local scan_file=$1
    local timestamp=$(date -Iseconds)

    # Look for cells with unusually high power (potential IMSI catcher)
    grep "Found CELL" "$scan_file" | while read -r line; do
        power=$(echo "$line" | grep -oP 'Power:\s*\K[-\d.]+')
        pci=$(echo "$line" | grep -oP 'cell\s+\K\d+')

        # Check if power is abnormally high (> -20 dBm is very suspicious)
        if [ -n "$power" ] && (( $(echo "$power > -20" | bc -l) )); then
            echo "[$timestamp] ** ALERT ** Abnormally high power detected!" | tee -a "$ALERT_LOG"
            echo "  PCI: $pci, Power: $power dBm" | tee -a "$ALERT_LOG"
            echo "  This could indicate a nearby IMSI catcher!" | tee -a "$ALERT_LOG"
            echo "" | tee -a "$ALERT_LOG"
        fi
    done
}

# Function to check a specific cell in detail
inspect_cell() {
    local freq=$1
    local pci=$2
    local prb=$3
    local ports=$4
    local timestamp=$(date -Iseconds)
    local detail_log="$LOG_DIR/cell_${pci}_${timestamp}.log"

    echo "[$timestamp] Detailed inspection of PCI=$pci..." | tee -a "$SCAN_LOG"

    # Try to decode MIB/SIB
    timeout 120 ./srsRAN_4G/build/lib/examples/pdsch_ue \
        -f "${freq}000000" \
        -c "$pci" \
        -p "$prb" \
        -P "$ports" \
        -n 100 \
        -r 0xFFFF > "$detail_log" 2>&1

    # Check for successful MIB decode
    if grep -q "MIB decoded" "$detail_log"; then
        echo "[$timestamp] MIB decode successful for PCI=$pci" | tee -a "$SCAN_LOG"

        # Extract MIB parameters
        grep -A 5 "MIB decoded" "$detail_log" >> "$SCAN_LOG"
    else
        echo "[$timestamp] MIB decode failed for PCI=$pci" | tee -a "$SCAN_LOG"
    fi
}

# Main monitoring loop
main() {
    echo "Starting continuous monitoring..."
    echo "Press Ctrl+C to stop"
    echo ""

    while true; do
        echo ""
        echo "========================================="
        echo "Scan cycle starting: $(date)"
        echo "========================================="

        # Scan each configured band
        for band in $BANDS; do
            scan_band "$band"
            sleep 5  # Brief pause between bands
        done

        echo ""
        echo "Scan cycle complete. Waiting $SCAN_INTERVAL seconds..."
        echo ""

        # Wait for next scan cycle
        sleep "$SCAN_INTERVAL"
    done
}

# Quick scan mode (single scan, no loop)
quick_scan() {
    echo "Quick scan mode - scanning all bands once..."

    for band in $BANDS; do
        scan_band "$band"
    done

    echo ""
    echo "Quick scan complete. Check $ALERT_LOG for alerts."
}

# Cell inspection mode
inspect_mode() {
    echo "Cell inspection mode"
    echo "Enter cell parameters from cell_database.json:"
    echo ""

    # Get parameters from user or command line
    FREQ=${1:-1935.0}
    PCI=${2:-192}
    PRB=${3:-50}
    PORTS=${4:-4}

    echo "Inspecting Cell PCI=$PCI @ $FREQ MHz ($PRB PRB, $PORTS ports)"
    inspect_cell "$FREQ" "$PCI" "$PRB" "$PORTS"
}

# Command line interface
case "${1:-monitor}" in
    monitor)
        main
        ;;
    quick)
        quick_scan
        ;;
    inspect)
        inspect_mode "$2" "$3" "$4" "$5"
        ;;
    *)
        echo "Usage: $0 {monitor|quick|inspect [freq] [pci] [prb] [ports]}"
        echo ""
        echo "  monitor  - Continuous monitoring (default)"
        echo "  quick    - Single scan of all bands"
        echo "  inspect  - Detailed inspection of specific cell"
        echo ""
        echo "Examples:"
        echo "  $0 monitor              # Start continuous monitoring"
        echo "  $0 quick                # Quick scan"
        echo "  $0 inspect 1935.0 192 50 4   # Inspect Cell 192"
        exit 1
        ;;
esac
