# B210 Portapack-Style System Design

A portable, touchscreen-equipped multi-protocol RF detection system built around the USRP B210 clone with companion RP2350 controller and ESP32-C5/C6 radio modules.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Hardware Architecture](#hardware-architecture)
3. [SDR Comparison: AD9361 vs AD9363](#sdr-comparison-ad9361-vs-ad9363)
4. [GPIO Interface](#gpio-interface)
5. [Component Selection](#component-selection)
6. [BOM and Cost Analysis](#bom-and-cost-analysis)
7. [POC Build Guide](#poc-build-guide)
8. [Software Architecture](#software-architecture)
9. [App Framework](#app-framework)
10. [Performance Specifications](#performance-specifications)

---

## System Overview

### Concept

Build a Flipper Zero / Portapack Mayhem-style portable device that:
- Uses the B210 SDR for wideband RF (70 MHz - 6 GHz)
- Adds ESP32-C5/C6 for Wi-Fi 6, BLE 5.3, and Zigbee
- Provides touchscreen UI driven by RP2350
- Detects and classifies urban IoT infrastructure
- Runs standalone on battery power

### System Block Diagram

```
┌──────────────────────────────────────────────────────────────┐
│  HOST COMPUTER (Laptop/Raspberry Pi 4/NUC)                   │
│  ├─ GNU Radio / UHD                                          │
│  ├─ Main DSP processing                                      │
│  ├─ Demodulation / Decoding                                  │
│  └─ Data aggregation from all sources                        │
└────────────┬────────────────────────────┬────────────────────┘
             │ USB 3.0                    │ Ethernet/Wi-Fi
             │ (5 Gbps)                   │
             ↓                            ↓
┌─────────────────────────────┐  ┌──────────────────────────────┐
│  USRP B210 (Main SDR)       │  │  RP2350 Controller Board     │
│  ┌────────────────────────┐ │  │  ┌────────────────────────┐  │
│  │ Dual AD9361            │ │  │  │ RP2350 MCU             │  │
│  │ 70MHz - 6GHz           │ │  │  │ - Display driver       │  │
│  │ 61.44 MS/s             │ │  │  │ - GPIO control         │  │
│  └────────────────────────┘ │  │  │ - Data aggregator      │  │
│  ┌────────────────────────┐ │  │  └────────────────────────┘  │
│  │ Xilinx Kintex-7        │ │  │  ┌────────────────────────┐  │
│  │ XC7K325T FPGA          │ │  │  │ 320x240 Display        │  │
│  │ - FFT processing       │ │  │  │ (ILI9341 Touch)        │  │
│  │ - GPIO control         │←┼──┼─→│                        │  │
│  └────────────────────────┘ │  │  └────────────────────────┘  │
│           ↓                  │  │  ┌────────────────────────┐  │
│  ┌────────────────────────┐ │  │  │ 16-pin FPC Interface   │  │
│  │ GPIO Header (16-pin)   │ │  │  │ (to B210)              │  │
│  └────────────────────────┘ │  │  └────────────────────────┘  │
└─────────────────────────────┘  └──────────────────────────────┘
                                            │ UART
                                            ↓
                               ┌──────────────────────────────┐
                               │  ESP32-C5 Radio Module       │
                               │  ├─ Wi-Fi 6 (2.4/5 GHz)     │
                               │  ├─ BLE 5.3                  │
                               │  └─ Autonomous scanning      │
                               └──────────────────────────────┘
                                            │ UART
                                            ↓
                               ┌──────────────────────────────┐
                               │  Optional: ESP32-C6          │
                               │  └─ Thread/Zigbee native     │
                               └──────────────────────────────┘
```

---

## Hardware Architecture

### Module 1: RP2350 Core Board

```
┌─────────────────────────────────────────┐
│  RP2350 (Main Controller)               │
│  ┌─────────────────────────────────┐   │
│  │ Dual M33 @ 150MHz               │   │
│  │ 520KB SRAM + 16MB QSPI Flash    │   │
│  └─────────────────────────────────┘   │
│                                          │
│  Peripherals:                            │
│  ├─ USB Host/Device (for host PC)       │
│  ├─ UART0 → ESP32-C5 (commands)        │
│  ├─ UART1 → ESP32-C6 (optional)        │
│  ├─ SPI0 → MicroSD card (logging)      │
│  ├─ SPI1 → Display (optional)          │
│  ├─ I2C → RTC, EEPROM                  │
│  └─ PIO → 802.15.4 radio interface     │
│                                          │
│  802.15.4 Radio Options:                │
│  ├─ AT86RF233 (Zigbee/802.15.4)       │
│  ├─ MRF24J40MA (Microchip)             │
│  └─ CC2652 (TI, more capable)          │
└─────────────────────────────────────────┘
```

**PCB Design Notes:**
- 4-layer board (power plane crucial for noise)
- 50Ω controlled impedance for RF traces
- Separate analog/digital grounds with single-point connection
- RF section isolated with ground pours

### Module 2: ESP32-C5 Radio Board

```
┌─────────────────────────────────────────┐
│  ESP32-C5-WROOM-1 Module                │
│  ┌─────────────────────────────────┐   │
│  │ RISC-V @ 240 MHz                │   │
│  │ 512KB RAM + 16MB PSRAM          │   │
│  │ 4MB Flash                        │   │
│  └─────────────────────────────────┘   │
│                                          │
│  Wireless:                               │
│  ├─ Wi-Fi 6 (802.11ax) 2.4/5GHz        │
│  ├─ Bluetooth 5.3 (BLE)                │
│  └─ External antenna connector          │
│                                          │
│  Interfaces:                             │
│  ├─ UART → RP2350 (data stream)        │
│  ├─ GPIO → Status LEDs                  │
│  └─ ADC → RSSI measurement (optional)   │
└─────────────────────────────────────────┘
```

**Firmware Mode:** Promiscuous scanning
- Monitor mode for Wi-Fi
- Passive BLE scanning
- OUI database in flash
- Real-time streaming to RP2350

### Module 3: ESP32-C6 (Optional Thread/Matter)

```
┌─────────────────────────────────────────┐
│  ESP32-C6 (if Thread/Matter needed)     │
│  ┌─────────────────────────────────┐   │
│  │ RISC-V @ 160 MHz                │   │
│  │ Wi-Fi 6 + BLE 5.0               │   │
│  │ 802.15.4 radio (Thread/Zigbee)  │   │
│  └─────────────────────────────────┘   │
│                                          │
│  Use Case:                               │
│  └─ Native Thread/Matter detection      │
│     (alternative to discrete 802.15.4)  │
└─────────────────────────────────────────┘
```

---

## SDR Comparison: AD9361 vs AD9363

### Quick Comparison

| Feature | AD9361 (B210) | AD9363 (Mini Board) |
|---------|---------------|---------------------|
| **Price** | $1,200 | $199-249 |
| **Frequency** | 70 MHz - 6 GHz | 325 MHz - 3.8 GHz |
| **RX Channels** | 2 (MIMO) | 1 (SISO) |
| **TX Channels** | 2 (MIMO) | 1 (SISO) |
| **Duplex** | Full duplex | Full duplex |
| **Bandwidth** | 56 MHz | 56 MHz |
| **Sample Rate** | 61.44 MS/s | 61.44 MS/s |
| **FPGA** | Kintex-7 XC7K325T | Spartan-7 XC7S15 |
| **Size** | ~160x100mm | 35x50mm |

### What AD9363 Can Do

| Application | Supported? | Notes |
|-------------|------------|-------|
| Wi-Fi 2.4 GHz | Yes | Full coverage |
| BLE detection | Yes | 2.4 GHz |
| Zigbee | Yes | 2.4 GHz |
| LoRa 915 MHz | Yes | US ISM band |
| LTE most bands | Yes | 700 MHz borderline |
| Cell testing | Mostly | Missing low bands |
| RollJam 433 MHz | Yes | Works |
| RollJam 315 MHz | No | 10 MHz below range |
| 5 GHz Wi-Fi | No | Above range |

### Hybrid Approach (Best Value)

```
Primary SDR:
└─ AD9363 board:                $199

Gap fillers:
├─ RTL-SDR Blog V4:             $40
│  └─ Covers: 0-1766 MHz (fills low end!)
├─ CC1101 module (315/433 MHz): $8
│  └─ For car fobs specifically
└─ ESP32-C6 (covers 2.4 GHz):   $8

Total Coverage: 0 MHz - 3.8 GHz
Total Cost: ~$255 (vs $1,200 for B210)
```

---

## GPIO Interface

### B210 Clone 16-Pin FPC Pinout

The OpenSourceSDRLab B210 uses a 16-pin FPC (Flat Printed Circuit) connector for GPIO.

```
Typical 16-pin GPIO Pinout:

Pin  │ Function      │ Direction │ Voltage
─────┼───────────────┼───────────┼─────────
  1  │ GND           │ Power     │ 0V
  2  │ GPIO_0        │ Bidir     │ 3.3V
  3  │ GPIO_1        │ Bidir     │ 3.3V
  4  │ GPIO_2        │ Bidir     │ 3.3V
  5  │ GPIO_3        │ Bidir     │ 3.3V
  6  │ GPIO_4        │ Bidir     │ 3.3V
  7  │ GPIO_5        │ Bidir     │ 3.3V
  8  │ GPIO_6        │ Bidir     │ 3.3V
  9  │ GPIO_7        │ Bidir     │ 3.3V
 10  │ SPI_CLK       │ Output    │ 3.3V
 11  │ SPI_MOSI      │ Output    │ 3.3V
 12  │ SPI_MISO      │ Input     │ 3.3V
 13  │ SPI_CS        │ Output    │ 3.3V
 14  │ +3.3V         │ Power     │ 3.3V
 15  │ +3.3V         │ Power     │ 3.3V
 16  │ GND           │ Power     │ 0V

⚠️ VERIFY with OpenSourceSDRLab documentation!
```

### FPC Breakout Solution

**For POC prototyping:**
- 16-pin FPC breakout board ($3-5)
- Available in 0.5mm or 1.0mm pitch
- Converts FPC to 2.54mm breadboard-compatible headers

**Measurement Guide:**
```
To determine FPC pitch:

0.5mm pitch: 16 pins = 8mm total width
1.0mm pitch: 16 pins = 16mm total width
1.27mm pitch: 16 pins = 20.32mm total width

Most B210 clones use 1.0mm pitch
```

### Pin Allocation for RP2350

```c
// B210 GPIO → RP2350 GPIO mapping

// Data Interface (6-bit parallel):
Pin 2 (GPIO_0) → RP2350 GPIO 2 (Data bit 0)
Pin 3 (GPIO_1) → RP2350 GPIO 3 (Data bit 1)
Pin 4 (GPIO_2) → RP2350 GPIO 4 (Data bit 2)
Pin 5 (GPIO_3) → RP2350 GPIO 5 (Data bit 3)
Pin 6 (GPIO_4) → RP2350 GPIO 6 (Data bit 4)
Pin 7 (GPIO_5) → RP2350 GPIO 7 (Data bit 5)

// Control Signals:
Pin 8 (GPIO_6) → RP2350 GPIO 8 (Data Valid)
Pin 9 (GPIO_7) → RP2350 GPIO 9 (Command)

// SPI Interface (alternative):
Pin 10 (SPI_CLK)  → RP2350 GPIO 10 (SCK)
Pin 11 (SPI_MOSI) → RP2350 GPIO 11 (MOSI)
Pin 12 (SPI_MISO) → RP2350 GPIO 12 (MISO)
Pin 13 (SPI_CS)   → RP2350 GPIO 13 (CS)
```

---

## Component Selection

### Display Options

| Display | Resolution | Touch | Interface | Cost | FPS with RP2350 |
|---------|------------|-------|-----------|------|-----------------|
| 2.8" ILI9341 Resistive | 320x240 | Yes | SPI | $8-10 | ~30 |
| 3.2" ILI9341 Capacitive | 320x240 | Yes | SPI | $15-18 | ~40 |
| 3.5" ILI9488 Capacitive | 480x320 | Yes | 8-bit | $25-30 | ~50 |

**Recommended:** 3.2" ILI9341 Capacitive ($18)
- Best balance of size, quality, and cost
- Smooth capacitive touch
- Good for detailed spectrum views

### MCU Selection

| MCU | RAM | Flash | Price | Notes |
|-----|-----|-------|-------|-------|
| Raspberry Pi Pico 2 | 520KB | 16MB | $5 | Recommended |
| ESP32-C6-DevKitC | 512KB | 4MB | $8 | Has Zigbee built-in |

### Radio Modules

| Module | Protocols | Frequency | Price |
|--------|-----------|-----------|-------|
| ESP32-C5 | Wi-Fi 6, BLE 5.3 | 2.4/5 GHz | $4 |
| ESP32-C6 | Wi-Fi 6, BLE, Zigbee | 2.4 GHz | $8 |
| AT86RF233 | 802.15.4 | 2.4 GHz | $8 |
| CC1101 | Sub-GHz | 315/433/868 MHz | $5 |

---

## BOM and Cost Analysis

### POC Build (Breadboard Prototype)

| Category | Item | Cost |
|----------|------|------|
| **Interface** | 16-pin FPC breakouts (both pitches) | $6 |
| | Breadboards (3x large) | $12 |
| | Jumper wire kit | $18 |
| | Breadboard power supply | $8 |
| | Digital calipers | $15 |
| **Subtotal** | | **$59** |
| **Dev Boards** | Raspberry Pi Pico 2 | $5 |
| | ESP32-C6-DevKitC-1 | $8 |
| | 3.2" ILI9341 touch LCD | $18 |
| | MicroSD breakout + card | $10 |
| | GPS module (optional) | $12 |
| | Rotary encoder + buttons | $8 |
| **Subtotal** | | **$61** |
| **Power** | 18650 batteries (3x) | $9 |
| | TP4056 chargers (3x) | $3 |
| | Battery holder | $2 |
| | MT3608 boost | $2 |
| | LM2596 buck | $2 |
| | Power switch | $1 |
| **Subtotal** | | **$19** |
| **Optional** | Logic level shifter | $3 |
| | LED indicators | $2 |
| | Heat shrink kit | $5 |
| | Debug OLED | $6 |
| **Subtotal** | | **$16** |
| **POC TOTAL** | | **$155** |
| **+ B210 Clone** | OpenSourceSDRLab | $1,200 |
| **SYSTEM TOTAL** | | **$1,355** |

### Budget Alternative (AD9363)

| Item | Cost |
|------|------|
| AD9363 board | $199 |
| RTL-SDR V4 | $40 |
| POC components | $155 |
| **TOTAL** | **$394** |

---

## POC Build Guide

### Phase 1: Measure and Procure (Week 1)

```
1. Measure B210 FPC cable:
   ├─ Count pins (should be 16)
   ├─ Measure pitch (0.5mm or 1.0mm)
   └─ Note contact orientation

2. Order components:
   ├─ FPC breakouts (both pitches if unsure)
   ├─ Raspberry Pi Pico 2
   ├─ ESP32-C6-DevKitC
   ├─ Display module
   └─ All other BOM items
```

### Phase 2: Assembly (Week 2)

```
Day 1: Power System
├─ Build breadboard power distribution
├─ Test all voltage rails (3.3V, 5V)
└─ Verify with multimeter

Day 2: FPC Interface
├─ Solder headers to FPC breakout
├─ Connect FPC cable from B210
├─ Test continuity
└─ Verify no shorts

Day 3: MCU Setup
├─ Install Pico 2 in breadboard
├─ Wire to FPC breakout
├─ Flash test firmware
└─ Verify GPIO communication

Day 4: Radio Module
├─ Install ESP32-C6
├─ Wire UART to Pico 2
├─ Flash scanning firmware
└─ Test Wi-Fi/BLE scanning

Day 5: Display
├─ Wire ILI9341 to Pico 2
├─ Test display driver
├─ Wire touch controller
└─ Verify touch input

Day 6-7: Integration
├─ Connect all modules
├─ Test end-to-end data flow
├─ Debug any issues
└─ Document pinouts and settings
```

### Wiring Diagram (RP2350 Pico 2)

```
B210 GPIO Interface:
├─ GPIO 2 → B210 GPIO_0 (data bit 0)
├─ GPIO 3 → B210 GPIO_1 (data bit 1)
├─ GPIO 4 → B210 GPIO_2 (data bit 2)
├─ GPIO 5 → B210 GPIO_3 (data bit 3)
├─ GPIO 6 → B210 GPIO_4 (data bit 4)
├─ GPIO 7 → B210 GPIO_5 (data bit 5)
├─ GPIO 8 → B210 GPIO_6 (data valid)
└─ GPIO 9 → B210 GPIO_7 (command)

ESP32-C6 Communication (UART):
├─ GPIO 0 (TX) → ESP32 GPIO 20 (RX)
├─ GPIO 1 (RX) → ESP32 GPIO 21 (TX)
└─ GND → common ground

Display (ILI9341 SPI):
├─ GPIO 10 → DC (data/command)
├─ GPIO 11 → RST (reset)
├─ GPIO 12 → CS (chip select)
├─ GPIO 13 → SCK (SPI clock)
├─ GPIO 14 → MOSI (SPI data out)
├─ GPIO 15 → MISO (SPI data in)
└─ GPIO 16 → T_CS (touch chip select)

MicroSD Card (SPI, shared):
├─ GPIO 17 → SD_CS
├─ GPIO 13 → SCK (shared)
├─ GPIO 14 → MOSI (shared)
└─ GPIO 15 → MISO (shared)

Controls:
├─ GPIO 18 → Rotary A
├─ GPIO 19 → Rotary B
├─ GPIO 20 → Rotary Button
├─ GPIO 21 → Button 1
├─ GPIO 22 → Button 2
└─ (Add 10kΩ pull-ups to 3.3V)
```

---

## Software Architecture

### Data Structures

```c
// Core detection packet structure
typedef struct {
    uint8_t protocol;        // WIFI, BLE, ZIGBEE, LORA
    uint64_t timestamp_us;   // Microsecond timestamp
    uint8_t mac[6];          // MAC address (OUI extractable)
    int8_t rssi;             // Signal strength
    uint16_t channel;        // Channel/frequency
    uint16_t data_len;       // Payload length
    uint8_t data[];          // Variable payload
} __attribute__((packed)) detection_packet_t;
```

### RP2350 Firmware Architecture

```c
// Main loop architecture
void core0_main() {
    // Handle USB communication with host
    while(1) {
        usb_task();
        aggregate_sensor_data();
        send_to_host();
        update_display();
    }
}

void core1_main() {
    // Handle Zigbee/802.15.4 real-time processing
    while(1) {
        zigbee_scan_channels();
        process_802154_packets();
        extract_device_info();
        buffer_for_core0();
    }
}
```

### ESP32-C5/C6 Scanner Firmware

```c
// Wi-Fi promiscuous mode callback
void wifi_sniffer_callback(void* buf, wifi_promiscuous_pkt_type_t type) {
    wifi_promiscuous_pkt_t *pkt = (wifi_promiscuous_pkt_t*)buf;

    // Extract frame control
    uint16_t frame_ctrl = ((uint16_t)pkt->payload[1] << 8) | pkt->payload[0];
    uint8_t frame_type = (frame_ctrl & 0x0C) >> 2;

    // Get source MAC (OUI in first 3 bytes)
    uint8_t *src_mac = &pkt->payload[10];

    // Lookup OUI in flash database
    const char* vendor = oui_lookup(src_mac);

    // Stream to RP2350
    detection_packet_t packet = {
        .protocol = PROTO_WIFI,
        .timestamp_us = esp_timer_get_time(),
        .rssi = pkt->rx_ctrl.rssi,
        .channel = pkt->rx_ctrl.channel,
        // ... populate rest
    };

    uart_write_bytes(UART_NUM_0, &packet, sizeof(packet));
}

// BLE scanning
void ble_scan_callback(esp_ble_gap_cb_event_t event,
                       esp_ble_gap_cb_param_t *param) {
    if (event == ESP_GAP_BLE_SCAN_RESULT_EVT) {
        uint8_t *addr = param->scan_rst.bda;
        int8_t rssi = param->scan_rst.rssi;

        // Check against known device signatures
        device_type_t type = identify_device(addr, param->scan_rst.ble_adv);

        // Stream detection
        send_detection_to_rp2350(PROTO_BLE, addr, rssi, type);
    }
}
```

### Host Software (Python)

```python
# Host coordinator daemon
import serial
import sqlite3
from dataclasses import dataclass
from datetime import datetime

@dataclass
class DetectedDevice:
    timestamp: datetime
    protocol: str  # WIFI, BLE, ZIGBEE
    mac: str
    oui_vendor: str
    rssi: int
    channel: int
    device_type: str  # Polara, Flock, etc.
    location: tuple  # GPS if available

class MultiProtocolDetector:
    def __init__(self, serial_port='/dev/ttyUSB0'):
        self.ser = serial.Serial(serial_port, 921600)
        self.db = sqlite3.connect('detections.db')
        self.init_database()

    def process_packet(self, raw_data):
        # Parse detection_packet_t structure
        protocol = raw_data[0]
        timestamp = int.from_bytes(raw_data[1:9], 'little')
        mac = raw_data[9:15]
        rssi = int.from_bytes([raw_data[15]], signed=True)

        # Lookup OUI vendor
        oui = ':'.join(f'{b:02X}' for b in mac[:3])
        vendor = self.oui_db.get(oui, 'Unknown')

        # Classify device
        device_type = self.classify_device(mac, protocol, raw_data)

        # Store in database
        self.store_detection(DetectedDevice(...))

    def classify_device(self, mac, protocol, data):
        """Identify specific device types"""
        oui = mac[:3]

        # Polara crosswalk devices
        if oui == bytes([0x00, 0x1B, 0xC5]):
            return "Polara APS"

        # Flock cameras
        if b'Flock' in data:
            return "Flock Camera"

        # Smart streetlight patterns
        if protocol == PROTO_ZIGBEE:
            if self.is_streetlight_pattern(data):
                return "Smart Streetlight"

        return "Unknown"
```

---

## App Framework

### Memory Layout

```
Flash Layout (16 MB):
┌─────────────────────────────────────────┐
│  0x00000000 - 0x00100000 (1 MB)        │
│  └─ Bootloader + HAL + Core libs        │
├─────────────────────────────────────────┤
│  0x00100000 - 0x00800000 (7 MB)        │
│  └─ Built-in Apps + UI library          │
├─────────────────────────────────────────┤
│  0x00800000 - 0x00E00000 (6 MB)        │
│  └─ OUI DB + Device signatures + Fonts  │
├─────────────────────────────────────────┤
│  0x00E00000 - 0x01000000 (2 MB)        │
│  └─ Reserved for firmware updates       │
└─────────────────────────────────────────┘

RAM Layout (520 KB):
┌─────────────────────────────────────────┐
│  Display Framebuffer:  300 KB           │
│  ├─ Front buffer:      150 KB           │
│  └─ Back buffer:       150 KB           │
├─────────────────────────────────────────┤
│  Current App State:    80 KB            │
├─────────────────────────────────────────┤
│  Packet Buffers:       80 KB            │
├─────────────────────────────────────────┤
│  System (USB/FatFS):   60 KB            │
└─────────────────────────────────────────┘
```

### App Structure

```c
typedef struct {
    const char *name;
    const char *category;
    void (*init)(void);
    void (*loop)(void);
    void (*draw)(framebuffer_t *fb);
    void (*input)(input_event_t *evt);
    void (*deinit)(void);
} app_t;

const app_t builtin_apps[] = {
    // Scanner Apps
    {
        .name = "Wi-Fi Scanner",
        .category = "Scanners",
        .init = wifi_scanner_init,
        .loop = wifi_scanner_loop,
        .draw = wifi_scanner_draw,
        .input = wifi_scanner_input,
        .deinit = wifi_scanner_deinit
    },
    {
        .name = "BLE Scanner",
        .category = "Scanners",
        // ...
    },
    {
        .name = "Device Hunter",
        .category = "Detection",
        // Actively scans for known device types
    },
    {
        .name = "Spectrum Analyzer",
        .category = "Analysis",
        // Visual spectrum waterfall
    },
    {
        .name = "OUI Database",
        .category = "Tools",
        // Lookup MAC vendor info
    },
    {
        .name = "GPS Logger",
        .category = "Tools",
        // Log detections with GPS
    },
};
```

### Menu System

```c
const menu_item_t main_menu[] = {
    {"Scanners",  ICON_ANTENNA, MENU_SCANNERS},
    {"Detectors", ICON_TARGET,  MENU_DETECTORS},
    {"Analysis",  ICON_CHART,   MENU_ANALYSIS},
    {"Tools",     ICON_WRENCH,  MENU_TOOLS},
    {"Settings",  ICON_GEAR,    MENU_SETTINGS}
};

const menu_item_t scanner_menu[] = {
    {"Wi-Fi Scanner",    ICON_WIFI,      APP_WIFI_SCANNER},
    {"BLE Scanner",      ICON_BLUETOOTH, APP_BLE_SCANNER},
    {"Zigbee Analyzer",  ICON_ZIGBEE,    APP_ZIGBEE_ANALYZER},
    {"LoRa Monitor",     ICON_RADIO,     APP_LORA_MONITOR},
    {"Spectrum",         ICON_SPECTRUM,  APP_SPECTRUM}
};
```

---

## Performance Specifications

### Detection Capabilities

```
Protocol Coverage:
├─ Wi-Fi (ESP32-C5)
│  ├─ 2.4 GHz: 802.11 b/g/n/ax
│  ├─ 5 GHz: 802.11 a/n/ac/ax
│  ├─ Channels: All 2.4GHz (1-14), 5GHz (36-165)
│  └─ Capture rate: ~1000 packets/sec
│
├─ Bluetooth (ESP32-C5)
│  ├─ BLE 5.3 advertisements
│  ├─ Classic Bluetooth detection
│  ├─ Channels: 0-39 (37-39 for advertising)
│  └─ Scan rate: Full 37 channels in ~2 seconds
│
└─ Zigbee/802.15.4 (RP2350 + AT86RF233)
   ├─ Channels: 11-26 (2.4 GHz)
   ├─ Capture rate: ~500 packets/sec
   └─ Energy detection on all channels: <1 second
```

### Processing Throughput

```
RP2350 Core 0 (Coordinator):
- USB throughput: Up to 12 Mbps (Full Speed)
- Data aggregation: 5000 packets/sec
- Database updates: 1000 records/sec
- Display updates: 30-50 fps

RP2350 Core 1 (Zigbee):
- Channel scan: All 16 channels in 160ms
- Packet processing: 500 pps
- MAC extraction: 500 devices/sec

ESP32-C5 (Wi-Fi/BLE):
- Wi-Fi scan: ~100ms per channel
- BLE scan: 37 channels in 2 sec (optimized)
- OUI lookups: 10000/sec (flash cache)
- UART streaming: 921600 baud (115 KB/s)
```

### Power Budget

```
Component Power Draw:
├─ RP2350 @ 150MHz:        ~50 mA @ 3.3V  = 165 mW
├─ AT86RF233 (RX):         ~12 mA @ 3.3V  = 40 mW
├─ ESP32-C5 (scanning):    ~120 mA @ 3.3V = 396 mW
│  ├─ Wi-Fi active:        80 mA
│  └─ BLE scanning:        40 mA
├─ MicroSD card:           ~30 mA @ 3.3V  = 100 mW
├─ LEDs (3x):              ~10 mA @ 3.3V  = 33 mW
└─ Voltage regulators:     ~10 mA         = 33 mW
                          ──────────────────────────
Total:                     ~232 mA @ 3.3V = ~767 mW

Battery Life (10000 mAh @ 3.7V):
37 Wh / 0.767W = ~48 hours continuous operation
```

---

## Comparison to Alternatives

| Solution | Cost | Protocols | Portability | OUI Detection |
|----------|------|-----------|-------------|---------------|
| Your RP2350+ESP32-C5 | $40-70 | Wi-Fi, BLE, Zigbee | Excellent | Real-time |
| Laptop + Kismet | $500+ | All | Poor | Yes |
| Flipper Zero | $170 | Sub-GHz, BLE | Excellent | Limited |
| Ubertooth One | $120 | BLE only | Good | Yes (BLE) |
| GL.iNet router | $40-80 | Wi-Fi only | Good | Limited |

---

## Development Timeline

### Phase 1: Hardware (4-6 weeks)
- Week 1-2: Schematic design
- Week 3: PCB layout (both boards)
- Week 4: PCB fabrication + component sourcing
- Week 5-6: Assembly + bring-up

### Phase 2: Firmware (8-10 weeks)
- Week 1-2: RP2350 HAL + USB stack
- Week 3-4: Zigbee packet capture
- Week 5-6: ESP32-C5 Wi-Fi/BLE scanning
- Week 7-8: Inter-MCU communication protocol
- Week 9-10: Integration + testing

### Phase 3: Host Software (4-6 weeks)
- Week 1-2: Serial protocol + database
- Week 3-4: Device classification engine
- Week 5-6: Web UI + reporting

**Total: ~16-22 weeks for full system**

---

## Next Steps

1. **Order dev boards to prototype:**
   - Raspberry Pi Pico 2 ($5)
   - ESP32-C6-DevKitM-1 ($8)
   - 16-pin FPC breakout ($3)

2. **Breadboard test:**
   - UART communication between RP2350 ↔ ESP32-C6
   - ESP32-C6 Wi-Fi promiscuous mode
   - Zigbee packet capture

3. **Verify B210 GPIO:**
   - Measure FPC pitch
   - Test GPIO communication via UHD
   - Document actual pinout

4. **Design PCB once firmware proven**

---

## References

- [OpenSourceSDRLab B210](https://opensourcesdrlab.com/)
- [RP2350 Datasheet](https://datasheets.raspberrypi.com/rp2350/rp2350-datasheet.pdf)
- [ESP32-C5 Technical Reference](https://www.espressif.com/en/products/socs/esp32-c5)
- [AD9361 Datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/AD9361.pdf)
- [AD9363 Datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/AD9363.pdf)
