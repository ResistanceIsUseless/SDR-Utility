# B210 Portapack - Comprehensive Project Plan

## Executive Summary

A portable SDR platform for the XC7K325T B210 Clone, capable of 5G signal analysis, with touchscreen interface and wireless connectivity via ESP32-C5. Three design variants are proposed: standalone custom board, uConsole-based, and MNT Reform Pocket-based.

---

## 1. System Architecture Overview

### Core Components

| Component | Purpose | Selection Rationale |
|-----------|---------|---------------------|
| **B210 Clone** | RF Frontend (70 MHz - 6 GHz) | Already owned, XC7K325T provides 840 DSP slices |
| **RK3588** | Main Processing (FFT/DSP/5G) | 8-core, 6 TOPS NPU, 8K video encode/decode |
| **ESP32-C5** | WiFi 6/BLE 5.4 | 2.4/5GHz dual-band, low power, offloads wireless from main CPU |
| **Display** | Touch Interface | 4-5" IPS, 720p minimum for spectrum visualization |
| **Battery** | Power | 10000+ mAh for extended field use |

### Why RK3588 vs RP2350

| Feature | RP2350 | RK3588 | Requirement |
|---------|--------|--------|-------------|
| CPU Cores | 2 @ 150MHz | 8 @ 2.4GHz | ✗ / ✓ |
| RAM | 520KB | 8-32GB | ✗ / ✓ |
| DSP/FFT | Software only | NPU + GPU | ✗ / ✓ |
| USB3 | No | Yes (multiple) | ✗ / ✓ |
| 5G Processing | Impossible | Viable | ✗ / ✓ |
| Power Draw | ~50mW | ~5-15W | ✓ / ✓ |

**Verdict**: RP2350 cannot handle 56MHz bandwidth FFT, 5G demodulation, or waterfall rendering. RK3588 is mandatory.

---

## 2. Design Variants

### Variant A: Custom Standalone Board (Recommended)

```
┌─────────────────────────────────────────────────────────────┐
│                    B210 PORTAPACK                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   RK3588    │  │  ESP32-C5   │  │   5" Touch LCD      │  │
│  │  SOM/CM     │  │  WiFi/BLE   │  │   720p IPS          │  │
│  │             │  │  Module     │  │                     │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                     │             │
│  ┌──────┴────────────────┴─────────────────────┴──────────┐  │
│  │                 CARRIER BOARD (Custom PCB)              │  │
│  │  - USB3 Host for B210                                   │  │
│  │  - MIPI DSI for display                                 │  │
│  │  - SPI/UART for ESP32-C5                                │  │
│  │  - Battery management (BMS)                             │  │
│  │  - SD Card slot                                         │  │
│  │  - GPIO expansion header                                │  │
│  └─────────────────────────────────────────────────────────┘  │
│         │                                                     │
│  ┌──────┴──────┐  ┌──────────────┐  ┌────────────────────┐   │
│  │   B210      │  │  Li-Ion      │  │ SMA Antenna        │   │
│  │   Clone     │  │  Battery     │  │ Connectors         │   │
│  │  (USB3.0)   │  │  10000mAh    │  │ (Pass-through)     │   │
│  └─────────────┘  └──────────────┘  └────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Pros:**
- Optimized form factor
- Best thermal design
- Direct B210 integration possible
- Custom I/O arrangement

**Cons:**
- Highest development cost (~$200-500 for prototypes)
- Longest development time (6-12 months)
- PCB design expertise required

### Variant B: uConsole-Based

```
┌───────────────────────────────────────────────────────────────┐
│                      UCONSOLE MOD                              │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              CLOCKWORK UCONSOLE                          │  │
│  │  - Replace CM4 with RK3588 CM (if pin-compatible)        │  │
│  │  - OR use A06/A04 module with external RK3588            │  │
│  │  - Built-in keyboard (no touchscreen by default)         │  │
│  └─────────────────────────────────────────────────────────┘  │
│                           │                                    │
│  ┌──────────────┐  ┌──────┴───────┐  ┌─────────────────────┐  │
│  │  ESP32-C5    │  │  Adapter     │  │     B210 Clone      │  │
│  │  Hat/Module  │  │  Board       │  │     (External)      │  │
│  │  (GPIO)      │  │  (GPIO→USB)  │  │                     │  │
│  └──────────────┘  └──────────────┘  └─────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

