# SDR++ Setup for B210 Clone

## Problem
SDR++ doesn't show SoapySDR as a source option because SoapySDR-UHD module isn't installed.

## Solution: Install SoapySDR with UHD Support

### Step 1: Install SoapySDR

```bash
# Install SoapySDR
brew install soapysdr

# Install SoapySDR UHD module
brew install soapyuhd
```

### Step 2: Verify Installation

```bash
# List available SoapySDR devices
SoapySDRUtil --find

# Should show your B210:
# Found device 0
#   driver = uhd
#   type = b200
#   serial = 30AA038
```

### Step 3: Test with SoapySDR

```bash
# Probe the device
SoapySDRUtil --probe="driver=uhd"

# Should show:
# - RX channels
# - TX channels
# - Gain ranges
# - Frequency ranges
```

### Step 4: Configure SDR++

1. **Launch SDR++**
   ```bash
   # If installed via Homebrew
   sdrpp

   # Or launch the app from Applications
   ```

2. **Select Source**
   - Click "Source" dropdown at top
   - Should now see "SoapySDR" option
   - Select "SoapySDR"

3. **Configure Device**
   - In Source settings:
     - **Driver**: Select "UHD"
     - **Device String**: Leave blank or use `serial=30AA038`
     - **Sample Rate**: 2 MS/s
     - **Antenna**: RX2
     - **Channel**: 0

4. **Set Optimal Settings** (from auto_optimize.sh results)
   - **Gain**: Use the gain found by optimizer (likely 50-70 dB)
   - **Frequency**: Tune to detected signal
   - **Bandwidth**: 2 MHz for FM

### Alternative: Direct UHD in SDR++

Some SDR++ builds have native UHD support:

1. Click "Source" → Look for "USRP" or "UHD"
2. If available, select it directly
3. Configure:
   - Serial: 30AA038
   - Sample Rate: 2e6
   - Antenna: RX2

### Troubleshooting

#### "No SoapySDR devices found"

```bash
# Check SoapySDR can see UHD
SoapySDRUtil --find="driver=uhd"

# If nothing found, check UHD
uhd_find_devices

# Make sure both work independently first
```

#### "Failed to open device"

```bash
# Kill any other programs using the B210
pkill -f uhd
pkill -f rx_samples

# Try again
SoapySDRUtil --find
```

#### "SoapySDR not in source list"

SDR++ might not be compiled with SoapySDR support. Options:

1. **Reinstall SDR++ with SoapySDR**:
   ```bash
   brew uninstall sdrpp
   brew install sdrpp --with-soapysdr
   # (if option available)
   ```

2. **Build SDR++ from source** with SoapySDR:
   ```bash
   git clone https://github.com/AlexandreRouma/SDRPlusPlus.git
   cd SDRPlusPlus
   mkdir build && cd build
   cmake .. -DOPT_BUILD_SOAPY_SOURCE=ON
   make -j$(sysctl -n hw.ncpu)
   ```

3. **Use pre-built SDR++ from website**:
   - Download from https://www.sdrpp.org/
   - macOS builds include SoapySDR support

### Quick Test Commands

```bash
# 1. Verify SoapySDR sees device
SoapySDRUtil --find

# 2. Test RX with SoapySDR
SoapySDRUtil --probe="driver=uhd,serial=30AA038"

# 3. Capture samples via SoapySDR
python3 -c "
import SoapySDR
sdr = SoapySDR.Device(dict(driver='uhd'))
print('Device:', sdr.getHardwareInfo())
"
# (requires SoapySDR Python bindings)
```

### Device String Options

For SDR++ device configuration:

```
Basic:
driver=uhd

With serial:
driver=uhd,serial=30AA038

With specific settings:
driver=uhd,serial=30AA038,type=b200
```

### Expected SDR++ Settings

Once working, use these settings:

```
Source: SoapySDR (UHD)
Driver: uhd
Serial: 30AA038
Sample Rate: 2,000,000 (2 MS/s)
Antenna: RX2
Bandwidth: Auto or 56 MHz
RF Gain: 50-70 dB (from optimizer)
```

### Alternative SDR Software

If SDR++ is problematic, try these alternatives that work great with B210:

#### 1. GQRX (Easy, GUI)
```bash
brew install gqrx

# Launch and select:
# Device: UHD
# Device string: serial=30AA038,type=b200
# Input rate: 2000000
# Antenna: RX2
```

#### 2. CubicSDR (Modern, Multi-platform)
```bash
brew install cubicsdr

# Automatically detects B210 via SoapySDR
```

#### 3. GNU Radio Companion (Advanced)
```bash
brew install gnuradio

# Use UHD source blocks
gnuradio-companion
```

### Verify Current Setup

```bash
# Check what's installed
brew list | grep -E "(sdr|soap|uhd)"

# Should see:
# - uhd
# - soapysdr
# - soapyuhd (or similar)
```

### Full Installation from Scratch

If starting fresh:

```bash
# Install everything needed
brew install uhd
brew install soapysdr
brew install soapyuhd
brew install sdrpp

# Download UHD images
python3 /opt/homebrew/lib/uhd/utils/uhd_images_downloader.py -t b2xx

# Install B210 clone firmware
cp "B210/firmware/Kintex-7 USRP_B210/需替换BIN文件/usrp_b210_fpga.bin" \
   /opt/homebrew/share/uhd/images/usrp_b210_fpga.bin

# Test
SoapySDRUtil --find
```

---

**Bottom line**: You need **SoapySDR + SoapyUHD module** for SDR++ to see your B210. Install with `brew install soapysdr soapyuhd`.
