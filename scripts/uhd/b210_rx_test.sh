#!/bin/bash
# B210 Receive-Only Test Script
# This script tests the B210 in RX mode only - NO TRANSMISSION

echo "======================================"
echo "B210 RX-Only Test"
echo "======================================"
echo ""
echo "Options:"
echo "1) FM Radio Scanner (88-108 MHz)"
echo "2) GSM Scanner (900 MHz)"
echo "3) LTE Scanner (700-2600 MHz)"
echo "4) Custom Frequency RX"
echo "5) Spectrum Waterfall Display"
echo "6) Exit"
echo ""
read -p "Select option: " option

case $option in
    1)
        echo "Scanning FM Radio band..."
        echo "Using rx_sdr to capture FM band"
        read -p "Enter center frequency in MHz (default 98): " freq
        freq=${freq:-98}
        echo "Receiving on ${freq} MHz for 10 seconds..."
        rx_sdr -d driver=uhd,type=b200 -f ${freq}e6 -s 2e6 -g 40 -n 20e6 /tmp/fm_capture.iq
        echo "Capture saved to /tmp/fm_capture.iq"
        ;;
    2)
        echo "Scanning GSM band..."
        read -p "Enter GSM band (900 or 1800): " band
        if [ "$band" == "900" ]; then
            freq="945"
        else
            freq="1842"
        fi
        echo "Scanning GSM-${band} around ${freq} MHz..."
        echo "Use Kalibrate: kal -s GSM${band} -g 40 -d 0"
        kal -s GSM${band} -g 40 -d 0 || echo "Kalibrate not found"
        ;;
    3)
        echo "LTE Scanner"
        read -p "Enter LTE band center frequency in MHz (default 1950): " freq
        freq=${freq:-1950}
        echo "Scanning LTE on ${freq} MHz..."
        echo "Use: CellSearch -f ${freq}e6"
        which CellSearch && CellSearch -f ${freq}e6 || echo "CellSearch not found"
        ;;
    4)
        read -p "Enter frequency in MHz: " freq
        read -p "Enter sample rate in MHz (default 2): " srate
        read -p "Enter gain in dB (default 40): " gain
        srate=${srate:-2}
        gain=${gain:-40}
        echo "Receiving on ${freq} MHz with ${srate} MHz sample rate and ${gain} dB gain..."
        rx_sdr -d driver=uhd,type=b200 -f ${freq}e6 -s ${srate}e6 -g ${gain} -n 20e6 /tmp/rx_capture.iq
        echo "Capture saved to /tmp/rx_capture.iq"
        ;;
    5)
        echo "Starting spectrum waterfall..."
        read -p "Enter center frequency in MHz (default 100): " freq
        freq=${freq:-100}
        echo "Opening GQRX on ${freq} MHz (RX only)..."
        gqrx -d uhd,type=b200 || echo "GQRX not found"
        ;;
    6)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        ;;
esac
