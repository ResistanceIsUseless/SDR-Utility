# Cellular Research on macOS with B210 (USB Limitation Workaround)

## ⚠️ Important macOS Limitation

**Docker on macOS cannot forward USB devices** to containers. This means the RF-Swift Docker containers cannot directly access your B210.

## ✅ Solution: Two-Step Workflow

### Step 1: Capture (Native macOS with UHD)
Use native `rx_samples_to_file` command to capture IQ data from your B210

### Step 2: Analyze (Inside RF-Swift Container)
Use gr-gsm, Kalibrate, and other tools inside the container to analyze the captured data

---

## Your B210's Best Cellular Frequencies

From your auto-optimizer results:

| Frequency | Band | Carrier | SNR | Command for Capture |
|-----------|------|---------|-----|---------------------|
| **1930 MHz** | **LTE Band 2** | **AT&T/T-Mobile** | **20.4 dB** | `rx_samples_to_file --freq 1930e6 --rate 2e6 --gain 50 --ant TX/RX --type short --duration 30 --file ~/sdr_data/captures/lte_band2.dat` |
| **746 MHz** | **LTE Band 13** | **Verizon** | **17.0 dB** | `rx_samples_to_file --freq 746e6 --rate 2e6 --gain 60 --ant RX2 --type short --duration 30 --file ~/sdr_data/captures/lte_band13.dat` |
| 2110 MHz | AWS Band 4 | T-Mobile | 14.6 dB | `rx_samples_to_file --freq 2110e6 --rate 2e6 --gain 50 --ant TX/RX --type short --duration 30 --file ~/sdr_data/captures/aws_band4.dat` |

---

## Complete Workflow Example: GSM Scanning

### 1. Scan for GSM Towers (Native macOS)

```bash
# Scan GSM 900 band (890-915 MHz uplink, 935-960 MHz downlink)
# We'll scan the downlink range

cd ~/sdr_data/captures

# Capture GSM 900 downlink center frequency (945 MHz)
rx_samples_to_file \
  --freq 945e6 \
  --rate 2e6 \
  --gain 50 \
  --ant TX/RX \
  --type short \
  --duration 60 \
  --file gsm900_scan.dat

echo "✓ Captured 60 seconds of GSM 900 band"
```

### 2. Analyze with gr-gsm (Inside Container)

```bash
# Start RF-Swift cellular container
~/sdr_data/start_rfswift_cellular.sh

# Inside container:
cd /root/data/captures

# Decode the GSM capture
grgsm_decode -c gsm900_scan.dat -s 2e6 -f 945e6

# Or use the scanner to find channels
grgsm_scanner -c gsm900_scan.dat
```

---

## Workflow Example: LTE Cell Scanning

### 1. Capture LTE Band 13 (Your Strongest Signal)

```bash
# Capture 30 seconds of Verizon LTE Band 13
rx_samples_to_file \
  --freq 746e6 \
  --rate 10e6 \
  --gain 60 \
  --ant RX2 \
  --type short \
  --duration 30 \
  --file ~/sdr_data/captures/lte_band13_verizon.dat

echo "✓ Captured LTE Band 13 (746 MHz, 17 dB SNR)"
```

### 2. Analyze with srsRAN (Inside Container)

Unfortunately, srsRAN requires real-time access to the SDR. For LTE analysis, use these alternatives:

**Option A: Use inspectrum (Native macOS)**
```bash
brew install inspectrum
inspectrum ~/sdr_data/captures/lte_band13_verizon.dat
```

**Option B: Use GNU Radio (Inside Container)**
```bash
~/sdr_data/start_rfswift_cellular.sh

# Inside container:
gnuradio-companion

# Create a flowgraph:
# File Source → Complex to Mag → FFT Sink
```

---

## Real-Time Scanning Alternative

For tools that REQUIRE real-time SDR access (like Kalibrate), you can install them natively on macOS:

### Install Kalibrate Natively

```bash
# Install dependencies
brew install fftw

# Clone and build Kalibrate for UHD
git clone https://github.com/steve-m/kalibrate-uhd.git
cd kalibrate-uhd
./bootstrap && ./configure && make
sudo make install

# Scan for GSM towers (real-time)
kal -s GSM900 -g 50
```

---

## What Works Where

### Native macOS (Direct B210 Access)
✅ **Capture:** All `rx_samples_to_file` commands
✅ **Real-time:** Kalibrate, GQRX
✅ **Visualization:** inspectrum, GNU Radio
❌ **Container tools:** Cannot access B210 directly