**GPIO Modification Requirements:**
- uConsole uses a custom GPIO header (14-pin)
- Need adapter board: GPIO → USB3 hub → B210
- ESP32-C5 connects via remaining GPIO (SPI/UART)
- May need to modify case for antenna pass-through

**Pros:**
- Existing enclosure and battery
- Built-in keyboard for terminal access
- Lower cost entry point
- Community support

**Cons:**
- No native touchscreen
- Limited GPIO for expansion
- B210 must be external or require case mod
- RK3588 CM may not be pin-compatible

### Variant C: MNT Reform Pocket-Based

```
┌───────────────────────────────────────────────────────────────┐
│                   MNT REFORM POCKET MOD                        │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              MNT REFORM POCKET                           │  │
│  │  - Open hardware design (schematics available!)          │  │
│  │  - Already uses RK3588 or can be upgraded                │  │
│  │  - 7" display (larger spectrum view)                     │  │
│  │  - Mechanical keyboard                                   │  │
│  └─────────────────────────────────────────────────────────┘  │
│                           │                                    │
│  ┌──────────────┐  ┌──────┴───────┐  ┌─────────────────────┐  │
│  │  ESP32-C5    │  │  Custom      │  │     B210 Clone      │  │
│  │  PCIe/USB    │  │  Expansion   │  │   (Internal or      │  │
│  │  Adapter     │  │  Card        │  │    Dock Module)     │  │
│  └──────────────┘  └──────────────┘  └─────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

**Modification Approach:**
- MNT Reform Pocket has open KiCad files
- Custom expansion card slot for B210 interface
- ESP32-C5 as internal module or USB adapter
- Larger form factor accommodates B210 internally

**Pros:**
- Open hardware (full schematics available)
- Already powerful SOM options
- Room for internal modifications
- Active open-source community

**Cons:**
- Larger form factor
- Higher base cost (~$800+)
- Still requires significant modification
- No touchscreen (keyboard-focused design)

---

## 3. 5G Processing Architecture

### Challenge: 5G NR Bandwidth

| 5G Band | Bandwidth | Sample Rate Required | Data Rate |
|---------|-----------|---------------------|-----------|
| n41 | 100 MHz | 122.88 MSPS | ~3.9 Gbps IQ |
| n77/78 | 100 MHz | 122.88 MSPS | ~3.9 Gbps IQ |
| Sub-6 | 20-100 MHz | 30.72-122.88 MSPS | ~1-4 Gbps |

**B210 Limitation**: 56 MHz max real-time bandwidth (can capture partial 5G channels)

### Processing Pipeline

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐     ┌──────────┐
│  B210   │────▶│   RK3588    │────▶│   srsRAN    │────▶│ Display/ │
│  IQ     │USB3 │   DDR      │     │   5G NR     │     │ Analysis │
│  Stream │     │   Buffer    │     │   Decode    │     │          │
└─────────┘     └─────────────┘     └─────────────┘     └──────────┘
     │                │                    │
     │                ▼                    ▼
     │         ┌─────────────┐     ┌─────────────┐
     │         │  Mali GPU   │     │  NPU        │
     │         │  FFT/       │     │  ML-based   │
     │         │  Waterfall  │     │  Signal ID  │
     └─────────┴─────────────┘     └─────────────┘
```

### Software Stack

