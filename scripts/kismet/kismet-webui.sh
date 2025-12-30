#!/bin/bash
echo "=== Opening Kismet Web UI ==="
echo ""

# Check if Kismet is running
if pgrep -x "kismet" > /dev/null; then
    echo "✓ Kismet is running"
    echo "Opening web UI at http://localhost:2501"
    echo ""

    # Try to open in default browser
    if command -v xdg-open > /dev/null; then
        xdg-open http://localhost:2501 2>/dev/null &
    elif command -v chromium-browser > /dev/null; then
        chromium-browser http://localhost:2501 2>/dev/null &
    elif command -v firefox > /dev/null; then
        firefox http://localhost:2501 2>/dev/null &
    else
        echo "Could not find browser. Please open manually:"
        echo "http://localhost:2501"
    fi
else
    echo "✗ Kismet is not running!"
    echo ""
    read -p "Start Kismet now? (y/n): " start
    if [ "$start" = "y" ] || [ "$start" = "Y" ]; then
        echo ""
        echo "Starting Kismet..."
        kismet -c rtl433-0 --daemonize 2>&1 | grep -E "INFO|ERROR"
        sleep 3

        if pgrep -x "kismet" > /dev/null; then
            echo "✓ Kismet started!"
            echo "Opening web UI..."
            sleep 2
            xdg-open http://localhost:2501 2>/dev/null &
        else
            echo "✗ Failed to start Kismet"
        fi
    fi
fi

echo ""
read -p "Press Enter to close..."
