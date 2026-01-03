#!/bin/bash
# B210 Spectrum Analyzer Script
# Shows live FM radio spectrum using uhd_fft

export UHD_IMAGES_DIR=/usr/local/share/uhd/images

echo "======================================"
echo "B210 Spectrum Analyzer"
echo "======================================"
echo ""
echo "Select mode:"
echo "1) FM Radio Band (88-108 MHz)"
echo "2) GSM 900 MHz"
echo "3) LTE Band 7 (2.6 GHz)"
echo "4) Custom Frequency"
echo "5) Wide Sweep (50-500 MHz)"
echo ""
read -p "Select option [1-5]: " option

case $option in
    1)
        echo ""
        echo "Starting FM Radio Spectrum (88-108 MHz)..."
        echo "Center: 98 MHz, Span: 20 MHz, Gain: 60 dB"
        echo ""
        read -p "Which antenna? (RX2 or TX/RX) [RX2]: " ant
        ant=${ant:-RX2}
        echo "Using antenna: $ant"
        echo ""
        uhd_fft -f 98e6 -s 20e6 -g 60 -A "$ant" --args="type=b200"
        ;;
    2)
        echo ""
        echo "Starting GSM 900 Spectrum..."
        echo "Center: 945 MHz, Span: 10 MHz, Gain: 60 dB"
        echo ""
        read -p "Which antenna? (RX2 or TX/RX) [RX2]: " ant
        ant=${ant:-RX2}
        uhd_fft -f 945e6 -s 10e6 -g 60 -A "$ant" --args="type=b200"
        ;;
    3)
        echo ""
        echo "Starting LTE Band 7 Spectrum..."
        echo "Center: 2.6 GHz, Span: 20 MHz, Gain: 50 dB"
        echo ""
        read -p "Which antenna? (RX2 or TX/RX) [RX2]: " ant
        ant=${ant:-RX2}
        uhd_fft -f 2.6e9 -s 20e6 -g 50 -A "$ant" --args="type=b200"
        ;;
    4)
        echo ""
        read -p "Enter center frequency in MHz: " freq
        read -p "Enter bandwidth in MHz [10]: " bw
        read -p "Enter gain in dB [60]: " gain
        read -p "Which antenna? (RX2 or TX/RX) [RX2]: " ant
        bw=${bw:-10}
        gain=${gain:-60}
        ant=${ant:-RX2}
        echo ""
        echo "Starting spectrum analyzer..."
        echo "Freq: ${freq} MHz, BW: ${bw} MHz, Gain: ${gain} dB, Antenna: $ant"
        echo ""
        uhd_fft -f ${freq}e6 -s ${bw}e6 -g ${gain} -A "$ant" --args="type=b200"
        ;;
    5)
        echo ""
        echo "Wide sweep mode not yet implemented"
        echo "Use option 4 to manually sweep different frequencies"
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac
