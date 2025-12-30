#!/bin/bash
echo "╔════════════════════════════════════════════════════════╗"
echo "║         Wideband RF Scanner - Quick Scan              ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "This will scan multiple frequency bands and detect active signals."
echo ""
echo "Scanning bands:"
echo "  • VHF (24-50 MHz) - Marine, amateur radio"
echo "  • FM Radio (88-108 MHz)"
echo "  • Aviation (108-137 MHz)"
echo "  • 315 MHz ISM - Car keys, remotes"
echo "  • 433 MHz ISM - Weather stations, IoT"
echo "  • 868/915 MHz - Smart home, LoRa"
echo "  • ADS-B (1090 MHz) - Aircraft"
echo ""

read -p "Enter signal threshold in dB [10]: " threshold
threshold=${threshold:-10}

echo ""
echo "Starting scan..."
echo ""

/usr/bin/python3 /home/dragon/bin/rf-wideband-scanner.py --scan --threshold $threshold

echo ""
read -p "Press Enter to close..."
