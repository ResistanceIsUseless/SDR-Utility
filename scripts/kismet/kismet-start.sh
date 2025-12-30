#!/bin/bash
echo "=== Starting Kismet with RTL-SDR (rtl_433) ==="
echo ""
echo "Kismet will monitor 433 MHz ISM band for:"
echo "  - Weather sensors"
echo "  - Smart home devices"
echo "  - Tire pressure monitors"
echo "  - And 270+ other device types"
echo ""
echo "Web UI will be available at: http://localhost:2501"
echo ""

# Check if Kismet is already running
if pgrep -x "kismet" > /dev/null; then
    echo "WARNING: Kismet is already running!"
    echo ""
    read -p "Stop existing instance and restart? (y/n): " restart
    if [ "$restart" = "y" ] || [ "$restart" = "Y" ]; then
        echo "Stopping existing Kismet instance..."
        killall kismet 2>/dev/null
        sleep 2
    else
        echo "Keeping existing instance running."
        echo ""
        read -p "Press Enter to close..."
        exit 0
    fi
fi

echo "Starting Kismet in daemon mode..."
kismet -c rtl433-0 --daemonize 2>&1 | grep -E "INFO|ERROR"

echo ""
sleep 2

if pgrep -x "kismet" > /dev/null; then
    echo "✓ Kismet started successfully!"
    echo ""
    echo "Access web UI at: http://localhost:2501"
    echo "Logs location: /home/dragon/kismet_logs/"
    echo ""
    echo "To stop Kismet, use: kismet-stop.sh"
else
    echo "✗ Failed to start Kismet"
    echo "Check logs at: /home/dragon/.kismet/"
fi

echo ""
read -p "Press Enter to close..."
