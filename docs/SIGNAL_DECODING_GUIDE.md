# Signal Decoding Guide

Complete guide to detecting and decoding digital radio signals with USRP B210.

## Overview

This platform provides end-to-end signal intelligence:
1. **Spectrum Scanner** - Detect signals across 70 MHz - 6 GHz
2. **Signal Hunter** - Auto-detect and attempt decode
3. **Specialized Decoders** - P25, DMR, NXDN, D-STAR

## Quick Start

### 1. Scan for Signals

```bash
# Scan P25 800 MHz public safety band
cd /home/static/sdr-utilities/scripts
./spectrum_scanner.sh --start 851000000 --stop 869000000 --step 25000 --passes 5
```

### 2. Auto-Hunt and Decode

```bash
# Automatically find and decode P25 signals
./signal_hunter.sh --start 851000000 --stop 869000000 --mode p25
```

### 3. Manual P25 Decode

```bash
# Decode specific frequency
./p25_decoder.sh --freq 851000000 --gain 50
```

## Installed Decoders

### OP25 (P25 Phase 1/2)
- **Location**: `/home/static/op25/`
- **Modes**: Conventional, Trunking (EDACS, Motorola, P25)
- **Bands**: VHF, 700 MHz, 800 MHz public safety
- **Features**:
  - Voice decoding (IMBE vocoder)
  - Talkgroup following
  - Encryption detection
  - NAC filtering

### DSDcc (Digital Speech Decoder)
- **Protocols**: DMR, NXDN, D-STAR, ProVoice, P25
- **Use Case**: General digital voice decoder
- **Integration**: Via dsdcc command-line or GNU Radio blocks

## Common Frequencies

### P25 Public Safety

| Band    | Frequency Range      | Usage                    |
|---------|---------------------|--------------------------|
| VHF     | 162-174 MHz         | Fire, EMS, local PD      |
| 700 MHz | 763-775, 793-805 MHz| Public safety (narrowband)|
| 800 MHz | 851-869 MHz         | Public safety (most common)|

### DMR (Digital Mobile Radio)

| Band    | Frequency Range      | Usage                    |
|---------|---------------------|--------------------------|
| UHF     | 446-470 MHz         | Commercial, amateur      |
| VHF     | 144-148 MHz         | Amateur DMR repeaters    |

## Signal Hunter Workflow

The `signal_hunter.sh` script automates the detection-to-decode pipeline:

```
1. Spectrum Scan (multi-pass with averaging)
   ↓
2. Signal Analysis (find peaks above threshold)
   ↓
3. Signal Ranking (strongest to weakest)
   ↓
4. Auto-Decode (attempt decode on each signal)
```

**Example:**
```bash
# Hunt for P25 in 800 MHz band
./signal_hunter.sh \
    --start 851000000 \
    --stop 869000000 \
    --step 25000 \
    --threshold -60 \
    --passes 5 \
    --mode p25
```

**Output:**
```
Found 3 signal(s) above -60 dBm:

  Frequency          Power      Std Dev
  ----------------   --------   --------
  851.0125 MHz       -42.3 dBm  2.1 dB
  851.5000 MHz       -55.8 dBm  1.3 dB
  852.2375 MHz       -58.1 dBm  0.9 dB

Attempting decode...
Signal 1/3: 851.0125 MHz (-42.3 dBm)
[P25 decoder output...]
```

## P25 Decoder Options

### Basic Usage
```bash
./p25_decoder.sh --freq 851000000 --gain 50
```

### Advanced Options
```bash
./p25_decoder.sh \
    --freq 851000000 \      # Frequency in Hz
    --gain 60 \             # RX gain (30-70 dB typical)
    --nac 0x293 \           # Network Access Code (filter talkgroups)
    --squelch 50 \          # Squelch level
    --offset 0 \            # Frequency offset correction
    --ppm 0 \               # Clock drift correction
    --trunking \            # Enable trunking mode
    --verbose               # Detailed logging
```

### Trunking Mode

For trunked P25 systems (Motorola, EDACS):
```bash
./p25_decoder.sh --freq 851000000 --trunking
```

OP25 will:
- Follow control channel
- Track active talkgroups
- Switch frequencies automatically
- Decode voice channels

