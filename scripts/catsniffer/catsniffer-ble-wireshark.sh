#!/bin/bash
cd /home/dragon/Tools/CatSniffer-Tools/pycatsniffer_bv3
echo "=== CatSniffer BLE Sniffer with Wireshark ==="
echo "Starting BLE sniffer on channel 37..."
echo ""

# Set up FIFO and launch Wireshark in background
FIFO_PATH="/tmp/fcatsniffer_ble_$$"
mkfifo "$FIFO_PATH" 2>/dev/null || true

# Launch Wireshark in background
wireshark -k -i "$FIFO_PATH" &
WIRESHARK_PID=$!
sleep 2

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Cleaning up..."
    kill $WIRESHARK_PID 2>/dev/null
    rm -f "$FIFO_PATH"
    exit 0
}

trap cleanup INT TERM EXIT

# Start the sniffer with FIFO output
echo "Wireshark launched. Starting packet capture..."
echo "Press Ctrl+C to stop."
echo ""
/usr/bin/python3 cat_sniffer.py sniff /dev/ttyACM1 --phy ble -c 37 --fifo --fifo-name "$FIFO_PATH"

cleanup
