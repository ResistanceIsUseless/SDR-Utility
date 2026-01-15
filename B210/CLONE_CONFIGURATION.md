# B210 Clone Configuration Guide

## Critical Finding: Data Format Issue

**IMPORTANT:** This B210 clone has a **firmware bug in float32 IQ data format**. You **MUST** use `sc16` (16-bit signed integer) format for all captures.

### The Problem
- **Float32 format** (`--type float` or default): Produces corrupted data with NaN values and extreme power levels (10^38)
- **SC16 format** (`--type short`): Works perfectly with clean, valid IQ samples

### Solution
**Always use `--type short` flag** when capturing with `rx_samples_to_file`:

```bash
# CORRECT - sc16 format
rx_samples_to_file --freq 93.7e6 --rate 2e6 --gain 50 --ant RX2 --type short --file output.dat

# WRONG - float32 format (corrupted data!)
rx_samples_to_file --freq 93.7e6 --rate 2e6 --gain 50 --ant RX2 --file output.dat
```

## Optimal Settings (from auto-optimizer)

**Best Overall Signal:**
- **Frequency:** 2462 MHz (WiFi Channel 11)
- **Antenna:** TX/RX
- **Gain:** 50 dB
- **Sample Rate:** 2 MS/s
- **SNR:** 22.3 dB

**Test Command:**
```bash
rx_samples_to_file --freq 2462e6 --rate 2e6 --gain 50 --ant "TX/RX" --type short --duration 10 --file signal.dat
```

## Signal Detection Results

### Top Signals Detected

1. **WiFi Channel 11 (2462 MHz)** - SNR: 22.3 dB @ 50dB gain, TX/RX
2. **1930 MHz (PCS/LTE)** - SNR: 20.4 dB @ 50dB gain, TX/RX
3. **LTE Band 13 (746-751 MHz)** - SNR: 16-17 dB @ 50-60dB gain
4. **FM Radio (88-108 MHz)** - SNR: 8-15 dB @ various gains
5. **LTE Band 4 (2132.5 MHz)** - SNR: 15-16 dB @ 50-70dB gain

### Antenna Comparison

**RX2 Port:**
- Connected: ANT500 antenna
- Best for: Mid-range frequencies (700-2000 MHz)
- Typical SNR: 14-17 dB

**TX/RX Port:**
- Connected: [Your second antenna]
- Best for: Higher frequencies (WiFi 2.4 GHz)
- Typical SNR: 15-22 dB

## Recommended Gain Settings by Frequency

| Frequency Band | Optimal Gain | Notes |
|---------------|--------------|-------|
| FM (88-108 MHz) | 40-50 dB | Avoid >60 dB (saturation) |
| LTE 700 MHz | 50-60 dB | Strong signals in area |
| LTE 1900-2100 MHz | 50-60 dB | Good SNR at moderate gain |
| WiFi 2.4 GHz | 50 dB | Very strong local signals |

## Device Specifications

**Hardware:**
- FPGA: Xilinx Kintex-7 XC7K325T (clone-specific)
- RF Transceiver: AD9361BBCZ
- USB Controller: Cypress FX3
- Serial: 30AA038
- Product: B210
- Name: Custom_SDR_B210

**Firmware:**
- UHD Version: 4.9.0.1_1
- FPGA Firmware: Clone-specific (usrp_b210_fpga.bin)
- FX3 Firmware: Standard UHD (usrp_b200_fw.hex)

**Known Limitations:**
1. **Float32 data format broken** - use sc16 only
2. **AGC always enabled** in hardware (hardcoded in FPGA)
3. Requires clone-specific FPGA firmware

## Usage with Software

### SDR++ (GUI)
**Not recommended** - SoapySDR UHD module would need sc16 format support configuration

### GQRX (GUI) - Recommended
```bash
gqrx
```
Configuration:
- Device: UHD
- Device string: `serial=30AA038,type=b200`
- Input rate: 2000000
- Antenna: RX2 or TX/RX

### GNU Radio (Advanced)
Use UHD source blocks with:
- **Output Type:** `Complex Int16` (sc16)
- Sample Rate: 2 MS/s
- Antenna: RX2 or TX/RX
- Gain: 40-60 dB

### Command Line (rx_samples_to_file)
Always include `--type short`:
```bash
/opt/homebrew/Cellar/uhd/4.9.0.1_1/lib/uhd/examples/rx_samples_to_file \
  --freq 93.7e6 \
  --rate 2e6 \
  --gain 50 \
  --ant RX2 \
  --type short \
  --duration 10 \
  --file output.dat
```

### Visualization (ASCII Art FFT)
Works well for monitoring:
```bash
/opt/homebrew/Cellar/uhd/4.9.0.1_1/lib/uhd/examples/rx_ascii_art_dft \
  --freq 93.7e6 \
  --rate 2e6 \
  --gain 50 \
  --ant RX2 \
  --frame-rate 5
```

## Analysis Scripts

### analyze_with_dc_removal_pure.py
Analyzes sc16 IQ data files with DC offset removal:
```bash
python3 B210/scripts/analyze_with_dc_removal_pure.py /path/to/capture.dat
```

### auto_optimize.sh
Scans frequencies to find optimal settings (now uses sc16 format):
```bash
./B210/scripts/auto_optimize.sh
```
Results saved to: `/tmp/b210_optimization_results.txt`

## Troubleshooting

### "No signals detected"
1. Check antenna connections (RX2 or TX/RX)
2. Try different gain levels (40-70 dB)
3. Verify antenna covers frequency range
4. **Verify using `--type short`** (most common issue!)

### "Data looks corrupted / NaN values"
- **You forgot `--type short`** - float32 is broken on this clone!

### "Device not found"
```bash
uhd_find_devices
# Should show: serial=30AA038, name=Custom_SDR_B210
```

### "FPGA firmware errors"
Reinstall clone firmware:
```bash
cp "B210/firmware/Kintex-7 USRP_B210/需替换BIN文件/usrp_b210_fpga.bin" \
   /opt/homebrew/Cellar/uhd/4.9.0.1_1/share/uhd/images/
```

## Performance Notes

- **USB 3.0 required** for sustained rates > 10 MS/s
- **Sample rates tested:** 2 MS/s (reliable), up to 56 MS/s (theoretical)
- **Frequency range:** 70 MHz - 6 GHz (AD9361)
- **Gain range:** 0-76 dB (actual: 0-73 dB)

---

**Last Updated:** January 13, 2026
**Device Tested:** B210 Clone (Serial: 30AA038)
**UHD Version:** 4.9.0.1_1 on macOS