```yaml
Base OS: Armbian / Ubuntu 22.04 (arm64)

Core SDR:
  - UHD 4.x (B210 driver)
  - GNU Radio 3.10+
  - SoapySDR (abstraction layer)

5G Analysis:
  - srsRAN 5G (open-source 5G stack)
  - Open5GS (5G core simulation)
  - gr-nr (GNU Radio 5G blocks)

Visualization:
  - SDR++ (native arm64 builds exist)
  - GQRX (Qt-based, touch-friendly possible)
  - Custom Qt/GTK app with touch UI

ML/Signal Classification:
  - TensorFlow Lite (RK3588 NPU)
  - ONNX Runtime
  - Custom signal fingerprinting models
```

---

## 4. ESP32-C5 Integration

### ESP32-C5 Specifications
- **WiFi**: 802.11ax (WiFi 6) 2.4 GHz + 5 GHz
- **Bluetooth**: BLE 5.4
- **RISC-V**: Single-core 240 MHz
- **Available**: Expected Q1 2025 (use ESP32-C6 as interim)

### Connection Options

```
Option A: UART (Simple)
┌──────────┐  UART   ┌──────────┐
│  RK3588  │◀───────▶│ ESP32-C5 │
│          │ 3.3V    │          │
└──────────┘         └──────────┘
- 921600 baud typical
- Sufficient for control commands
- WiFi/BLE data flows through ESP32

Option B: SPI (Faster)
┌──────────┐  SPI    ┌──────────┐
│  RK3588  │◀───────▶│ ESP32-C5 │
│          │ 40MHz   │          │
└──────────┘         └──────────┘
- Up to 80 Mbps theoretical
- Better for streaming WiFi captures

Option C: USB (Easiest)
┌──────────┐  USB    ┌──────────┐
│  RK3588  │◀───────▶│ ESP32-C5 │
│          │ 12Mbps  │          │
└──────────┘         └──────────┘
- CDC/ECM device class
- Plug-and-play Linux support
```

### ESP32-C5 Firmware Functions

```c
// Proposed firmware capabilities
typedef struct {
    // WiFi Functions
    void (*wifi_scan)(void);              // Survey 2.4/5GHz networks
    void (*wifi_monitor)(channel_t ch);   // Monitor mode captures
    void (*wifi_inject)(packet_t *pkt);   // Packet injection
    
    // BLE Functions
    void (*ble_scan)(void);               // BLE advertisement scan
    void (*ble_sniff)(addr_t target);     // Targeted BLE sniffing
    
    // Control
    void (*set_channel)(band_t b, uint8_t ch);
    void (*set_power)(int8_t dbm);
    
    // Data Transfer
    void (*stream_to_host)(buffer_t *buf);
} esp32_c5_interface_t;
```

---

## 5. Hardware Interface Design

### B210 Clone Connections

Current B210 Clone interfaces:
- **USB 3.0 Type-C**: Main data (up to 5 Gbps)
- **SMA x4**: TRX1, TRX2, RX1, RX2
- **MMCX x3**: GPS, PPS, 10MHz Ref
- **FPC**: JTAG + GPIO (debugging)

### Proposed Carrier Board Block Diagram

