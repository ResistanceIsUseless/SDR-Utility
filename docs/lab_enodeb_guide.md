# Lab eNodeB Setup Guide - Controlled IMEI Research Environment

## ⚠️ CRITICAL WARNINGS ⚠️

### Legal Requirements

**DO NOT operate this system unless ALL of the following are true:**

1. ✅ **RF Shielded Environment:** Faraday cage or RF-shielded room (<-80 dB attenuation)
2. ✅ **Own Devices Only:** Test with SIM cards and devices you personally own
3. ✅ **No Signal Leakage:** Verified with spectrum analyzer
4. ✅ **Legal Authorization:** Written documentation of security research purpose
5. ✅ **Local Compliance:** Checked applicable laws in your jurisdiction

**Operating an unauthorized eNodeB can result in:**
- Heavy fines (up to $100,000+ in many jurisdictions)
- Criminal charges
- Interference with emergency services
- FCC/regulatory investigation

**This guide is for educational and security research ONLY.**

---

## Overview

This setup creates a complete LTE network in your lab:

```
[Phone/UE] <--RF--> [USRP B210] <--USB 3.0--> [srsENB] <--S1--> [srsEPC]

                                                    +--> IMEI Captured
                                                    +--> IMSI Captured
                                                    +--> Logs & PCAPs
```

**Purpose:**
- Test IMEI randomization features
- Research LTE security mechanisms
- Validate IMSI catcher detection tools
- Educational understanding of LTE protocols

---

## RF Isolation Requirements

### Minimum Requirements

**Option 1: Faraday Cage (Recommended)**
- Commercial RF shielded enclosure
- Attenuation: >80 dB @ 2 GHz
- Size: Large enough for USRP + antenna + test device
- Examples:
  - Ramsey STE2000 or similar
  - Custom copper mesh enclosure
  - RF shielded room/tent

**Option 2: RF Attenuators (Less Safe)**
- 60+ dB attenuators on TX path
- SMA attenuators in series
- Coaxial cable connections only (no antenna!)
- Risk: Still possible signal leakage

**Option 3: Cable-Only (Safest)**
- USRP TX → Attenuator (30 dB) → Attenuator (30 dB) → Phone RF input (requires special cable)
- No wireless transmission
- Requires phone with external antenna connector

### Verification Procedure

**BEFORE operating eNodeB:**

```bash
# 1. Put USRP in Faraday cage
# 2. Run spectrum analyzer OUTSIDE cage
# 3. Transmit test signal on USRP

# From outside cage, scan for leakage
uhd_fft -f 2.6e9 -s 10e6

# Should see nothing above noise floor
# If signal detected: DO NOT PROCEED
```

**Legal threshold:** Typically need <-80 dBm outside cage.

---

## System Architecture

### Components

1. **srsENB** (eNodeB - Base Station)
   - Handles radio interface (PHY, MAC, RLC, PDCP, RRC)
   - Communicates with UEs over RF
   - Connects to EPC via S1 interface

2. **srsEPC** (Evolved Packet Core)
   - MME (Mobility Management Entity) - handles signaling
   - HSS (Home Subscriber Server) - stores user credentials
   - SP-GW (Serving/Packet Gateway) - data plane

3. **USRP B210** - Software-defined radio

### Network Configuration

```
MCC/MNC: 001/01 (Test network)
Band: 7 (2600 MHz) - NOT Band 2 to avoid real networks
Bandwidth: 10 MHz (50 PRB)
TAC: 0x0007
Cell ID: 0x19B
TX Power: 30 dB (LOW - for lab only!)
```

**Why Band 7?**
- Not heavily used in US
- Different from Band 2 (our defensive monitoring band)
- Reduces risk of accidental interference

---

## Setup Instructions

### Step 1: Verify RF Isolation

```bash
# Test procedure documented above
# DO NOT SKIP THIS STEP
```

### Step 2: Prepare Configuration Files

All files created at `/home/static/`:
- `lab_enb.conf` - eNodeB configuration
- `lab_epc.conf` - Core network configuration
- `user_db.csv` - Subscriber database

### Step 3: Configure User Database

Edit `user_db.csv` to add your test SIM credentials:

```csv
# Your test UE
my_phone,mil,YOUR_IMSI,YOUR_K,opc,YOUR_OPC,8000,000000000000,9,dynamic
```

**Getting SIM credentials:**

**Option A: Programmable SIM Cards (Recommended)**
- Buy sysmocom sysmoUSIM-SJS1 or similar
- Program with known credentials using `pySim`
- Use for testing only

