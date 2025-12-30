#!/bin/bash
echo "=== Wireshark with CatSniffer ==="
echo ""
echo "Starting Wireshark..."
echo "Look for 'CatSniffer' in the interface list!"
echo ""
echo "Tips:"
echo "  - Select the CatSniffer interface"
echo "  - Choose your ZigBee channel (11-26)"
echo "  - Click Start to begin capturing"
echo "  - Use display filter: wpan or zbee_nwk"
echo ""
sudo wireshark