```
                     ┌────────────────────────────────────────┐
                     │           CARRIER BOARD                 │
                     │                                         │
    ┌────────┐       │  ┌──────────────────────────────────┐  │
    │ RK3588 │◀─────▶│──│ PCIE/USB3 to USB3.0 Hub        │  │
    │ CM5    │ PCIE  │  │ (GL3590 or similar)             │  │
    │        │       │  └─────────────┬────────────────────┘  │
    └────────┘       │                │                        │
                     │                ▼                        │
                     │  ┌──────────────────────────────────┐  │
                     │  │ USB 3.0 Type-C Female           │──┼──▶ B210
                     │  │ (For B210 connection)            │  │
                     │  └──────────────────────────────────┘  │
                     │                                         │
    ┌────────┐       │  ┌──────────────────────────────────┐  │
    │ RK3588 │◀─────▶│──│ SPI / UART Interface            │  │
    │        │ GPIO  │  └─────────────┬────────────────────┘  │
    └────────┘       │                │                        │
                     │                ▼                        │
                     │  ┌──────────────────────────────────┐  │
                     │  │ ESP32-C5 Module                  │  │
                     │  │ (Onboard WiFi 6 + BLE 5.4)      │  │
                     │  └──────────────────────────────────┘  │
                     │                                         │
    ┌────────┐       │  ┌──────────────────────────────────┐  │
    │ RK3588 │◀─────▶│──│ MIPI DSI (4-lane)               │──┼──▶ LCD
    │        │ DSI   │  └──────────────────────────────────┘  │
    └────────┘       │                                         │
                     │  ┌──────────────────────────────────┐  │
    ┌────────┐       │  │ I2C Touch Controller            │  │
    │ RK3588 │◀─────▶│──│ (GT911 or FT5x06)               │──┼──▶ Touch
    │        │ I2C   │  └──────────────────────────────────┘  │
    └────────┘       │                                         │
                     │  ┌──────────────────────────────────┐  │
                     │  │ Power Management                 │  │
                     │  │ - BQ25895 (USB-C PD Charging)   │  │
                     │  │ - BQ27441 (Fuel Gauge)          │  │
                     │  │ - TPS65987 (USB-C Controller)   │  │
                     │  └──────────────────────────────────┘  │
                     │                                         │
                     │  ┌──────────────────────────────────┐  │
                     │  │ Misc I/O                         │  │
                     │  │ - SD Card slot (UHS-I)          │  │
                     │  │ - Audio codec (optional)        │  │
                     │  │ - Status LEDs                    │  │
                     │  │ - Power/Reset buttons           │  │
                     │  └──────────────────────────────────┘  │
                     └────────────────────────────────────────┘
```

---

## 6. Bill of Materials (Preliminary)

### Variant A: Custom Board

| Component | Part Number | Est. Cost | Source |
|-----------|-------------|-----------|--------|
| RK3588 CM | Rock5 CM5 / Orange Pi CM5 | $80-150 | AliExpress |
| Carrier PCB | Custom 4-layer | $50-100 | JLCPCB |
| ESP32-C5 Module | ESP32-C5-WROOM | $5-8 | LCSC |
| 5" Touch LCD | WT32-SC01 Plus style | $25-40 | AliExpress |
| USB3 Hub IC | GL3590 | $3 | LCSC |
| Power ICs | BQ25895 + BQ27441 | $10 | DigiKey |
| Battery | 3.7V 10000mAh LiPo | $20 | Various |
| Enclosure | 3D Print + Aluminum | $30-50 | Local |
| Passives/Connectors | Various | $30 | LCSC |
| **TOTAL** | | **~$250-450** | |

### Variant B: uConsole Mod

| Component | Part Number | Est. Cost | Source |
|-----------|-------------|-----------|--------|
| uConsole Kit | DevTerm A06/A04 | $220-320 | ClockworkPi |
| ESP32-C5 Module | ESP32-C5-WROOM | $5-8 | LCSC |
| Adapter Board | Custom 2-layer | $10-20 | JLCPCB |
| USB-C Hub | Generic | $15 | Amazon |
| Case Modifications | 3D printed parts | $10 | Local |
| **TOTAL** | | **~$260-380** | |

*Note: May still need external RK3588 SBC for 5G processing*

### Variant C: MNT Reform Pocket Mod

| Component | Part Number | Est. Cost | Source |
|-----------|-------------|-----------|--------|
| MNT Reform Pocket | Base kit | $800+ | MNT Research |
| Custom Expansion Card | PCB design | $30 | JLCPCB |
| ESP32-C5 Module | ESP32-C5-WROOM | $5-8 | LCSC |
| Internal B210 Mount | 3D printed | $10 | Local |
| **TOTAL** | | **~$850-950** | |

---

## 7. Software Development Plan

### Phase 1: Base Platform (Month 1-2)
```
[ ] Set up RK3588 development environment
[ ] Port UHD to arm64 (or use existing builds)
[ ] Test B210 @ 56MHz bandwidth over USB3
[ ] Baseline FFT performance benchmarks
```

