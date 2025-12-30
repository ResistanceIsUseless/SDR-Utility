#!/bin/bash
echo "=== RTL-SDR 433 MHz Monitor (rtl_433) ==="
echo ""
echo "This will monitor 433 MHz ISM band for wireless devices."
echo "Supports 273+ device types including:"
echo "  - Weather stations (Acurite, LaCrosse, Oregon Scientific)"
echo "  - Smart home sensors (temp, humidity, motion)"
echo "  - Tire pressure monitors (TPMS)"
echo "  - Remote controls and doorbells"
echo ""
echo "Output format: Human-readable with signal levels"
echo ""
read -p "Press Enter to start monitoring (Ctrl+C to stop)..."
echo ""

# Run rtl_433 with human-readable output and signal levels
rtl_433 -d 0 -F log -M time:unix -M level -M protocol
