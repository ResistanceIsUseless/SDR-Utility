#!/bin/bash
echo "╔════════════════════════════════════════════════════════╗"
echo "║      Wideband RF Scanner - Continuous Monitor         ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""
echo "This will continuously monitor for new RF signals."
echo "Scans all bands every 30 seconds and alerts on new activity."
echo ""

read -p "Enter signal threshold in dB [10]: " threshold
threshold=${threshold:-10}

echo ""
echo "Starting continuous monitoring..."
echo "Press Ctrl+C to stop"
echo ""
sleep 2

/usr/bin/python3 /home/dragon/bin/rf-wideband-scanner.py --monitor --threshold $threshold

echo ""
read -p "Press Enter to close..."
