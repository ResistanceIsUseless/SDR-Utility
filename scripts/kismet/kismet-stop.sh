#!/bin/bash
echo "=== Stopping Kismet ==="
echo ""

if pgrep -x "kismet" > /dev/null; then
    echo "Stopping Kismet server..."
    killall kismet 2>/dev/null
    sleep 2

    # Force kill if still running
    if pgrep -x "kismet" > /dev/null; then
        echo "Force killing Kismet..."
        killall -9 kismet 2>/dev/null
        sleep 1
    fi

    # Also stop capture helpers
    killall kismet_cap_sdr_rtl433 2>/dev/null

    echo "✓ Kismet stopped"
else
    echo "Kismet is not running"
fi

echo ""
read -p "Press Enter to close..."
