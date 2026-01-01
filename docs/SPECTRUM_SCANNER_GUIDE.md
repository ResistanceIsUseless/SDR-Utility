# Wideband Spectrum Scanner Guide

## Overview

The spectrum scanner (`spectrum_scanner.sh`) performs **true wideband sweeps** across any frequency range the USRP B210 supports, not just LTE bands.

**Key difference from cell_monitor.sh:**
- `cell_monitor.sh`: LTE-specific, scans predefined EARFCN lists
- `spectrum_scanner.sh`: RF-agnostic, scans ANY frequency range with custom step size

---

## USRP B210 Capabilities

**Frequency Range:** 70 MHz to 6 GHz
**Sample Rate:** Up to 56 MS/s (61.44 MS/s instantaneous)
**Bandwidth:** Up to 56 MHz instantaneous

**This scanner can find:**
- FM radio stations
- Aviation communications
- Marine VHF
- TV broadcasts
- Cell towers (all technologies: 2G, 3G, 4G, 5G)
- WiFi networks
- Bluetooth devices
- GPS signals
- Unknown transmitters
- IMSI catchers (any frequency!)

---

## Quick Start Examples

### 1. Full Spectrum Scan (70 MHz - 6 GHz)

**WARNING:** Takes ~8 hours with 1 MHz steps!

```bash
# Full range, 1 MHz steps
./spectrum_scanner.sh

# Faster: 10 MHz steps (~45 minutes)
./spectrum_scanner.sh --step 10000000 --dwell 0.05
```

### 2. FM Broadcast Band (88-108 MHz)

```bash
# Find local FM stations
./spectrum_scanner.sh \
  --start 88000000 \
  --stop 108000000 \
  --step 100000 \
  --dwell 0.2
```

### 3. All Cell Bands (700 MHz - 2.7 GHz)

```bash
# Scan all common cellular frequencies
./spectrum_scanner.sh \
  --start 700000000 \
  --stop 2700000000 \
  --step 1000000 \
  --dwell 0.1
```

**Finds:**
- LTE Bands 2, 4, 5, 12, 13, 66, 71
- 3G/UMTS
- 2G/GSM
- Any IMSI catchers in this range!

### 4. WiFi 2.4 GHz Band

```bash
# Scan for WiFi networks and Bluetooth
./spectrum_scanner.sh \
  --start 2400000000 \
  --stop 2500000000 \
  --step 1000000 \
  --dwell 0.1
```

### 5. LTE Band 2 - DETAILED

```bash
# Very detailed scan (100 kHz steps)
./spectrum_scanner.sh \
  --start 1930000000 \
  --stop 1990000000 \
  --step 100000 \
  --dwell 0.5 \
  --gain 50
```

**Use case:** Find ALL signals in Band 2, not just LTE cells

### 6. Quick Reconnaissance

```bash
# Fast overview (10 MHz steps, quick dwell)
./spectrum_scanner.sh \
  --start 70000000 \
  --stop 6000000000 \
  --step 10000000 \
  --dwell 0.05
```

**Time:** ~45 minutes
**Use case:** Quick survey to find active frequency ranges

---

## Command Line Options

```bash
./spectrum_scanner.sh [OPTIONS]

OPTIONS:
  -s, --start FREQ    Start frequency in Hz
  -e, --stop FREQ     Stop frequency in Hz
  -t, --step SIZE     Step size in Hz
  -d, --dwell TIME    Dwell time in seconds
  -g, --gain GAIN     RX gain in dB (default: 40)
  -o, --output DIR    Output directory
  -r, --rate RATE     Sample rate in Hz
  -h, --help          Show help
```

---

## Output Files

Each scan creates:

1. **CSV Data** (`scan_TIMESTAMP.csv`)
   ```csv
   frequency_hz,power_db,timestamp
   88000000,-45.3,2025-12-31T22:00:01
   88100000,-62.1,2025-12-31T22:00:02
   ...
   ```

2. **Report** (`scan_TIMESTAMP_report.txt`)
   - Top 20 strongest signals
   - Band identification
   - Summary statistics

3. **Peaks List** (`scan_TIMESTAMP_peaks.csv`)
   - All signals > -60 dBm
   - Sorted by strength

4. **Plot** (`scan_TIMESTAMP_plot.png`) - if gnuplot available
   - Visual spectrum graph

**Location:** `/home/static/spectrum_scans/`

---

## Frequency Bands of Interest

### Broadcast & Aviation
```bash
# FM Radio (88-108 MHz)
./spectrum_scanner.sh -s 88e6 -e 108e6 -t 100e3

# Civilian Aviation (108-137 MHz)
./spectrum_scanner.sh -s 108e6 -e 137e6 -t 25e3

# VHF Marine (156-162 MHz)
./spectrum_scanner.sh -s 156e6 -e 162e6 -t 25e3
```

