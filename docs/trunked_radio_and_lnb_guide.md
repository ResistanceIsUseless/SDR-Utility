# Trunked Radio (P25/DMR/etc) and Satellite LNB Setup Guide

## Current Trunked Radio Tools Status

### Already Installed
- **dsd-fme** - Digital Speech Decoder `/usr/local/bin/dsd-fme`
  - Decodes: P25, DMR, NXDN, D-STAR, ProVoice, X2-TDMA
  - Good for voice decoding but NOT trunking

- **codec2** - Voice codec libraries
  - Used by various digital decoders

### What You're Missing for Full P25/Trunking

**SDRTrunk does NOT cover everything.** Here's the landscape:

#### Option 1: SDRTrunk (Java-based, GUI)
**Best for: Beginners, multiple protocols**
- ✓ P25 Phase 1 & 2
- ✓ DMR
- ✓ LTR
- ✓ Passport
- ✓ MPT1327
- ✗ Not in apt repos (manual install)

```bash
# Install SDRTrunk
cd ~/Downloads
wget https://github.com/DSheirer/sdrtrunk/releases/latest/download/sdr-trunk-linux-x86_64.zip
unzip sdr-trunk-linux-x86_64.zip -d ~/SDRTrunk
cd ~/SDRTrunk
./sdr-trunk
```

#### Option 2: OP25 (Python-based, CLI)
**Best for: P25 Phase 1 & 2, trunking experts**
- ✓ P25 Phase 1 trunking
- ✓ P25 Phase 2 (with TDMA)
- ✓ Encryption detection
- ✓ Multiple sites
- ✗ Only P25 (no DMR)

```bash
# Install OP25
sudo apt install -y git cmake build-essential libboost-all-dev libusb-1.0-0-dev \
    python3-numpy python3-requests gnuplot sox

cd ~/Downloads
git clone https://github.com/boatbod/op25.git
cd op25
./install.sh
```

#### Option 3: Trunk-Recorder
**Best for: Recording multiple talkgroups automatically**
- ✓ P25 Phase 1 & 2
- ✓ SmartNet
- ✓ Automatic recording
- ✓ Multiple channels
- ✗ Complex setup

```bash
# Install Trunk-Recorder
sudo apt install -y git cmake build-essential libboost-all-dev libusb-1.0-0-dev \
    libcurl4-openssl-dev libssl-dev gnuradio-dev gr-osmosdr libuhd-dev \
    libpthread-stubs0-dev libsndfile1-dev libgmp-dev libspdlog-dev libfmt-dev

cd ~/Downloads
git clone https://github.com/robotastic/trunk-recorder.git
cd trunk-recorder
mkdir build && cd build
cmake ..
make -j4
sudo make install
```

#### Option 4: DSDcc (Library - already available!)
**Best for: Integration with other tools**
```bash
sudo apt install dsdcc libdsdcc-dev
```

### Recommended Setup for P25

**For casual monitoring:**
1. Install **SDRTrunk** (easiest, GUI-based)
2. Use with your CaribouLite
3. Monitor local P25 systems

**For serious trunking:**
1. Install **OP25** for P25
2. Configure with local trunking system info from RadioReference
3. Use multiple dongles for better coverage

**For automated recording:**
1. Install **Trunk-Recorder**
2. Configure talkgroups
3. Let it record continuously

## Your GeoSatPro LNB Setup (950-2150 MHz IF)

### What You Can Receive

**YES! This is PERFECT for satellite reception!** Here's what you can capture:

#### Ku-Band Satellites (10.7-12.75 GHz downconverted to 950-2150 MHz)

Your LNB takes signals from 10.7-12.75 GHz and converts them to 950-2150 MHz IF:
- LO (Local Oscillator): Usually 9750 MHz or 10600 MHz
- IF = (Satellite Freq) - (LO Freq)

**What you can decode:**

1. **DVB-S/DVB-S2 TV broadcasts**
   - FTA (Free-to-Air) channels
   - News feeds
   - Educational content