**Option B: Extract from existing SIM (Advanced)**
```bash
# WARNING: May brick your SIM!
# Only use with SIMs you own and don't need

# Using pySim-read
pySim-read.py -p0 -d /dev/ttyUSB0

# Will show IMSI, may show Ki if accessible
```

**NEVER use credentials from:**
- Active service SIM cards
- SIMs you don't own
- Production devices

### Step 4: Start Core Network

```bash
# Terminal 1: Start EPC
cd /home/static
sudo ./srsRAN_4G/build/srsepc/src/srsepc ./lab_epc.conf
```

**Expected output:**
```
Built in Release mode using commit...
Reading configuration file...
MME S1 setup request
Connecting to AMF on 127.0.0.1:38412
HSS Initialized
SPGW GTP-U Initialized
```

### Step 5: Start eNodeB

```bash
# Terminal 2: Start eNB (in Faraday cage!)
cd /home/static
UHD_IMAGES_DIR=/usr/share/uhd/4.9.0/images \
sudo ./srsRAN_4G/build/srsenb/src/srsenb ./lab_enb.conf
```

**Expected output:**
```
Opening USRP channels=1
USRP RF device successfully opened
Setting frequency: 2630.00 MHz
S1AP: S1 Setup Request sent
S1AP: S1 Setup Response received
```

### Step 6: Connect Test Device

**On your test phone (in Faraday cage):**

1. **Enable airplane mode first**
2. Insert test SIM card
3. Disable airplane mode
4. **Manually select network:** Settings → Mobile → Network → Search → Select "00101" (Test PLMN)
5. Phone should connect

**What happens:**
1. Phone scans for networks → Finds your eNodeB
2. Phone attempts RACH → eNodeB responds
3. Phone sends Attach Request → **IMSI/IMEI transmitted**
4. EPC authenticates using credentials from `user_db.csv`
5. Connection established

### Step 7: Capture IMEI/IMSI

**Check logs:**

```bash
# EPC log shows attachment with IMEI
grep -i "imei\|attach" /tmp/epc.log

# Example output:
# NAS - Attach Request - IMSI: 001010123456789
# NAS - UE Capabilities - IMEISV: 3534900698733190
```

**Check PCAP files:**

```bash
# Open with Wireshark
wireshark /tmp/epc_nas.pcap &

# Filter for attach request:
# nas_eps.nas_msg_emm_type == 0x41

# Look for "Mobile identity - IMEISV"
```

**Parse from S1AP:**

```bash
# Install asn1 tools
sudo apt-get install asn1c

# Decode S1AP messages
tshark -r /tmp/epc_s1ap.pcap -Y "s1ap" -T fields \
  -e s1ap.IMEISV -e s1ap.IMSI | grep -v "^$"
```

---

## Security Research Applications

### Test 1: IMEI Randomization

**Purpose:** Verify Android 10+ IMEI randomization

**Procedure:**
1. Connect phone 1st time → Record IMEI
2. Factory reset phone
3. Connect phone 2nd time → Record IMEI
4. Compare: Should be different if randomization works

**Expected:**
- Android 10+: IMEI should randomize
- Older Android: Same IMEI
- iOS: Generally randomizes

### Test 2: IMSI Catcher Detection Tools

**Purpose:** Test SnoopSnitch, G3Torch, etc.

**Procedure:**
1. Install detection app on test phone
2. Connect to your lab eNodeB
3. Check if app detects suspicious behavior
4. Tune eNodeB parameters to avoid detection
5. Understand detection limitations

**What to test:**
- Does app detect no encryption (EEA0)?
- Does it flag unknown PLMN?
- Does it detect LAC/TAC anomalies?
- Response to fake neighbor lists?

### Test 3: Forced Downgrade

**Purpose:** Test 4G→2G downgrade attacks

**Modify `lab_enb.conf`:**
```
# Enable 2G fallback
# (requires srsENB with 2G support or separate 2G BTS)
```

**Then observe:**
- Does phone accept downgrade?
- Do security apps alert?
- Is encryption disabled in 2G mode?

### Test 4: Paging Message Injection

**Purpose:** Understand paging-based tracking

**Procedure:**
1. Connect phone to network
2. From EPC, trigger paging
3. Observe in PCAP: Paging message with IMSI/TMSI
4. Understand privacy implications

**Code location:**
- `srsRAN_4G/srsepc/src/mme/s1ap.cc` - paging functions

---

## Data Collection & Analysis

