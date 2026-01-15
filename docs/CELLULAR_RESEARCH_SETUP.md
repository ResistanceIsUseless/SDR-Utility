# Cellular Research Setup for B210 Clone (macOS ARM64)

## Your Device Capabilities

**B210 Clone Specs:**
- ✅ Frequency Range: 70 MHz - 6 GHz (covers all cellular bands!)
- ✅ Bandwidth: Up to 56 MHz (capture entire LTE channels)
- ✅ Full Duplex: Monitor uplink + downlink simultaneously
- ✅ 2 RX channels: Track multiple frequencies

**Detected Cellular Signals (from auto-optimizer):**
- 746 MHz - LTE Band 13 (Verizon) - SNR: 17.0 dB ✓
- 751 MHz - LTE Band 13 (Verizon) - SNR: 16.5 dB ✓
- 869 MHz - Cellular band - SNR: 14.5 dB ✓
- 894 MHz - Cellular band - SNR: 14.4 dB ✓
- 1930 MHz - PCS/LTE (AT&T/T-Mobile) - SNR: 20.4 dB ✓
- 1960 MHz - LTE Band 2 - SNR: 14.6 dB ✓
- 2110 MHz - AWS/LTE (T-Mobile) - SNR: 14.6 dB ✓

---

## Installation Plan

### Phase 1: Core Tools (macOS Native) ⭐ START HERE

```bash
# Install GNU Radio (required for most cellular tools)
brew install gnuradio

# Install Python tools
pip3 install pyrtlsdr numpy scipy matplotlib

# Install analysis tools
brew install wireshark
```

### Phase 2: Cellular Tools via Docker 🐳 RECOMMENDED

**RF-Swift** - Complete cellular research toolkit in Docker:
```bash
# Install Docker Desktop for Mac
brew install --cask docker

# Pull RF-Swift (includes ALL tools)
docker pull penthertz/rfswift:latest

# Run RF-Swift with B210 access
docker run -it --privileged \
  -v /dev/bus/usb:/dev/bus/usb \
  -p 8080:8080 \
  penthertz/rfswift:latest
```

**What RF-Swift includes:**
- ✅ gr-gsm (GSM/2G sniffing)
- ✅ srsRAN (LTE/4G/5G)
- ✅ Modmobmap (Cell tower mapping)
- ✅ IMSI-catcher detection
- ✅ Kalibrate (cell tower scanner)
- ✅ 5Ghoul (5G fuzzing)
- ✅ YateBTS (GSM base station)
- ✅ All dependencies pre-configured

### Phase 3: Build from Source (Advanced)

**gr-gsm** - GSM protocol decoder:
```bash
# Install dependencies
brew install cmake swig fftw cppunit

# Clone and build
git clone https://github.com/ptrkrysik/gr-gsm.git
cd gr-gsm
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j4
sudo make install
```

**srsRAN** - 4G/5G research platform:
```bash
# Install dependencies
brew install cmake libconfig fftw mbedtls

# Clone and build
git clone https://github.com/srsran/srsRAN_4G.git
cd srsRAN_4G
mkdir build && cd build
cmake ..
make -j4
sudo make install
```

---

## Recommended: Use RF-Swift Docker 🎯

### Why RF-Swift?

1. **All-in-one:** Everything pre-installed and configured
2. **macOS compatible:** Runs in Docker, no ARM64 build issues
3. **No compilation:** Ready to use immediately
4. **Actively maintained:** Regular updates
5. **Community:** PentHertz team provides support

### Quick Start with RF-Swift

```bash
# 1. Start Docker Desktop
open -a Docker

# 2. Pull RF-Swift
docker pull penthertz/rfswift:latest

# 3. Run with USB access (for B210)
docker run -it --privileged \
  -v /dev/bus/usb:/dev/bus/usb \
  -v ~/sdr_data:/root/data \
  -p 8080:8080 \
  --name rfswift \
  penthertz/rfswift:latest

# Inside container, B210 should be accessible via UHD
uhd_find_devices
```

---

