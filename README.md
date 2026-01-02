# SDR Utilities - LTE Security Research Platform

Complete toolkit for LTE security research, IMSI catcher detection, and spectrum analysis using USRP B210.

**Platform:** USRP B210 over USB 3.0
**Software:** srsRAN 4G, UHD 4.9.0
**Status:** ✅ Fully Operational

---

## Contents

### Scripts (`scripts/`)

| Script | Purpose | Output |
|--------|---------|--------|
| `cell_monitor.sh` | LTE cell monitoring & IMSI catcher detection | Cell database, alerts |
| `spectrum_scanner.sh` | Wideband RF spectrum scanner (70 MHz - 6 GHz) | Power measurements, plots |
| `signal_hunter.sh` | Auto-detect and decode digital radio signals | Decoded audio, logs |
| `p25_decoder.sh` | P25 Phase 1/2 decoder (conventional & trunking) | Voice audio, metadata |

### Documentation (`docs/`)

| Document | Content |
|----------|---------|
| `PROJECT_SUMMARY.md` | Complete project overview & status |
| `defensive_monitoring_guide.md` | IMSI catcher detection guide |
| `SPECTRUM_SCANNER_GUIDE.md` | Spectrum scanner usage |
| `SIGNAL_DECODING_GUIDE.md` | P25/DMR/NXDN signal decoding |
| `lab_enodeb_guide.md` | Lab eNodeB setup (RF-isolated only!) |
| `usb3_lte_decode_report.md` | USB 3.0 validation & performance |

### Configurations (`configs/`)

| File | Purpose |
|------|---------|
| `cell_database.json` | Known legitimate cells baseline |
| `lab_enb.conf` | eNodeB configuration (lab use only) |
| `lab_epc.conf` | Core network configuration |
| `user_db.csv` | Subscriber database template |
| `ue_sib_decode.conf` | UE configuration for SIB decode |

---

## Quick Start

### 1. Defensive Monitoring

Detect IMSI catchers and rogue base stations:

```bash
# Quick scan (baseline)
cd scripts
./cell_monitor.sh quick

# Continuous monitoring
./cell_monitor.sh monitor &

# Check alerts
tail -f /home/static/cell_monitoring/alerts.log
```

### 2. Spectrum Analysis

Scan any frequency range:

```bash
# Full LTE bands (700 MHz - 2.7 GHz)
./spectrum_scanner.sh --start 700e6 --stop 2700e6 --step 1e6

# WiFi 2.4 GHz
./spectrum_scanner.sh --start 2400e6 --stop 2500e6 --step 1e6

# FM broadcast
./spectrum_scanner.sh --start 88e6 --stop 108e6 --step 100e3
```

### 3. Signal Decoding (P25/DMR/NXDN)

Auto-detect and decode digital radio signals:

```bash
# Auto-hunt for P25 in 800 MHz public safety band
./signal_hunter.sh --start 851e6 --stop 869e6 --mode p25

# Decode specific P25 frequency
./p25_decoder.sh --freq 851000000 --gain 50

# VHF public safety
./signal_hunter.sh --start 162e6 --stop 174e6 --mode p25
```

### 4. Lab Testing (RF-Isolated Only!)

⚠️ **Requires Faraday cage and own devices only!**

See `docs/lab_enodeb_guide.md` for complete safety procedures.

---

## Features

### Cell Monitoring
- ✅ LTE Band 2, 4, 12, 66 support
- ✅ Real-time cell parameter tracking
- ✅ New cell detection
- ✅ Power anomaly alerts
- ✅ Automated baseline creation
- ✅ MIB decode capability

### Spectrum Scanner
- ✅ 70 MHz - 6 GHz coverage (USRP B210 range)
- ✅ Custom step size (1 Hz to 1 GHz)
- ✅ Real-time RSSI display
- ✅ Multi-pass averaging (detect intermittent signals)
- ✅ Statistical analysis (avg, min, max, std dev)
- ✅ CSV data export
- ✅ Peak detection
- ✅ Automatic band identification
- ✅ Python fast mode (100x faster)

