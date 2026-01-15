# Target Devices for Detection and Interaction

This document catalogs urban infrastructure and IoT devices that can be detected, analyzed, and potentially interacted with using the B210/AD9363 SDR system.

---

## Table of Contents

1. [Crosswalk / APS Systems](#crosswalk--aps-systems)
2. [License Plate Recognition](#license-plate-recognition)
3. [Acoustic Detection](#acoustic-detection)
4. [Smart Streetlights](#smart-streetlights)
5. [Traffic Infrastructure](#traffic-infrastructure)
6. [Smart Parking](#smart-parking)
7. [LoRa/LoRaWAN Sensors](#loralowan-sensors)
8. [Vehicle Key Fobs](#vehicle-key-fobs)
9. [Protocol Summary](#protocol-summary)
10. [OUI Database](#oui-database)
11. [Device Signatures](#device-signatures)

---

## Crosswalk / APS Systems

### Polara Accessible Pedestrian Signal (APS)

**Manufacturer:** Polara Engineering
**Purpose:** Accessible pedestrian crossing signals for visually impaired

**Communication:**
- **Protocol:** Bluetooth Low Energy (BLE 5.x)
- **Frequency:** 2.4 GHz
- **OUI:** `00:1B:C5` (example - verify in field)
- **Service UUID:** Custom (device-specific)
- **Name Pattern:** Contains "Polara"

**Features:**
- Audio cues for pedestrians
- Vibrating tactile indicators
- Mobile app integration (Polara Navigator)
- Configurable via BLE

**Detection Method:**
```c
// Device signature for Polara APS
const device_signature_t polara_aps = {
    .name = "Polara iNS/iDS",
    .type = DEVICE_POLARA_APS,
    .oui = {0x00, 0x1B, 0xC5},  // Verify OUI
    .protocol = PROTO_BLE,
    .has_name_pattern = true,
    .name_pattern = "Polara",
    .icon = ICON_CROSSWALK
};
```

**RSSI Estimation:**
| RSSI (dBm) | Distance |
|------------|----------|
| -30 to -40 | < 5m |
| -40 to -50 | 5-15m |
| -50 to -70 | 15-50m |
| < -70 | > 50m |

---

## License Plate Recognition

### Flock Safety LPR Cameras

**Manufacturer:** Flock Safety
**Purpose:** Automated license plate recognition for law enforcement

**Communication:**
- **Primary:** LTE/5G cellular backhaul
- **Configuration:** BLE (for setup)
- **Frequency:** Cellular bands + 2.4 GHz BLE

**LTE Bands Used:**
- Band 2 (1900 MHz PCS)
- Band 4 (AWS 1700/2100 MHz)
- Band 12/13/17 (700 MHz)
- Band 66 (AWS-3)

**Detection:**
- May advertise "Flock" in BLE name during setup
- Cellular IMEI patterns (if known)
- Visual identification + RF confirmation

**Detection Signature:**
```c
const device_signature_t flock_camera = {
    .name = "Flock LPR Camera",
    .type = DEVICE_FLOCK_LPR,
    .protocol = PROTO_LTE | PROTO_BLE,
    .has_name_pattern = true,
    .name_pattern = "Flock",
    .icon = ICON_CAMERA
};
```

---

## Acoustic Detection

### ShotSpotter / SoundThinking

**Manufacturer:** SoundThinking (formerly ShotSpotter)
**Purpose:** Gunshot detection and location

**Communication:**
- **Backhaul:** LTE/5G cellular
- **Mesh:** Proprietary or 802.15.4
- **Frequency:** Cellular bands

**Detection Notes:**
- Units are typically pole-mounted
- Use cellular for data transmission
- May have maintenance BLE interface
- Multiple units triangulate gunshot locations

---

## Smart Streetlights

### Zigbee-Based Streetlights

**Protocol:** Zigbee (802.15.4) / ZigBee PRO
**Frequency:** 2.4 GHz (channels 11-26)
**Profile ID:** `0x0104` (Home Automation)
**Device ID:** `0x0100` (On/Off Light)

**Common Manufacturers:**
- GE Current
- Philips Lighting (Signify)
- Acuity Brands
- Silver Spring Networks (Itron)

**Detection Signature:**
```c
const device_signature_t zigbee_streetlight = {
    .name = "Smart Streetlight",
    .type = DEVICE_STREETLIGHT_ZIGBEE,
    .protocol = PROTO_ZIGBEE,
    .zigbee_profile_id = 0x0104,  // HA profile
    .zigbee_device_id = 0x0100,   // On/Off Light
    .icon = ICON_LIGHTBULB
};
```

### LoRa-Based Streetlights

**Protocol:** LoRaWAN
**Frequency:** 915 MHz (US), 868 MHz (EU)

**Manufacturers:**
- Signify
- Telensa
- Itron

---

## Traffic Infrastructure

### Traffic Signal Controllers

**Common Protocols:**
- NTCIP (National Transportation Communications for ITS Protocol)
- Cellular backhaul
- Ethernet (local network)

**Detection:**
- DSRC 5.9 GHz (out of AD9363 range)
- C-V2X cellular (within range)
- BLE for maintenance

### Electronic Toll Collection

**Frequency:** 915 MHz (US)
**Protocol:** Proprietary

**Systems:**
- E-ZPass
- SunPass
- FasTrak

---

## Smart Parking

### Parking Meters

**Communication:**
- **Cellular:** LTE for payment processing
- **Mesh:** 802.15.4 or LoRa
- **Wi-Fi:** For configuration

**Common Frequencies:**
- 915 MHz (LoRa)
- 2.4 GHz (Zigbee/Wi-Fi/BLE)
- Cellular bands

### Parking Occupancy Sensors

**Types:**
- In-ground magnetic sensors
- Overhead cameras
- Ultrasonic sensors

**Communication:**
- LoRaWAN (most common)
- Cellular
- 802.15.4 mesh

---

## LoRa/LoRaWAN Sensors

### Smart City Sensor Networks

**Frequency:**
- US: 902-928 MHz (915 MHz center)
- EU: 863-870 MHz (868 MHz center)

**Bandwidth:** 125 kHz, 250 kHz, or 500 kHz
**Spreading Factor:** SF7-SF12

**Common Applications:**
- Environmental monitoring (air quality, noise)
- Flood detection
- Waste bin fill level
- Smart irrigation
- Building occupancy

**Detection:**
```c
// LoRa packet detection
typedef struct {
    uint32_t frequency;      // Center frequency
    uint8_t spreading_factor;
    uint8_t bandwidth;       // 125/250/500 kHz
    uint8_t coding_rate;
    int8_t rssi;
    int8_t snr;
    uint8_t dev_addr[4];     // Device address
    uint16_t fcnt;           // Frame counter
} lora_packet_t;
```

---

## Vehicle Key Fobs

### Rolling Code Systems (RollJam Targets)

**US Frequencies:**
- **315 MHz** (most US vehicles) - Below AD9363 range
- **433.92 MHz** (some US, most EU)

**EU Frequencies:**
- **433.92 MHz** (primary)
- **868 MHz** (newer systems)

**Protocols:**
- KeeLoq (rolling code)
- AUT64
- HiTag2
- Manufacturer proprietary

**AD9363 Compatibility:**
| Frequency | AD9363 Support | Workaround |
|-----------|----------------|------------|
| 315 MHz | No (10 MHz below) | CC1101 module or upconverter |
| 433 MHz | Yes | Direct capture |
| 868 MHz | Yes | Direct capture |

### Tire Pressure Monitoring (TPMS)

**Frequency:** 315 MHz (US), 433 MHz (EU)
**Protocol:** OOK/FSK modulation

---

## Protocol Summary

### By Frequency Band

| Frequency Range | Protocols | AD9363 | AD9361 (B210) |
|-----------------|-----------|--------|---------------|
| 315 MHz | Car fobs, TPMS | No | Yes |
| 325-400 MHz | ISM devices | Yes | Yes |
| 433 MHz | Car fobs, ISM | Yes | Yes |
| 868/915 MHz | LoRa, ISM | Yes | Yes |
| 700-900 MHz | LTE low bands | Partial | Yes |
| 1700-2100 MHz | LTE mid bands | Yes | Yes |
| 2.4 GHz | Wi-Fi, BLE, Zigbee | Yes | Yes |
| 3.5 GHz | 5G NR | Partial | Yes |
| 5 GHz | Wi-Fi | No | Yes |
| 5.9 GHz | DSRC | No | Yes |

### By Protocol Type

| Protocol | Frequency | Bandwidth | Use Case |
|----------|-----------|-----------|----------|
| BLE | 2.4 GHz | 2 MHz | APS, beacons, config |
| Zigbee | 2.4 GHz | 2 MHz | Streetlights, mesh |
| Wi-Fi | 2.4/5 GHz | 20-160 MHz | Infrastructure |
| LoRa | 868/915 MHz | 125-500 kHz | Sensors |
| LTE | Various | 5-20 MHz | Backhaul |
| OOK/FSK | 315/433 MHz | Narrow | Key fobs, remotes |

---

## OUI Database

### Known Device OUIs

```
# Format: OUI | Manufacturer | Device Types

00:1B:C5 | Polara | APS crosswalk systems
A4:C1:38 | Example | Flock cameras (verify)
XX:XX:XX | Signify | Smart streetlights
XX:XX:XX | Itron | Smart meters
XX:XX:XX | Semtech | LoRa modules

# To be populated from field research
```

### OUI Lookup Implementation

```c
// OUI database structure
typedef struct {
    uint8_t oui[3];
    const char *vendor;
    device_type_t likely_type;
} oui_entry_t;

const char* oui_lookup(const uint8_t *mac) {
    uint32_t oui = (mac[0] << 16) | (mac[1] << 8) | mac[2];

    // Binary search in sorted OUI database
    for (int i = 0; i < oui_db_size; i++) {
        if (memcmp(oui_db[i].oui, mac, 3) == 0) {
            return oui_db[i].vendor;
        }
    }
    return "Unknown";
}
```

---

## Device Signatures

### Signature Database Structure

```c
typedef enum {
    DEVICE_POLARA_APS,
    DEVICE_POLARA_WPS,
    DEVICE_FLOCK_CAMERA,
    DEVICE_SHOTSPOTTER,
    DEVICE_STREETLIGHT_ZIGBEE,
    DEVICE_STREETLIGHT_LORA,
    DEVICE_PARKING_METER,
    DEVICE_TRAFFIC_CONTROLLER,
    DEVICE_TPMS_SENSOR,
    DEVICE_KEY_FOB,
    DEVICE_LORA_SENSOR,
    DEVICE_UNKNOWN
} device_type_t;

typedef struct {
    const char *name;
    device_type_t type;
    uint8_t oui[3];
    uint8_t protocol;           // WIFI, BLE, ZIGBEE, LORA, LTE
    uint16_t ble_service_uuid;  // For BLE devices
    uint16_t zigbee_profile_id; // For Zigbee devices
    uint16_t zigbee_device_id;
    bool has_name_pattern;
    const char *name_pattern;
    uint8_t icon;
} device_signature_t;
```

### Full Signature Database

```c
const device_signature_t known_devices[] = {
    // Crosswalk systems
    {
        .name = "Polara iNS/iDS",
        .type = DEVICE_POLARA_APS,
        .oui = {0x00, 0x1B, 0xC5},
        .protocol = PROTO_BLE,
        .has_name_pattern = true,
        .name_pattern = "Polara",
        .icon = ICON_CROSSWALK
    },

    // Surveillance
    {
        .name = "Flock LPR Camera",
        .type = DEVICE_FLOCK_CAMERA,
        .protocol = PROTO_LTE | PROTO_BLE,
        .has_name_pattern = true,
        .name_pattern = "Flock",
        .icon = ICON_CAMERA
    },

    // Smart lights
    {
        .name = "Zigbee Streetlight",
        .type = DEVICE_STREETLIGHT_ZIGBEE,
        .protocol = PROTO_ZIGBEE,
        .zigbee_profile_id = 0x0104,
        .zigbee_device_id = 0x0100,
        .icon = ICON_LIGHTBULB
    },

    // Add more signatures as discovered...
};
```

---

## Field Research Notes

### Data Collection Template

```
Date: ___________
Location: ___________
GPS: ___________

Device Type: ___________
Protocol: ___________
Frequency: ___________
MAC/Address: ___________
OUI: ___________
RSSI: ___________ dBm
BLE Name: ___________
Service UUIDs: ___________

Notes:
___________
```

### Privacy & Legal Considerations

- Passive reception is generally legal
- Do not transmit without authorization
- Do not interfere with emergency services
- Respect privacy laws regarding data collection
- This documentation is for educational/research purposes

---

## References

- IEEE OUI Database: https://standards-oui.ieee.org/
- Zigbee Alliance Device Types: https://zigbeealliance.org/
- LoRaWAN Specification: https://lora-alliance.org/
- Bluetooth SIG Assigned Numbers: https://www.bluetooth.com/specifications/assigned-numbers/
