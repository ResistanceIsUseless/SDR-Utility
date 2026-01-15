# B210 Clone Troubleshooting - RX Data Issue

**Problem**: Getting zeros or corrupted data (NaN values) when trying to receive signals.

**Current Status**:
- Device detected: ✅
- FPGA loads: ✅
- Register tests pass: ✅
- **RX data**: ❌ (zeros/NaN)

## Root Cause Analysis

The AD9361 RF transceiver is not calibrating/initializing properly with current firmware.

## Available Firmware Files

Located in `B210/firmware/`:

1. **usrp_b210_fpga.bin** (5.2 MB) - Currently installed
2. **libresdr_b210_v2.bin** (4.3 MB) - LibreSDR variant 2
3. **libresdr_b210.bin** (4.3 MB) - LibreSDR variant 1
4. **usrp_b210_fpga_libresdr.bin** (2.9 MB) - LibreSDR FPGA
5. **lmesserStep_b210.bin** (2.9 MB) - LimeSDR variant
6. **usrp_b210_fpga_CLONE_BACKUP** (2.9 MB) - Backup

## Testing Different Firmware

### Try LibreSDR Firmware First

LibreSDR is a common clone firmware that often works better:

```bash
# Backup current firmware
cp /opt/homebrew/Cellar/uhd/4.9.0.1/share/uhd/images/usrp_b210_fpga.bin \
   /opt/homebrew/Cellar/uhd/4.9.0.1/share/uhd/images/usrp_b210_fpga.bin.kintex_backup

# Try LibreSDR v2
cp B210/firmware/libresdr_b210_v2.bin \
   /opt/homebrew/Cellar/uhd/4.9.0.1/share/uhd/images/usrp_b210_fpga.bin

# Test
uhd_find_devices
rx_samples_to_file --freq 93.7e6 --rate 1e6 --gain 60 --ant RX2 --duration 2 --file /tmp/test.dat

# Check if data is valid
python3 B210/scripts/analyze_signal.py /tmp/test.dat
```

### If That Doesn't Work, Try Others

```bash
# Try LibreSDR v1
cp B210/firmware/libresdr_b210.bin \
   /opt/homebrew/Cellar/uhd/4.9.0.1/share/uhd/images/usrp_b210_fpga.bin

# Try LibreSDR FPGA variant
cp B210/firmware/usrp_b210_fpga_libresdr.bin \
   /opt/homebrew/Cellar/uhd/4.9.0.1/share/uhd/images/usrp_b210_fpga.bin

# Try LimeSDR variant
cp B210/firmware/lmesserStep_b210.bin \
   /opt/homebrew/Cellar/uhd/4.9.0.1/share/uhd/images/usrp_b210_fpga.bin
```

## LED Indicators (From Manual)

When receiving on RX2, check these LEDs:

- **POWER LED** (red): Should be on when powered
- **STATUS LED** (blue): Should be on after firmware loads
- **RX2 LED** (blue): Should be blue when receiving on RX2
- **CLK LED** (red): Flashes with PPS (if GPS locked or external PPS)

**Check**: Are the RX2 LED turning blue during reception?

## UHD Version Compatibility

The clone manual mentions it needs specific firmware. UHD 4.9.0.1 might be too new.

### Try Older UHD Version

```bash
# Check what UHD versions are available
brew search uhd

# If needed, install older version
# brew install uhd@4.6  # (if available)
```

## Alternative: Use Windows Software

The clone came with Windows software package:
- Location: `B210/firmware/Kintex-7 USRP_B210/windows软件/`
- File: `uhd_4.6.0.0-release_Win64_VS2019.exe`

The manufacturer tested with **UHD 4.6.0.0**, not 4.9.0.1.

## Quick Test Script

```bash
#!/bin/bash
# Test all firmware variants

FIRMWARE_DIR="B210/firmware"
UHD_IMAGES="/opt/homebrew/Cellar/uhd/4.9.0.1/share/uhd/images"

FIRMWARES=(
    "libresdr_b210_v2.bin"
    "libresdr_b210.bin"
    "usrp_b210_fpga_libresdr.bin"
    "lmesserStep_b210.bin"
)

for FW in "${FIRMWARES[@]}"; do
    echo "Testing: $FW"
    cp "$FIRMWARE_DIR/$FW" "$UHD_IMAGES/usrp_b210_fpga.bin"

    # Test
    rx_samples_to_file --freq 100e6 --rate 1e6 --gain 50 --ant RX2 --duration 1 --file /tmp/test_$FW.dat 2>&1 | grep -E "(Error|Failed)" && echo "FAILED" || echo "SUCCESS"

    # Check for real data
    python3 -c "
import struct
with open('/tmp/test_$FW.dat', 'rb') as f:
    data = f.read(800)
    vals = [struct.unpack('ff', data[i:i+8]) for i in range(0, 800, 8)]
    mags = [(i**2 + q**2)**0.5 for i,q in vals]
    if max(mags) > 0.0001 and 'nan' not in str(vals):
        print('✓ VALID DATA')
    else:
        print('✗ BAD DATA')
"
    echo ""
done
```

## Expected Behavior

**Good signal**:
```
Sample 0: I=0.001234, Q=-0.002345, Mag=0.002645
Sample 1: I=0.003456, Q=0.001234, Mag=0.003669
```

**Bad signal** (current issue):
```
Sample 0: I=0.000000, Q=0.000000, Mag=0.000000
Sample 6: I=     nan, Q=-1800175472445010768837019172864.000000, Mag=     nan
```

## Next Steps

1. ✅ Check LEDs during reception (especially RX2 LED)
2. ✅ Try libresdr_b210_v2.bin firmware
3. ✅ If that fails, test all other firmware variants
4. ✅ Consider downgrading to UHD 4.6.0.0
5. ⚠️ Check antenna connection (ANT500 on RX2 port)

## References

- Manual: `B210/firmware/Kintex-7 USRP_B210/USRP_B210说明.pdf`
- Manufacturer tested with: UHD 4.6.0.0
- Compatible with: Vivado 2024.1