### Cellular (2G/3G/4G/5G)
```bash
# LTE Band 12/13 (700 MHz) - First Responder/Verizon
./spectrum_scanner.sh -s 698e6 -e 806e6 -t 1e6

# GSM 850 / LTE Band 5
./spectrum_scanner.sh -s 824e6 -e 894e6 -t 200e3

# LTE Band 2 (PCS) - AT&T/T-Mobile
./spectrum_scanner.sh -s 1930e6 -e 1990e6 -t 100e3

# LTE Band 4/66 (AWS)
./spectrum_scanner.sh -s 2110e6 -e 2200e6 -t 1e6

# LTE Band 7 (2.6 GHz)
./spectrum_scanner.sh -s 2620e6 -e 2690e6 -t 1e6
```

### WiFi & Bluetooth
```bash
# WiFi 2.4 GHz + Bluetooth
./spectrum_scanner.sh -s 2400e6 -e 2500e6 -t 1e6

# WiFi 5 GHz
./spectrum_scanner.sh -s 5150e6 -e 5850e6 -t 1e6
```

### GPS
```bash
# GPS L1
./spectrum_scanner.sh -s 1575e6 -e 1576e6 -t 10e3 -d 1.0
```

---

## IMSI Catcher Detection Use Case

**Scenario:** Attacker uses IMSI catcher on unusual frequency to avoid detection

**Problem:** `cell_monitor.sh` only checks LTE bands - might miss it!

**Solution:** Full spectrum scan

```bash
# Scan 700 MHz - 3 GHz (covers most cellular + some buffer)
./spectrum_scanner.sh \
  --start 700000000 \
  --stop 3000000000 \
  --step 1000000 \
  --output /home/static/imsi_catcher_scans

# Check results for unexpected strong signals
grep -v ",-999" /home/static/imsi_catcher_scans/scan_*_peaks.csv
```

**Look for:**
- Strong signals (-20 to -30 dBm) outside LTE bands
- Isolated peaks not matching known services
- Signals that appear/disappear quickly

---

## Performance Optimization

### Speed vs Detail Trade-off

**Fast Survey (45 min):**
```bash
./spectrum_scanner.sh -t 10000000 -d 0.05  # 10 MHz steps, 50ms dwell
```

**Detailed Analysis (8 hours):**
```bash
./spectrum_scanner.sh -t 1000000 -d 0.1    # 1 MHz steps, 100ms dwell
```

**Ultra-Detailed (days!):**
```bash
./spectrum_scanner.sh -t 100000 -d 0.5     # 100 kHz steps, 500ms dwell
```

### USB 3.0 Optimization

With USB 3.0 working, you can use higher sample rates:

```bash
# High sample rate for better accuracy
./spectrum_scanner.sh --rate 30000000  # 30 MS/s
```

**Trade-off:**
- Higher rate = better frequency resolution
- Higher rate = more CPU usage
- Recommended: 20 MS/s (default)

### Python Fast Scanner

If you have `python3-uhd` installed:

```bash
# First run creates fast_scanner.py
./spectrum_scanner.sh ...

# Automatically uses Python version if available
# 10-100x faster than bash version!
```

**Install Python UHD:**
```bash
sudo apt-get install python3-uhd
# Or pip3 install uhd (if available)
```

---

## Comparison: Spectrum Scanner vs Cell Monitor

| Feature | spectrum_scanner.sh | cell_monitor.sh |
|---------|---------------------|-----------------|
| **Frequency Range** | Any (70 MHz - 6 GHz) | LTE bands only |
| **Step Size** | Custom (1 Hz - 1 GHz) | Fixed (EARFCN) |
| **Detects** | All RF signals | LTE cells only |
| **Speed** | Slower (must sweep) | Faster (knows where to look) |
| **Output** | Power measurements | Cell parameters |
| **Use Case** | RF reconnaissance | IMSI catcher detection |
| **Finds IMSI Catchers** | YES (any frequency) | Only if using LTE bands |

