# Cellular Research Quick Reference Card

## Your B210 Cellular Capabilities ⭐

```
Device: B210 Clone (Serial: 30AA038)
Range: 70 MHz - 6 GHz (ALL cellular bands!)
Bandwidth: Up to 56 MHz
Channels: 2 RX (can monitor 2 frequencies simultaneously)
```

## Best Detected Cellular Signals

| Frequency | Band | Carrier | SNR | Command |
|-----------|------|---------|-----|---------|
| **1930 MHz** | **LTE Band 2** | **AT&T/T-Mobile** | **20.4 dB** ⭐ | `--freq 1930e6 --gain 50 --ant TX/RX` |
| **746 MHz** | **LTE Band 13** | **Verizon** | **17.0 dB** ⭐ | `--freq 746e6 --gain 60 --ant RX2` |
| 751 MHz | LTE Band 13 | Verizon | 16.5 dB | `--freq 751e6 --gain 60 --ant RX2` |
| 2132.5 MHz | LTE Band 4 | T-Mobile | 15.1 dB | `--freq 2132.5e6 --gain 50 --ant TX/RX` |
| 2110 MHz | AWS | T-Mobile | 14.6 dB | `--freq 2110e6 --gain 50 --ant TX/RX` |

## Quick Commands

### Test B210 on Cellular Bands
```bash
~/sdr_data/test_b210_cellular.sh
```

### Capture LTE Band 13 (Best Verizon Signal)
```bash
rx_samples_to_file --freq 746e6 --rate 5e6 --gain 60 \
  --ant RX2 --type short --duration 30 \
  --file lte_band13_capture.dat
```

### Capture LTE Band 2 (Best AT&T/T-Mobile)
```bash
rx_samples_to_file --freq 1930e6 --rate 5e6 --gain 50 \
  --ant TX/RX --type short --duration 30 \
  --file lte_band2_capture.dat
```

### Wide-band Cellular Scan
```bash
rx_samples_to_file --freq 1930e6 --rate 20e6 --gain 50 \
  --ant TX/RX --type short --duration 10 \
  --file cellular_wideband.dat
```

## RF-Swift (Docker - All Tools)

### Start RF-Swift
```bash
~/sdr_data/start_rfswift.sh

# Or manually:
docker run -it --privileged \
  -v ~/sdr_data:/root/data \
  -p 8080:8080 \
  penthertz/rfswift:latest
```

### Inside RF-Swift Container

**Verify B210:**
```bash
uhd_find_devices
```

**Scan for GSM towers:**
```bash
kal -s GSM900 -g 50
```

**Scan for LTE cells:**
```bash
# Scan Band 13 (your best signal)
srsenb_cell_search -f 746e6 -g 60

# Scan Band 2
srsenb_cell_search -f 1930e6 -g 50
```

**Live GSM monitoring:**
```bash
grgsm_livemon -f 935M -g 50
```

**IMSI catcher detection:**
```bash
python3 /opt/IMSI-catcher/simple_IMSI-catcher.py --scan
```

## Cell Tower Mapping

### Using Modmobmap
```bash
# In RF-Swift container
cd /opt/Modmobmap

# Scan LTE on your best band
python3 modmobmap.py --scan --tech lte \
  --freq 746 --gain 60 --antenna RX2

# Map results
python3 modmobmap.py --map
```

### Manual Mapping
```bash
# Capture while moving with GPS
rx_samples_to_file --freq 746e6 --rate 2e6 --gain 60 \
  --ant RX2 --type short --duration 300 \
  --file tower_map_$(date +%Y%m%d_%H%M%S).dat
```

## Analysis Tools

### Inspectrum (Visual Analysis)
```bash
brew install inspectrum
inspectrum lte_band13_capture.dat
```

### GNU Radio Companion
```bash
gnuradio-companion
```

### Wireshark (Protocol Analysis)
```bash
# gr-gsm outputs to UDP port 4729
# In Wireshark: Capture loopback, filter 'gsmtap'
```

## US Cellular Bands Reference

### 2G/GSM (Legacy)
- **GSM 850**: 824-894 MHz
- **PCS 1900**: 1850-1990 MHz ✓ YOU HAVE THIS

### 4G/LTE (Primary)
- **Band 2 (PCS)**: 1930-1990 MHz ✓ **20.4 dB SNR** ⭐ STRONGEST
- **Band 4 (AWS)**: 2110-2155 MHz ✓ 14.6 dB SNR
- **Band 5 (850)**: 869-894 MHz ✓ 14.5 dB SNR
- **Band 12**: 699-716 MHz (similar to Band 13)
- **Band 13**: 746-756 MHz ✓ **17.0 dB SNR** ⭐ STRONG
- **Band 66**: 2110-2200 MHz ✓ overlaps AWS

