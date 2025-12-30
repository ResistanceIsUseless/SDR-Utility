#!/bin/bash
cd /home/dragon/Tools/CatSniffer-Tools/catnip_uploader
echo "=== CatSniffer Firmware Uploader ==="
echo ""
sudo /usr/bin/python3 catnip_uploader.py releases
echo ""
echo "To upload firmware, use:"
echo "  sudo /usr/bin/python3 catnip_uploader.py load <firmware_name>"
echo ""
bash