### Logs to Review

**1. EPC Log (`/tmp/epc.log`):**
```bash
# Find IMEI/IMSI
grep -E "IMSI|IMEI|Attach" /tmp/epc.log

# Example:
# 2025-12-31T22:30:00 [NAS] Attach Request - IMSI: 001010123456789
# 2025-12-31T22:30:01 [NAS] UE Capabilities - IMEISV: 3534900698733190
```

**2. eNB Log (`/tmp/enb.log`):**
```bash
# Find UE attachments
grep -i "rrc.*setup\|attach" /tmp/enb.log
```

**3. PCAP Files:**

Open in Wireshark:
```bash
wireshark /tmp/epc_nas.pcap &
```

**Wireshark filters:**
- Attach Request: `nas_eps.nas_msg_emm_type == 0x41`
- IMSI: `nas_eps.emm.imsi`
- IMEISV: `nas_eps.emm.imeisv`
- All NAS: `nas_eps`

### Extracting IMEI Programmatically

**Python script:**

```python
#!/usr/bin/env python3
import re

def extract_imei_from_log(log_file):
    """Extract IMEI/IMEISV from EPC log"""
    with open(log_file, 'r') as f:
        for line in f:
            if 'IMEISV' in line:
                # IMEISV format: 16 digits (IMEI + software version)
                match = re.search(r'IMEISV:?\s*(\d{16})', line)
                if match:
                    imeisv = match.group(1)
                    imei = imeisv[:14]  # First 14 digits
                    sv = imeisv[14:]     # Software version
                    print(f"IMEI: {imei}")
                    print(f"SV: {sv}")
                    return imei

            if 'IMSI' in line:
                match = re.search(r'IMSI:?\s*(\d{15})', line)
                if match:
                    print(f"IMSI: {match.group(1)}")

    return None

# Usage
extract_imei_from_log('/tmp/epc.log')
```

**Run:**
```bash
chmod +x extract_imei.py
./extract_imei.py
```

---

## Troubleshooting

### UE Doesn't See Network

**Check:**
1. RF isolation setup correct? (Faraday cage closed?)
2. eNB and EPC both running?
3. S1 connection established? (check eNB log)
4. Correct band/frequency?

**Debug:**
```bash
# Check S1AP connection
grep "S1 Setup" /tmp/enb.log

# Should show:
# S1AP: S1 Setup Request sent
# S1AP: S1 Setup Response received
```

### UE Sees Network But Won't Connect

**Check:**
1. SIM credentials in `user_db.csv`?
2. IMSI matches?
3. K and OPc values correct?
4. MCC/MNC matches (`001/01`)?

**Debug:**
```bash
# Check auth failure
grep -i "auth\|security" /tmp/epc.log

# Common error:
# Authentication failure - check K/OPc
```

### S1 Setup Fails

**Check:**
1. EPC running first?
2. Firewall blocking port 36412?
3. MME address correct? (127.0.0.1 for local)

**Fix:**
```bash
# Disable firewall temporarily
sudo ufw disable

# Restart both EPC and eNB
```

### RF Issues

**Check:**
1. USRP USB 3.0 connection
2. TX/RX gain settings
3. Antenna connected?
4. Frequency correct? (2630 MHz for Band 7)

**Debug:**
```bash
# Test USRP TX/RX
uhd_fft -f 2.63e9 -s 10e6
```

---

## Safety Checklist

Before EVERY operation:

- [ ] Faraday cage verified with spectrum analyzer
- [ ] All personnel aware of RF transmission
- [ ] Emergency shutdown procedure in place
- [ ] Test devices only (no production SIMs)
- [ ] Logs will be reviewed and deleted after test
- [ ] TX power set to minimum (30 dB)
- [ ] Not using production LTE bands
- [ ] Have written authorization for testing

---

## Shutdown Procedure

**Proper shutdown:**

```bash
# 1. Stop eNB first (Ctrl+C in Terminal 2)
# 2. Stop EPC (Ctrl+C in Terminal 1)
# 3. Verify no transmission:

uhd_fft -f 2.63e9 -s 10e6  # Should see only noise

# 4. Disable phone network (airplane mode)
# 5. Remove test SIM
# 6. Open Faraday cage
```

**NEVER:**
- Leave system running unattended
- Operate with Faraday cage open
- Use on production bands
- Test with strangers' devices

---

## Legal & Ethical Guidelines

### Allowed (with proper RF isolation):

