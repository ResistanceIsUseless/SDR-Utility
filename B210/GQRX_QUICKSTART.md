# GQRX Quick Start Guide for B210

## Launch GQRX

```bash
gqrx
```

## Initial Configuration

When the "Configure I/O devices" window appears:

### Device Settings
```
Device:        UHD
Device string: serial=30AA038,type=b200
Input rate:    2000000
Decimation:    None
Bandwidth:     0 (auto)
Antenna:       RX2
```

Click **OK**

## Your Optimal Settings (From Auto-Optimizer)

### Best Signal: WiFi Channel 11
```
Frequency:    2462000000 Hz (2462 MHz)
Mode:         WFM (Wide FM) or RAW
Filter Width: Auto
RF Gain:      50 dB
```

### FM Radio: The River 93.7
```
Frequency:    93700000 Hz (93.7 MHz)
Mode:         WFM (Wide FM)
Filter Width: 200 kHz
RF Gain:      50 dB
```

### LTE Band 13
```
Frequency:    746000000 Hz (746 MHz)
Mode:         RAW
Filter Width: 2 MHz
RF Gain:      60 dB
```

## Controls

**Play/Stop:** Click the power button (top left)
**Tune:** Click on the waterfall or use frequency selector
**Gain:** Slide the "RF" gain slider (50-60 dB works best)
**Record:** Click File → Start I/Q Recording

## Tips

1. **Strong signals:** Keep gain 40-60 dB to avoid saturation
2. **Weak signals:** Increase gain to 70 dB
3. **Waterfall colors:** Right-click waterfall → Settings
4. **FFT size:** Larger = more detail, smaller = faster updates
5. **Audio demod:** Select mode (WFM for FM radio, AM for AM radio)

## Keyboard Shortcuts

- `Space`: Start/Stop
- `Up/Down`: Change frequency
- `F`: Toggle full screen
- `S`: Take screenshot
- `R`: Start/stop recording

## Recording IQ Data

To save raw IQ samples for later analysis:

1. Click **File → Start I/Q Recording**
2. Choose location and filename
3. Format will be **sc16** (16-bit signed complex) - the working format!
4. Click **Stop I/Q Recording** when done

## Advantages Over SDR++

- ✅ No firmware fix needed
- ✅ Native UHD support
- ✅ Better signal analysis tools
- ✅ Bookmarks for frequencies
- ✅ Professional-grade waterfall
- ✅ Works perfectly with B210 clones

## All Your Detected Signals

Based on auto-optimizer results:

| Frequency | Description | Gain | SNR |
|-----------|-------------|------|-----|
| 2462 MHz | WiFi Ch 11 | 50 dB | 22.3 dB |
| 1930 MHz | PCS/LTE | 50 dB | 20.4 dB |
| 746 MHz | LTE Band 13 | 60 dB | 17.0 dB |
| 751 MHz | LTE Band 13 | 60 dB | 16.5 dB |
| 102.7 MHz | FM Radio | 50 dB | 14.5 dB |
| 98.1 MHz | FM Radio | 50 dB | 13.7 dB |
| 93.7 MHz | The River FM | 50 dB | 14.7 dB |

Just plug these into GQRX and enjoy!

---

**Bottom Line:** GQRX is the easiest path to using your B210 clone with a GUI. No firmware compilation needed, works with sc16 format perfectly.
