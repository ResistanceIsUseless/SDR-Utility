#!/bin/bash
echo "=== RTL-SDR 433 MHz JSON Output ==="
echo ""
read -p "Enter output filename [rtl433_devices.json]: " filename
filename=${filename:-rtl433_devices.json}

read -p "Enter duration in seconds [60]: " duration
duration=${duration:-60}

echo ""
echo "Capturing 433 MHz devices for $duration seconds..."
echo "Output file: $filename"
echo ""
echo "Press Ctrl+C to stop early."
echo ""

# Run rtl_433 with JSON output
timeout $duration rtl_433 -d 0 -F json -M time:unix -M level -M protocol > "$filename" 2>&1

echo ""
if [ -f "$filename" ]; then
    echo "✓ Capture complete!"
    echo "File: $filename"
    echo "Size: $(wc -c < "$filename") bytes"
    echo ""
    echo "Device count: $(grep -c "model" "$filename")"
    echo ""
    echo "First few detections:"
    head -5 "$filename"
else
    echo "✗ No output file created"
fi

echo ""
read -p "Press Enter to close..."
