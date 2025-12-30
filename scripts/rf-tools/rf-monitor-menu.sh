#!/bin/bash

show_menu() {
    clear
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║         RF Monitoring Tools - Main Menu               ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo ""
    echo "┌─ KISMET (Unified RF Dashboard) ────────────────────────┐"
    echo "│  1. Start Kismet with RTL-SDR (433 MHz monitoring)     │"
    echo "│  2. Stop Kismet                                        │"
    echo "│  3. Open Kismet Web UI                                │"
    echo "└────────────────────────────────────────────────────────┘"
    echo ""
    echo "┌─ WIDEBAND RF SCANNER (Auto-Detect & Decode) ───────────┐"
    echo "│  4. Quick Scan (all bands)                            │"
    echo "│  5. Continuous Monitor (alerts on new signals)        │"
    echo "│  6. Decode Specific Frequency                         │"
    echo "└────────────────────────────────────────────────────────┘"
    echo ""
    echo "┌─ RTL-SDR / rtl_433 (433 MHz ISM Band) ─────────────────┐"
    echo "│  7. Monitor 433 MHz devices (live view)               │"
    echo "│  8. Capture to JSON file                              │"
    echo "│  9. List supported protocols (273+)                   │"
    echo "└────────────────────────────────────────────────────────┘"
    echo ""
    echo "┌─ CATSNIFFER (2.4 GHz Protocols) ───────────────────────┐"
    echo "│ 10. BLE Capture → Wireshark                           │"
    echo "│ 11. Zigbee Capture → Wireshark                        │"
    echo "│ 12. Thread Capture → Wireshark                        │"
    echo "│ 13. BLE Capture → PCAP file                           │"
    echo "│ 14. Zigbee Capture → PCAP file                        │"
    echo "│ 15. BLE PCAP Analyzer (devices & sensitive data)      │"
    echo "│ 16. Smart Meter Scanner (PG&E)                        │"
    echo "│ 17. Smart Meter Targeted Capture                      │"
    echo "│ 18. List CatSniffer protocols                         │"
    echo "│ 19. Update CatSniffer firmware                        │"
    echo "└────────────────────────────────────────────────────────┘"
    echo ""
    echo "  0. Exit"
    echo ""
}

while true; do
    show_menu
    read -p "Select option: " choice
    echo ""

    case $choice in
        1)
            /home/dragon/bin/kismet-start.sh
            ;;
        2)
            /home/dragon/bin/kismet-stop.sh
            ;;
        3)
            /home/dragon/bin/kismet-webui.sh
            ;;
        4)
            /home/dragon/bin/rf-scanner-quick.sh
            ;;
        5)
            /home/dragon/bin/rf-scanner-monitor.sh
            ;;
        6)
            /home/dragon/bin/rf-scanner-decode.sh
            ;;
        7)
            /home/dragon/bin/rtl433-monitor.sh
            ;;
        8)
            /home/dragon/bin/rtl433-json.sh
            ;;
        9)
            /home/dragon/bin/rtl433-protocols.sh
            ;;
        10)
            /home/dragon/bin/catsniffer-ble-wireshark.sh
            ;;
        11)
            /home/dragon/bin/catsniffer-zigbee-wireshark.sh
            ;;
        12)
            /home/dragon/bin/catsniffer-thread-wireshark.sh
            ;;
        13)
            /home/dragon/bin/catsniffer-ble-pcap.sh
            ;;
        14)
            /home/dragon/bin/catsniffer-zigbee-pcap.sh
            ;;
        15)
            /home/dragon/bin/ble-analyzer-menu.sh
            ;;
        16)
            /home/dragon/bin/smart-meter-scan.sh
            ;;
        17)
            /home/dragon/bin/smart-meter-capture.sh
            ;;
        18)
            /home/dragon/bin/catsniffer-protocols.sh
            ;;
        19)
            /home/dragon/bin/catsniffer-firmware.sh
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Press Enter to continue..."
            read
            ;;
    esac
done
