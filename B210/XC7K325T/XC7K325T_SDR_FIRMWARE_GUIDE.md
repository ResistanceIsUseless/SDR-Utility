# XC7K325T SDR Firmware Guide
## OpenSourceSDRLab USRP B210 Clone (XC7K325T + AD9361)

---

## Table of Contents
1. [Hardware Overview](#hardware-overview)
2. [Key Differences from Standard B210](#key-differences-from-standard-b210)
3. [Prerequisites](#prerequisites)
4. [Firmware Building Options](#firmware-building-options)
5. [Method 1: Using Pre-built Binaries](#method-1-using-pre-built-binaries)
6. [Method 2: Building from UHD Source](#method-2-building-from-uhd-source)
7. [Method 3: Building Custom Firmware with Vivado](#method-3-building-custom-firmware-with-vivado)
8. [Flashing Firmware](#flashing-firmware)
9. [Troubleshooting](#troubleshooting)
10. [Configuration Files](#configuration-files)

---

## Hardware Overview

### Board Specifications
- **FPGA**: Xilinx Kintex-7 XC7K325T-2FFG900C
- **RF Frontend**: Analog Devices AD9361BBCZ
- **Interface**: USB 3.0 Type-C
- **Max Bandwidth**: 56 MHz real-time
- **Dimensions**: 70 x 97 x 11.5 mm

### Key Features
- Full-duplex transceiver (TRX1/TRX2)
- Additional receive-only ports (RX1/RX2)
- GPS module (onboard)
- PPS (Pulse Per Second) input
- 10 MHz external reference input
- JTAG debugging interface (FPC connector)
- Multiple status LEDs

### Interfaces
- **RF Ports**: SMA connectors for TRX1, TRX2, RX1, RX2
- **Timing**: MMCX connectors for GPS, PPS, 10MHz reference
- **Data**: USB 3.0 Type-C
- **Debug**: FPC connector for JTAG + GPIO

---

## Key Differences from Standard B210

### Hardware Differences

| Feature | Standard B210 | XC7K325T Clone |
|---------|---------------|----------------|
| FPGA | XC7A75T (Artix-7) | XC7K325T (Kintex-7) |
| Logic Cells | ~76,000 | ~326,000 |
| Block RAM | 4.8 Mb | 16 Mb |
| DSP Slices | 180 | 840 |
| Max Bandwidth | 56 MHz | 56 MHz |
| GPS | Optional GPSDO | Onboard GPS module |
| USB | USB 3.0 Micro-B | USB 3.0 Type-C |

### Critical Differences for Firmware

1. **FPGA Part Number**: XC7K325T vs XC7A100T/XC7A75T
   - Different device family (Kintex-7 vs Artix-7)
   - More resources available (4.3x more logic cells)
   - Different speed grades and package types

2. **Pin Mapping**: May differ from standard B210
   - Verify pinout.xdc constraints file
   - Check AD9361 interface connections
   - Validate USB interface signals

3. **Timing Constraints**: Kintex-7 may require different timing
   - Higher speed grade capabilities
   - Different internal routing architecture

4. **GPS Integration**: Onboard GPS vs external GPSDO
   - GPS has priority over external PPS
   - Different control interface

---

## Prerequisites

### Software Requirements

1. **Xilinx Vivado** (for FPGA builds)
   - Version: 2019.1 or newer recommended
   - License: WebPACK license supports Kintex-7 XC7K325T
   - Download: [Xilinx Download Page](https://www.xilinx.com/support/download.html)

2. **UHD (USRP Hardware Driver)**
   - Version: 4.0 to 4.7 recommended
   - Source: [Ettus Research UHD](https://github.com/EttusResearch/uhd)

3. **Build Tools**
   ```bash
   sudo apt-get install git cmake build-essential
   sudo apt-get install libboost-all-dev libusb-1.0-0-dev python3-mako
   sudo apt-get install doxygen python3-docutils python3-requests
   sudo apt-get install python3-numpy python3-setuptools
   ```

4. **Programming Tools**
   - Xilinx Vivado (includes Vivado Hardware Manager)
   - openFPGALoader (alternative open-source option)

### Hardware Requirements

- USB 3.0 port (USB 2.0 will work but with reduced bandwidth)
- JTAG programmer (optional, for direct FPGA programming)
  - Xilinx Platform Cable USB
  - Compatible JTAG adapter
- Good quality USB 3.0 Type-C cable

---

## Firmware Building Options

There are three main approaches to getting firmware for your XC7K325T board:

### Quick Summary

| Method | Difficulty | Time | Customization | Best For |
|--------|-----------|------|---------------|----------|
| Pre-built Binaries | Easy | 5 min | None | Quick testing |
| UHD Build | Medium | 1-2 hrs | Limited | Standard use |
| Custom Vivado | Hard | 4-8 hrs | Full | Development |

---

## Method 1: Using Pre-built Binaries

### ⚠️ Warning
Pre-built binaries from other B210 clones (XC7A100T/XC7A75T) will **NOT work** directly on XC7K325T without modification. The bitstream is device-specific.

### If You Find XC7K325T Binaries

If you locate pre-built binaries specifically for XC7K325T:

1. **Install UHD**
   ```bash
   sudo add-apt-repository ppa:ettusresearch/uhd
   sudo apt-get update
   sudo apt-get install libuhd-dev uhd-host
   ```

2. **Backup Original Firmware**
   ```bash
   cd /usr/share/uhd/images
   sudo cp usrp_b210_fpga.bin usrp_b210_fpga.bin.backup
   ```

3. **Install Custom Firmware**
   ```bash
   # Download your XC7K325T binary
   wget <URL_TO_XC7K325T_BINARY>

   # Copy to UHD images directory
   sudo cp usrp_b210_fpga.bin /usr/share/uhd/images/
   ```

4. **Test Detection**
   ```bash
   uhd_find_devices
   uhd_usrp_probe
   ```

### Current Status
As of now, there are **no publicly available pre-built binaries** specifically for the XC7K325T variant. You will need to build from source.

---

## Method 2: Building from UHD Source

This method builds the FPGA firmware from Ettus Research's official UHD repository, modified for XC7K325T.

### Step 1: Install UHD Host Software

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install git cmake build-essential libboost-all-dev \
    libusb-1.0-0-dev python3-mako python3-numpy python3-requests

# Clone UHD repository
cd ~/
git clone https://github.com/EttusResearch/uhd.git
cd uhd

# Checkout stable version
git checkout v4.6.0.0  # or latest stable version
git submodule update --init --recursive

# Build and install UHD
cd host
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j$(nproc)
sudo make install
sudo ldconfig
```

### Step 2: Prepare FPGA Build Environment

```bash
# Source Vivado settings
source /opt/Xilinx/Vivado/2019.1/settings64.sh

# Navigate to B210 FPGA directory
cd ~/uhd/fpga/usrp3/top/b200
```

### Step 3: Modify for XC7K325T

You need to modify the FPGA build scripts to target XC7K325T instead of XC7A75T.

**Edit Makefile** (or build.tcl):

```tcl
# Find the device specification line (example)
# Change from:
set PART "xc7a75tfgg484-2"

# To:
set PART "xc7k325tffg900-2"
```

**Key files to check/modify**:
- `Makefile` - Build configuration
- `b200.v` or `b200_core.v` - Top-level design
- `timing.xdc` - Timing constraints
- `pins.xdc` - Pin constraints (CRITICAL - must match your board)

### Step 4: Obtain Correct Pin Constraints

This is **CRITICAL**. You need the correct `pinout.xdc` file for your specific board.

**Option A**: Check the LSC-Unicamp repository
```bash
# The repository has a pinout.xdc for XC7K325T
wget https://raw.githubusercontent.com/LSC-Unicamp/processor-ci-controller/main/fpga/opensourceSDRLabKintex7/pinout.xdc
```

**Option B**: Contact the board manufacturer
- Request the complete constraints file (XDC)
- Verify all pin assignments match your board revision

**Option C**: Reverse engineer from working board
- Use Vivado Hardware Manager to read existing bitstream
- Extract pin assignments from device

### Step 5: Build the FPGA Bitstream

```bash
# In the b200 directory
make B210_FPGA_PART=xc7k325tffg900-2

# This will take 1-2 hours depending on your system
# Output: usrp_b210_fpga.bit
```

### Step 6: Convert to UHD Binary Format

```bash
# UHD uses .bin format, not .bit
cd ~/uhd/fpga/usrp3/top/b200/build

# Generate binary
promgen -w -p bin -o usrp_b210_fpga.bin -s 8192 -u 0 usrp_b210_fpga.bit

# Or use Vivado's write_cfgmem command
vivado -mode batch -source ../generate_bin.tcl
```

### Step 7: Install Firmware

```bash
sudo cp usrp_b210_fpga.bin /usr/share/uhd/images/
```

---

## Method 3: Building Custom Firmware with Vivado

For complete control and customization, build directly in Vivado.

### Step 1: Create Vivado Project

```bash
# Source Vivado
source /opt/Xilinx/Vivado/2019.1/settings64.sh

# Start Vivado GUI
vivado &
```

1. **Create New Project**
   - Project Name: `xc7k325t_b210`
   - Project Type: RTL Project
   - Add Sources: UHD RTL files from `~/uhd/fpga/usrp3/`

2. **Select Part**
   - Family: Kintex-7
   - Package: ffg900
   - Speed Grade: -2
   - Part: **xc7k325tffg900-2**

### Step 2: Add Design Sources

Add all necessary files from UHD repository:

```
uhd/fpga/usrp3/top/b200/
├── b200.v (or b200_core.v)
├── b200.xdc (constraints)
└── (all supporting modules)

uhd/fpga/usrp3/lib/
├── rfnoc/
├── control/
├── fifo/
└── (other support modules)
```

### Step 3: Add Constraints

**CRITICAL**: Use correct pin constraints for XC7K325T board.

```tcl
# Example pinout.xdc structure
# AD9361 Interface
set_property PACKAGE_PIN AA12 [get_ports {CAT_DATA_CLK}]
set_property PACKAGE_PIN AB11 [get_ports {CAT_RX_FRAME}]
# ... (continue for all pins)

# USB Interface (FX3)
set_property PACKAGE_PIN Y14 [get_ports {FX3_PCLK}]
# ... (continue for all pins)

# Clock constraints
create_clock -period 16.000 [get_ports CAT_DATA_CLK]
create_clock -period 10.000 [get_ports FX3_PCLK]
```

### Step 4: Generate IP Cores

UHD uses several Xilinx IP cores:

1. **Clock Wizard** (for clock generation)
2. **FIFO Generator** (for data buffering)
3. **AXI interconnect** (for internal bus)

Generate these through Vivado IP Catalog, configured for XC7K325T.

### Step 5: Build and Generate Bitstream

```tcl
# In Vivado TCL console
reset_run synth_1
launch_runs synth_1 -jobs 8
wait_on_run synth_1

launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# Generate binary file
write_cfgmem -format bin -interface SPIx4 -size 128 \
    -loadbit "up 0x0 ./xc7k325t_b210.runs/impl_1/b200.bit" \
    -file usrp_b210_fpga.bin
```

### Step 6: Analyze Results

Check timing, utilization, and power:

```tcl
open_run impl_1
report_timing_summary
report_utilization
report_power
```

---

## Flashing Firmware

### Method 1: Using UHD (Automatic)

If using UHD with custom firmware in `/usr/share/uhd/images/`:

```bash
# UHD automatically loads firmware on device connection
uhd_find_devices

# Force firmware reload
uhd_image_loader --args="type=b200" --fpga-path=/usr/share/uhd/images/usrp_b210_fpga.bin
```

### Method 2: Using Vivado Hardware Manager

For direct FPGA programming via JTAG:

1. **Connect JTAG adapter** to FPC connector on board
2. **Open Vivado Hardware Manager**
   ```bash
   vivado -mode gui
   # Open Hardware Manager
   # Open Target -> Auto Connect
   ```

3. **Program Device**
   - Right-click on XC7K325T device
   - Program Device
   - Select: `usrp_b210_fpga.bit`
   - Program

4. **Program Flash** (for persistent storage)
   - Right-click on device
   - Add Configuration Memory Device
   - Select: s25fl128sxxxxxx0 (or board-specific flash)
   - Program flash with `.bin` file

### Method 3: Using openFPGALoader

Open-source alternative to Vivado:

```bash
# Install openFPGALoader
sudo apt-get install libudev-dev libftdi1-dev libhidapi-dev
git clone https://github.com/trabucayre/openFPGALoader.git
cd openFPGALoader
mkdir build
cd build
cmake ..
make -j$(nproc)
sudo make install

# Program FPGA (volatile)
openFPGALoader -b xc7k325t usrp_b210_fpga.bit

# Program Flash (persistent)
openFPGALoader -b xc7k325t -f usrp_b210_fpga.bit
```

**Board definition** for openFPGALoader may need to be added:

```yaml
# Add to boards.yml
opensourcesdrlab_xc7k325t:
  fpga_part: xc7k325tffg900
  cable: ft2232
  programmer: vivado
```

---

## Troubleshooting

### Device Not Detected

```bash
# Check USB connection
lsusb | grep -i "Ettus\|2500\|b200"

# Expected output (may vary):
# Bus 002 Device 005: ID 2500:0020 Ettus Research LLC USRP B200

# Check kernel messages
dmesg | tail -n 50

# Verify permissions
sudo usermod -a -G usrp $USER
sudo udevadm control --reload-rules
```

### UHD Device Permission Issues

Create udev rules:

```bash
sudo nano /etc/udev/rules.d/uhd-usrp.rules
```

Add:
```
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0020", MODE="0666"
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0002", MODE="0666"
```

Reload rules:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Firmware Loading Fails

```bash
# Check UHD version
uhd_config_info --version

# Re-download images
sudo /usr/lib/uhd/utils/uhd_images_downloader.py

# Force specific firmware
uhd_image_loader --args="type=b200" --fpga-path=/path/to/your/usrp_b210_fpga.bin --verbose
```

### FPGA Build Errors

**Timing Violations**:
- Review clock constraints in XDC file
- Check timing reports: `report_timing_summary`
- May need to adjust speed grade or add pipeline stages

**Pin Assignment Errors**:
- Verify all pins are valid for XC7K325T-FFG900 package
- Check for pin conflicts
- Ensure differential pairs are correctly assigned

**Resource Utilization Errors**:
- XC7K325T has more resources than XC7A75T
- If hitting limits, design may have other issues
- Check synthesis settings

### USB 3.0 Issues

```bash
# Check USB speed
lsusb -t

# If device shows as USB 2.0:
# 1. Try different USB port
# 2. Check cable quality (must be USB 3.0 rated)
# 3. Update USB 3.0 controller drivers

# Force USB 3.0
# Add to kernel command line: usbcore.authorized_default=0
```

### AD9361 Not Responding

```bash
# Check AD9361 initialization in dmesg
dmesg | grep -i ad9361

# Test with uhd_usrp_probe
uhd_usrp_probe --args="type=b200" --init-only

# If fails, possible issues:
# - Incorrect SPI/pin mapping
# - AD9361 not powered correctly
# - Clock reference problems
```

### GPS/PPS Issues

```bash
# Check GPS module
# GPS has priority over external PPS on this board

# Test GPS lock
# LED indicators should show GPS status

# Monitor PPS
# Use oscilloscope on PPS MMCX connector
# Should see 1Hz pulse when GPS locked
```

---

## Configuration Files

### Essential XDC Constraints Template

```tcl
# master_constraints.xdc for XC7K325T SDR Board
# Based on USRP B210 architecture

#######################################
# Clock Constraints
#######################################

# AD9361 Data Clock (40 MHz)
create_clock -period 25.000 -name CAT_DATA_CLK [get_ports CAT_DATA_CLK_P]

# FX3 USB Clock (100 MHz)
create_clock -period 10.000 -name FX3_PCLK [get_ports FX3_PCLK]

# 10 MHz Reference Clock (optional)
create_clock -period 100.000 -name CLK_10MHZ [get_ports CLK_10MHZ]

#######################################
# AD9361 Interface
#######################################

# Data Clock (LVDS)
set_property PACKAGE_PIN <PIN> [get_ports CAT_DATA_CLK_P]
set_property PACKAGE_PIN <PIN> [get_ports CAT_DATA_CLK_N]
set_property IOSTANDARD LVDS_25 [get_ports CAT_DATA_CLK_*]

# Data Pins (12-bit)
# set_property PACKAGE_PIN <PIN> [get_ports {CAT_RX_DATA[0]}]
# ... (continue for all 12 bits)

# Control Pins
set_property PACKAGE_PIN <PIN> [get_ports CAT_RX_FRAME]
set_property PACKAGE_PIN <PIN> [get_ports CAT_TX_FRAME]
set_property PACKAGE_PIN <PIN> [get_ports CAT_ENABLE]
set_property PACKAGE_PIN <PIN> [get_ports CAT_TXNRX]
set_property PACKAGE_PIN <PIN> [get_ports CAT_RESET]

# SPI Interface
set_property PACKAGE_PIN <PIN> [get_ports CAT_SPI_SCLK]
set_property PACKAGE_PIN <PIN> [get_ports CAT_SPI_MOSI]
set_property PACKAGE_PIN <PIN> [get_ports CAT_SPI_MISO]
set_property PACKAGE_PIN <PIN> [get_ports CAT_SPI_CS]

#######################################
# FX3 USB Interface
#######################################

# Clock and Control
set_property PACKAGE_PIN <PIN> [get_ports FX3_PCLK]
set_property PACKAGE_PIN <PIN> [get_ports FX3_SLCS]
set_property PACKAGE_PIN <PIN> [get_ports FX3_SLRD]
set_property PACKAGE_PIN <PIN> [get_ports FX3_SLOE]
set_property PACKAGE_PIN <PIN> [get_ports FX3_SLWR]
set_property PACKAGE_PIN <PIN> [get_ports FX3_PKTEND]
set_property PACKAGE_PIN <PIN> [get_ports {FX3_ADDR[0]}]
set_property PACKAGE_PIN <PIN> [get_ports {FX3_ADDR[1]}]

# Data Bus (32-bit)
# set_property PACKAGE_PIN <PIN> [get_ports {FX3_DATA[0]}]
# ... (continue for all 32 bits)

# Flags
set_property PACKAGE_PIN <PIN> [get_ports FX3_FLAGA]
set_property PACKAGE_PIN <PIN> [get_ports FX3_FLAGB]
set_property PACKAGE_PIN <PIN> [get_ports FX3_FLAGC]
set_property PACKAGE_PIN <PIN> [get_ports FX3_FLAGD]

#######################################
# GPS and Timing
#######################################

# GPS Serial Interface
set_property PACKAGE_PIN <PIN> [get_ports GPS_TXD]
set_property PACKAGE_PIN <PIN> [get_ports GPS_RXD]

# PPS Input
set_property PACKAGE_PIN <PIN> [get_ports PPS_IN]

# 10 MHz Reference
set_property PACKAGE_PIN <PIN> [get_ports CLK_10MHZ]

#######################################
# LEDs
#######################################

set_property PACKAGE_PIN <PIN> [get_ports LED_PWR]
set_property PACKAGE_PIN <PIN> [get_ports LED_STATUS]
set_property PACKAGE_PIN <PIN> [get_ports LED_PPS]
set_property PACKAGE_PIN <PIN> [get_ports LED_TX]
set_property PACKAGE_PIN <PIN> [get_ports LED_RX]

#######################################
# Timing Exceptions
#######################################

# CDC (Clock Domain Crossing) constraints
set_false_path -from [get_clocks CAT_DATA_CLK] -to [get_clocks FX3_PCLK]
set_false_path -from [get_clocks FX3_PCLK] -to [get_clocks CAT_DATA_CLK]

# Input delays
set_input_delay -clock [get_clocks CAT_DATA_CLK] -min 2.000 [get_ports CAT_RX_DATA*]
set_input_delay -clock [get_clocks CAT_DATA_CLK] -max 8.000 [get_ports CAT_RX_DATA*]

# Output delays
set_output_delay -clock [get_clocks CAT_DATA_CLK] -min 1.000 [get_ports CAT_TX_DATA*]
set_output_delay -clock [get_clocks CAT_DATA_CLK] -max 5.000 [get_ports CAT_TX_DATA*]
```

### Build Configuration (Makefile Example)

```makefile
# Makefile for XC7K325T B210 FPGA Build

# Project Settings
PROJECT = xc7k325t_b210
TOP = b200_core
PART = xc7k325tffg900-2

# Paths
UHD_DIR = $(HOME)/uhd/fpga/usrp3
BUILD_DIR = ./build
IP_DIR = ./ip

# Vivado Settings
VIVADO = vivado
VIVADO_MODE = batch

# Source Files
RTL_SRCS = $(UHD_DIR)/top/b200/b200_core.v \
           $(UHD_DIR)/lib/rfnoc/*.v \
           # ... (add all required sources)

XDC_FILES = pinout.xdc \
            timing.xdc

# Targets
all: bitstream

bitstream: $(BUILD_DIR)/$(PROJECT).bit

$(BUILD_DIR)/$(PROJECT).bit:
	@echo "Building FPGA bitstream for XC7K325T..."
	$(VIVADO) -mode $(VIVADO_MODE) -source build.tcl

clean:
	rm -rf $(BUILD_DIR)

program: $(BUILD_DIR)/$(PROJECT).bit
	$(VIVADO) -mode $(VIVADO_MODE) -source program.tcl

.PHONY: all clean program bitstream
```

### Vivado Build Script (build.tcl)

```tcl
# build.tcl - Automated build script for XC7K325T

# Create project
create_project -force xc7k325t_b210 ./build -part xc7k325tffg900-2

# Add source files
add_files {b200_core.v}
add_files -fileset constrs_1 {pinout.xdc timing.xdc}

# Set top module
set_property top b200_core [current_fileset]

# Synthesis settings
set_property strategy Flow_PerfOptimized_high [get_runs synth_1]
set_property STEPS.SYNTH_DESIGN.ARGS.RETIMING true [get_runs synth_1]

# Implementation settings
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

# Run synthesis
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Run implementation
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# Generate reports
open_run impl_1
report_timing_summary -file ./build/timing_summary.rpt
report_utilization -file ./build/utilization.rpt
report_power -file ./build/power.rpt

# Generate binary file
write_cfgmem -format bin -interface SPIx4 -size 128 \
    -loadbit "up 0x0 ./build/xc7k325t_b210.runs/impl_1/b200_core.bit" \
    -file ./build/usrp_b210_fpga.bin

puts "Build complete! Binary: ./build/usrp_b210_fpga.bin"
```

---

## Additional Resources

### Documentation
- [UHD Manual](https://files.ettus.com/manual/)
- [AD9361 Reference Manual](https://www.analog.com/en/products/ad9361.html)
- [Xilinx Kintex-7 Documentation](https://www.xilinx.com/products/silicon-devices/fpga/kintex-7.html)

### Community
- [Ettus Research Knowledge Base](https://kb.ettus.com/)
- [GNU Radio Mailing List](https://lists.gnu.org/mailman/listinfo/discuss-gnuradio)
- [r/RTLSDR Subreddit](https://reddit.com/r/RTLSDR)

### GitHub Repositories
- [UHD Source](https://github.com/EttusResearch/uhd)
- [LSC-Unicamp XC7K325T Project](https://github.com/LSC-Unicamp/processor-ci-controller/tree/main/fpga/opensourceSDRLabKintex7)
- [LibreSDR Projects](https://github.com/topics/libresdr)

### Tools
- [Xilinx Vivado WebPACK](https://www.xilinx.com/support/download.html) - Free FPGA design suite
- [openFPGALoader](https://github.com/trabucayre/openFPGALoader) - Open-source FPGA programmer
- [GNU Radio](https://www.gnuradio.org/) - SDR application framework

---

## Next Steps

1. **Acquire Correct Pin Constraints**
   - Contact OpenSourceSDRLab for official pinout.xdc
   - Or use LSC-Unicamp repository files as starting point

2. **Set Up Build Environment**
   - Install Vivado 2019.1 or newer
   - Clone UHD repository
   - Install dependencies

3. **Initial Build Attempt**
   - Start with Method 2 (UHD Source Build)
   - Modify for XC7K325T part number
   - Use available pin constraints

4. **Test and Iterate**
   - Flash firmware via JTAG first (non-permanent)
   - Test basic functionality with uhd_usrp_probe
   - Validate RF performance
   - Flash to permanent storage once stable

5. **Optimize**
   - Fine-tune timing constraints
   - Optimize for power consumption
   - Add custom features if needed

---

## License and Disclaimer

This guide is provided for educational purposes. The hardware and software components may be subject to various licenses:

- **UHD**: GPL v3
- **Xilinx Vivado**: Proprietary (free WebPACK license available)
- **Hardware**: Check with manufacturer

**Disclaimer**: Modifying FPGA firmware can render your device inoperable. Always maintain backups and understand the risks involved. RF transmission is regulated - ensure compliance with local regulations.

---

**Document Version**: 1.0
**Last Updated**: 2025-12-10
**Contributor**: AI Assistant

For updates and corrections, please contribute to the project repository.
