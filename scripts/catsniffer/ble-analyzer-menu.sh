#!/bin/bash
echo "=== BLE PCAP Analyzer ==="
echo ""
echo "Analyzes BLE packet captures for:"
echo "  1. Device enumeration (MAC, name, manufacturer)"
echo "  2. Sensitive data exposure (credentials, keys, PII)"
echo ""

# Default PCAP directory
PCAP_DIR="/home/dragon/Tools/CatSniffer-Tools/pycatsniffer_bv3/dumps/pcaps"

# Check if there are recent PCAP files
if [ -d "$PCAP_DIR" ]; then
    echo "Recent BLE captures in $PCAP_DIR:"
    ls -lht "$PCAP_DIR"/*.pcap 2>/dev/null | head -5 | awk '{print "  " $9 " (" $5 ", " $6 " " $7 ")"}'
    echo ""
fi

read -p "Enter PCAP file path (or drag & drop file here): " pcap_file

# Remove quotes if drag-and-dropped
pcap_file="${pcap_file//\'/}"
pcap_file="${pcap_file//\"/}"

if [ ! -f "$pcap_file" ]; then
    echo ""
    echo "ERROR: File not found: $pcap_file"
    echo ""
    read -p "Press Enter to close..."
    exit 1
fi

echo ""
echo "Analyzing: $pcap_file"
echo ""

/usr/bin/python3 /home/dragon/bin/ble-pcap-analyzer.py "$pcap_file"

echo ""
read -p "Press Enter to close..."