### Signal Decoding
- ✅ P25 Phase 1/2 (OP25 integration)
- ✅ Conventional & trunking modes
- ✅ Auto-detect and hunt mode
- ✅ Voice decoding (IMBE vocoder)
- ✅ DMR/NXDN support (dsdcc)
- ✅ Automatic signal ranking
- ✅ Multi-protocol detection

### Lab Environment
- ✅ Complete eNodeB + EPC
- ✅ IMEI/IMSI capture
- ✅ Security research tools
- ✅ Safety checklists

---

## Requirements

### Hardware
- USRP B210 (or compatible SDR)
- USB 3.0 connection (critical for performance)
- Antenna (appropriate for frequency range)
- (Optional) Faraday cage for lab testing

### Software
- srsRAN 4G (23.04.0+)
- UHD (4.9.0+)
- Python 3 with UHD bindings (for fast scanning)
- OP25 (P25 decoder)
- dsdcc (DMR/NXDN/D-STAR decoder)
- GNU Radio 3.10+
- gnuplot (optional, for plots)

### Installation

```bash
# Install srsRAN
sudo apt-get install srsran

# Install UHD
sudo apt-get install uhd-host python3-uhd

# Install GNU Radio and decoders
sudo apt-get install gnuradio gnuradio-dev dsdcc

# Install OP25 (P25 decoder)
cd /home/static
git clone https://github.com/boatbod/op25.git
cd op25
sudo ./install.sh -f

# Download UHD images
sudo uhd_images_downloader

# Verify USRP
uhd_usrp_probe

# Make scripts executable
chmod +x scripts/*.sh
```

---

## USB 3.0 Performance

**Critical:** USB 3.0 is required for MIB decode and advanced features.

| Feature | USB 2.0 | USB 3.0 |
|---------|---------|---------|
| Sample Rate | 2-3 MS/s | 23.04 MS/s |
| MIB Decode | ❌ Failed | ✅ Success |
| PDSCH Decode | ❌ No | ✅ Yes |
| Band Scan | ⚠️ Overflows | ✅ Stable |

**Verify USB 3.0:**
```bash
lsusb -t | grep 5000M
# Should show USRP at 5000M
```

---

## Detection Capabilities

### What Can Be Detected

**IMSI Catchers:**
- ✅ New unknown cells
- ✅ High power anomalies (>-20 dBm)
- ✅ Cell parameter changes
- ✅ Unusual frequencies
- ✅ Cell ID fluctuations

**Other Signals:**
- ✅ FM radio stations
- ✅ WiFi networks (2.4 & 5 GHz)
- ✅ Bluetooth devices
- ✅ GPS signals
- ✅ Unknown transmitters

### Detection Methods

1. **Baseline Comparison** - Track normal cells
2. **Power Threshold** - Alert on strong signals
3. **Parameter Stability** - Detect changes
4. **Spectrum Sweep** - Find activity outside LTE bands

---

## Example Workflows

### Daily Security Monitoring

```bash
# Morning baseline
./cell_monitor.sh quick

# Start monitoring
./cell_monitor.sh monitor &

# Evening: Review alerts
grep -i "alert" /home/static/cell_monitoring/alerts.log
```

### Investigate Suspicious Activity

```bash
# Alert triggered - investigate

# 1. Verify with cell monitor
./cell_monitor.sh inspect <freq> <pci> <prb> <ports>

# 2. Scan surrounding spectrum
./spectrum_scanner.sh -s <freq-10e6> -e <freq+10e6> -t 100e3

# 3. Check if outside LTE bands
./spectrum_scanner.sh -s 700e6 -e 3000e6 -t 10e6
```

### Initial Area Survey

```bash
# 1. Full spectrum scan
./spectrum_scanner.sh -s 700e6 -e 3000e6 -t 10e6

# 2. LTE-specific scan
./cell_monitor.sh quick

# 3. Document baseline
cp /home/static/cell_monitoring/*.log baseline/
cp /home/static/spectrum_scans/*.csv baseline/
```

---

## Output Files

