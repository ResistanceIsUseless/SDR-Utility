# UHD Commands Reference

All UHD example commands are now in your PATH. Open a **new terminal** for the changes to take effect.

---

## Quick Start Commands

### Device Detection & Info
```bash
uhd_find_devices              # Find all connected USRP devices
uhd_usrp_probe                # Detailed device information
uhd_config_info               # Show UHD installation info
```

---

## RX (Receive) Commands

### ASCII Spectrum Visualizer ⭐
```bash
rx_ascii_art_dft --freq 100e6 --rate 1e6 --gain 20
```

**Common frequencies:**
- FM Radio: `--freq 98e6` (adjust to local station)
- Cell bands: `--freq 900e6`
- WiFi: `--freq 2.45e9`

### Record to File
```bash
rx_samples_to_file --freq 100e6 --rate 1e6 --gain 20 --duration 10 capture.dat
```

### Advanced RX
```bash
rx_multi_samples               # Multi-channel receive
rx_samples_to_udp             # Stream to UDP
rx_timed_samples              # Timed sample capture
```

---

## TX (Transmit) Commands

⚠️ **WARNING**: These commands transmit RF signals. Ensure proper licensing and antenna setup.

### Waveform Generator
```bash
tx_waveforms --freq 915e6 --rate 1e6 --gain 10 --wave-type SINE
```

**Wave types:** CONST, SQUARE, RAMP, SINE

### Transmit from File
```bash
tx_samples_from_file --freq 915e6 --rate 1e6 --gain 10 samples.dat
```

---

## Testing & Benchmarking

### Performance Benchmark ⭐
```bash
benchmark_rate --rx_rate 10e6 --tx_rate 10e6 --duration 30
```

Tests sustained RX/TX rates and detects dropped samples.

### Latency Test
```bash
latency_test --duration 10
```

### Timed Commands Test
```bash
test_timed_commands            # Test command timing precision
```

### Clock Sync Test
```bash
test_clock_synch               # Test clock synchronization
```

### PPS Input Test
```bash
test_pps_input                 # Test pulse-per-second input
```

---

## GPS & Timing

### Sync to GPS
```bash
sync_to_gps                    # Synchronize device to GPS
```

---

## Hardware Tests

### GPIO Control
```bash
gpio --list                    # List GPIO pins
gpio --set <pin>               # Set GPIO pin
```

### SPI Interface
```bash
spi                            # SPI bus testing
```

---

## RFNoC (Radio Network-on-Chip) Commands

For advanced FPGA block control:

```bash
rfnoc_nullsource_ce_rx         # Null source to RX
rfnoc_radio_loopback          # Radio loopback test
rfnoc_replay_samples_from_file # Replay samples via RFNoC
rfnoc_rx_to_file              # RFNoC RX to file
```

---

## Common Parameter Reference

### Frequency (--freq)
- Format: Hz (e.g., `100e6` = 100 MHz)
- Range: 50 MHz to 6 GHz (for B210)
- Examples:
  - FM: `88e6` to `108e6`
  - GSM900: `900e6`
  - WiFi 2.4G: `2.4e9`
  - WiFi 5G: `5.5e9`

### Sample Rate (--rate)
- Format: Samples/second (e.g., `1e6` = 1 MS/s)
- Range: Up to 56 MS/s (USB 3.0), ~30 MS/s (USB 2.0)
- Common rates:
  - `1e6` - 1 MS/s (narrowband)
  - `5e6` - 5 MS/s (wideband FM)
  - `10e6` - 10 MS/s (moderate)
  - `20e6` - 20 MS/s (wideband)

### Gain (--gain)
- Format: dB (e.g., `20`)
- Range: 0 to 76 dB
- Guidelines:
  - `0-20` dB: Strong nearby signals
  - `20-40` dB: Medium strength signals
  - `40-60` dB: Weak signals
  - `60-76` dB: Very weak/distant signals
  - Too high = noise amplification

### Duration (--duration)
- Format: Seconds (e.g., `10`)
- Controls capture/transmit time
- Use `Ctrl+C` to stop if not specified

---

## Example Workflows

### 1. Find Strong Signals
```bash
# Scan FM radio band
rx_ascii_art_dft --freq 98e6 --rate 10e6 --gain 20
```

### 2. Record and Analyze
```bash
# Record 30 seconds
rx_samples_to_file --freq 100e6 --rate 1e6 --gain 20 --duration 30 signal.dat

# Check file size
ls -lh signal.dat
```

### 3. Performance Test
```bash
# Test max sustained rate
benchmark_rate --rx_rate 20e6 --tx_rate 20e6 --duration 60
```

### 4. Loopback Test
```bash
# Terminal 1: Start RX
rx_samples_to_file --freq 915e6 --rate 1e6 --gain 20 loopback.dat

# Terminal 2: Start TX (with cable connecting TX to RX)
tx_waveforms --freq 915e6 --rate 1e6 --gain 10 --wave-type SINE
```

---

## Troubleshooting Commands

### Check for Overruns/Underruns
```bash
# Watch for 'O' (overrun) or 'U' (underrun) indicators
benchmark_rate --rx_rate 30e6 --duration 60
```

### Test Different USB Speeds
```bash
# Start low
benchmark_rate --rx_rate 1e6 --duration 10

# Increase gradually
benchmark_rate --rx_rate 5e6 --duration 10
benchmark_rate --rx_rate 10e6 --duration 10
benchmark_rate --rx_rate 20e6 --duration 10
```

### Verify Device Communication
```bash
uhd_usrp_probe --args="serial=30AA038" 2>&1 | grep -E "(loopback|PASS|FAIL)"
```

---

## Tips

1. **Start with Low Gain**: Begin with `--gain 10` and increase if needed
2. **Check Your Rate**: Use `benchmark_rate` to find max sustainable rate for your setup
3. **USB 3.0 Matters**: For rates >30 MS/s, use USB 3.0 port and cable
4. **Use Ctrl+C to Stop**: Most commands run continuously until interrupted
5. **Check File Sizes**: RX captures create large files quickly
   - 1 MS/s = ~8 MB/second (for complex samples)
   - 10 MS/s = ~80 MB/second
6. **Antenna Required**: Connect appropriate antenna for best results

---

## All Available Commands

To see all available UHD example commands:
```bash
ls /opt/homebrew/lib/uhd/examples/
```

Current count: **28 commands**

---

## PATH Configuration

UHD commands added to your PATH via `~/.zshrc`:
```bash
export PATH="/opt/homebrew/lib/uhd/examples:$PATH"
```

**Reload your shell** to apply:
```bash
# Start a new terminal, or:
source ~/.zshrc
```

---

## Getting Help

Each command has built-in help:
```bash
rx_ascii_art_dft --help
benchmark_rate --help
tx_waveforms --help
```

---

**Last Updated**: 2026-01-13
**UHD Version**: 4.9.0.1
**Device**: Custom_SDR_B210 (Serial: 30AA038)
