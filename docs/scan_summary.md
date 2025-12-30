# CaribouLite Frequency Scan Summary
**Date:** 2025-12-05
**Hardware:** CaribouLite HiF Channel (1MHz - 6GHz)

## Successfully Decoded Data Streams

### 1. 315 MHz - ISM US Band
**Signal Type:** Pulse Width Modulation (PWM)
**Devices Detected:**

#### HT680 Remote Control
- **Time:** 15:07:31
- **Address:** 0x0A0402
- **Status:** Buttons 2 & 3 PRESSED
- **Tristate Code:** ZZ00X0000ZXZ1Z101X
- **Use Case:** Remote control device (likely garage door or gate opener)

#### Security+ v1 Protocol (Garage Door Opener)
- **Time:** 15:07:34 - 15:07:36
- **Fixed Code:** 903981141
- **Rolling Code:** 1376075364
- **Protocol:** LiftMaster/Chamberlain Security+ v1
- **Use Case:** Garage door opener with rolling code security

### 2. 121.5 MHz - Aviation Emergency Frequency
**Signal Type:** FSK (Frequency Shift Keying)
**Activity:** Multiple FSK packages detected
- **Pulse Patterns:** Complex multi-width patterns (44-1264 μs)
- **SNR:** ~27-39 dB (strong signal)
- **Status:** Raw FSK detected but not decoded to specific protocol

### 3. 162.4 MHz - NOAA Weather Radio
**Signal Type:** FSK (Frequency Shift Keying)
**Activity:** Strong FSK signals detected
- **Pulse Patterns:** Complex timing (44-1264 μs range)
- **SNR:** Strong signal quality
- **Status:** FSK carrier detected, likely SAME/EAS weather alerts

## Signal Detection Summary (Without Full Decode)

### 100 MHz - FM Radio Band
- **Signal Type:** OOK (On-Off Keying)
- **Pulse Widths:** 44 μs - 2180 μs
- **RSSI:** -24.3 dB
- **SNR:** 29.9 dB

### 137.5 MHz - NOAA Weather Satellite (APT)
- **Signal Type:** OOK pulses
- **Activity:** Intermittent short pulses (40-44 μs)
- **SNR:** ~19 dB

### 433.92 MHz - ISM EU Band
- **Signal Type:** OOK
- **Activity:** Single isolated pulses
- **RSSI:** -24.3 dB
- **Status:** Minimal activity during scan period

### 868 MHz - ISM EU Band
- **Status:** No signals detected during scan

### 915 MHz - ISM US Band
- **Status:** No signals detected during scan

### 1090 MHz - ADS-B Aircraft Transponders
- **Signal Type:** OOK
- **Activity:** Single pulses detected (127-147 μs)
- **SNR:** 25-29 dB
- **Status:** Pulse detection but no complete ADS-B packet decode

### 1575.42 MHz - GPS L1
- **Status:** No signals detected (expected - requires specialized GPS receiver)

### 2.4 GHz - WiFi/ISM Band
- **Signal Type:** OOK
- **Activity:** Multiple short pulses detected
- **Pulse Widths:** 2-24 μs
- **Status:** WiFi/Bluetooth activity present

### 5.8 GHz - WiFi 5GHz Band
- **Status:** Not scanned (frequency may be at edge of HiF range)

## Most Active Frequencies

1. **315 MHz** - Multiple decodable transmissions (garage openers, remotes)
2. **121.5 MHz** - Strong FSK aviation signals
3. **162.4 MHz** - Weather radio FSK signals
4. **2.4 GHz** - WiFi/ISM activity
5. **1090 MHz** - Some ADS-B aircraft pulse activity

## Technical Notes

- **Sample Rate:** 1.333 MHz (4M/3)
- **Bandwidth:** 160 kHz
- **Gain:** AGC (Automatic Gain Control) 0-69 dB range
- **Detection Method:** rtl_433 with auto-level threshold adjustment
- **Antenna:** Connected to CaribouLite HiF channel

## Recommendations for Further Analysis

1. **ADS-B Decoding:** Use dump1090 or similar ADS-B-specific decoder for aircraft tracking
2. **Weather Satellite:** Use WXtoImg or noaa-apt for NOAA APT image decoding
3. **Aviation Voice:** Use GQRX or SDR++ with AM/FM demodulation for 121.5 MHz
4. **Extended Monitoring:** Run longer scans (hours) to capture more intermittent transmissions
5. **Frequency Hopping:** Monitor 2.4 GHz band with wider bandwidth for Bluetooth/WiFi analysis

## Files Generated

- `/home/dragon/315mhz_decoded.txt` - Full 315 MHz scan results
- `/home/dragon/433mhz_decoded.txt` - Full 433 MHz scan results
- `/home/dragon/915mhz_decoded.txt` - Full 915 MHz scan results
- `/home/dragon/tpms_scan.txt` - TPMS sensor scan results
- `/home/dragon/freq_scan.sh` - Scanning script for reuse
