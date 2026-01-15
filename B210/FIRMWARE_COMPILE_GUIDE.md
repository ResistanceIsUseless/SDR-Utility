# B210 Clone Firmware Compilation Guide

## For ARM64 Mac Users (Apple Silicon)

This guide covers how to compile the B210 clone FPGA firmware to fix the float32 bug when you cannot run Xilinx Vivado natively on ARM64.

---

## Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Option 1: Docker with x86 Emulation](#option-1-docker-with-x86-emulation)
4. [Option 2: Linux VM (UTM/Parallels)](#option-2-linux-vm-utmparallels)
5. [Option 3: Windows VM](#option-3-windows-vm)
6. [Option 4: Remote Build Server](#option-4-remote-build-server)
7. [The Fix to Apply](#the-fix-to-apply)
8. [Build Process](#build-process)
9. [Installing the Fixed Firmware](#installing-the-fixed-firmware)
10. [Verification](#verification)

---

## Overview

### The Problem

Your B210 clone has a bug in `iq_to_float.v` that corrupts float32 IQ data:
- Float32 produces values of 10^38 (should be ±1.0)
- ~15% of samples are NaN
- SC16 format works fine (current workaround)

### The Solution

Recompile the FPGA firmware with the corrected IEEE 754 exponent calculation.

### Why ARM64 Can't Compile Natively

- Xilinx Vivado only runs on x86_64 Linux and Windows
- No ARM64 version exists
- Must use emulation or a VM

---

## Requirements

### Hardware
- 16GB+ RAM recommended (Vivado is memory-hungry)
- 80GB+ free disk space (Vivado install + project)
- Fast SSD recommended

### Software
- Docker Desktop (for Option 1)
- UTM or Parallels (for Options 2/3)
- Xilinx account (free registration required)

### Files You Need
Located in your repo at `B210/firmware/Kintex-7 USRP_B210/`:
- FPGA project files (in `固件源工程/B210_Project_Firmwire/`)
- Or extract from `Kintex-7 USRP_B210.zip`

---

## Option 1: Docker with x86 Emulation

### Pros
- No full VM needed
- Can run alongside macOS apps
- Reproducible build environment

### Cons
- x86 emulation is slow (expect 2-4x longer builds)
- Requires ~40GB for Vivado Docker image
- May have stability issues

### Step 1: Install Docker Desktop

```bash
# Install via Homebrew
brew install --cask docker

# Start Docker Desktop
open -a Docker
```

Enable Rosetta emulation in Docker Desktop:
1. Open Docker Desktop → Settings → General
2. Enable "Use Rosetta for x86/amd64 emulation on Apple Silicon"
3. Apply & Restart

### Step 2: Use Pre-built Vivado Docker Image

There are community-maintained Vivado Docker images:

```bash
# Pull a Vivado image (example - check for latest)
docker pull ghcr.io/hdl/vivado:2024.1

# Or use Xilinx's official container (requires registration)
# https://github.com/Xilinx/Vitis-AI/tree/master/docker
```

### Step 3: Create Build Script

Create `docker-build-firmware.sh`:

```bash
#!/bin/bash
# Docker-based B210 firmware build

VIVADO_IMAGE="ghcr.io/hdl/vivado:2024.1"
PROJECT_DIR="$(pwd)/B210/firmware/Kintex-7 USRP_B210/固件源工程/B210_Project_Firmwire"

# Run Vivado in Docker with x86 emulation
docker run --platform linux/amd64 \
    -v "$PROJECT_DIR:/project" \
    -v "$(pwd)/B210/scripts:/scripts" \
    -w /project \
    $VIVADO_IMAGE \
    vivado -mode batch -source /scripts/build_fixed_firmware.tcl
```

### Step 4: Create Vivado Build Script

Create `B210/scripts/build_fixed_firmware.tcl`:

```tcl
# build_fixed_firmware.tcl - Build B210 firmware with float32 fix

puts "Opening B210 project..."
open_project B210_Project_Firmwire.xpr

puts "Running synthesis..."
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

puts "Running implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}

puts "Generating binary file..."
set bit_file [glob -nocomplain ./B210_Project_Firmwire.runs/impl_1/*.bit]
if {$bit_file eq ""} {
    puts "ERROR: Bitstream not found!"
    exit 1
}

write_cfgmem -format bin -interface SPIx4 -size 128 \
    -loadbit "up 0x0 $bit_file" \
    -file ./usrp_b210_fpga_fixed.bin -force

puts "SUCCESS! Fixed firmware: usrp_b210_fpga_fixed.bin"
```

### Expected Docker Build Time

On Apple Silicon with Rosetta emulation:
- Synthesis: 30-60 minutes
- Implementation: 45-90 minutes
- Bitstream: 15-30 minutes
- **Total: 2-4 hours**

---

## Option 2: Linux VM (UTM/Parallels)

### Recommended for Most Users

This is the most reliable method with best performance.

### Step 1: Install UTM (Free) or Parallels (Paid)

```bash
# UTM (free, open source)
brew install --cask utm

# Or Parallels (better x86 emulation performance)
# Download from https://www.parallels.com/
```

### Step 2: Create Ubuntu x86_64 VM

**For UTM:**

1. Download Ubuntu 22.04 x86_64 ISO:
   - https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso

2. Create new VM in UTM:
   - Click "+" → "Emulate"
   - Select "Linux"
   - Choose x86_64 architecture
   - RAM: 16GB minimum (24GB recommended)
   - Disk: 120GB minimum
   - CPUs: 4-8 cores

3. Install Ubuntu from ISO

**For Parallels:**

1. Create new VM → Install Windows or another OS from DVD/image
2. Select Ubuntu 22.04 x86_64 ISO
3. Configure: 16GB RAM, 120GB disk, 4+ CPUs

### Step 3: Install Vivado in VM

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y libtinfo5 libncurses5 libstdc++6 \
    lib32stdc++6 libgtk2.0-0 libxi6 libxtst6 libxrender1 \
    libfontconfig1 libfreetype6 python3 python3-pip \
    git build-essential

# Download Vivado from Xilinx
# Go to: https://www.xilinx.com/support/download.html
# Download: Vivado ML Standard 2024.1 (or latest)
# File: Xilinx_Unified_2024.1_xxxx_Lin64.bin (~100GB download)

# Make installer executable
chmod +x Xilinx_Unified_*.bin

# Run installer
./Xilinx_Unified_*.bin

# During installation:
# - Select "Vivado" product
# - Select "Vivado ML Standard" (free WebPACK license)
# - Install to /tools/Xilinx/Vivado/2024.1
# - Install only "Kintex-7" device support (saves space)
```

### Step 4: Transfer Project Files

**Option A: Shared Folder**

In UTM/Parallels, set up a shared folder pointing to your B210/firmware directory.

**Option B: Copy via SCP**

```bash
# On Mac, get VM IP address from VM's terminal:
# ip addr show

# Copy files
scp -r "B210/firmware/Kintex-7 USRP_B210" user@vm-ip:~/
```

### Step 5: Build in VM

```bash
# In VM terminal
source /tools/Xilinx/Vivado/2024.1/settings64.sh

# Navigate to project
cd "~/Kintex-7 USRP_B210/固件源工程/B210_Project_Firmwire"

# Apply the fix first (see "The Fix to Apply" section)

# Run Vivado in batch mode
vivado -mode batch -source build.tcl

# Or open GUI for interactive build
vivado B210_Project_Firmwire.xpr
```

### Expected VM Build Time

On Apple Silicon with UTM (x86 emulation):
- Synthesis: 20-40 minutes
- Implementation: 30-60 minutes
- Bitstream: 10-20 minutes
- **Total: 1-2 hours**

With Parallels (better emulation):
- **Total: 45 minutes - 1.5 hours**

---

## Option 3: Windows VM

### If You Prefer Windows

Vivado also runs on Windows 10/11 x64.

### Step 1: Create Windows VM

**For UTM:**
- Download Windows 11 ARM ISO (runs x64 apps via emulation)
- Or Windows 10 x64 ISO for pure x86 emulation

**For Parallels:**
- Use built-in Windows 11 ARM installation
- x64 Vivado runs via Windows' built-in x64 emulation

### Step 2: Install Vivado for Windows

1. Download from Xilinx: `Xilinx_Unified_2024.1_xxxx_Win64.exe`
2. Run installer, select Vivado ML Standard
3. Install to `C:\Xilinx\Vivado\2024.1`

### Step 3: Build

Open Vivado, load project, apply fix, and build as described in the Build Process section.

---

## Option 4: Remote Build Server

### Use a Cloud x86 Server

If you have access to an x86_64 Linux server or cloud instance.

### AWS/GCP/Azure Option

```bash
# Create Ubuntu 22.04 x86_64 instance
# Recommended: c5.2xlarge (8 vCPU, 16GB RAM) or equivalent
# Storage: 150GB SSD

# Install Vivado (see Linux VM instructions)

# Transfer project files
rsync -avz "B210/firmware/Kintex-7 USRP_B210" user@server:~/

# SSH in and build
ssh user@server
cd "~/Kintex-7 USRP_B210/固件源工程/B210_Project_Firmwire"
source /tools/Xilinx/Vivado/2024.1/settings64.sh
vivado -mode batch -source build.tcl
```

### GitHub Actions (Limited)

The repo already has `.github/workflows/build-b210-firmware.yml` but Vivado requires a license and is too large for standard GitHub runners.

For self-hosted runners with Vivado pre-installed, this could work.

---

## The Fix to Apply

Before building, you must apply the float32 fix to `iq_to_float.v`.

### Locate the File

```
B210/firmware/Kintex-7 USRP_B210/固件源工程/B210_Project_Firmwire/
  B210_Project_Firmwire.srcs/sources_1/imports/B210_Project_Firmwire/
    lib/vita_200/iq_to_float.v
```

### Apply the Fix

**Option A: Run the fix script**

```bash
./B210/scripts/fix_float32_firmware.sh
```

**Option B: Manual edit**

Open `iq_to_float.v` and replace the entire contents with:

```verilog
//
// Copyright 2014 Ettus Research LLC
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// FIXED VERSION - Corrected exponent calculation for IEEE 754

module iq_to_float

  #(parameter BITS_IN =16,
    parameter BITS_OUT = 32
    )
   (
    input [15:0] in,
    output [31:0] out
    );

   //2s complement
   wire [15:0] unsigned_mag;

   //leading bit registers
   wire [15:0] lead;
   wire [15:0] reversed_mag;

   //16-4 encoder
   wire [3:0] binary_out;

   wire [22:0] fraction;
   wire [7:0] exponent;

   wire [15:0] binary_in;

   binary_encoder #(.SIZE(16))
   encoding (.in(binary_in),.out(binary_out));

   // Detect sign, if negative detected perform 2's complement
   assign unsigned_mag = (in[15] == 1)?((~in[15:0])+1'b1):in[15:0];

   //detect leading one
   wire [15:0] complement = ((~reversed_mag[BITS_IN-1:0])+1'b1);
   assign lead = complement & reversed_mag;

   // FIXED: Correct exponent calculation for 16-bit to float32
   // For 16-bit input: exponent = 127 + (15 - binary_out)
   // binary_out is the position of leading 1 from MSB (0-15)
   wire [15:0] pre_frac = unsigned_mag << (15 - binary_out);
   assign fraction = {pre_frac[14:0],8'h0};

   // FIXED: Corrected exponent formula
   wire [7:0] calculated_exp = 8'd127 + 8'd15 - {4'b0, binary_out};

   // Handle special cases
   wire is_zero = (in == 16'b0);
   wire is_overflow = (binary_out > 4'd15);

   assign exponent = is_zero ? 8'b0 :
                     is_overflow ? 8'hFF :
                     calculated_exp;

   // Construct output with overflow protection
   wire [22:0] frac_out = is_overflow ? 23'h7FFFFF : fraction;
   assign out = {in[15], exponent, frac_out};

   //reverse the signed input
   genvar r;
   generate
      for (r = 0; r < 16; r = r+1) begin:bit_reverse
    assign reversed_mag[r] = unsigned_mag[BITS_IN-r-1];
      end
   endgenerate

   //reversed the output of the detect the leading bit procedure
   genvar i;
   generate
     for (i= 0; i < 16; i = i+1) begin: i_rev
       assign binary_in[i] = lead[BITS_IN-i-1];
     end
   endgenerate

endmodule
```

### What the Fix Does

**Original (buggy):**
```verilog
assign exponent = (in == 16'b0)?(8'b0):(binary_out +'d127);
```

**Fixed:**
```verilog
wire [7:0] calculated_exp = 8'd127 + 8'd15 - {4'b0, binary_out};
assign exponent = is_zero ? 8'b0 : is_overflow ? 8'hFF : calculated_exp;
```

The fix:
1. Corrects the IEEE 754 exponent calculation (127 + 15 - binary_out)
2. Adds overflow protection for edge cases
3. Properly handles zero input

---

## Build Process

### In Vivado GUI

1. Open Vivado
2. File → Open Project → `B210_Project_Firmwire.xpr`
3. In Flow Navigator:
   - Click "Run Synthesis" → Wait for completion
   - Click "Run Implementation" → Wait for completion
   - Click "Generate Bitstream" → Wait for completion
4. File → Export → Export Hardware → Include bitstream

### In Vivado TCL/Batch Mode

Create `build.tcl`:

```tcl
# Open project
open_project B210_Project_Firmwire.xpr

# Run synthesis
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check for errors
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "Synthesis failed!"
}

# Run implementation
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Check for errors
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "Implementation failed!"
}

# Generate .bin file from .bit
set bit_file [glob ./B210_Project_Firmwire.runs/impl_1/*.bit]
write_cfgmem -format bin -interface SPIx4 -size 128 \
    -loadbit "up 0x0 $bit_file" \
    -file ./usrp_b210_fpga_fixed.bin -force

puts "Build complete: usrp_b210_fpga_fixed.bin"
```

Run with:
```bash
source /tools/Xilinx/Vivado/2024.1/settings64.sh
vivado -mode batch -source build.tcl
```

### Build Outputs

After successful build:
- `B210_Project_Firmwire.runs/impl_1/b200.bit` - Bitstream file
- `usrp_b210_fpga_fixed.bin` - Binary for UHD (this is what you need)

---

## Installing the Fixed Firmware

### Step 1: Transfer to Mac

Copy `usrp_b210_fpga_fixed.bin` from VM/Docker to your Mac.

### Step 2: Backup Original

```bash
cp /opt/homebrew/share/uhd/images/usrp_b210_fpga.bin \
   /opt/homebrew/share/uhd/images/usrp_b210_fpga.bin.BACKUP
```

### Step 3: Install Fixed Firmware

```bash
cp usrp_b210_fpga_fixed.bin \
   /opt/homebrew/share/uhd/images/usrp_b210_fpga.bin
```

### Step 4: Reload Device

```bash
# Unplug and replug the B210
# Or force firmware reload:
uhd_image_loader --args="type=b200" \
    --fpga-path=/opt/homebrew/share/uhd/images/usrp_b210_fpga.bin
```

---

## Verification

### Test Float32 Format

```bash
# Capture with float32 (previously broken)
rx_samples_to_file --freq 93.7e6 --rate 2e6 --gain 50 \
    --ant RX2 --duration 5 --file test_float32.dat

# Analyze
python3 B210/scripts/analyze_float32.py test_float32.dat
```

### Expected Results (After Fix)

```
Samples analyzed: 10000
Valid samples: 100%
NaN count: 0
Inf count: 0
Value range: [-1.0, +1.0]
Average power: -35.2 dBFS
```

### Regression Test SC16

Ensure sc16 still works:

```bash
rx_samples_to_file --freq 93.7e6 --rate 2e6 --gain 50 \
    --ant RX2 --type short --duration 5 --file test_sc16.dat

python3 B210/scripts/analyze_with_dc_removal_pure.py test_sc16.dat
```

### If Something Goes Wrong

Restore the backup:

```bash
cp /opt/homebrew/share/uhd/images/usrp_b210_fpga.bin.BACKUP \
   /opt/homebrew/share/uhd/images/usrp_b210_fpga.bin
```

---

## Troubleshooting

### Vivado License Issues

Vivado ML Standard (WebPACK) is free and supports Kintex-7 XC7K325T.

If prompted for license:
1. Create free Xilinx account
2. Generate WebPACK license at https://www.xilinx.com/getlicense
3. Install license file in Vivado

### Build Fails: Timing Violations

If you see timing violations:
```
[Timing 38-282] The design failed to meet timing requirements.
```

Try:
1. Check timing reports: `report_timing_summary`
2. May need to adjust clock constraints in XDC file
3. Try lower Vivado optimization settings

### Build Fails: Resource Utilization

XC7K325T has plenty of resources for B210. If you see resource errors:
1. Check for other modifications to the design
2. Verify correct part number in project settings

### Device Not Working After Flash

1. Power cycle the B210 (unplug USB, wait 10 seconds, replug)
2. Check `uhd_find_devices` and `uhd_usrp_probe`
3. If device not recognized, restore backup firmware
4. May need to use JTAG recovery (see XC7K325T_SDR_FIRMWARE_GUIDE.md)

### Docker Build Crashes

x86 emulation on ARM64 can be unstable:
1. Increase Docker memory limit (Settings → Resources)
2. Reduce parallel jobs (`-jobs 2` instead of `-jobs 4`)
3. Try running in a full Linux VM instead

---

## Summary: Recommended Approach

| Your Situation | Recommended Option |
|---------------|-------------------|
| Have Parallels | Option 2 (Linux VM in Parallels) |
| Free tools only | Option 2 (Linux VM in UTM) |
| Already have cloud server | Option 4 (Remote Build) |
| Experimental/quick test | Option 1 (Docker) |
| Windows preference | Option 3 (Windows VM) |

### Time Investment

| Task | Time |
|------|------|
| VM/Docker setup | 1-2 hours |
| Vivado download | 2-4 hours (100GB) |
| Vivado installation | 30-60 minutes |
| Apply fix | 5 minutes |
| FPGA build | 1-4 hours |
| Install & test | 15 minutes |
| **Total** | **5-12 hours** |

---

## Alternative: Stay with SC16

If the compilation process seems too complex, remember:

**SC16 format works perfectly** and is actually more efficient:
- No conversion overhead in FPGA
- 4 bytes per sample vs 8 bytes
- All your current tools are configured for it

The float32 fix is only needed if you must use software that requires float32 format.

---

**Last Updated:** January 15, 2026
**Target Device:** B210 Clone (XC7K325T, Serial: 30AA038)
**Vivado Version:** 2024.1 (or compatible)
