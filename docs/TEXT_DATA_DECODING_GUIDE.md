# Text & Data Decoding Guide

Complete guide to intercepting and decoding text messages, pager data, and telemetry from RF signals.

## Overview

This platform can decode multiple types of text/data transmissions:

1. **POCSAG/FLEX Pagers** - Fire/EMS/hospital dispatch messages
2. **P25 Short Data Service (SDS)** - Police/public safety text & GPS
3. **ISM Band Devices** - Weather sensors, TPMS, IoT telemetry
4. **APRS** - Amateur radio position reports & messages

---

## 1. Pager Decoding (POCSAG/FLEX)

### What Are Pagers?

Traditional one-way messaging devices still widely used by:
- **Fire departments** - Dispatch notifications
- **Hospitals** - Doctor/nurse alerts
- **EMS** - Emergency response
- **Utilities** - Maintenance calls

### Common Pager Frequencies

| Frequency    | Use Case                  | Coverage      |
|--------------|---------------------------|---------------|
| 152.0075 MHz | Fire/EMS (most common)    | Regional      |
| 152.2400 MHz | Hospital paging           | Local         |
| 152.8400 MHz | Commercial paging         | Regional      |
| 157.4500 MHz | Wide area paging          | Multi-state   |
| 163.2500 MHz | Regional dispatch         | Multi-county  |
| 453.xxxx MHz | UHF paging                | Local         |

### Pager Protocols

**POCSAG** (Post Office Code Standardisation Advisory Group):
- **POCSAG512** - 512 baud (most common, older systems)
- **POCSAG1200** - 1200 baud (common)
- **POCSAG2400** - 2400 baud (less common)

**FLEX**:
- Advanced paging protocol
- Higher throughput
- Better error correction

### Quick Start: Decode Fire/EMS Pages

```bash
cd /home/static/sdr-utilities/scripts

# Most common fire/EMS paging frequency
./pager_decoder.sh --freq 152007500
```

**Example Output:**
```
POCSAG512: Address: 1234567  Function: 0  Alpha:
"STATION 5 RESPOND TO STRUCTURE FIRE 123 MAIN ST CROSS ST ELM"

POCSAG512: Address: 2345678  Function: 3  Numeric: "555-1234"

POCSAG1200: Address: 3456789  Function: 2  Alpha:
"DR SMITH CALL ER STAT CODE BLUE ROOM 302"
```

### Hunt for Active Pagers

```bash
# Scan VHF paging band and auto-decode
./signal_hunter.sh \
    --start 152000000 \
    --stop 154000000 \
    --mode pager \
    --step 12500 \
    --passes 10
```

### Decode All Pager Types

```bash
# Decode POCSAG512, POCSAG1200, POCSAG2400, and FLEX
./pager_decoder.sh \
    --freq 152007500 \
    --protocol ALL \
    --log fire_dispatch.log
```

### Understanding Pager Messages

**Address:** Unique pager ID (7-digit capcode)
**Function:** Message type (0-3)
- Function 0: Alphanumeric (text messages)
- Function 1: Numeric only
- Function 2: Tone alert
- Function 3: Activation/special

**Message Types:**
- **Alpha:** Full text messages
- **Numeric:** Phone numbers, unit codes
- **Tone:** Just beeps (no text)

---

## 2. P25 Data Decoding (Short Data Service)

### What is P25 SDS?

P25 digital radio systems carry data alongside voice:
- **Text messages** between units and dispatch
- **GPS coordinates** (AVL - Automatic Vehicle Location)
- **Status updates** (10-8 = in-service, 10-97 = arrived)
- **Unit IDs** and affiliations
- **Emergency alerts**

### P25 Data is Already Decoded!

OP25 automatically decodes P25 data - it's part of our p25_decoder.sh:

```bash
# Decode P25 voice AND data
./p25_decoder.sh --freq 851000000 --verbose
```

**Example Output:**
```
P25 Phase 1
TGID: 1234 (Police Dispatch)
SRC:  5678 (Unit 23)
Type: Data
SDS:  "10-97 AT 123 MAIN ST"

P25 Phase 1
TGID: 1234 (Police Dispatch)
SRC:  5678 (Unit 23)
GPS:  37.7749° N, 122.4194° W
Speed: 35 MPH
```

### P25 Data Types

| Type | Description | Example |
|------|-------------|---------|
| **SDS** | Short Data Service text | "10-97", "ETA 5 MIN" |
| **GPS** | Location coordinates | 37.7749° N, 122.4194° W |
| **Status** | Unit status codes | 10-8, 10-97, 10-23 |
| **Emergency** | Emergency button pressed | EMERGENCY UNIT 23 |
| **Affiliation** | Unit joins talkgroup | Unit 23 → TG 1234 |

### Logging P25 Data

```bash
# Log all P25 voice and data to file
./p25_decoder.sh \
    --freq 851000000 \
    --verbose \
    2>&1 | tee p25_data.log
```

### Extract Only Data Messages

```bash
# Filter for SDS/GPS only
./p25_decoder.sh --freq 851000000 --verbose 2>&1 | grep -E "SDS|GPS"
```

---

