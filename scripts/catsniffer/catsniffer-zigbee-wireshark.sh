#!/bin/bash
cd /home/dragon/Tools/CatSniffer-Tools/pycatsniffer_bv3
echo "=== CatSniffer ZigBee Sniffer with Wireshark ==="
echo "Starting ZigBee sniffer on channel 11..."
echo ""

# Set up FIFO and launch Wireshark in background
FIFO_PATH="/tmp/fcatsniffer_$$"
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
/usr/bin/python3 cat_sniffer.py sniff /dev/ttyACM1 --phy zigbee -c 11 --fifo --fifo-name "$FIFO_PATH"

cleanup