### Cell Monitor
```
/home/static/cell_monitoring/
├── scans.log              # All scan results
├── alerts.log             # Detected anomalies
└── band*_*.log            # Raw scan data
```

### Spectrum Scanner
```
/home/static/spectrum_scans/
├── scan_*.csv             # Power measurements
├── scan_*_report.txt      # Analysis report
├── scan_*_peaks.csv       # Strong signals only
└── scan_*_plot.png        # Visualization
```

---

## Safety & Legal

### Legal (Passive)
✅ Receiving broadcast signals
✅ Measuring power levels
✅ Defensive monitoring
✅ Spectrum analysis

### Requires Authorization (Active)
⚠️ Lab eNodeB operation
⚠️ Own devices only
⚠️ RF-shielded environment
⚠️ Written documentation

### Illegal
❌ Unauthorized transmission
❌ Jamming signals
❌ Surveillance of others
❌ Interference with networks

---

## Troubleshooting

### USRP Not Found
```bash
# Check connection
lsusb | grep Ettus

# Check UHD
uhd_usrp_probe

# Set images path
export UHD_IMAGES_DIR=/usr/share/uhd/4.9.0/images
```

### No Power Measurements (Spectrum Scanner)
```bash
# Install Python UHD
sudo apt-get install python3-uhd

# Verify
python3 -c "import uhd; print('OK')"
```

### Low SNR / Poor Performance
```bash
# Check USB 3.0
lsusb -t | grep 5000M

# Increase gain
./cell_monitor.sh quick  # Uses default gain
# Or
./spectrum_scanner.sh --gain 50
```

---

## Performance Optimization

### Spectrum Scanner

**Fast survey (45 min):**
```bash
./spectrum_scanner.sh -s 70e6 -e 6000e6 -t 10e6 -d 0.05
```

**Detailed analysis (8 hours):**
```bash
./spectrum_scanner.sh -s 70e6 -e 6000e6 -t 1e6 -d 0.1
```

**Python acceleration:**
- Automatic if `python3-uhd` installed
- 10-100x faster than bash version

---

## Project Status

**Completed:**
- ✅ USB 3.0 validation (8x performance boost)
- ✅ MIB decode from 2 cells
- ✅ PDSCH decode capability
- ✅ Defensive monitoring system
- ✅ Wideband spectrum scanner with multi-pass averaging
- ✅ P25 Phase 1/2 decoder integration (OP25)
- ✅ Signal hunter (auto-detect & decode)
- ✅ DMR/NXDN decoder support (dsdcc)
- ✅ Lab eNodeB setup
- ✅ Complete documentation

**In Progress:**
- ⚠️ SIB1 full decode (MIB working, SIB1 partial)
- ⚠️ Multi-band expansion (currently Band 2)
- ⚠️ DMR/NXDN decoder wrappers (dsdcc installed, scripts pending)

**Planned:**
- 🔲 5G NSA/SA support
- 🔲 ML-based anomaly detection
- 🔲 Geographic cell mapping
- 🔲 Paging message monitoring

---

## Contributing

This is a research/educational project. Contributions welcome:

1. Additional LTE bands
2. Improved detection algorithms
3. Better visualization
4. Documentation improvements
5. Bug fixes

**Guidelines:**
- Maintain legal/ethical standards
- Document all changes
- Test thoroughly
- Follow existing code style

---

## License

Educational and research use only. Use responsibly and legally.

**No warranty.** Use at your own risk.

---

## References

**srsRAN:** https://www.srslte.com/
**UHD:** https://www.ettus.com/uhd/
**3GPP Specs:** https://www.3gpp.org/

**Research Papers:**
- "Practical attacks against privacy and availability in 4G/LTE" (Rupprecht et al.)
- "LTE security disabled misconfiguration" (Hong et al.)

---

## Contact & Support

For issues:
1. Check relevant guide in `docs/`
2. Review troubleshooting section
3. Verify USB 3.0 connection
4. Check UHD/srsRAN versions

---

**Built with USB 3.0 on MNT Reform Pocket - Making LTE security research accessible.**

Last Updated: 2026-01-01
Version: 1.0