## Interpreting Results

### Signal Strength
- **-40 to -20 dBm**: Excellent (nearby transmission)
- **-60 to -40 dBm**: Good (decodable)
- **-80 to -60 dBm**: Weak (may decode)
- **< -80 dBm**: Very weak (likely won't decode)

### Standard Deviation
- **< 1 dB**: Continuous carrier
- **1-3 dB**: Intermittent signal (beaconing)
- **> 3 dB**: Bursty/noisy signal

### P25 Decoder Output

**Good Decode:**
```
P25 Phase 1
NAC: 0x293
TGID: 1234 (Police Dispatch)
Encryption: None
Signal: -45 dBm
Audio: Clear
```

**Bad Decode:**
```
P25: CRC errors
Signal: -75 dBm (too weak)
Try: increase gain, adjust antenna
```

## Troubleshooting

### No Signals Found

1. **Check antenna connection**
2. **Verify frequency range** - Are you scanning the right band?
3. **Lower threshold** - Try `--threshold -70` for weaker signals
4. **Increase gain** - Try `--gain 60-70`
5. **More passes** - Try `--passes 10` for intermittent signals

### Can't Decode Signal

1. **Wrong modulation** - P25 signal decoded as DMR won't work
2. **Encrypted** - P25 with encryption shows "encrypted voice"
3. **Too weak** - Signal below -70 dBm usually won't decode
4. **Wrong NAC** - P25 uses Network Access Codes to filter
5. **Trunking** - Control channel needs trunking mode enabled

### OP25 Errors

**"No USRP found"**
```bash
# Check USRP connection
uhd_find_devices
```

**"Underflow/Overflow"**
```bash
# USB 3.0 bandwidth issue - lower sample rate
./p25_decoder.sh --freq 851000000 --rate 500000
```

**"Cannot set sample rate"**
```bash
# USRP B210 supports 200 kHz - 56 MS/s
# For P25, 1 MS/s is typical
./p25_decoder.sh --freq 851000000 --rate 1000000
```

## Advanced: GNU Radio Integration

OP25 GNU Radio blocks are now installed:

```python
from gnuradio import op25_repeater

# Use in GNU Radio Companion
# Blocks available:
# - op25_repeater.p25_frame_assembler
# - op25_repeater.fsk4_demod_ff
# - op25_repeater.gardner_cc
# - op25_repeater.vocoder
```

## Security Research

### IMEI Catcher Detection

P25 systems can reveal:
- **System ID** - Network identification
- **Site ID** - Tower location
- **NAC** - Network access code
- **Talkgroups** - Active channels
- **Encryption status** - AES/DES detection

Monitor for:
- Unexpected control channels
- Changed System IDs
- Spoofed talkgroups
- Encryption status changes

### Defensive Monitoring

Use `signal_hunter.sh` in continuous mode:
```bash
# Monitor 800 MHz band every 5 minutes
while true; do
    ./signal_hunter.sh --start 851000000 --stop 869000000
    sleep 300
done
```

Log all detections to identify:
- New transmitters
- Changed frequencies
- Suspicious activity patterns

## Next Steps

1. **Try signal_hunter.sh** - Automated detection and decode
2. **Scan local public safety** - Find active P25 systems
3. **Decode LTE with srsRAN** - Cellular signal analysis
4. **Build GNU Radio flowgraphs** - Custom demodulators
5. **Explore DMR/NXDN** - Commercial radio systems

## References

- **OP25 Documentation**: `/home/static/op25/README.md`
- **DSDcc**: Digital Speech Decoder for multiple protocols
- **GNU Radio**: Software-defined radio framework
- **USRP B210**: 70 MHz - 6 GHz SDR hardware

## Script Locations

```
/home/static/sdr-utilities/scripts/
├── spectrum_scanner.sh   # Multi-pass spectrum analyzer
├── signal_hunter.sh      # Auto-detect and decode
├── p25_decoder.sh        # P25 Phase 1/2 decoder
└── cell_monitor.sh       # LTE cell scanner
```

---
**WARNING**: Only monitor frequencies you are legally authorized to receive. P25 public safety transmissions are not encrypted for transparency, but intercepting for unauthorized purposes may be illegal in your jurisdiction.
