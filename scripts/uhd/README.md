# UHD Scripts

Scripts for UHD-based SDR devices (USRP B210, B200, etc.).

These scripts use UHD command-line tools and are optimized for USRP hardware.

## Scripts

### Testing
- `test_b210.sh` - Comprehensive regression test suite for B210
- `b210_rx_test.sh` - RX functionality test

### Spectrum Analysis
- `b210_spectrum.sh` - Real-time spectrum display using rx_ascii_art_dft

### Optimization
- `optimize_rx.sh` - Interactive RX parameter optimization
- `auto_optimize.sh` - Automatic gain/rate optimization for current frequency

## Requirements

- UHD installed (`brew install uhd` or `apt install uhd-host`)
- USRP B210/B200 or compatible device
- macOS: UHD examples in `/opt/homebrew/lib/uhd/examples`
- Linux: UHD examples in `/usr/lib/uhd/examples`

## Usage Examples

```bash
# Run full test suite
./scripts/uhd/test_b210.sh

# View spectrum at 98 MHz
./scripts/uhd/b210_spectrum.sh 98e6

# Auto-optimize for FM band
./scripts/uhd/auto_optimize.sh --freq 98e6
```

## Notes

- All scripts handle the B210 clone's float32 bug by using `--type short`
- Default antenna: RX2 for < 1 GHz, TX/RX for > 1 GHz
- Recommended sample rate: 2 MHz for general use
