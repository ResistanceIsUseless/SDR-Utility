# B210 Signal Optimization Guide

Since you've successfully detected LTE before, the hardware works. Here's how to optimize signal strength:

## Quick Checklist

### 1. Antenna Connection
- [ ] **ANT500 connected to RX2 port** (not TX/RX)
- [ ] Antenna fully screwed in (hand tight)
- [ ] No damage to SMA connector
- [ ] Cable not pinched

### 2. Antenna Positioning
- [ ] Near window (FM signals better outdoors)
- [ ] Vertical orientation for FM
- [ ] Away from metal objects
- [ ] Not near computer/USB hub (EMI)

### 3. Software Settings
- [ ] Using **RX2 antenna** in command: `--ant RX2`
- [ ] Gain 40-60 dB for FM: `--gain 50`
- [ ] Sample rate 1-2 MS/s: `--rate 2e6`

### 4. LED Indicators (CRITICAL)
Watch the LEDs on your B210 while receiving:
- **RX2 LED should turn BLUE** when receiving
- If it stays off = not receiving on that port
- If STATUS LED off = firmware not loaded

## Immediate Test Commands

### Best Settings for FM Reception

```bash
# Optimal FM reception on RX2
rx_ascii_art_dft --freq 93.7e6 --rate 2e6 --gain 55 --ant RX2 --ref-lvl -30

# Try different gain if too noisy
rx_ascii_art_dft --freq 93.7e6 --rate 2e6 --gain 45 --ant RX2 --ref-lvl -30

# Scan wider FM band
rx_ascii_art_dft --freq 98e6 --rate 10e6 --gain 50 --ant RX2 --ref-lvl -30
```

### Quick Gain Test

```bash
# Test at multiple gains to find optimal
for gain in 30 40 50 60 70; do
    echo "Testing gain: $gain"
    rx_samples_to_file --freq 93.7e6 --rate 2e6 --gain $gain --ant RX2 --duration 1 --file test_g$gain.dat
    python3 B210/scripts/analyze_signal.py test_g$gain.dat
done
```

## Common Issues

### Issue: Weak Signal Despite Good Antenna

**Possible causes**:
1. **Frequency offset** - Clone may have slight oscillator offset
   - Try ±50 kHz: `--freq 93.65e6` or `--freq 93.75e6`

2. **Wrong antenna port selected**
   - Ensure using: `--ant RX2` (not TX/RX)

3. **Gain too high** - Causes noise floor to rise
   - Try gain 40-50 instead of 60-76

4. **Sample rate too high** - USB 2.0 overhead
   - Try 1 MS/s instead of 2 MS/s

### Issue: All Noise, No Peaks

**Check**:
```bash
# Verify antenna switch is working
rx_samples_to_file --freq 100e6 --rate 1e6 --gain 50 --ant RX2 --duration 1 --file test_rx2.dat
rx_samples_to_file --freq 100e6 --rate 1e6 --gain 50 --ant "TX/RX" --duration 1 --file test_txrx.dat

# Compare power levels
python3 B210/scripts/analyze_signal.py test_rx2.dat
python3 B210/scripts/analyze_signal.py test_txrx.dat

# Should see power difference between ports
```

### Issue: Data All Zeros (New Problem)

If you're suddenly getting zeros when it worked before:
```bash
# 1. Reload firmware
uhd_find_devices

# 2. Check device probe
uhd_usrp_probe --args="serial=30AA038" | grep -E "(LO|Register|loopback)"

# Should see: "Register loopback test passed"
```

## Optimal Settings by Signal Type

### FM Radio (88-108 MHz)
```bash
rx_ascii_art_dft --freq 98e6 --rate 2e6 --gain 50 --ant RX2 --bw 200e3
```

### LTE (You've detected this before!)
```bash
# LTE Band 4 (AWS): 2110-2155 MHz downlink
rx_ascii_art_dft --freq 2132.5e6 --rate 10e6 --gain 50 --ant RX2

# LTE Band 13: 746-756 MHz downlink
rx_ascii_art_dft --freq 751e6 --rate 5e6 --gain 60 --ant RX2

# LTE Band 2: 1930-1990 MHz downlink
rx_ascii_art_dft --freq 1960e6 --rate 10e6 --gain 50 --ant RX2
```

### WiFi 2.4 GHz
```bash
rx_ascii_art_dft --freq 2.437e9 --rate 20e6 --gain 40 --ant RX2
```

### GSM 900
```bash
rx_ascii_art_dft --freq 945e6 --rate 5e6 --gain 55 --ant RX2
```

## Run Optimization Script

```bash
# Comprehensive test of all settings
./B210/scripts/optimize_rx.sh
```

This will test:
1. Both antenna ports
2. Multiple gain settings
3. Different sample rates
4. Frequency offset calibration
5. LED indicator check

## ANT500 Antenna Specs

The ANT500 is typically a wideband antenna. Check yours for:
- **Frequency range**: Should cover 70-6000 MHz
- **Connector**: SMA male
- **Length**: Usually telescoping or flexible

If it's a different antenna, verify it covers FM band (88-108 MHz).

## Advanced: Frequency Calibration

If signals appear consistently off-frequency:

```bash
# Test frequency offset
for offset in -100e3 -50e3 -25e3 0 25e3 50e3 100e3; do
    freq=$(python3 -c "print(int(93.7e6 + $offset))")
    echo "Testing offset: $offset Hz"
    rx_ascii_art_dft --freq $freq --rate 2e6 --gain 50 --ant RX2 2>/dev/null | head -20 &
    PID=$!
    sleep 3
    kill $PID 2>/dev/null
    wait $PID 2>/dev/null
done
```

## Expected Signal Levels

### Good FM Station (Local)
- Noise floor: -60 to -70 dB
- Signal peak: -20 to -30 dB
- SNR: 30-40 dB

### Weak FM Station (Distant)
- Noise floor: -60 to -70 dB
- Signal peak: -40 to -50 dB
- SNR: 10-20 dB

### No Signal (Just Noise)
- Flat spectrum at -60 dB
- No peaks above noise floor
- SNR: < 5 dB

## Compare with Previous Success

Since you detected LTE before:
1. Were you using same antenna?
2. Same location?
3. Same gain settings?
4. Was RX2 LED turning blue?
5. Any system changes (macOS update, USB hub, etc.)?

## USB 3.0 vs USB 2.0

Currently operating in USB 2.0 mode. To get USB 3.0:
- Use native USB-C port (not hub/dock)
- Use USB 3.0 rated cable
- Check System Report to verify SuperSpeed

```bash
system_profiler SPUSBDataType | grep -A 10 "2500"
# Look for "Speed: Up to 5 Gb/s" (USB 3.0)
# vs "Speed: Up to 480 Mb/s" (USB 2.0)
```

USB 2.0 limits sample rate to ~30 MS/s, but that's fine for FM (only need 2 MS/s).

---

**Bottom Line**: Run the optimization script, watch the RX2 LED, and adjust gain. The hardware works - it's about finding the right settings for your location.
