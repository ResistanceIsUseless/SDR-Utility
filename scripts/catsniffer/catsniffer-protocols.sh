#!/bin/bash
cd /home/dragon/Tools/CatSniffer-Tools/pycatsniffer_bv3
echo "=== CatSniffer Supported Protocols ==="
echo ""
/usr/bin/python3 cat_sniffer.py protocols
echo ""
read -p "Press Enter to close..."
