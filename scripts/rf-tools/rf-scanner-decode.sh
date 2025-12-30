#!/bin/bash
echo "╔════════════════════════════════════════════════════════╗"
echo "║       Wideband RF Scanner - Decode Frequency          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

read -p "Enter frequency in MHz: " freq

if [ -z "$freq" ]; then
    echo "ERROR: No frequency specified"
    read -p "Press Enter to close..."
    exit 1
fi

echo ""
echo "Available decoders:"
echo "  1. rtl_433   - ISM band devices (315/433/868/915 MHz)"
echo "  2. rtl_fm    - FM demodulation (general purpose)"
echo "  3. dump1090  - ADS-B aircraft (1090 MHz)"
echo "  4. auto      - Automatically select based on frequency"
echo ""

read -p "Select decoder [4]: " decoder_choice
decoder_choice=${decoder_choice:-4}

case $decoder_choice in
    1) decoder="rtl_433" ;;
    2) decoder="rtl_fm" ;;
    3) decoder="dump1090" ;;
    *) decoder="" ;;
esac

read -p "Capture duration in seconds [30]: " duration
duration=${duration:-30}

echo ""
echo "Decoding ${freq} MHz for ${duration} seconds..."
echo ""

if [ -z "$decoder" ]; then
    /usr/bin/python3 /home/dragon/bin/rf-wideband-scanner.py --freq $freq --duration $duration
else
    /usr/bin/python3 /home/dragon/bin/rf-wideband-scanner.py --freq $freq --decoder $decoder --duration $duration
fi

echo ""
read -p "Press Enter to close..."