### 5G NR (Newer)
- **n2**: Same as LTE Band 2 ✓
- **n5**: Same as LTE Band 5 ✓
- **n66**: Extended AWS ✓
- **n77**: 3300-4200 MHz ✓ B210 can receive
- **n260**: 37-40 GHz (mmWave) ✗ B210 can't receive

## Common Carrier Frequencies

### Verizon
- **Primary**: Band 13 (746-756 MHz) ✓ **17 dB SNR - YOUR BEST**
- Secondary: Band 4 (2110-2155 MHz) ✓
- 5G: n5, n66, n260

### AT&T
- **Primary**: Band 2 (1930-1990 MHz) ✓ **20.4 dB SNR - YOUR BEST**
- Secondary: Band 5 (869-894 MHz) ✓
- Secondary: Band 4/66 (2110+ MHz) ✓
- 5G: n2, n5, n260

### T-Mobile
- **Primary**: Band 4 (2110-2155 MHz) ✓ **14.6 dB SNR**
- **Primary**: Band 2 (1930-1990 MHz) ✓ **20.4 dB SNR**
- Mid-band 5G: n41 (2.5 GHz) ✓ B210 can receive
- 5G: n260, n261

## Safety Checklist ✅

### Legal (Passive Reception)
- ✅ Scanning for cell towers
- ✅ Receiving broadcast signals
- ✅ Measuring signal strength
- ✅ Analyzing protocols (encrypted traffic only)
- ✅ Educational research
- ✅ IMSI catcher detection

### Illegal (Active Operations)
- ❌ Operating fake base station
- ❌ Jamming cellular signals
- ❌ Decrypting user traffic
- ❌ Intercepting calls/SMS
- ❌ Transmitting on cellular bands

### Best Practices
1. **RX Only**: Never connect TX antenna
2. **Faraday Cage**: Test in shielded room when learning
3. **Document Everything**: Keep research logs
4. **No PII**: Don't capture personal information
5. **Air-Gapped**: Analyze on separate machine
6. **Report Findings**: Responsible disclosure

## Troubleshooting

### "No UHD Devices Found"
```bash
# Check USB connection
uhd_find_devices

# Try different USB port
# Replug B210
```

### "Permission Denied"
```bash
# Add user to dialout/plugdev group (Linux)
# On macOS: Use sudo or fix permissions

sudo chmod 666 /dev/bus/usb/*/*
```

### "Overflow" or "Underrun" Errors
```bash
# Reduce sample rate
--rate 2e6  # instead of 20e6

# Check USB 3.0 connection
```

### Low Signal Strength
```bash
# Increase gain
--gain 70  # max is 76 dB

# Check antenna connection
# Move closer to window
# Try different antenna port (RX2 vs TX/RX)
```

## Resources

### Documentation
- RF-Swift: https://github.com/PentHertz/RF-Swift
- gr-gsm: https://github.com/ptrkrysik/gr-gsm
- srsRAN: https://github.com/srsran/srsRAN_4G
- Modmobmap: https://github.com/PentHertz/Modmobmap

### Your Local Docs
- Setup Guide: `docs/CELLULAR_RESEARCH_SETUP.md`
- B210 Config: `B210/CLONE_CONFIGURATION.md`
- Optimal Settings: `/tmp/b210_optimal_settings.txt`

### Communities
- r/RTLSDR - Reddit community
- r/cellular - Cellular technology
- UHD Users List: usrp-users@lists.ettus.com

## Next Steps

1. **Run installer:**
   ```bash
   ./scripts/install_cellular_tools.sh
   ```

2. **Test your B210:**
   ```bash
   ~/sdr_data/test_b210_cellular.sh
   ```

3. **Start RF-Swift:**
   ```bash
   ~/sdr_data/start_rfswift.sh
   ```

4. **Scan your area:**
   ```bash
   # Inside RF-Swift
   kal -s GSM900 -g 50
   srsenb_cell_search -f 746e6 -g 60
   ```

5. **Capture and analyze:**
   ```bash
   # Capture 30 seconds of LTE Band 13
   rx_samples_to_file --freq 746e6 --rate 5e6 --gain 60 \
     --ant RX2 --type short --duration 30 \
     --file lte_capture.dat

   # Analyze with inspectrum
   inspectrum lte_capture.dat
   ```

---

**Remember:** Your B210 has excellent cellular reception:
- **Best overall**: 1930 MHz (20.4 dB SNR) - AT&T/T-Mobile
- **Best Verizon**: 746 MHz (17.0 dB SNR) - LTE Band 13

**Always operate legally:** Passive reception only!
