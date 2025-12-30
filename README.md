# SDR Utility - Software Defined Radio Configuration and Tools

This repository contains configuration files, scripts, firmware, and documentation for Software Defined Radio (SDR) work, specifically focused on the B210 Clone and CaribouLite SDR platforms.

## Directory Structure

### B210/
Files and configurations for USRP B210 Clone (XC7K325T-based SDR)

- **configs/** - SDR++ and dual antenna configuration files
  - `b210_sdrpp_settings.txt` - SDR++ settings for B210
  - `b210_sdrpp_config.txt` - SDR++ configuration
  - `b210_dual_antenna_config.txt` - Dual antenna setup configuration

- **scripts/** - Utility scripts for B210 operations
  - `b210_rx_test.sh` - Reception test script
  - `b210_spectrum.sh` - Spectrum analyzer script

- **firmware/** - FPGA firmware binary
  - `usrp_b210_fpga.bin` - B210 FPGA firmware

- **docs/** - Documentation
  - `USRP_B210.pdf` - B210 documentation

- **constraints/** - FPGA constraint files
  - `b210.xdc` - Xilinx Design Constraints file

- **XC7K325T/** - Kintex-7 FPGA specific files and documentation
  - Various markdown files documenting the B210 clone project
  - Template constraint files
  - Project status and testing results

### cariboulite/
Complete source code and documentation for the CaribouLite SDR platform
- Hardware designs, schematics, and PCB files
- Software libraries and drivers
- GNU Radio integration
- Firmware and FPGA code
- Examples and documentation

### scans/
RF spectrum scan results and frequency analysis
- `315mhz_decoded.txt` - 315 MHz band scan results
- `433mhz_decoded.txt` - 433 MHz band scan results
- `915mhz_decoded.txt` - 915 MHz band scan results
- `tpms_scan.txt` - Tire Pressure Monitoring System scan
- `scan_results/` - Additional scan data
- `sweep_results/` - Frequency sweep results

### docs/
General SDR documentation and guides
- `scan_summary.md` - Summary of RF scan findings
- `recommended_tools.md` - Recommended SDR tools and software
- `trunked_radio_and_lnb_guide.md` - Trunked radio systems and LNB guide

## Hardware Platforms

### USRP B210 Clone (XC7K325T)
A clone of the Ettus USRP B210 using a Xilinx Kintex-7 XC7K325T FPGA. This project includes custom firmware, configurations, and extensive documentation of the bring-up process.

### CaribouLite
An open-source, dual-channel SDR HAT for Raspberry Pi, covering frequencies from 389.5 MHz to 3800 MHz with transmit and receive capabilities.

## Getting Started

Refer to the specific subdirectories for detailed documentation on each platform:
- For B210 setup, see `B210/XC7K325T/` documentation files
- For CaribouLite, see `cariboulite/README.md` and related documentation
- For general SDR tools and recommendations, see `docs/recommended_tools.md`

## License

Files in this repository come from various sources:
- CaribouLite files maintain their original licensing
- B210 configuration and custom scripts are provided as-is for personal use
- Refer to individual directories for specific licensing information