✅ Testing your own devices
✅ Security research with documented purpose
✅ Educational learning about LTE
✅ IMSI catcher detection tool validation
✅ IMEI randomization testing

### NOT Allowed:

❌ Capturing data from devices you don't own
❌ Operating without RF shielding
❌ Transmitting on licensed bands
❌ Tracking people without consent
❌ Interfering with real networks
❌ Surveillance of any kind

### Documentation

**Maintain written records:**
1. Date and time of each test
2. Purpose of research
3. Devices tested (you own)
4. Results and findings
5. Attestation of RF isolation

**Example:**
```
Test Date: 2025-12-31
Purpose: Validate IMEI randomization on Android 14
Devices: Google Pixel 8 (IMEI: XXXXXX - I own this device)
RF Isolation: Ramsey STE2000 Faraday cage, verified with Rohde & Schwarz FSH4
Results: IMEI randomized successfully between connections
```

---

## Advanced Topics

### Passive Monitoring (No TX)

**Safer alternative:** Monitor existing network passively

**Requires:**
- Commercial eNodeB with logging enabled
- OR sniff encrypted LTE (limited info available)

**What you can get:**
- Cell parameters (MIB/SIB) - **Public broadcast**
- Paging messages - ⚠️ **Privacy concerns**
- PDCCH allocations - Some info

**What you CANNOT get passively:**
- IMEI (encrypted in LTE)
- User data (encrypted)
- Authentication details

**Recommendation:** For defensive research, passive monitoring is safer and legal.

### srsUE as Test Device

**Instead of real phone:**

```bash
# Use srsUE to connect
./srsRAN_4G/build/srsue/src/srsue ./ue_lab.conf
```

**Advantages:**
- Full control
- Easy logging
- No privacy concerns
- Can script tests

**Configure with known IMSI/IMEI:**
```conf
[usim]
imsi = 001010123456789
imei = 353490069873319  # Set known IMEI for testing
```

---

## Comparison: Passive vs Active Monitoring

| Feature | Passive (Defensive) | Active (Lab eNodeB) |
|---------|---------------------|---------------------|
| **TX Required** | No | Yes |
| **RF Isolation** | Not needed | **REQUIRED** |
| **Legal Risk** | Very Low | High (if improper) |
| **IMEI Capture** | No | Yes |
| **SIB Decode** | Yes | Yes |
| **Paging** | Partial | Full |
| **Purpose** | IMSI catcher detection | Security research |
| **Setup** | Simple | Complex |

**Recommendation:**
- **Start with passive monitoring** (`cell_monitor.sh`)
- **Only use lab eNodeB** for specific research needs
- **Never combine both** (don't TX while defensive monitoring)

---

## Next Steps

### Learning Path

1. **Week 1:** Passive monitoring only
   - Run `cell_monitor.sh` for 7 days
   - Build comprehensive cell database
   - Understand normal vs anomalous

2. **Week 2:** RF isolation setup
   - Acquire/build Faraday cage
   - Verify attenuation
   - Test with dummy load

3. **Week 3:** Lab eNodeB (RX only)
   - Start EPC and eNB
   - Monitor logs
   - Don't connect devices yet

4. **Week 4:** Controlled testing
   - Connect test device
   - Capture IMEI/IMSI
   - Validate detection tools

### Resources

**Hardware:**
- Faraday cage: TechShield, Ramsey, or DIY copper mesh
- RF attenuators: Mini-Circuits, Pasternack
- Test SIMs: sysmocom, Osmocom

**Software:**
- srsRAN: https://www.srslte.com/
- Wireshark: https://www.wireshark.org/
- pySim: https://github.com/osmocom/pysim

**Documentation:**
- 3GPP TS 36.413: S1AP spec
- 3GPP TS 24.301: NAS protocol (IMEI here)
- srsRAN docs: https://docs.srsran.com/

---

## Summary

You now have a complete lab eNodeB setup for controlled IMEI/IMSI research.

**Critical reminders:**
1. **ONLY operate in RF-shielded environment**
2. **Test own devices only**
3. **Document all research**
4. **Know your local laws**

**What you can do:**
- Test IMEI randomization
- Validate detection tools
- Understand LTE security
- Educational research

**What we've built:**
1. ✅ Passive monitoring system (defensive)
2. ✅ Lab eNodeB setup (research)
3. ✅ Complete documentation

**Safe research practices:**
- Default to passive monitoring
- Use lab eNodeB sparingly
- Maintain ethical standards
- Contribute to defensive security

---

**You're ready to proceed with controlled, legal, ethical LTE security research!**
