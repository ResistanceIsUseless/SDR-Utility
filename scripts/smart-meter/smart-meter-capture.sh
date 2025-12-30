#!/bin/bash
# Targeted Smart Meter Capture
# Use this after finding the active channel with smart-meter-scan.sh

cd /home/dragon/Tools/CatSniffer-Tools/pycatsniffer_bv3

echo "==================================="
echo "  Smart Meter Long Capture"
echo "==================================="
echo ""

# Get channel from user
read -p "Enter the channel to capture (default: 11): " CHANNEL
CHANNEL=${CHANNEL:-11}

read -p "Capture duration in seconds (default: 300 = 5 min): " DURATION
DURATION=${DURATION:-300}

FILENAME="smart_meter_ch${CHANNEL}_$(date +%Y%m%d_%H%M%S).pcap"

echo ""
echo "Starting capture:"
echo "  Channel: $CHANNEL"
echo "  Duration: $DURATION seconds"
echo "  Output: $FILENAME"
echo ""
echo "IMPORTANT: Keep CatSniffer within 5 feet of the meter!"
echo ""
read -p "Press Enter to start..."

echo ""
echo "Capturing... (Ctrl+C to stop early)"
echo ""

timeout $DURATION /usr/bin/python3 cat_sniffer.py sniff /dev/ttyACM1 \
    --phy zigbee -c $CHANNEL \
    --pcap --pcap-name "$FILENAME" 2>&1 | grep -v "Unknown syntax"

echo ""
echo "Capture complete!"
echo ""

PCAP=$(ls -t dumps/pcaps/*${FILENAME} 2>/dev/null | head -1)
if [ -f "$PCAP" ]; then
    SIZE=$(stat -c%s "$PCAP")
    echo "Captured: $SIZE bytes"
    echo "File: $PCAP"
    echo ""
    echo "To analyze in Wireshark:"
    echo "  wireshark '$PCAP'"
    echo ""
    echo "Look for:"
    echo "  - Zigbee Network Layer frames"
    echo "  - Beacon frames (coordinator)"
    echo "  - Data Request/Response"
    echo "  - Device addresses (64-bit IEEE addresses)"
else
    echo "Error: Capture file not found"
fi
