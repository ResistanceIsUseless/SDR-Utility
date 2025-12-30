#!/bin/bash
echo "=== Killerbee ZigBee Packet Dump ==="
echo ""
echo "This will capture ZigBee packets to a PCAP file."
echo ""
read -p "Enter channel (11-26): " channel
read -p "Enter filename [zigbee_capture.pcap]: " filename
filename=${filename:-zigbee_capture.pcap}
echo ""
echo "Starting capture on channel $channel to $filename..."
echo "Press Ctrl+C to stop."
echo ""
sudo zbdump -f "$filename" -c "$channel"
