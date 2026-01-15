# 🎯 START HERE - Cellular Research with B210

## What You Have

✅ **B210 Clone** - Covers ALL cellular bands (70 MHz - 6 GHz)
✅ **GQRX** - Already installed
✅ **URH** - Universal Radio Hacker already installed
✅ **Strong cellular signals detected**:
   - 1930 MHz: 20.4 dB SNR ⭐ (AT&T/T-Mobile LTE Band 2)
   - 746 MHz: 17.0 dB SNR ⭐ (Verizon LTE Band 13)

## ⚠️ Important macOS Note

**Docker on macOS cannot access USB devices directly.** This means:
- ✅ You can capture IQ data with native `rx_samples_to_file` commands
- ✅ You can analyze captures inside RF-Swift containers
- ❌ RF-Swift containers cannot directly control your B210

**Solution:** Two-step workflow (capture native → analyze in container)
**See:** `docs/CELLULAR_MACOS_WORKFLOW.md` for complete instructions

## Quick Start (5 Minutes)

### Step 1: Install Tools
```bash
cd /Users/matthew/Projects/SDR-Utility
./scripts/install_cellular_tools.sh
```

This installs:
- GNU Radio (cellular analysis framework)
- RF-Swift Docker (ALL cellular tools in one)
- Helper scripts

### Step 2: Test Your B210
```bash
~/sdr_data/test_b210_cellular.sh
```

Should show: ✓✓✓ (all tests pass)

### Step 3: Start RF-Swift Cellular Container
```bash
~/sdr_data/start_rfswift_cellular.sh
```

This launches the cellular tools container with:
- gr-gsm (GSM/2G decoder)
- Kalibrate (cell scanner)
- GNU Radio + cellular blocks
- IMSI-catcher detection tools

**Remember:** On macOS, capture IQ data first with native commands, then analyze in the container.

## OR: Quick Manual Scan (macOS Workflow)

### 1. Capture IQ Data (Native macOS)
```bash
# Capture 30 seconds of LTE Band 13 (Verizon) - Your best signal!
rx_samples_to_file --freq 746e6 --rate 5e6 --gain 60 \
  --ant RX2 --type short --duration 30 \
  --file ~/sdr_data/captures/verizon_lte.dat
```

### 2. Analyze (Choose One)

**Option A: Visual analysis with inspectrum**
```bash
brew install inspectrum
inspectrum ~/sdr_data/captures/verizon_lte.dat
```

**Option B: Decode in RF-Swift container**
```bash
~/sdr_data/start_rfswift_cellular.sh
# Inside: Use gr-gsm or GNU Radio to analyze /root/data/captures/verizon_lte.dat
```

## What is RF-Swift?

**RF-Swift** = Complete cellular research lab in Docker

Includes everything:
- ✅ **gr-gsm** - Decode GSM/2G
- ✅ **srsRAN** - LTE/4G/5G analysis
- ✅ **Kalibrate** - Cell tower scanner
- ✅ **Modmobmap** - Map cell towers
- ✅ **IMSI-catcher tools** - Detect fake towers
- ✅ **5Ghoul** - 5G fuzzing
- ✅ **YateBTS** - GSM base station (testing only!)

**Why Docker?** 
- No compilation needed
- Works on ARM64 Mac
- All dependencies pre-configured
- Isolated from your system

## Documentation

📖 **Full Guide:** `docs/CELLULAR_RESEARCH_SETUP.md`
📋 **Quick Reference:** `docs/CELLULAR_QUICK_REFERENCE.md`
⚙️ **B210 Config:** `B210/CLONE_CONFIGURATION.md`

## Your Best Cellular Bands

| Frequency | Carrier | SNR | Use This |
|-----------|---------|-----|----------|
| 1930 MHz | AT&T/T-Mobile | 20.4 dB ⭐ | `--freq 1930e6 --gain 50 --ant TX/RX` |
| 746 MHz | Verizon | 17.0 dB ⭐ | `--freq 746e6 --gain 60 --ant RX2` |
| 2110 MHz | T-Mobile | 14.6 dB | `--freq 2110e6 --gain 50 --ant TX/RX` |

## Safety First ⚖️

### ✅ Legal (What You Can Do):
- Scan for cell towers
- Receive broadcast signals
- Analyze signal strength
- Educational research
- Detect IMSI catchers

### ❌ Illegal (Don't Do This):
- Operate fake base station
- Intercept calls/SMS
- Jam signals
- Decrypt user data
- Transmit on cellular bands

**Rule:** Passive reception only! Your B210 can only receive (safe & legal).

## Recommended Learning Path

### Week 1: Basics
1. Install tools (today!)
2. Scan for cell towers in your area
3. Identify carriers (AT&T, Verizon, T-Mobile)
4. Map signal strengths

### Week 2: GSM/2G
1. Use gr-gsm to decode broadcast channels
2. Extract cell info (MCC, MNC, LAC, Cell ID)
3. Monitor handoff patterns

### Week 3: LTE/4G
1. Decode Master Information Block (MIB)
2. Decode System Information Blocks (SIB)
3. Analyze LTE downlink

### Week 4: Advanced
1. Multi-band monitoring
2. Carrier aggregation analysis
3. IMSI catcher detection

## Community Resources

- r/RTLSDR - Reddit
- UHD Users: usrp-users@lists.ettus.com
- RF-Swift Issues: github.com/PentHertz/RF-Swift

## Need Help?

Check these first:
1. Run test: `~/sdr_data/test_b210_cellular.sh`
2. Check device: `uhd_find_devices`
3. Read quick reference: `docs/CELLULAR_QUICK_REFERENCE.md`

---

**Ready?** Run the installer:
```bash
./scripts/install_cellular_tools.sh
```