## 3. ISM Band Device Decoding

### What is the ISM Band?

Industrial, Scientific, Medical (ISM) unlicensed bands used by:
- Weather stations
- Wireless thermometers
- Tire pressure monitors (TPMS)
- Smart home sensors
- Garage door openers
- Wireless doorbells

### Common ISM Frequencies

| Frequency | Region | Devices |
|-----------|--------|---------|
| 315 MHz   | North America | Garage doors, car remotes, TPMS |
| 433.92 MHz| Europe/Asia | Weather stations, sensors, remotes |
| 868 MHz   | Europe | Smart home, LoRa |
| 915 MHz   | North America | Industrial sensors, LoRa |

### Quick Start: Find Weather Stations

```bash
cd /home/static/sdr-utilities/scripts

# Most common ISM frequency (433.92 MHz)
./ism_decoder.sh --freq 433920000
```

**Example Output:**
```
time      : 2026-01-01 08:45:23
model     : Acurite-Tower
id        : 12345
channel   : A
battery   : OK
temperature_C : 22.3
humidity  : 45

time      : 2026-01-01 08:45:45
model     : LaCrosse-TX141THBv2
id        : 234
temperature_C : 21.1
humidity  : 52
battery   : OK
test      : No

time      : 2026-01-01 08:46:12
model     : Fine-Offset-WHx080
id        : 45678
temperature_C : 23.5
humidity  : 48
wind_avg_m_s : 2.3
wind_dir_deg : 180
rain_mm  : 0.0
```

### Hunt for ISM Devices

```bash
# Scan 433 MHz band for active devices
./signal_hunter.sh \
    --start 433800000 \
    --stop 434100000 \
    --mode ism \
    --step 50000 \
    --passes 10
```

### Decode TPMS (Tire Pressure Monitors)

```bash
# 315 MHz - North American TPMS
./ism_decoder.sh --freq 315000000 --log tpms.log
```

**Example TPMS Output:**
```
time      : 2026-01-01 09:15:34
model     : Schrader
type      : TPMS
id        : A1B2C3D4
pressure_PSI : 32.5
temperature_C : 25
battery   : OK
```

### JSON Output for Parsing

```bash
# JSON format for programmatic parsing
./ism_decoder.sh \
    --freq 433920000 \
    --format json \
    --log devices.json
```

---

## 4. Typical Workflows

### Workflow 1: Monitor Fire Dispatch

```bash
# 1. Find active paging frequency
./signal_hunter.sh \
    --start 152000000 \
    --stop 154000000 \
    --mode pager \
    --step 12500

# 2. Decode strongest pager frequency found
./pager_decoder.sh --freq 152007500 --log fire_dispatch.log
```

### Workflow 2: Track Police GPS

```bash
# Decode P25 with verbose data output
./p25_decoder.sh --freq 851000000 --verbose 2>&1 | \
    tee -a p25_full.log | \
    grep -E "GPS|SDS"
```

### Workflow 3: Find IoT Devices

```bash
# Scan 433 MHz for wireless sensors
./signal_hunter.sh \
    --start 433800000 \
    --stop 434100000 \
    --mode ism \
    --step 50000

# Log all found devices
./ism_decoder.sh --freq 433920000 --format json --log iot_devices.json
```

### Workflow 4: Comprehensive SIGINT

```bash
# 1. Scan VHF public safety (P25 + pagers)
./signal_hunter.sh --start 162e6 --stop 174e6 --mode p25

# 2. Scan 800 MHz (P25 only)
./signal_hunter.sh --start 851e6 --stop 869e6 --mode p25

# 3. Check for pagers
./pager_decoder.sh --freq 152007500 --protocol ALL

# 4. Check ISM devices
./ism_decoder.sh --freq 433920000
```

---

## 5. Decoder Reference

### Pager Decoder Options

```bash
./pager_decoder.sh \
    --freq 152007500 \      # Frequency in Hz
    --gain 40 \              # RX gain
    --protocol POCSAG512 \   # POCSAG512, POCSAG1200, POCSAG2400, FLEX, ALL
    --log pager.log          # Optional log file
```

### ISM Decoder Options

```bash
./ism_decoder.sh \
    --freq 433920000 \       # Frequency in Hz
    --gain 40 \              # RX gain
    --format kv \            # kv, json, csv
    --log devices.log        # Optional log file
```

### P25 Decoder Options

```bash
./p25_decoder.sh \
    --freq 851000000 \       # Frequency in Hz
    --gain 50 \              # RX gain
    --verbose \              # Show data messages
    --nac 0x293 \            # Filter by NAC
    --trunking               # Trunking mode (follows control channel)
```

---

## 6. Common Frequencies Reference

### VHF Paging (152-159 MHz)

```
152.0075 - Fire/EMS dispatch (most common)
152.0150 - Fire/EMS alternate
152.2400 - Hospital paging
152.8400 - Commercial paging
153.7700 - Regional paging
157.4500 - Wide area paging
```

### UHF Paging (450-470 MHz)

```
453.xxxx - Local paging
462.xxxx - GMRS/paging overlap
```

### P25 Public Safety

