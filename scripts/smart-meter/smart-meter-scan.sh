#!/bin/bash
# Smart Meter Channel Scanner
# Scans common Zigbee channels to find smart meter traffic

cd /home/dragon/Tools/CatSniffer-Tools/pycatsniffer_bv3

echo "==================================="
echo "  Smart Meter Channel Scanner"
echo "==================================="
echo ""
echo "This will scan Zigbee channels commonly used by smart meters."
echo "Get your CatSniffer within 5 feet of the meter!"
echo ""
read -p "Press Enter when ready..."
echo ""

# Common smart meter channels
CHANNELS=(11 15 20 25)

for channel in "${CHANNELS[@]}"; do
    freq=$((2400 + (channel - 10) * 5))
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Scanning Channel $channel ($freq MHz)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Capture for 30 seconds
    timeout 30 /usr/bin/python3 cat_sniffer.py sniff /dev/ttyACM1 \
        --phy zigbee -c $channel \
        --pcap --pcap-name "meter_scan_ch${channel}.pcap" 2>&1 | grep -v "Unknown syntax" &
    
    PID=$!
    
    # Show countdown
    for i in {30..1}; do
        echo -ne "\rCapturing... $i seconds remaining  "
        sleep 1
    done
    
    wait $PID 2>/dev/null
    
    # Check if we got packets
    PCAP=$(ls -t dumps/pcaps/*meter_scan_ch${channel}.pcap 2>/dev/null | head -1)
    if [ -f "$PCAP" ]; then
        SIZE=$(stat -c%s "$PCAP")
        if [ $SIZE -gt 100 ]; then
            echo -e "\n✓ Captured data on channel $channel!"
            echo "  File: $PCAP ($SIZE bytes)"
        else
            echo -e "\n✗ No significant traffic on channel $channel"
        fi
    fi
    echo ""
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Scan Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Checking which channels had activity..."
echo ""

for channel in "${CHANNELS[@]}"; do
    PCAP=$(ls -t dumps/pcaps/*meter_scan_ch${channel}.pcap 2>/dev/null | head -1)
    if [ -f "$PCAP" ]; then
        SIZE=$(stat -c%s "$PCAP")
        if [ $SIZE -gt 100 ]; then
            echo "Channel $channel: $SIZE bytes captured"
        fi
    fi
done

echo ""
echo "To open captures in Wireshark:"
echo "  cd /home/dragon/Tools/CatSniffer-Tools/pycatsniffer_bv3/dumps/pcaps"
echo "  wireshark meter_scan_ch*.pcap"
echo ""