**Recommendation:**
- **Daily monitoring:** Use `cell_monitor.sh` (faster, LTE-specific)
- **Initial survey:** Use `spectrum_scanner.sh` (find everything)
- **Suspicious activity:** Use `spectrum_scanner.sh` (verify it's not on odd frequency)

---

## Integration with Cell Monitor

### Workflow 1: Initial Survey

```bash
# Step 1: Full spectrum scan to find active ranges
./spectrum_scanner.sh -s 700e6 -e 3000e6 -t 10e6 -d 0.05

# Step 2: Review peaks
cat /home/static/spectrum_scans/scan_*_report.txt

# Step 3: Focus on cellular bands with cell_monitor
./cell_monitor.sh quick

# Step 4: Document baseline
cp /home/static/spectrum_scans/scan_*.csv baseline_spectrum.csv
```

### Workflow 2: Anomaly Investigation

```bash
# Alert from cell_monitor.sh: Unknown cell detected

# Step 1: Verify it's really LTE
./cell_monitor.sh inspect 1935.0 192 50 4

# Step 2: Scan surrounding spectrum for other activity
./spectrum_scanner.sh -s 1900e6 -e 2000e6 -t 100e3

# Step 3: Check if there's activity outside LTE bands
./spectrum_scanner.sh -s 700e6 -e 3000e6 -t 10e6

# Step 4: Compare with baseline
diff baseline_spectrum.csv /home/static/spectrum_scans/scan_*.csv
```

---

## Advanced Usage

### 1. Automated Baseline Tracking

```bash
# Cron job: Scan every night at 2 AM
0 2 * * * /home/static/spectrum_scanner.sh -s 700e6 -e 3000e6 -t 10e6 -d 0.05
```

### 2. Differential Scanning

```bash
# Scan 1 (baseline)
./spectrum_scanner.sh -s 1900e6 -e 2000e6 -o baseline

# Later: Scan 2 (check for changes)
./spectrum_scanner.sh -s 1900e6 -e 2000e6 -o current

# Compare
diff baseline/scan_*.csv current/scan_*.csv | grep "^>" | \
  awk -F',' '{print $1, $2}' | while read freq power; do
    if (( $(echo "$power > -40" | bc -l) )); then
        echo "NEW STRONG SIGNAL: $freq Hz @ $power dBm"
    fi
done
```

### 3. Multi-Band Sweep Script

```bash
#!/bin/bash
# Scan all cellular bands sequentially

BANDS=(
    "700000000 806000000"    # Band 12/13
    "824000000 894000000"    # Band 5
    "1930000000 1990000000"  # Band 2
    "2110000000 2200000000"  # Band 4/66
    "2620000000 2690000000"  # Band 7
)

for band in "${BANDS[@]}"; do
    ./spectrum_scanner.sh -s $(echo $band | cut -d' ' -f1) \
                          -e $(echo $band | cut -d' ' -f2) \
                          -t 1000000 -d 0.1
    sleep 5
done
```

---

## Troubleshooting

### No Data / All -999 Values

**Problem:** Power readings show -999

**Causes:**
1. No UHD power measurement tools installed
2. USRP not connected
3. Frequency out of B210 range

**Fix:**
```bash
# Test USRP
uhd_usrp_probe

# If Python UHD available, scanner auto-uses it
python3 -c "import uhd; print('UHD Python available')"
```

### Scan Too Slow

**Problem:** Taking forever

**Solutions:**
1. Increase step size: `--step 10000000` (10 MHz)
2. Reduce dwell time: `--dwell 0.05` (50ms)
3. Install python3-uhd for 100x speedup
4. Scan smaller ranges

### High CPU Usage

**Problem:** CPU at 100%

**Causes:**
- High sample rate
- Fast sweeping
- Plotting enabled

**Fix:**
```bash
# Lower sample rate
./spectrum_scanner.sh --rate 10000000

# Disable plotting
export GNUPLOT=""
```

---

## Safety & Legal

**Legal to scan:**
✅ Receiving signals (passive)
✅ Measuring power levels
✅ Identifying frequencies
✅ All frequency ranges

**NOT legal:**
❌ Transmitting without license
❌ Jamming signals
❌ Decoding encrypted communications
❌ Intercepting private communications

**This scanner:**
- Receives only (no TX)
- Measures power (no decoding)
- Public information only

---

## Example Output

```
$ ./spectrum_scanner.sh -s 1930e6 -e 1990e6 -t 1e6

========================================
  Wideband Spectrum Scanner - USRP B210
========================================

Scan Parameters:
  Start: 1930.00 MHz
  Stop:  1990.00 MHz
  Step:  1.00 MHz
  Dwell: 0.1s per step
  Gain:  40 dB
  Rate:  20.00 MHz

  Steps: 61
  Time:  0.1 minutes

Starting scan at 2025-12-31 22:00:00
Output: /home/static/spectrum_scans/scan_20251231_220000.csv

[100%] 1990.00 MHz: -45.2 dB

Scan complete!
Results: /home/static/spectrum_scans/scan_20251231_220000.csv

TOP 20 STRONGEST SIGNALS:
================================================================================
  Frequency          Power (dBm)    Band/Service (estimated)
--------------------------------------------------------------------------------
  1935.00 MHz        -31.0          LTE Band 2 (PCS)
  1935.30 MHz        -17.5          LTE Band 2 (PCS)
  1960.00 MHz        -52.3          LTE Band 2 (PCS)
  ...
```

---

## Summary

You now have **true wideband scanning capability**:

**What spectrum_scanner.sh does that cell_monitor.sh doesn't:**
- ✅ Scans ANY frequency (70 MHz - 6 GHz)
- ✅ Custom step size (1 Hz to 1 GHz)
- ✅ Finds non-LTE signals (FM, WiFi, GPS, etc.)
- ✅ Detects IMSI catchers on unusual frequencies
- ✅ Complete RF reconnaissance

**When to use which:**

| Scenario | Tool |
|----------|------|
| Daily LTE monitoring | `cell_monitor.sh` |
| Initial area survey | `spectrum_scanner.sh` |
| Find all RF activity | `spectrum_scanner.sh` |
| Track specific cells | `cell_monitor.sh` |
| Investigate anomaly | Both! |

**Next steps:**
1. Run initial full scan: `./spectrum_scanner.sh -s 700e6 -e 3000e6 -t 10e6`
2. Review results
3. Set up daily automated scans
4. Integrate with cell_monitor.sh for complete coverage

---

**You now have complete RF spectrum awareness!**
