#!/bin/bash
echo "=== RTL-SDR rtl_433 Supported Protocols ==="
echo ""
echo "Total protocols supported: 273+"
echo ""
echo "Listing all supported device types..."
echo ""

rtl_433 -R help 2>&1 | grep -E "^\[" | head -50

echo ""
echo "Showing first 50 protocols. For full list:"
echo "  rtl_433 -R help"
echo ""
read -p "Press Enter to close..."
