# SDR Analysis Scripts

Generic SDR analysis scripts that work with any SDR hardware (B210, RTL-SDR, HackRF, etc.).

These scripts analyze captured IQ data and perform signal processing tasks.

## Scripts

### Signal Analysis
- `analyze_signal.py` - Basic signal analysis (FFT, power spectral density)
- `analyze_with_dc_removal.py` - Signal analysis with DC offset removal
- `analyze_with_dc_removal_pure.py` - Pure Python DC removal implementation

### Scanning
- `scan_fm.sh` - Scan FM broadcast band (88-108 MHz) and identify stations

## Requirements

### Python Scripts
```bash
pip3 install numpy scipy matplotlib
```

### Shell Scripts
- Any SDR hardware with command-line tools
- For UHD devices: `rx_samples_to_file`
- For RTL-SDR: `rtl_sdr`
- For HackRF: `hackrf_transfer`

## Usage Examples

### Capture and Analyze
```bash
# Capture IQ data
rx_samples_to_file --freq 98e6 --rate 2e6 --gain 50 \
  --ant RX2 --type short --duration 5 --file fm_capture.dat

# Analyze captured data
python3 scripts/sdr/analyze_with_dc_removal_pure.py fm_capture.dat
```

### FM Band Scan
```bash
./scripts/sdr/scan_fm.sh
```

## Input Format

Analysis scripts expect raw IQ data in the following formats:
- **int16 (sc16)**: Interleaved I/Q samples, 16-bit signed integers
- **float32**: Interleaved I/Q samples, 32-bit floats (if your hardware supports it)
- **complex64**: Complex samples (NumPy format)

Default assumption: int16 (sc16) format

## Output

- **FFT plots**: Frequency domain representation
- **Time domain plots**: I/Q waveforms
- **Power spectral density**: Signal power distribution
- **Statistics**: SNR, peak frequency, bandwidth estimates
