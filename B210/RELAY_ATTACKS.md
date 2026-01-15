# Bluetooth, RFID, and Rolling Code Attacks

An educational overview of relay attacks against proximity-based access systems, rolling code vulnerabilities in vehicle keyless entry, and RFID access control.

---

## Table of Contents

1. [Overview](#overview)
2. [How Relay Attacks Work](#how-relay-attacks-work)
3. [Target Systems](#target-systems)
4. [Attack Methodologies](#attack-methodologies)
5. [Rolling Code Attacks](#rolling-code-attacks)
6. [Technical Implementation](#technical-implementation)
7. [Detection and Prevention](#detection-and-prevention)
8. [Legal Considerations](#legal-considerations)
9. [References](#references)

---

## Overview

### What is a Relay Attack?

A relay attack exploits proximity-based authentication by extending the communication range between a legitimate device (key fob, phone, RFID card) and a reader/vehicle. The attacker doesn't break encryption or clone credentials—they simply trick the system into thinking the authorized device is nearby when it's actually far away.

```
Normal Operation:
┌──────────┐     2-10m      ┌──────────┐
│  Key Fob │ ←───────────→  │  Vehicle │
└──────────┘   (legitimate)  └──────────┘

Relay Attack:
┌──────────┐    ┌──────────┐          ┌──────────┐    ┌──────────┐
│  Key Fob │ ←→ │ Attacker │ ~~~~~~~~ │ Attacker │ ←→ │  Vehicle │
└──────────┘    │  Device  │  relay   │  Device  │    └──────────┘
   (home)       │    #1    │ (50-100m)│    #2    │    (driveway)
                └──────────┘          └──────────┘
```

### Why It Works

Proximity-based systems assume:
- If communication occurs, the device must be nearby
- Signal strength (RSSI) indicates distance
- Challenge-response happens fast enough to prevent relay

These assumptions are flawed:
- Radio signals can be relayed over any distance
- RSSI can be manipulated or ignored
- Modern relay systems add minimal latency (<1ms)

---

## How Relay Attacks Work

### Basic Principle

1. **Attacker A** positions near the victim's key/phone (inside house, pocket, bag)
2. **Attacker B** positions near the target vehicle/door
3. Both attackers have relay devices that forward signals bidirectionally
4. Vehicle sends challenge → relayed to key → key responds → relayed back
5. Vehicle unlocks, thinking key is present

### Signal Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        RELAY ATTACK FLOW                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. Vehicle wakes up (door handle touched or button pressed)    │
│     └─→ Broadcasts: "Any key nearby?"                          │
│                                                                 │
│  2. Attacker B's device receives broadcast                      │
│     └─→ Relays over: Wi-Fi / Cellular / Radio link             │
│                                                                 │
│  3. Attacker A's device retransmits near victim's key          │
│     └─→ Key thinks vehicle is nearby                           │
│                                                                 │
│  4. Key responds with authentication                            │
│     └─→ Challenge-response protocol executes                   │
│                                                                 │
│  5. Attacker A relays response back to Attacker B              │
│     └─→ Sub-millisecond latency                                │
│                                                                 │
│  6. Attacker B retransmits to vehicle                          │
│     └─→ Vehicle validates, unlocks                             │
│                                                                 │
│  Total time: <100ms (faster than human perception)              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Target Systems

### 1. Passive Keyless Entry (PKE) - Vehicles

**Frequencies:**
- LF (Low Frequency): 125 kHz or 134 kHz (wake-up signal from vehicle)
- UHF (Ultra High Frequency): 315 MHz (US) or 433 MHz (EU) (key response)

**Vulnerable Manufacturers:**
- Most modern vehicles with "keyless" or "smart key" systems
- Tesla (BLE-based)
- BMW, Mercedes, Audi, VW Group
- Toyota, Lexus, Honda
- Ford, GM, Chrysler

**Protocol:**
```
Vehicle (LF 125kHz)          Key Fob (UHF 315/433MHz)
       │                              │
       │──── Wake-up signal ─────────→│
       │     (LF, ~2m range)          │
       │                              │
       │←─── "I'm here" + ID ─────────│
       │     (UHF, ~100m range)       │
       │                              │
       │──── Challenge (encrypted) ──→│
       │                              │
       │←─── Response (encrypted) ────│
       │                              │
       │     [UNLOCK]                 │
```

### 2. Bluetooth Low Energy (BLE) Keyless Entry

**Frequency:** 2.4 GHz (BLE channels 37, 38, 39 for advertising)

**Target Systems:**
- Tesla Phone Key
- BMW Digital Key
- Genesis Digital Key
- Smart locks (August, Yale, Schlage)
- Apple CarKey

**BLE Vulnerabilities:**
- RSSI-based distance estimation easily spoofed
- No time-of-flight verification in BLE 4.x/5.0
- BLE 5.1+ direction finding helps but not universally implemented

### 3. RFID Access Control

**Frequencies:**
- 125 kHz (HID Prox, EM4100) - highly vulnerable
- 13.56 MHz (MIFARE, iCLASS, DESFire)
- 860-960 MHz (UHF RFID)

**Target Systems:**
- Building access cards
- Hotel room keys
- Parking garages
- Corporate badges

**HID Prox (125 kHz) - Trivially Relayed:**
```
Reader                    Card
  │                        │
  │──── RF field ─────────→│
  │     (powers card)      │
  │                        │
  │←─── Card ID (fixed) ───│
  │     (no encryption!)   │
  │                        │
  │     [ACCESS GRANTED]   │
```

### 4. NFC Payment/Access

**Frequency:** 13.56 MHz

**Target Systems:**
- Contactless payment cards
- Apple Pay / Google Pay (phone must be unlocked)
- Transit cards

**Note:** Payment cards have transaction limits and fraud detection that limit relay attack utility.

---

## Attack Methodologies

### Method 1: Wired Relay (Simplest)

**Equipment:**
- 2x RF receiver/transmitter modules
- Long coaxial cable (10-100m)
- Or: Ethernet + RF-over-IP

**Pros:** Low latency, simple, cheap
**Cons:** Requires physical cable, conspicuous

```
┌─────────┐  coax   ┌─────────┐
│ RX/TX 1 │────────│ RX/TX 2 │
└────┬────┘        └────┬────┘
     │                  │
   [KEY]            [VEHICLE]
```

### Method 2: Wireless Relay (Common)

**Equipment:**
- 2x SDR devices (HackRF, RTL-SDR + TX capable device)
- 2x laptops or Raspberry Pi
- Wi-Fi or cellular link between them

**Latency:** 1-10ms typical
**Range:** Unlimited (internet relay)

```python
# Conceptual pseudocode (educational only)
# Attacker A - Near victim's key
def relay_near_key():
    while True:
        # Receive LF signal from vehicle (relayed)
        lf_signal = receive_from_partner()

        # Retransmit to wake up key
        transmit_lf(lf_signal)

        # Capture key's UHF response
        uhf_response = capture_uhf()

        # Relay back to partner
        send_to_partner(uhf_response)

# Attacker B - Near vehicle
def relay_near_vehicle():
    while True:
        # Capture vehicle's LF wake-up
        lf_signal = capture_lf()

        # Send to partner for retransmission
        send_to_partner(lf_signal)

        # Receive key's response (relayed)
        uhf_response = receive_from_partner()

        # Retransmit to vehicle
        transmit_uhf(uhf_response)
```

### Method 3: BLE Relay Attack

**Equipment:**
- 2x ESP32 or nRF52840 devices
- Internet connection (Wi-Fi/cellular)

**Attack against Tesla, smart locks, etc.:**

```
┌──────────────────────────────────────────────────────────────┐
│                     BLE RELAY ATTACK                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Phone (victim)          Relay Link          Vehicle/Lock   │
│       │                      │                    │          │
│       │   ┌──────────┐      │     ┌──────────┐  │          │
│       │←─→│ Device A │~~~~~~│~~~~~│ Device B │←→│          │
│       │   │ (ESP32)  │ WiFi │     │ (ESP32)  │  │          │
│       │   └──────────┘      │     └──────────┘  │          │
│       │                      │                    │          │
│  [Home]                 [Internet]          [Parking lot]   │
│                                                              │
│  Device A: Acts as vehicle/lock (GATT server)               │
│  Device B: Acts as phone (GATT client)                      │
│  All BLE traffic transparently relayed                      │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**BLE Relay Implementation (ESP32):**

```c
// Conceptual - Educational purposes only
// Device A (near phone) - Presents as vehicle

void setup_ble_relay_phone_side() {
    // Create BLE server mimicking vehicle's service UUID
    BLEDevice::init("RelayA");
    BLEServer *server = BLEDevice::createServer();

    // Clone target vehicle's service/characteristic UUIDs
    BLEService *service = server->createService(VEHICLE_SERVICE_UUID);

    // When phone connects and sends data:
    // Forward to Device B via WiFi/internet
}

void on_write_from_phone(uint8_t *data, size_t len) {
    // Relay to partner device
    wifi_send_to_partner(data, len);

    // Wait for response from actual vehicle
    uint8_t *response = wifi_receive_from_partner();

    // Send back to phone
    ble_notify(response);
}
```

### Method 4: RFID Relay (Proxmark-based)

**Equipment:**
- 2x Proxmark3 devices
- Communication link

**125 kHz HID Prox Attack:**

```bash
# Device A (near card) - Proxmark in sim mode
proxmark3> lf hid sim -r    # Simulate reader, capture response

# Device B (near reader) - Proxmark in card mode
proxmark3> lf hid clone     # Replay captured credentials
```

**13.56 MHz Relay:**

```bash
# More complex due to encryption
# Requires real-time relay of challenge-response
# Tools: NFCGate (Android), custom Proxmark firmware
```

---

## Rolling Code Attacks

Rolling code systems (KeeLoq, etc.) were designed to prevent simple replay attacks. However, several vulnerabilities exist that don't require relay or jamming—just a single CC1101 or similar transceiver.

### How Rolling Codes Work

```
┌─────────────────────────────────────────────────────────────────┐
│                    ROLLING CODE BASICS                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Key Fob State:                Vehicle State:                   │
│  ├─ Secret Key: K             ├─ Secret Key: K (same)          │
│  ├─ Counter: N                ├─ Counter: M                    │
│  └─ Manufacturer Bits         └─ Accept Window: M to M+256     │
│                                                                 │
│  Button Press:                                                  │
│  1. Fob calculates: Code = Encrypt(K, N)                       │
│  2. Fob transmits: Code + Counter N                            │
│  3. Fob increments: N = N + 1                                  │
│                                                                 │
│  Vehicle Receives:                                              │
│  1. Decrypt code using K                                        │
│  2. Check if counter N is within window [M, M+256]             │
│  3. If valid: UNLOCK, set M = N + 1                            │
│  4. If invalid: REJECT                                         │
│                                                                 │
│  The "window" allows for out-of-range button presses           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### RollJam Attack (Two Devices, Jamming)

Samy Kamkar's famous RollJam requires:
- **Device 1:** Captures signal + jams to prevent vehicle receipt
- **Device 2:** Stores captured code for later use

```
┌─────────────────────────────────────────────────────────────────┐
│                     ROLLJAM ATTACK                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Step 1: First button press                                     │
│  ┌─────┐    code_1000    ┌───────────┐    JAMMED    ┌────────┐ │
│  │ Fob │ ───────────────→│  RollJam  │ ────────X───→│Vehicle │ │
│  └─────┘                 │  Device   │              └────────┘ │
│                          │(captures) │                          │
│                          └───────────┘                          │
│  User: "Huh, didn't work" → presses again                      │
│                                                                 │
│  Step 2: Second button press                                    │
│  ┌─────┐    code_1001    ┌───────────┐   code_1000  ┌────────┐ │
│  │ Fob │ ───────────────→│  RollJam  │ ───────────→│Vehicle │ │
│  └─────┘                 │(captures) │   (replays)  └────────┘ │
│                          │           │              [UNLOCKS]   │
│                          └───────────┘                          │
│  User thinks it worked, but attacker now has code_1001         │
│                                                                 │
│  Step 3: Later - Attacker uses saved code_1001                 │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Single-Device Attacks (No Jamming Required)

Several vulnerabilities allow attacks with a single CC1101 module:

#### 1. RollBack/Resynchronization Attack

Some vehicles have a "resync" mechanism that accepts older codes under certain conditions:

```
┌─────────────────────────────────────────────────────────────────┐
│                   ROLLBACK ATTACK                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Vulnerability: Resync allows codes BEHIND current counter     │
│                                                                 │
│  Attack Steps:                                                  │
│  1. Capture code_1000 (passive, single device)                 │
│  2. Wait for victim to press button many times                  │
│     └─ Vehicle now at counter ~1100                            │
│  3. Some vehicles accept "resync sequence":                     │
│     ├─ Rapid succession of older codes                         │
│     ├─ Or: specific timing patterns                            │
│     └─ Or: after battery disconnect/timeout                    │
│                                                                 │
│  Example Vulnerable Conditions:                                 │
│  ├─ Vehicle battery recently disconnected                      │
│  ├─ Key battery recently replaced                              │
│  ├─ Counter rolled over (after 65536 presses)                  │
│  └─ Manufacturer-specific "emergency resync" triggers          │
│                                                                 │
│  Single CC1101 captures and replays - no jamming needed        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 2. Counter Exhaustion Attack

```
Vulnerability: Limited counter window + predictable increment

Attack:
1. Capture a single code with counter N
2. Force victim to exhaust their window:
   ├─ Block vehicle signal (Faraday cage scenario)
   └─ Victim presses button 256+ times (trying to unlock)
3. Vehicle counter is now at M, but fob is at N+256+
4. Vehicle may trigger resync mode
5. Replay captured code_N during resync window
```

#### 3. Cryptographic Weakness Attacks (KeeLoq)

KeeLoq's encryption has been cryptanalyzed:

```
┌─────────────────────────────────────────────────────────────────┐
│               KEELOQ CRYPTOGRAPHIC ATTACKS                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  2008: Side-channel attack recovers key in minutes              │
│  2009: Algebraic attack reduces complexity                      │
│  2012: Practical key recovery demonstrated                      │
│                                                                 │
│  Attack with single device:                                     │
│  1. Capture 2-4 consecutive codes from same fob                │
│  2. Apply cryptanalysis to recover secret key K                │
│  3. Generate ANY future valid code                             │
│                                                                 │
│  Equipment: Single CC1101 + laptop for computation             │
│  Time: Minutes to hours depending on method                    │
│                                                                 │
│  Known vulnerable: Many pre-2016 KeeLoq implementations        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### 4. Sub-GHz Replay on Non-Rolling Systems

Many aftermarket and older systems still use static codes:

```c
// Identifying static vs rolling code systems
// Static: Same code every time (trivially replayed)
// Rolling: Different code each press

// Capture approach with CC1101:
typedef struct {
    uint32_t frequency;     // 315/433 MHz
    uint8_t modulation;     // OOK/ASK typically
    uint16_t bit_length;    // Code length in bits
    uint8_t code[8];        // Captured code
    uint32_t timestamp;     // When captured
} captured_signal_t;

// Analysis:
// - Capture multiple presses
// - If identical → static code → replay works
// - If different → rolling code → need attack variant
```

### Single CC1101 Implementation

**Hardware:**
- CC1101 module (~$5)
- Arduino/ESP32/STM32
- 315/433 MHz antenna

**Capture and Analyze:**

```c
// Conceptual - Educational purposes only
// CC1101 configuration for key fob capture

void cc1101_setup_keyfob_capture() {
    // Set frequency (315 MHz for US, 433 MHz for EU)
    cc1101_set_freq(315.0);  // MHz

    // OOK/ASK modulation (most key fobs)
    cc1101_set_modulation(MOD_ASK_OOK);

    // Data rate varies by manufacturer
    cc1101_set_datarate(3.79);  // kBaud typical

    // Bandwidth for capture
    cc1101_set_rx_bandwidth(58);  // kHz

    // Enable raw mode for analysis
    cc1101_set_packet_format(PKT_FORMAT_ASYNC_SERIAL);
}

void capture_keyfob_signal() {
    uint8_t buffer[256];
    int len = 0;

    // Wait for signal
    while (!cc1101_carrier_sense());

    // Capture raw bits
    len = cc1101_receive_raw(buffer, sizeof(buffer), 1000);

    // Analyze for rolling code structure
    analyze_rolling_code(buffer, len);
}
```

### Detecting Single-Device Attacks

**RF Monitoring Approach:**

```c
// Detection: Monitor for suspicious capture activity

typedef struct {
    uint32_t frequency;
    int8_t rssi;
    uint32_t timestamp;
    bool is_vehicle_freq;  // 315/433 MHz range
    bool during_unlock;    // Correlated with key press
} rf_detection_t;

bool detect_capture_attempt(rf_detection_t *events, int count) {
    // Look for:
    // 1. Receiver near vehicle during key press
    // 2. Strong signal that doesn't match vehicle
    // 3. Suspiciously timed captures

    for (int i = 0; i < count; i++) {
        if (events[i].is_vehicle_freq &&
            events[i].rssi > -50 &&  // Strong signal
            events[i].during_unlock) {
            return true;  // Possible capture attempt
        }
    }
    return false;
}
```

**Counter-Surveillance Equipment:**

| Device | Purpose | Range |
|--------|---------|-------|
| RF detector | Detect nearby transmitters | 10m |
| Spectrum analyzer | Identify monitoring equipment | 50m |
| TSCM sweep | Professional counter-surveillance | Varies |

### Prevention Against Rolling Code Attacks

**For Vehicle Owners:**

| Prevention | Effectiveness | Notes |
|------------|---------------|-------|
| Faraday pouch | High | Prevents ANY RF capture |
| Check for RF activity | Medium | RF detector near vehicle |
| Update vehicle firmware | Medium | Patches known vulnerabilities |
| Aftermarket security | High | PIN-to-drive, kill switches |
| Steering wheel lock | High | Physical barrier |

**For Manufacturers:**

```c
// Modern rolling code improvements

// 1. AES-based rolling codes (replaces KeeLoq)
#define USE_AES_128 1

// 2. Timestamp verification
typedef struct {
    uint32_t counter;
    uint32_t timestamp;  // Must be recent
    uint8_t hmac[16];    // HMAC for integrity
} modern_rolling_code_t;

bool verify_modern_code(modern_rolling_code_t *code) {
    // Check timestamp freshness
    if (abs(get_rtc_time() - code->timestamp) > MAX_AGE_SECONDS) {
        return false;  // Stale code
    }

    // Verify HMAC
    if (!verify_hmac(code)) {
        return false;  // Tampered
    }

    // Standard counter check
    if (!counter_in_window(code->counter)) {
        return false;
    }

    return true;
}

// 3. Mutual authentication
// Vehicle and key both prove identity
// Prevents replay of captured unilateral codes
```

### Attack Comparison Table

| Attack | Devices | Jamming | Crypto Break | Difficulty | Success Rate |
|--------|---------|---------|--------------|------------|--------------|
| Simple Replay | 1 | No | No | Low | Static only |
| RollJam | 2 | Yes | No | Medium | High |
| RollBack | 1 | No | No | Medium | Vehicle-dependent |
| Counter Exhaust | 1 | Partial | No | Medium | Low |
| KeeLoq Crypto | 1 | No | Yes | High | High (vulnerable) |
| Key Clone | 1 | No | Yes | High | High |

---

## Technical Implementation

### Hardware Requirements by Attack Type

| Attack Type | Equipment | Cost | Difficulty |
|-------------|-----------|------|------------|
| PKE (125kHz LF) | 2x Proxmark3 or custom LF boards | $300-600 | Medium |
| PKE (315/433 UHF) | 2x HackRF or YARD Stick One | $200-600 | Medium |
| BLE Relay | 2x ESP32 DevKit | $20-40 | Low |
| RFID 125kHz | 2x Proxmark3 Easy | $80-160 | Low |
| RFID 13.56MHz | 2x Proxmark3 RDV4 + relay fw | $600+ | High |

### SDR Configuration for PKE Relay

**For 125 kHz LF (Vehicle → Key wake-up):**

```
Challenge: Most SDRs don't go this low!

Solutions:
├─ Dedicated LF equipment:
│  ├─ Proxmark3 (125/134 kHz)
│  ├─ Custom coil + amplifier
│  └─ EM4100 reader/writer modules
│
└─ Upconverter approach:
   └─ Upconvert 125 kHz → 10.125 MHz → SDR
```

**For 315/433 MHz UHF (Key → Vehicle response):**

```python
# Using GNU Radio + HackRF (conceptual)
# Educational demonstration only

class KeyFobRelay:
    def __init__(self):
        self.sdr = HackRF()
        self.center_freq = 315e6  # US car fobs
        self.sample_rate = 2e6

    def capture_and_relay(self):
        # Capture OOK/ASK modulated signal from key
        samples = self.sdr.receive(duration=0.1)

        # Send to partner over network
        self.network_send(samples)

    def retransmit(self, samples):
        # Retransmit captured signal
        self.sdr.transmit(samples)
```

### Latency Requirements

| System | Max Acceptable Latency | Notes |
|--------|----------------------|-------|
| PKE (most vehicles) | 20-50ms | Some allow up to 100ms |
| BLE (Tesla, smart locks) | 10-30ms | Tighter timing |
| RFID 125kHz | 100ms+ | Very forgiving |
| RFID 13.56MHz DESFire | 5-10ms | Strict timing |
| Contactless payment | 500ms | Transaction timeout |

### Relay Link Options

| Method | Latency | Range | Complexity |
|--------|---------|-------|------------|
| Direct cable | <1ms | 10-100m | Low |
| Wi-Fi (local) | 1-5ms | 100m | Low |
| Wi-Fi (internet) | 10-100ms | Unlimited | Medium |
| Cellular 4G | 30-100ms | Unlimited | Medium |
| Cellular 5G | 5-20ms | Unlimited | Medium |
| LoRa | 50-200ms | 1-10km | Medium |
| Custom RF link | 1-10ms | 1km | High |

---

## Detection and Prevention

### Attack Detection Methods

**1. Time-of-Flight (ToF) Measurement**
```
If relay adds latency, ToF-based systems detect it:

Normal: Signal travels at speed of light
        2m distance = ~6.7 nanoseconds round-trip

Relay:  Even 1ms added latency = 300km equivalent distance
        System detects anomaly → DENY ACCESS
```

**2. Ultra-Wideband (UWB) Ranging**
```
UWB provides centimeter-accurate distance measurement:
├─ Apple U1 chip (iPhone 11+, AirTag)
├─ Samsung Galaxy (select models)
├─ BMW Digital Key Plus
├─ Genesis GV60
└─ Smart locks (newer models)

UWB is highly resistant to relay attacks due to:
├─ Precise time-of-flight measurement
├─ Very short pulse duration
└─ Channel impulse response verification
```

**3. Motion/Accelerometer Correlation**
```
If key is moving but phone/car accelerometer shows stationary:
└─ Possible relay attack indicator
```

**4. RSSI Anomaly Detection**
```
Sudden RSSI changes inconsistent with physical movement:
└─ Flag for additional verification
```

### Prevention Measures (Users)

| Prevention | Effectiveness | User Action |
|------------|---------------|-------------|
| Faraday pouch for key | High | Store key in RF-blocking bag |
| Disable passive entry | High | Require button press to unlock |
| Motion-based key sleep | Medium | Key sleeps when stationary |
| PIN-to-drive | High | Require PIN even after unlock |
| Steering wheel lock | High | Physical barrier |
| UWB-enabled key | Very High | Upgrade to newer key fob |

### Prevention Measures (Manufacturers)

**1. Implement UWB Ranging**
```c
// UWB distance verification
bool verify_key_proximity(uwb_session_t *session) {
    float distance = uwb_get_distance(session);
    float confidence = uwb_get_confidence(session);

    if (distance < MAX_UNLOCK_DISTANCE && confidence > 0.95) {
        return true;  // Key is genuinely nearby
    }
    return false;  // Possible relay attack
}
```

**2. Challenge-Response Timing Bounds**
```c
// Strict timing verification
#define MAX_RESPONSE_TIME_US 1000  // 1ms max

bool verify_response_timing(uint64_t challenge_sent,
                            uint64_t response_received) {
    uint64_t round_trip = response_received - challenge_sent;

    if (round_trip > MAX_RESPONSE_TIME_US) {
        log_security_event("Possible relay attack - timing violation");
        return false;
    }
    return true;
}
```

**3. Multi-Factor Proximity**
```
Combine multiple signals:
├─ BLE RSSI
├─ UWB distance
├─ Accelerometer correlation
├─ User intent (touch door handle)
└─ Historical location patterns

All must agree for access grant
```

### Faraday Protection

**DIY Faraday Pouch:**
```
Materials:
├─ Conductive fabric (nickel/copper mesh)
├─ Or: Multiple layers of aluminum foil
└─ Non-conductive outer layer

Test effectiveness:
├─ Put key in pouch
├─ Try to unlock car
└─ Should fail completely
```

**Commercial Options:**
- Silent Pocket
- RFID blocking wallets
- Car key signal blockers

---

## Legal Considerations

### Legality Summary

| Action | Legal Status | Notes |
|--------|--------------|-------|
| Research (own devices) | Generally legal | Educational purposes |
| Penetration testing (authorized) | Legal with contract | Written permission required |
| Unauthorized access | **ILLEGAL** | Criminal offense |
| Possession of tools | Varies by jurisdiction | Intent matters |
| Selling relay devices | Often restricted | Check local laws |

### Relevant Laws (US)

- **Computer Fraud and Abuse Act (CFAA)** - Unauthorized access to computer systems
- **Wire Fraud (18 U.S.C. § 1343)** - Using electronic communications for fraud
- **State vehicle theft laws** - Even temporary unauthorized use
- **FCC regulations** - Unlicensed transmission violations

### Relevant Laws (EU/UK)

- **Computer Misuse Act 1990** (UK)
- **GDPR** implications for captured data
- **National vehicle security regulations**

### Ethical Research Guidelines

```
DO:
├─ Test only on your own vehicles/devices
├─ Get written authorization for third-party testing
├─ Report vulnerabilities responsibly
├─ Publish research to improve security
└─ Work with manufacturers on fixes

DON'T:
├─ Access vehicles/systems without permission
├─ Use techniques for theft or unauthorized access
├─ Sell attack tools to bad actors
├─ Publicly release weaponized exploits
└─ Ignore responsible disclosure timelines
```

---

## Research Equipment

### For PKE Research (Own Vehicles)

**Basic Setup:**
```
LF Side (125 kHz):
├─ Proxmark3 Easy ($40-80)
├─ Or: Custom LF antenna + amplifier
└─ Range: ~1m from key

UHF Side (315/433 MHz):
├─ YARD Stick One ($100)
├─ Or: HackRF One ($300)
├─ CC1101 module ($5) for basic testing
└─ Range: Capture at ~5-10m
```

**Advanced Setup:**
```
├─ 2x Proxmark3 RDV4 ($300 each)
├─ Custom relay firmware
├─ Low-latency network link
├─ LF amplifier for extended range
└─ UHF amplifier (check FCC limits!)
```

### For BLE Research

**Basic Setup:**
```
├─ 2x ESP32 DevKit ($10 each)
├─ nRF Connect app (analysis)
├─ Wireshark + BLE sniffer
└─ Custom relay firmware
```

**Advanced Setup:**
```
├─ 2x nRF52840 Dongle ($10 each)
├─ Ubertooth One (BLE sniffing)
├─ Custom GATT relay software
└─ Timing analysis equipment
```

### Analysis Tools

| Tool | Purpose | Platform |
|------|---------|----------|
| Proxmark3 | LF/HF RFID analysis | Hardware |
| HackRF | Wideband SDR capture | Hardware |
| Wireshark | Protocol analysis | Software |
| nRF Connect | BLE analysis | Mobile app |
| GNU Radio | Signal processing | Software |
| Flipper Zero | Multi-protocol analysis | Hardware |
| YARD Stick One | Sub-GHz analysis | Hardware |

---

## References

### Academic Papers

- "Relay Attacks on Passive Keyless Entry and Start Systems in Modern Cars" - ETH Zurich
- "A Practical Relay Attack on ISO 14443 Proximity Cards" - Cambridge
- "Ghost Talk: Mitigating EMI Signal Injection Attacks against Automotive Sensors"
- "Securing Passive Keyless Entry and Start Systems" - USENIX

### Security Conferences

- DEF CON - Automotive hacking village
- Black Hat - Vehicle security research
- CCC (Chaos Communication Congress)
- USENIX Security Symposium

### Manufacturer Security Resources

- Tesla Security Research Program
- BMW Responsible Disclosure
- FCA Bug Bounty Program
- GM Security Research

### Tools and Frameworks

- Proxmark3 GitHub: https://github.com/RfidResearchGroup/proxmark3
- GNU Radio: https://www.gnuradio.org/
- HackRF: https://greatscottgadgets.com/hackrf/
- Car Hacking Tools: https://github.com/jgamblin/CarHackingTools

---

## Disclaimer

This document is for **educational and authorized security research purposes only**.

- Never attempt relay attacks on vehicles or systems you don't own
- Always obtain written permission before testing third-party systems
- Unauthorized access to vehicles is a criminal offense
- Responsible disclosure helps improve security for everyone

The techniques described here are documented to:
1. Help security researchers identify vulnerabilities
2. Assist manufacturers in improving their systems
3. Educate vehicle owners about risks and protections
4. Support authorized penetration testing activities
