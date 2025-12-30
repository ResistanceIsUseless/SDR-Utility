#!/bin/bash
cd /home/dragon/Tools/CatSniffer-Tools/pycatsniffer_bv3
echo "=== CatSniffer ZigBee Packet Capture ==="
echo ""
read -p "Enter ZigBee channel (11-26) [default: 15]: " channel
channel=${channel:-15}
read -p "Enter output filename [zigbee_capture.pcap]: " filename
filename=${filename:-zigbee_capture.pcap}
echo ""
echo "Capturing ZigBee traffic on channel $channel to $filename"
echo "Press Ctrl+C to stop."
echo ""
/usr/bin/python3 cat_sniffer.py sniff /dev/ttyACM1 --phy zigbee -c "$channel" --pcap --pcap-name "$filename"
echo ""
echo "Capture saved to: $filename"
read -p "Press Enter to close..."
