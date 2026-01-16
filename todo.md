# SDR Tools Installation Status

## Completed
- [x] Install core dependencies (Homebrew, Python)
- [x] Install GNU Radio and SoapySDR stack
- [x] Install SDR++ with UHD/SoapySDR support (built from source)
- [x] Install SDR GUI applications (GQRX, inspectrum, URH)
- [x] Install signal decoders (rtl_433, rtlamr, multimon-ng)
- [x] Install kalibrate-rtl for GSM cell scanning
- [x] Install SoapyUHD module (built from source)
- [x] Install Python analysis tools
- [x] RF-Swift Docker (telecom_2Gto3G - 13.5GB with srsRAN, gr-gsm, etc.)
- [x] Create cellular workflow scripts

## Pending
- [ ] Install Wireshark (requires sudo - run: `brew install --cask wireshark`)

## Installed Tools Summary

### GUI Applications
| Tool | Command | Description |
|------|---------|-------------|
| **SDR++** | `~/bin/sdrpp` | SDR++ with B210/UHD support (WORKING) |
| GQRX | `gqrx` | SDR receiver with waterfall |
| GNU Radio | `gnuradio-companion` | Signal processing framework |
| URH | `urh` | Universal Radio Hacker |
| inspectrum | `inspectrum` | Signal analyzer |

### Signal Decoders
| Tool | Command | Description |
|------|---------|-------------|
| rtl_433 | `rtl_433` | ISM band decoder (433/315/868 MHz) |
| multimon-ng | `multimon-ng` | Multi-protocol decoder (POCSAG, DTMF) |
| rtlamr | `~/go/bin/rtlamr` | Smart meter decoder |
| kalibrate | `kal` | GSM cell tower scanner |

### Cellular Tools (via Docker)
| Tool | Description |
|------|-------------|
| srsRAN | 4G/5G LTE stack (srsue, srsenb) |
| gr-gsm | GSM decoder (grgsm_decode) |
| kalibrate | Cell tower scanner |
| Wireshark | Protocol analyzer |
| IMSI tools | IMSI catcher detection |

### Docker Image
```
penthertz/rfswift_noble:telecom_2Gto3G (13.5GB)
```

## Cellular Testing Workflow

Since Docker on macOS can't access USB, use two-step workflow:

### 1. Capture IQ Data (Native)
```bash
# GSM capture
cellular capture-gsm 935.2e6

# LTE capture (Band 13 Verizon)
cellular capture-lte 746e6

# 5G NR capture
cellular capture-5g 3700e6
```

### 2. Analyze in Docker
```bash
cellular analyze
# Inside container:
# grgsm_decode -c /root/data/captures/gsm_*.dat
# cell_search -b 13
```

### Helper Scripts
- `~/bin/sdrpp` - Launch SDR++ with B210 support
- `~/bin/cellular` - Cellular capture/analysis workflow
- `~/sdr_data/start_rfswift.sh` - Launch RF-Swift container

## Common Frequencies

### LTE Bands
| Band | Frequency | Carrier |
|------|-----------|---------|
| 2 | 1930 MHz | AT&T/T-Mobile |
| 4 | 2110 MHz | AWS |
| 13 | 746 MHz | Verizon |
| 66 | 2110 MHz | Extended AWS |

### 5G NR Bands
| Band | Frequency | Notes |
|------|-----------|-------|
| n41 | 2500 MHz | T-Mobile |
| n77 | 3700 MHz | C-band |
| n78 | 3500 MHz | Mid-band |

## B210 Clone Notes
- Always use `--type short` for command-line captures
- SDR++ handles format automatically (works fine)
- RX2 antenna for < 1 GHz, TX/RX for > 1 GHz