### Phase 2: GUI Framework (Month 2-3)
```
[ ] Evaluate Qt6 vs GTK4 for touch UI
[ ] Design spectrum analyzer widget
[ ] Implement waterfall display (GPU-accelerated)
[ ] Create touch-friendly frequency/gain controls
```

### Phase 3: 5G Integration (Month 3-5)
```
[ ] Compile srsRAN for arm64
[ ] Implement 5G NR cell scanner
[ ] Add basic 5G signal analysis
[ ] Decode MIB/SIB messages where possible
```

### Phase 4: ESP32-C5 Integration (Month 4-5)
```
[ ] Develop ESP32-C5 firmware (WiFi monitor mode)
[ ] Implement BLE scanning/sniffing
[ ] Create host-side driver/API
[ ] Integrate WiFi analysis into main UI
```

### Phase 5: Polish & Features (Month 5-6)
```
[ ] Signal recording/playback
[ ] Export to common formats (SigMF)
[ ] Remote operation (VNC/web interface)
[ ] Battery optimization
[ ] Documentation
```

---

## 8. uConsole/Reform Pocket GPIO Mapping

### uConsole Expansion Port (14-pin)

```
Pin  Function        B210 Portapack Use
──────────────────────────────────────
1    GND             GND
2    3.3V            ESP32-C5 Power
3    GPIO (UART TX)  ESP32 RX
4    GPIO (UART RX)  ESP32 TX  
5    GPIO (SPI CLK)  ESP32 SPI (optional)
6    GPIO (SPI MOSI) ESP32 SPI (optional)
7    GPIO (SPI MISO) ESP32 SPI (optional)
8    GPIO (SPI CS)   ESP32 SPI (optional)
9    I2C SDA         Touch controller
10   I2C SCL         Touch controller
11   USB D+          USB hub to B210
12   USB D-          USB hub to B210
13   5V              USB hub power
14   GND             GND
```

**Challenge**: uConsole doesn't expose USB3, only USB2 via GPIO. Would need external USB3 hub with own power.

### MNT Reform Pocket Expansion

The Reform Pocket uses standard PCIe/M.2 slots - much easier to interface:
- M.2 Key-M for NVMe (can be adapted)
- Full-size PCIe slot possible with riser
- Better suited for high-bandwidth B210 connection

---

## 9. Thermal Considerations

### Power Budget

| Component | Idle | Active | Peak |
|-----------|------|--------|------|
| RK3588 | 3W | 8W | 15W |
| B210 (USB powered) | 1W | 3W | 5W |
| ESP32-C5 | 0.1W | 0.5W | 0.8W |
| Display | 1W | 2W | 2.5W |
| **Total** | **5W** | **13W** | **23W** |

### Cooling Solutions

1. **Passive (Quiet Operation)**
   - Large aluminum heatsink on RK3588
   - Thermal pads to case (if metal)
   - Limited to ~10W continuous

2. **Active (High Performance)**
   - 40mm fan with PWM control
   - Heat pipe to external fins
   - Supports sustained 20W+

### Battery Life Estimates

| Battery | Idle Time | Active Use |
|---------|-----------|------------|
| 5000 mAh | 3.5 hrs | 1.5 hrs |
| 10000 mAh | 7 hrs | 3 hrs |
| 20000 mAh | 14 hrs | 6 hrs |

---

## 10. Recommendations

### Recommended Path: Variant A (Custom Board)

**Rationale:**
1. **Optimal Performance**: Direct USB3 connection to RK3588
2. **Proper Thermal Design**: Can design adequate cooling
3. **Touch Interface**: Modern SDR UX expectation
4. **Compact Form Factor**: Single integrated device
5. **Full Control**: Can optimize for specific use case

### Alternative: Variant B (uConsole) for Prototyping

Use uConsole as initial development platform:
1. Get software working on A06 module
2. Test B210 over USB (even USB2 for initial dev)
3. Validate ESP32-C5 integration
4. Port to custom hardware later