## Cellular Research Workflow

### Step 1: Scan for Cell Towers

**Using Kalibrate (in RF-Swift):**
```bash
# Scan GSM 900 MHz band
kal -s GSM900 -g 50

# Scan GSM 1800 MHz (DCS) band
kal -s DCS -g 50

# Scan specific channel
kal -c 51 -g 50
```

**Using gr-gsm scanner:**
```bash
# Scan 900 MHz GSM band
grgsm_scanner -b GSM900

# Scan 1800 MHz GSM band
grgsm_scanner -b DCS1800
```

**Manual scan with your B210:**
```bash
# Your detected LTE bands from auto-optimizer results
# Band 13 (Verizon): 746-751 MHz (best SNR: 17 dB)
# Band 2 (AT&T/T-Mobile): 1930-1960 MHz (SNR: 20.4 dB)
# AWS Band (T-Mobile): 2110 MHz (SNR: 14.6 dB)
```

### Step 2: Capture Cell Tower Data

**Capture GSM with gr-gsm:**
```bash
# Capture specific ARFCN (example: channel 51)
grgsm_livemon -f 935.2M -g 50 -s 2e6

# This opens GNU Radio Companion with live GSM decoding
# Shows: Cell ID, LAC, MCC, MNC, and broadcast messages
```

**Capture LTE with srsRAN:**
```bash
# Cell search on Band 13 (your strongest signal)
srsenb_cell_search -f 746e6 -g 50

# Outputs: Cell ID, Physical Cell ID (PCI), frequency offset
```

### Step 3: Decode and Analyze

**Wireshark for GSM:**
```bash
# gr-gsm can output to Wireshark via UDP
grgsm_livemon -f 935.2M --udp-ports=4729

# In Wireshark: Capture on loopback, filter 'gsmtap'
```

**IMSI Catcher Detection:**
```bash
# In RF-Swift container
python3 /opt/IMSI-catcher/simple_IMSI-catcher.py --scan
```

### Step 4: Map Cell Towers

**Using Modmobmap:**
```bash
# Install (via RF-Swift or separately)
git clone https://github.com/PentHertz/Modmobmap.git
cd Modmobmap

# Scan and map
python3 modmobmap.py --scan --tech gsm --freq 900
python3 modmobmap.py --scan --tech lte --freq 1930

# Generates map with cell tower locations
```

---

## Safety and Legal Considerations ⚖️

### ✅ LEGAL (Passive Reception):
- Scanning for cell towers
- Receiving broadcast channels
- Analyzing signal strength
- Mapping cell tower locations
- Educational/research purposes
- IMSI catcher detection

### ❌ ILLEGAL (Active Transmission):
- Operating fake base stations
- Intercepting phone calls/SMS
- Jamming cellular signals
- Man-in-the-middle attacks
- Impersonating cell towers
- Decrypting user traffic

### Best Practices:
1. **Passive only:** Your B210 receiving only (no TX)
2. **Research purpose:** Document everything
3. **No PII:** Don't capture personal information
4. **Air-gapped:** Use separate machine for analysis
5. **Faraday cage:** Test in shielded environment when learning

---

## Cellular Band Reference

### Your B210 Can Monitor:

**2G/GSM:**
- GSM 850: 824-894 MHz (uplink), 869-894 MHz (downlink) ✓ YOU DETECTED THIS
- GSM 900: 890-915 MHz (uplink), 935-960 MHz (downlink)
- DCS 1800: 1710-1785 MHz (uplink), 1805-1880 MHz (downlink)
- PCS 1900: 1850-1910 MHz (uplink), 1930-1990 MHz (downlink) ✓ YOU DETECTED THIS

**3G/UMTS:**
- Band 2 (PCS): 1850-1910 MHz (uplink), 1930-1990 MHz (downlink) ✓
- Band 4 (AWS): 1710-1755 MHz (uplink), 2110-2155 MHz (downlink) ✓
- Band 5 (850): 824-849 MHz (uplink), 869-894 MHz (downlink) ✓

