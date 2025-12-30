#!/bin/bash
cd /home/dragon/Tools/CatSniffer-Tools/pycatsniffer_bv3
echo "=== CatSniffer BLE Packet Capture ==="
echo ""
read -p "Enter BLE channel (37, 38, or 39) [default: 37]: " channel
channel=${channel:-37}
read -p "Enter output filename [ble_capture.pcap]: " filename
filename=${filename:-ble_capture.pcap}
echo ""
echo "Capturing BLE traffic on channel $channel to $filename"
echo "Press Ctrl+C to stop."
echo ""
/usr/bin/python3 cat_sniffer.py sniff /dev/ttyACM1 --phy ble -c "$channel" --pcap --pcap-name "$filename"
echo ""
echo "Capture saved to: $filename"
read -p "Press Enter to close..."