### Development Sequence

```
Month 1-2: uConsole Development Platform
├── Get UHD/GNU Radio running
├── Prototype ESP32-C5 interface
└── Develop basic UI

Month 3-4: Custom Hardware Design  
├── KiCad schematic/layout
├── Order prototype PCBs
└── Test RK3588 CM integration

Month 5-6: Integration & Polish
├── Port software to custom board
├── Optimize power/thermal
└── Finalize enclosure
```

---

## 11. Open Questions / Next Steps

### Hardware Questions
- [ ] Which RK3588 CM to use? (Rock5 CM5 vs Orange Pi CM5 vs Radxa)
- [ ] Touch display selection (capacitive vs resistive)
- [ ] Antenna arrangement (internal vs external SMA)
- [ ] Case design (3D printed vs injection mold vs CNC)

### Software Questions
- [ ] Base OS (Armbian vs Ubuntu vs custom Buildroot)
- [ ] GUI toolkit (Qt6 vs GTK4 vs custom)
- [ ] Real-time kernel patches needed?

### Integration Questions
- [ ] B210 firmware compatibility with Linux arm64
- [ ] USB3 hub IC selection (GL3590 vs VL822)
- [ ] ESP32-C5 availability timeline (use C6 interim?)

### Regulatory/Legal
- [ ] FCC/CE considerations for transmit capability
- [ ] Export restrictions on 5G analysis tools

---

## 12. References

### Similar Projects
- HackRF Portapack: https://github.com/portapack-mayhem
- SDR++ arm64: https://github.com/AlexandreRouworst/SDRPlusPlus
- srsRAN: https://github.com/srsran/srsRAN_Project
- CaribouLite: Referenced in this repo

### RK3588 Resources
- Rock5 CM5: https://wiki.radxa.com/Rock5/CM5
- Orange Pi CM5: http://www.orangepi.org/
- Armbian RK3588: https://www.armbian.com/

### ESP32-C5 Resources
- Announcement: https://www.espressif.com/en/news/ESP32-C5
- ESP32-C6 (interim): https://www.espressif.com/en/products/socs/esp32-c6

---

## Appendix A: B210 Clone Specifications Summary

From your XC7K325T documentation:

```
FPGA:          Xilinx Kintex-7 XC7K325T-2FFG676C
RF Frontend:   Analog Devices AD9361BBCZ
Frequency:     70 MHz - 6 GHz
Bandwidth:     Up to 56 MHz real-time
Channels:      2 TX, 2 RX (full duplex)
Interface:     USB 3.0 Type-C
DSP Slices:    840 (vs 180 on standard B210)
Logic Cells:   326,000 (vs 76,000 on standard B210)
Block RAM:     16 Mb (vs 4.8 Mb on standard B210)
```

**Key Advantage**: The XC7K325T has significantly more FPGA resources than standard B210 - could potentially offload some DSP to FPGA if custom firmware is developed.

---

## Appendix B: 5G NR Bands Supported by B210

| Band | Frequency | Bandwidth | B210 Support |
|------|-----------|-----------|--------------|
| n1 | 2100 MHz | 5-20 MHz | ✓ Full |
| n3 | 1800 MHz | 5-20 MHz | ✓ Full |
| n5 | 850 MHz | 5-10 MHz | ✓ Full |
| n7 | 2600 MHz | 5-20 MHz | ✓ Full |
| n28 | 700 MHz | 5-15 MHz | ✓ Full |
| n41 | 2500 MHz | 20-100 MHz | ⚠️ Partial (56MHz max) |
| n77 | 3700 MHz | 20-100 MHz | ⚠️ Partial (56MHz max) |
| n78 | 3500 MHz | 20-100 MHz | ⚠️ Partial (56MHz max) |
| n79 | 4700 MHz | 40-100 MHz | ⚠️ Partial (56MHz max) |

**Note**: For 100MHz 5G NR channels, you can capture ~56MHz of the channel and analyze the captured portion.