**4G/LTE:**
- Band 2: 1850-1910 MHz (uplink), 1930-1990 MHz (downlink) ✓ SNR: 20.4 dB
- Band 4: 1710-1755 MHz (uplink), 2110-2155 MHz (downlink) ✓ SNR: 14.6 dB
- Band 5: 824-849 MHz (uplink), 869-894 MHz (downlink) ✓ SNR: 14.5 dB
- Band 13: 777-787 MHz (uplink), 746-756 MHz (downlink) ✓ SNR: 17.0 dB
- Band 66: 1710-1780 MHz (uplink), 2110-2200 MHz (downlink) ✓

**5G NR:**
- n2: 1850-1910 MHz (uplink), 1930-1990 MHz (downlink) ✓
- n5: 824-849 MHz (uplink), 869-894 MHz (downlink) ✓
- n66: 1710-1780 MHz (uplink), 2110-2200 MHz (downlink) ✓
- n77: 3300-4200 MHz (TDD) - B210 supports this!
- n78: 3300-3800 MHz (TDD) - B210 supports this!

---

## Project Ideas

### Beginner Level:
1. **Cell Tower Mapping**
   - Scan your neighborhood
   - Map all visible cell towers
   - Identify carriers (AT&T, Verizon, T-Mobile)
   - Measure signal strength

2. **IMSI Catcher Detection**
   - Monitor for fake base stations
   - Track suspicious cell tower behavior
   - Log anomalies

3. **Frequency Usage Analysis**
   - Which bands are most active?
   - Time-of-day patterns
   - Carrier comparison

### Intermediate Level:
4. **GSM Protocol Analysis**
   - Decode broadcast channels (BCCH)
   - Extract cell info (MCC, MNC, LAC, Cell ID)
   - Track handoff patterns

5. **LTE Downlink Decoding**
   - Decode Master Information Block (MIB)
   - Decode System Information Blocks (SIB)
   - Extract cell configuration

6. **Coverage Mapping**
   - Drive/walk with B210 + laptop
   - Log GPS + signal strength
   - Generate coverage heatmap

### Advanced Level:
7. **5G NR Monitoring**
   - Scan 5G bands (3.5 GHz)
   - Decode synchronization signals
   - Track beam management

8. **Carrier Aggregation Analysis**
   - Monitor multiple LTE bands simultaneously
   - Analyze carrier combining strategies

9. **Protocol Fuzzing** (isolated environment only!)
   - Use 5Ghoul for 5G testing
   - Document vulnerabilities
   - Responsible disclosure

---

## Your Optimal Cellular Bands (Based on Tests)

From your auto-optimizer results:

| Band | Frequency | Carrier | SNR | Gain | Antenna | Priority |
|------|-----------|---------|-----|------|---------|----------|
| PCS (Band 2) | 1930 MHz | AT&T/T-Mobile | 20.4 dB | 50 dB | TX/RX | ⭐⭐⭐ BEST |
| LTE Band 13 | 746 MHz | Verizon | 17.0 dB | 60 dB | RX2 | ⭐⭐⭐ BEST |
| LTE Band 13 | 751 MHz | Verizon | 16.5 dB | 60 dB | RX2 | ⭐⭐⭐ |
| LTE Band 4 | 2132.5 MHz | T-Mobile | 15.1 dB | 50 dB | TX/RX | ⭐⭐ |
| AWS | 2110 MHz | T-Mobile | 14.6 dB | 50 dB | TX/RX | ⭐⭐ |
| LTE Band 2 | 1960 MHz | AT&T | 14.6 dB | 50 dB | TX/RX | ⭐⭐ |
| Cellular 850 | 869 MHz | Multiple | 14.5 dB | 50 dB | TX/RX | ⭐⭐ |
| Cellular 850 | 894 MHz | Multiple | 14.4 dB | 50 dB | TX/RX | ⭐ |

**Start with:** 1930 MHz (best SNR) or 746 MHz (Verizon Band 13)

---

## Installation Script

Let me create an automated installer:
