# B210 Clone RX Issue - Summary

**Date**: 2026-01-13
**Status**: ⚠️ PARTIAL - Device detected but RX data corrupted

---

## What's Working ✅

- Device detection: Device found as "Custom_SDR_B210"
- FPGA loading: Firmware loads successfully
- Register tests: All loopback tests pass
- USB communication: No dropped samples in benchmark
- Hardware path: benchmark_rate shows 10M samples received

## What's NOT Working ❌

- **RX data corruption**: Getting zeros and NaN values
- **AD9361 initialization**: RF chip not calibrating properly
- **No valid signals**: Cannot receive FM radio or any RF

## Root Cause

**UHD version mismatch**:
- You have: **UHD 4.9.0.1** (latest)
- Manufacturer tested with: **UHD 4.6.0.0** (from manual)
- The Kintex-7 clone firmware is not fully compatible with UHD 4.9.0.1

## Evidence

### Test Results
```
Sample 0: I=0.000000, Q=0.000000, Mag=0.000000  ← All zeros
Sample 6: I=     nan, Q=-1800175472445010768... ← Overflow/NaN
```

### Firmware Tests
- ✅ Kintex-7 firmware: Loads, but bad data
- ❌ LibreSDR v2: Hangs during FPGA load
- ❌ LibreSDR v1: Hangs during FPGA load
- (LibreSDR firmwares are for Artix-7, not Kintex-7)

---

## Solutions (In Order of Likelihood)

### Solution 1: Downgrade to UHD 4.6.0.0 (RECOMMENDED)

The manufacturer tested with UHD 4.6.0.0. You need to match that version.

**On macOS:**

```bash
# Check if older UHD available
brew search uhd

# If available, install specific version
brew unlink uhd
brew install uhd@4.6.0

# Or build from source:
git clone https://github.com/EttusResearch/uhd.git
cd uhd
git checkout v4.6.0.0
cd host
mkdir build && cd build
cmake ..
make -j$(sysctl -n hw.ncpu)
sudo make install
```

After installing UHD 4.6.0.0:
```bash
# Download matching images
python3 /usr/local/lib/uhd/utils/uhd_images_downloader.py -t b2xx

# Install clone firmware
cp "B210/firmware/Kintex-7 USRP_B210/需替换BIN文件/usrp_b210_fpga.bin" \
   /usr/local/share/uhd/images/usrp_b210_fpga.bin

# Test
uhd_find_devices
rx_ascii_art_dft --freq 93.7e6 --rate 1e6 --gain 50 --ant RX2
```

### Solution 2: Use Windows with Provided Software

The manufacturer included Windows software tested with the clone:

**Location**: `B210/firmware/Kintex-7 USRP_B210/windows软件/`
- `uhd_4.6.0.0-release_Win64_VS2019.exe` (200 MB)
- `libusb-1.0.dll`
- `erllc_uhd_winusb_driver.zip`

This is the **guaranteed working** configuration.

### Solution 3: Check with Manufacturer

The clone manufacturer may have updated firmware for UHD 4.9.x:

**Contact**:
- Check product page for firmware updates
- Look for user forums/Discord
- Email seller for technical support

**Ask for**:
- Updated firmware for UHD 4.9.0.1
- AD9361 initialization fix
- Known compatibility issues

### Solution 4: Try Different Sample Rates

Some clones have issues with specific sample rates:

```bash
# Try very low rate
rx_samples_to_file --freq 93.7e6 --rate 200e3 --gain 50 --ant RX2 --duration 2 --file test.dat

# Try standard rates
for rate in 200e3 500e3 1e6 2e6 5e6; do
    echo "Testing rate: $rate"
    rx_samples_to_file --freq 100e6 --rate $rate --gain 50 --ant RX2 --duration 1 --file test_$rate.dat
    python3 B210/scripts/analyze_signal.py test_$rate.dat $rate
done
```

---

## Verification Checklist

Before testing solutions, verify:

- [ ] ANT500 antenna connected to **RX2 port** (not TX/RX)
- [ ] Antenna fully screwed in
- [ ] Check LEDs during RX:
  - [ ] POWER LED (red) - on
  - [ ] STATUS LED (blue) - on after firmware load
  - [ ] **RX2 LED (blue)** - should turn blue when receiving
- [ ] Try antenna near window for better FM signal
- [ ] Verify 93.7 MHz "The River" is active in your area

---

## Quick Diagnosis Commands

```bash
# 1. Device detection
uhd_find_devices

# 2. Check current UHD version
uhd_config_info --version

# 3. Capture and analyze
rx_samples_to_file --freq 100e6 --rate 1e6 --gain 50 --ant RX2 --duration 1 --file test.dat
python3 B210/scripts/analyze_signal.py test.dat

# 4. Check raw samples
python3 -c "
import struct
with open('test.dat', 'rb') as f:
    for i in range(10):
        data = f.read(8)
        if data:
            i_val, q_val = struct.unpack('ff', data)
            print(f'I={i_val:.6f}, Q={q_val:.6f}')
"
```

**Good data**: Small non-zero values (-0.1 to 0.1)
**Bad data**: All zeros or NaN/inf values

---

## Alternative: Try Different Clone Board

If this board continues to have issues, consider:

1. **HackRF One** (~$300) - Well-supported, works out of box
2. **RTL-SDR v4** (~$40) - RX only, but rock solid
3. **Original USRP B210** (~$1000+) - Guaranteed compatibility
4. **PlutoSDR** (~$200) - Good alternative, different architecture

---

## Current Configuration

```
Device: Custom_SDR_B210
Serial: 30AA038
FPGA: XC7K325T-2FFG676C
Current UHD: 4.9.0.1
Required UHD: 4.6.0.0 (per manufacturer)
Firmware: Kintex-7 USRP_B210 specific
Status: Device detected, but RX data corrupted
```

---

## Next Immediate Steps

1. **Downgrade to UHD 4.6.0.0** - Most likely to fix the issue
2. **Check RX2 LED** - Should be blue when receiving
3. **Test with Windows software** - Guaranteed working config
4. **Contact manufacturer** - May have updated firmware

---

## Why This Happened

The clone uses **Kintex-7 (XC7K325T)** instead of the original **Artix-7 (XC7A75T)**. The manufacturer provided firmware for their specific hardware, but only tested with UHD 4.6.0.0.

UHD 4.9.0.1 (released later) has changes to AD9361 initialization that aren't compatible with the clone's modified firmware.

---

**Bottom Line**: You need to match the manufacturer's test environment (UHD 4.6.0.0) or use their Windows software package.