```
VHF:      162-174 MHz (Fire/EMS)
700 MHz:  763-775, 793-805 MHz
800 MHz:  851-869 MHz (most common)
```

### ISM Bands

```
315 MHz:  315.000 (North America - remotes, TPMS)
433 MHz:  433.920 (Europe/Asia - sensors)
868 MHz:  868.000 (Europe - smart home)
915 MHz:  915.000 (North America - industrial)
```

---

## 7. Tips & Tricks

### Increase Pager Detection

Pagers transmit in bursts - use longer dwell time:
```bash
./signal_hunter.sh \
    --start 152e6 --stop 154e6 \
    --mode pager \
    --dwell 0.5 \
    --passes 10
```

### Filter P25 Data Only

```bash
# Extract only GPS coordinates
./p25_decoder.sh --freq 851e6 --verbose 2>&1 | grep "GPS:"

# Extract only text messages
./p25_decoder.sh --freq 851e6 --verbose 2>&1 | grep "SDS:"
```

### Log ISM Devices Over Time

```bash
# Run for 24 hours, log all devices
timeout 86400 ./ism_decoder.sh \
    --freq 433920000 \
    --format json \
    --log "ism_$(date +%Y%m%d).json"
```

### Multi-Frequency Pager Monitoring

```bash
# Monitor multiple pager frequencies
while true; do
    timeout 300 ./pager_decoder.sh --freq 152007500 --log pager1.log &
    timeout 300 ./pager_decoder.sh --freq 152240000 --log pager2.log &
    wait
done
```

---

## 8. Understanding Output

### Pager Message Format

```
POCSAG512: Address: 1234567  Function: 0  Alpha: "MESSAGE TEXT"
           ^         ^        ^            ^      ^
           Protocol  Capcode  Type         Format Content
```

### P25 Data Format

```
TGID: 1234 (Police Dispatch)    ← Talkgroup
SRC:  5678 (Unit 23)             ← Source unit
Type: Data                       ← Message type
SDS:  "10-97 AT 123 MAIN ST"    ← Text content
```

### ISM Device Format (Key-Value)

```
model     : Acurite-Tower     ← Device manufacturer/model
id        : 12345             ← Unique device ID
channel   : A                 ← Channel setting
temperature_C : 22.3          ← Temperature in Celsius
humidity  : 45                ← Humidity percentage
battery   : OK                ← Battery status
```

---

## 9. Security & Privacy Considerations

### Legal Monitoring

**Generally Legal:**
- Receiving broadcast pager messages (public safety transparency)
- Decoding P25 public safety data (unencrypted)
- Monitoring ISM band devices

**Important Notes:**
- Do not use intercepted information for illegal purposes
- Do not interfere with emergency services
- Respect privacy of non-public communications
- Check local laws regarding interception

### Encrypted P25

Modern P25 systems often use **AES encryption** for sensitive communications:
```
P25 Phase 1
TGID: 1234 (Narcotics Unit)
Type: Voice
Encryption: AES-256
```

**You cannot decrypt encrypted P25** - it will just show as encrypted.

### HIPAA Considerations

Hospital pagers may contain **protected health information (PHI)**:
- Patient names
- Room numbers
- Medical conditions

**Use only for authorized research/monitoring.**

---

## 10. Troubleshooting

### No Pager Messages Received

**Possible causes:**
1. Wrong frequency - scan first with signal_hunter
2. Too short dwell time - pagers burst, use --passes 10
3. Low gain - try --gain 50
4. Wrong protocol - try --protocol ALL

**Solution:**
```bash
# Scan first to find active pagers
./signal_hunter.sh --start 152e6 --stop 154e6 --mode pager --passes 10
```

### P25 Data Not Showing

**OP25 shows voice but no data:**
- Add `--verbose` flag
- Data is intermittent - wait longer
- System may be fully encrypted

```bash
./p25_decoder.sh --freq 851e6 --verbose -v 3
```

### ISM Devices Not Decoded

**rx_sdr running but no devices:**
1. Wrong frequency - 433.92 MHz is Europe/Asia, not USA
2. No devices nearby - move closer or use better antenna
3. Transmission interval - sensors transmit every 30-60 seconds

**Solution:**
```bash
# USA: Try 315 MHz for TPMS/remotes
./ism_decoder.sh --freq 315000000

# Europe: Try 433.92 MHz
./ism_decoder.sh --freq 433920000
```

---

## 11. Script Locations

```
/home/static/sdr-utilities/scripts/
├── pager_decoder.sh    # POCSAG/FLEX pager decoder
├── ism_decoder.sh      # ISM band device decoder
├── p25_decoder.sh      # P25 voice & data decoder
└── signal_hunter.sh    # Auto-detect & decode (supports all modes)
```

## 12. Next Steps

1. **Find local pagers** - Scan 152-159 MHz
2. **Monitor P25 data** - Add --verbose to p25_decoder
3. **Discover IoT devices** - Scan 433 MHz ISM band
4. **Automate collection** - Set up long-term logging
5. **Analyze patterns** - Parse logs for trends

---

**Built for comprehensive text/data SIGINT with USRP B210**

Last Updated: 2026-01-01
