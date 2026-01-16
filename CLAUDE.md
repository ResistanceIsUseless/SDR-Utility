# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

SDR-Utility is a documentation and configuration repository for Software Defined Radio (SDR) hardware platforms, primarily the **USRP B210 Clone** (XC7K325T FPGA) and **CaribouLite** (Raspberry Pi HAT). This is primarily a reference/utility repo with scripts, configurations, and firmware - not a traditional software development project.

## Hardware Platforms

### B210 Clone (Primary - macOS)
- **FPGA:** Xilinx Kintex-7 XC7K325T (clone-specific, not standard Ettus)
- **RF Transceiver:** AD9361BBCZ (70 MHz - 6 GHz)
- **Serial:** 30AA038
- **UHD Version:** 4.9.0.1

**Critical Bug:** Float32 IQ data format is broken in clone firmware. Always use `--type short` (sc16 format).

### CaribouLite (Raspberry Pi HAT)
- **Channels:** Dual-channel SDR (Sub-1GHz: 389.5-510 MHz / 779-1020 MHz, Wide: 30 MHz - 6 GHz)
- **Platform:** Raspberry Pi (NOT RPi 5 - SMI interface removed)
- **Distribution:** Requires Bullseye (bookworm has kernel header issues)

## Common Commands

### B210 Operations (macOS)
```bash
# Device detection
uhd_find_devices
uhd_usrp_probe

# Spectrum visualization
rx_ascii_art_dft --freq 98e6 --rate 2e6 --gain 50 --ant RX2

# Capture IQ data (MUST use --type short for this clone)
rx_samples_to_file --freq 93.7e6 --rate 2e6 --gain 50 --ant RX2 --type short --duration 10 --file output.dat

# Benchmark performance
benchmark_rate --rx_rate 20e6 --tx_rate 20e6 --duration 30

# Analyze captured data
python3 scripts/sdr/analyze_with_dc_removal_pure.py /path/to/capture.dat

# Auto-optimize settings
./scripts/uhd/auto_optimize.sh
```

### CaribouLite Operations (Raspberry Pi)
```bash
# Installation (don't use sudo)
cd cariboulite && ./install.sh

# Test HAT detection
cat /proc/device-tree/hat/product  # Should show "CaribouLite RPI Hat"

# Check kernel module
lsmod | grep smi

# Test via SoapySDR
SoapySDRUtil --probe

# Run test application
./build/cariboulite_test_app
```

### RF Analysis Scripts
```bash
# rtl_433 ISM band monitoring
./scripts/rtl433/rtl433-monitor.sh

# Kismet wireless monitoring
./scripts/kismet/kismet-start.sh

# CatSniffer BLE/Zigbee capture
./scripts/catsniffer/catsniffer-ble-wireshark.sh
```

## Project Structure

```
SDR-Utility/
├── B210/                    # B210 Clone documentation and setup
│   ├── scripts/
│   │   ├── setup/          # One-time setup/install scripts
│   │   └── firmware/       # Firmware fixes and installation
│   ├── firmware/           # Clone firmware files (Git LFS)
│   └── *.md                # Documentation
│
├── cariboulite/            # Complete CaribouLite source
│
├── scripts/                # Operational scripts (organized by use)
│   ├── uhd/               # UHD/B210 testing & optimization
│   ├── sdr/               # Generic SDR analysis (any hardware)
│   ├── rtl433/            # ISM band decoders
│   ├── kismet/            # Wireless monitoring
│   ├── catsniffer/        # BLE/Zigbee/Thread tools
│   ├── rf-tools/          # General RF utilities
│   └── killerbee/         # Zigbee security tools
│
├── scans/                 # RF scan results
└── docs/                  # Research guides
```

### Script Organization Philosophy

- **B210/scripts/setup/** - Install dependencies, configure drivers (run once)
- **B210/scripts/firmware/** - Firmware patching and installation
- **scripts/uhd/** - Daily use scripts for UHD devices (testing, optimization)
- **scripts/sdr/** - Hardware-agnostic analysis tools (work with any SDR)
- **scripts/{tool}/** - Tool-specific workflows (rtl_433, kismet, etc.)

## B210 Clone-Specific Notes

### Data Format Requirement
The clone firmware has a bug in IEEE 754 float32 conversion. **Always specify `--type short`** for rx_samples_to_file or data will be corrupted with NaN values.

### Recommended Settings
| Band | Frequency | Gain | Antenna |
|------|-----------|------|---------|
| FM Radio | 88-108 MHz | 40-50 dB | RX2 |
| LTE 700 | 746 MHz | 50-60 dB | RX2 |
| LTE 1900 | 1930 MHz | 50 dB | TX/RX |
| WiFi 2.4G | 2462 MHz | 50 dB | TX/RX |

### GQRX Configuration
- Device string: `serial=30AA038,type=b200`
- Input rate: 2000000
- Antenna: RX2 or TX/RX

### Firmware Location
Clone-specific FPGA firmware: `B210/firmware/Kintex-7 USRP_B210/`
Install to: `/opt/homebrew/share/uhd/images/usrp_b210_fpga.bin`

## CaribouLite-Specific Notes

### Platform Constraints
- **No RPi 5 support** - SMI interface was removed by Broadcom
- Requires disabling `spi` and `arm-i2c` dtoverlays (uses direct /dev/mem access via pigpio)
- Needs kernel headers installed for smi_stream_dev module compilation
- Requires sudo for hardware access (pigpio limitation)

### Installation Troubleshooting
1. Edit `/boot/config.txt` to comment out: `#dtparam=spi=on` and `#dtparam=i2c_arm=on`
2. After kernel upgrades, recompile kernel module from `software/libcariboulite/caribou_smi/kernel`

## CI/CD

GitHub Actions workflow for B210 firmware builds: `.github/workflows/build-b210-firmware.yml`
- Requires Xilinx Vivado (manual setup - not automated)
- Applies float32 fix via `B210/scripts/firmware/fix_float32_firmware.sh`

## Cellular Research (macOS Workflow)

Docker on macOS cannot access USB devices, so use a two-step workflow:
1. Capture IQ data natively with `rx_samples_to_file`
2. Analyze in RF-Swift container (gr-gsm, srsRAN, kalibrate)

Setup: `./scripts/install_cellular_tools.sh`

## Legal Reminder

SDR reception is generally legal; transmission requires licensing. This repo is for educational/research purposes with passive reception only.