### Inside RF-Swift Container
✅ **Analysis:** gr-gsm decode (on captured files)
✅ **Visualization:** GNU Radio, Wireshark (GSMTAP)
✅ **Processing:** Python scripts, signal analysis
❌ **Real-time capture:** No USB access

---

## Recommended Setup

### For GSM/2G Research:
1. **Install Kalibrate natively** (real-time scanning)
2. **Capture with rx_samples_to_file** (IQ data)
3. **Analyze in RF-Swift container** (gr-gsm decode)

### For LTE/4G Research:
1. **Capture with rx_samples_to_file** (IQ data)
2. **Analyze with inspectrum** (native macOS)
3. **Use GNU Radio** (container or native) for signal processing

### For IMSI Catcher Detection:
1. **Monitor multiple frequencies** with rx_samples_to_file
2. **Log cell IDs over time** (gr-gsm in container)
3. **Detect anomalies** (sudden changes in cell configuration)

---

## Quick Reference: Common Captures

```bash
# GSM 900 (935-960 MHz downlink)
rx_samples_to_file --freq 945e6 --rate 2e6 --gain 50 --ant TX/RX --type short --duration 60 --file ~/sdr_data/captures/gsm900.dat

# GSM 1800 (1805-1880 MHz downlink)
rx_samples_to_file --freq 1842e6 --rate 2e6 --gain 50 --ant TX/RX --type short --duration 60 --file ~/sdr_data/captures/gsm1800.dat

# LTE Band 2 (1930-1990 MHz) - YOUR BEST SIGNAL
rx_samples_to_file --freq 1930e6 --rate 10e6 --gain 50 --ant TX/RX --type short --duration 30 --file ~/sdr_data/captures/lte_band2.dat

# LTE Band 13 (746-756 MHz) - YOUR BEST VERIZON
rx_samples_to_file --freq 746e6 --rate 10e6 --gain 60 --ant RX2 --type short --duration 30 --file ~/sdr_data/captures/lte_band13.dat

# Wide-band scan (capture multiple channels at once)
rx_samples_to_file --freq 1930e6 --rate 20e6 --gain 50 --ant TX/RX --type short --duration 10 --file ~/sdr_data/captures/wideband_lte.dat
```

---

## Containers Available

RF-Swift provides specialized containers for different cellular technologies:

| Container | Use For | Pull Command |
|-----------|---------|--------------|
| **telecom_2Gto3G** | GSM, UMTS | `rfswift images pull -i telecom_2Gto3G` |
| **telecom_4G_5GNSA** | LTE, 5G NSA | `rfswift images pull -i telecom_4G_5GNSA` |
| **telecom_5G** | 5G SA | `rfswift images pull -i telecom_5G` |

Currently installed:
- ✅ telecom_2Gto3G (12.8 GB)

---

## Legal Reminder ⚖️

### ✅ Legal (Passive Reception):
- Scanning for cell towers
- Receiving broadcast channels
- Analyzing signal strength
- Research and education

### ❌ Illegal:
- Operating fake base stations
- Intercepting calls/SMS
- Jamming signals
- Decrypting user data

**Always operate in receive-only mode with your B210!**

---

## Next Steps

1. **Test your B210 on cellular bands:**
   ```bash
   ~/sdr_data/test_b210_cellular.sh
   ```

2. **Capture your first GSM signal:**
   ```bash
   rx_samples_to_file --freq 945e6 --rate 2e6 --gain 50 --ant TX/RX --type short --duration 30 --file ~/sdr_data/captures/my_first_gsm.dat
   ```

3. **Analyze in RF-Swift:**
   ```bash
   ~/sdr_data/start_rfswift_cellular.sh
   # Inside: grgsm_decode -c /root/data/captures/my_first_gsm.dat -s 2e6 -f 945e6
   ```

---

## Troubleshooting

### "No signals detected in capture"
- Check antenna connection
- Increase gain (`--gain 60` or higher)
- Verify frequency (use your auto-optimizer results)
- Try different antenna port (TX/RX vs RX2)

### "Container cannot find captures"
- Ensure files are in `~/sdr_data/captures/`
- Inside container, they appear in `/root/data/captures/`
- Check file permissions

### "USB overflow" during capture
- Reduce sample rate: `--rate 2e6` instead of `--rate 20e6`
- Check USB 3.0 connection
- Close other applications

---

For more information, see:
- `START_HERE_CELLULAR.md` - Quick start guide
- `CELLULAR_QUICK_REFERENCE.md` - Command reference
- `CELLULAR_RESEARCH_SETUP.md` - Detailed setup