2. **Data downlinks**
   - Weather satellite data (some Ku-band weather sats)
   - Research satellites
   - Amateur radio satellites on QO-100 (Es'hail-2)

3. **QO-100 / Es'hail-2 Amateur Radio Satellite**
   - Narrowband transponder: 10489.550 MHz → ~739 MHz IF
   - Wideband transponder: 10491 MHz → ~741 MHz IF
   - SSB, CW, digital modes
   - **THIS IS THE BEST TARGET!**

### Physical Connection

**Connect LNB to CaribouLite:**

Your LNB has an F-connector output. You'll need:
1. F-to-SMA adapter
2. DC bias-tee to power the LNB (12-18V)
3. LNB needs power!

**IMPORTANT:** CaribouLite HiF channel specs:
- Input: 1 MHz - 6 GHz
- 950-2150 MHz fits perfectly! ✓
- But you need to power the LNB separately or with bias-tee

### Software for Satellite Decoding

#### For DVB-S/S2 TV:
```bash
# Already installed!
# Use satdump or dvb tools

# Scan for channels
dvbscan -c -a 0 -f 0

# Or use satdump GUI
satdump
```

#### For QO-100 Amateur Satellite:
```bash
# Use GQRX or SDR++ to tune
# Narrow transponder: Set CaribouLite to ~739 MHz
# Wideband: Set to ~741 MHz

# For SSB/CW:
gqrx

# Or use SDR++
sdrpp
```

### LNB Power Injection

**Option 1: External bias-tee**
```bash
# You need a bias-tee that can provide 12-18V DC
# Examples:
# - Mini-Circuits ZFBT-4R2GW+
# - Nooelec bias-tee
# - DIY with DC injector
```

**Option 2: Check if CaribouLite supports it**
```bash
# Check CaribouLite GPIO capabilities
# Some versions support bias-tee via GPIO
```

**Option 3: Use external LNB power supply**
- Satellite finder with built-in power
- Dedicated LNB power inserter
- Connect before CaribouLite input

### Example Setup for QO-100

```bash
# 1. Connect LNB to CaribouLite HiF channel (with power!)
# 2. Calculate IF frequency:
#    QO-100 beacon: 10489.550 MHz
#    LNB LO: 9750 MHz (standard)
#    IF = 10489.550 - 9750 = 739.550 MHz

# 3. Tune CaribouLite to IF frequency
gqrx &

# In GQRX:
# - Input device: CaribouLite HiF
# - Frequency: 739550000 Hz
# - Mode: USB for SSB uplink, CW for beacons
# - You should hear amateur radio operators!

# 4. For wideband transponder (DATV):
# Frequency: 741 MHz
# Bandwidth: 8 MHz
# Use SDR++ or GQRX to see the spectrum
```

### What Satellites Are Available?

**Using your LNB at your location, you can receive:**

1. **Geostationary satellites** (if dish is pointed):
   - Check https://www.lyngsat.com for what's at your longitude
   - Many FTA channels
   - News feeds

2. **QO-100 / Es'hail-2** (26°E, visible from Americas, Europe, Africa, Asia)
   - Always available if in coverage area
   - Active ham radio traffic
   - Best for testing!

3. **Other Ku-band satellites**
   - Depends on dish pointing
   - Can scan for signals

### Testing the LNB Setup

```bash
# 1. Make sure LNB is powered (12-18V)
# 2. Connect to CaribouLite HiF
# 3. Quick scan:

# Scan from 950-2150 MHz looking for signals
rtl_433 -d driver=Cariboulite,channel=HiF -f 1050M -s 2M

# Or use SDR++ for visual spectrum:
sdrpp
# Tune through 950-2150 MHz range
# Look for spikes in the waterfall
```

### Advanced: Decoding Specific Satellites

**For DVB-S2 with satdump:**
```bash
# Already installed!
satdump

# Select:
# - Input: CaribouLite HiF
# - Pipeline: DVB-S2
# - Frequency: (whatever you found in scan)
# - Symbol rate: (from lyngsat.com for that satellite)
```

**For data downlinks:**
```bash
# Use GNU Radio with gr-satellites
# Already have gnuradio installed
gr-satellites
```

## Complete Installation Command

```bash
# Install all recommended trunked radio tools
sudo apt install -y dsdcc libdsdcc-dev git cmake build-essential \
    libboost-all-dev libusb-1.0-0-dev python3-numpy python3-requests

# Install OP25 (for P25 trunking)
cd ~/Downloads
git clone https://github.com/boatbod/op25.git
cd op25
./install.sh

# For DVB satellite work (already have satdump)
# Just verify it works:
satdump --help
```

## Summary

### Trunked Radio
- **SDRTrunk**: GUI, multiple protocols (P25, DMR, etc.) - Manual install
- **OP25**: Best for P25 Phase 1/2 trunking - Needs compilation
- **Trunk-Recorder**: Automated recording - Needs compilation
- **dsd-fme**: Already installed, decodes digital voice (not trunking)

### LNB + CaribouLite
- **YES, it will work!** 950-2150 MHz fits CaribouLite HiF perfectly
- **Need LNB power** (12-18V via bias-tee or external)
- **Best targets**: QO-100 amateur satellite, DVB-S2 FTA channels
- **Already have decoders**: satdump, GNU Radio, SDR++

Want me to install any of these tools or help set up the LNB?
