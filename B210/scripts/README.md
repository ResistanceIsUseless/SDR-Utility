# B210 Scripts

Scripts specific to the USRP B210 Clone (XC7K325T FPGA + AD9361).

## Directory Structure

### setup/
**One-time setup and installation scripts**
- `setup_b210_mac.sh` - Complete B210 setup for macOS (UHD, drivers, permissions)
- `setup_b210.sh` - Linux setup variant
- `install_soapy_uhd.sh` - Install SoapyUHD module for SDR++ compatibility
- `libresdr_patch.sh` - Apply libresdr patches for B210 clone compatibility

### firmware/
**Firmware management and fixes**
- `fix_float32_firmware.sh` - Fix float32 conversion bug in B210 clone firmware
- `install_fixed_firmware.sh` - Install patched firmware to UHD images directory

## Operational Scripts

Operational scripts have been moved to the root `scripts/` directory:

- **scripts/uhd/** - UHD/B210-specific operational scripts (testing, optimization)
- **scripts/sdr/** - Generic SDR scripts (analysis, scanning) that work with any SDR

## Usage

### First-Time Setup
```bash
# macOS
./B210/scripts/setup/setup_b210_mac.sh

# Linux
./B210/scripts/setup/setup_b210.sh

# Add SoapyUHD for SDR++ support
./B210/scripts/setup/install_soapy_uhd.sh
```

### Firmware Fix (if needed)
```bash
# Fix float32 bug
./B210/scripts/firmware/fix_float32_firmware.sh

# Install fixed firmware
./B210/scripts/firmware/install_fixed_firmware.sh
```

### Testing and Operation
See `scripts/uhd/` and `scripts/sdr/` for operational scripts.
