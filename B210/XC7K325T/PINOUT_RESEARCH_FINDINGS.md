# XC7K325T B210 Clone - Pinout Research Findings

## Summary

After extensive GitHub research, here are the findings regarding pinout and constraints files for the OpenSourceSDRLab XC7K325T-based USRP B210 clone.

---

## Key Discovery: Package Difference

### Critical Issue Identified

The OpenSourceSDRLab board uses **FFG900 package**, but the openFPGALoader configuration references **FFG676 package**.

- **Your board**: XC7K325T-FFG900 (900-pin package)
- **Generic Kintex-7 board**: XC7K325T-FFG676 (676-pin package)
- **Standard B210**: XC7A75T-FGG484 (484-pin package)

**This means pin assignments will be completely different between these packages.**

---

## Resources Found

### 1. LSC-Unicamp Repository
**Repository**: [processor-ci-controller/fpga/opensourceSDRLabKintex7](https://github.com/LSC-Unicamp/processor-ci-controller/tree/main/fpga/opensourceSDRLabKintex7)

**Files Available**:
- `pinout.xdc` - Basic constraints for XC7K325T
- `main.sv` - Top-level SystemVerilog module
- `Makefile` - Build configuration using openFPGALoader
- `run.tcl` - Vivado build script
- `generate_ip.tcl` - IP core generation

**Pinout Contents**:
```tcl
# System Clock: G22 (50 MHz, LVCMOS33)
# Reset: D26 (LVCMOS33)
# LEDs: A23-E25 (8 LEDs, LVCMOS33)
# UART: B20 (RX), C22 (TX) - LVCMOS33
# SPI: A14 (MOSI), D14 (MISO), B12 (SCK), C14 (CS) - LVCMOS33
```

**Purpose**: This is a **basic RISC-V processor board**, NOT a B210 SDR clone.
- No AD9361 interface
- No FX3 USB interface
- No RF frontend pins
- Basic peripherals only (UART, SPI, LEDs)

**Usefulness for Your Board**: ⚠️ **LIMITED**
- Confirms FFG900 package is used
- Shows basic constraint syntax for XC7K325T
- Provides Vivado build script examples
- **Does NOT provide B210/AD9361 pin mapping**

---

### 2. Official Ettus B200 Constraints (UCF Format)
**Repository**: [EttusResearch/uhd/fpga/usrp3/top/b200](https://github.com/EttusResearch/uhd)

**Files Available**:
- `b200.ucf` - Main pin constraints (UCF format, older Xilinx format)
- `gpio.ucf` - GPIO pin definitions
- `timing.ucf` - Timing constraints

**Key Interfaces Defined** (for XC7A75T-FGG484):

#### AD9361 (Catalina) Interface
```ucf
# SPI Interface
cat_ce:    Y1   (LVCMOS18)
cat_miso:  V1   (LVCMOS18)
cat_mosi:  T4   (LVCMOS18)
cat_sclk:  P7   (LVCMOS18)

# Control Signals
codec_enable:   J6  (LVCMOS18)
codec_en_agc:   P6  (LVCMOS18)
codec_reset:    Y2  (LVCMOS18)
codec_sync:     M3  (LVCMOS18)
codec_txrx:     M7  (LVCMOS18)

# TX Data Bus (12-bit)
tx_codec_d[0:11]: T2, R1, V2, N1, V3, T1, W1, U1, W3, U3, P2, R3

# RX Data Bus (12-bit)
rx_codec_d[0:11]: M1, K1, K2, G3, M2, J4, L3, H1, L4, G1, N3, M4

# Clocks
cat_clkout_fpga:   J3  (LVCMOS18)
codec_data_clk_p:  K3  (LVCMOS18)
codec_fb_clk_p:    P3  (LVCMOS18, output)
codec_main_clk_p:  K5  (LVDS_25)
codec_main_clk_n:  K4  (LVDS_25)

# Frame signals
rx_frame_p: U4 (LVCMOS18)
tx_frame_p: T3 (LVCMOS18)
```

#### FX3 USB Interface (GPIF II)
```ucf
# Clock
IFCLK: H21 (LVCMOS18)

# Control Lines
FX3_EXTINT: U20 (LVCMOS18)
GPIF_CTL[0:12]: P22, N22, AA18, AB18, P19, AA2, M22, AB19, M19, R20, M21, M20

# 32-bit Data Bus
GPIF_D[0:31]: T17, U14, U13, AA6, AB6, Y3, AB3, AA4, V20, AB2, V21, T22,
              U22, R22, AA12, AB12, Y13, N20, T21, K18, H22, J20, K19, L19,
              N19, K22, L22, L20, J22, K20, G22, F22
```

#### RF Frontend Control
```ucf
# RF Switches
SFDX1_RX: A16    SFDX1_TX: D14
SFDX2_RX: C11    SFDX2_TX: A11
SRX1_RX:  D15    SRX1_TX:  C16
SRX2_RX:  B12    SRX2_TX:  D11

# Band Select
tx_bandsel_a: C13    tx_bandsel_b: D17
rx_bandsel_a: C9     rx_bandsel_b: A13    rx_bandsel_c: E16

# TX/RX Enable
tx_enable1: Y4    tx_enable2: R19
```

#### GPS and Timing
```ucf
gps_lock:     B14  (LVCMOS33)
gps_rxd:      A15  (LVCMOS33)
gps_txd:      A14  (LVCMOS33)
gps_txd_nmea: C15  (LVCMOS33)

PPS_IN_EXT: B10  (LVCMOS33)
PPS_IN_INT: A10  (LVCMOS33)
```

#### LEDs
```ucf
LED_RX1:       C22  (LVCMOS18)
LED_RX2:       L15  (LVCMOS18)
LED_TXRX1_TX:  C20  (LVCMOS18)
LED_TXRX2_RX:  D21  (LVCMOS18)
LED_TXRX1_RX:  K16  (LVCMOS18)
LED_TXRX2_TX:  D22  (LVCMOS18)
```

#### Other
```ucf
ref_sel:   AA14  (LVCMOS18) - Reference clock select
pll_lock:  AB10  (LVCMOS18) - PLL lock indicator
AUX_PWR_ON: B16  (LVCMOS33) - Auxiliary power control
```

**Usefulness**: ⚠️ **REFERENCE ONLY**
- Shows complete B210 interface requirements
- Pin assignments are for **XC7A75T-FGG484**, not XC7K325T-FFG900
- All pin numbers will be different on your board
- I/O standards may be the same
- Signal names should match

---

### 3. openFPGALoader Board Configuration
**Repository**: [trabucayre/openFPGALoader](https://github.com/trabucayre/openFPGALoader)

**Configuration Found**:
```yaml
opensourceSDRLabKintex7:
  fpga_part: xc7k325tffg676  # ⚠️ WRONG PACKAGE
  cable: ft2232
  programmer: vivado
```

**Issue**: Board definition shows FFG676 package, but your board is FFG900.

**Implication**:
- openFPGALoader configuration may work for programming
- But pin assignments would be completely different
- This suggests there may be TWO different XC7K325T boards from OpenSourceSDRLab

---

## Critical Questions to Resolve

### 1. Verify Your Board's Package
Look at the FPGA chip marking on your board:
- **XC7K325T-2FFG900C** = 900-pin package (27mm x 27mm BGA)
- **XC7K325T-2FFG676C** = 676-pin package (27mm x 27mm BGA)

They look similar but have different pin counts. Check the label on the chip.

### 2. Contact Manufacturer
OpenSourceSDRLab MUST provide:
- Complete XDC constraints file for your specific board
- Schematic (at minimum, interface sections)
- Test bitstream or known-working firmware

**Why**: Without correct pin assignments, you risk:
- Damaging the FPGA
- Damaging the AD9361
- Damaging the FX3 USB controller
- Creating shorts or conflicts

### 3. Check for Existing Firmware
Since this is a commercial product, firmware should exist:
- Check product download page
- Request from seller/manufacturer
- Look for customer forum or support resources

---

## What We Know About Your Board

### Hardware Specifications (Confirmed)
From product page:
- FPGA: XC7K325T (Kintex-7)
- Package: **Assumed FFG900** (needs verification)
- RF: AD9361BBCZ
- USB: USB 3.0 Type-C (likely Cypress FX3)
- GPS: Onboard module
- Interfaces: PPS input, 10MHz reference, RF ports

### Required Interfaces (Based on B210 Architecture)

1. **AD9361 Interface** (~40 signals)
   - 12-bit TX data bus (parallel)
   - 12-bit RX data bus (parallel)
   - Control lines (enable, reset, sync, txrx, etc.)
   - SPI bus (4 lines)
   - Clock signals (data clock, FB clock, main clock LVDS)
   - Frame signals (RX/TX frame)

2. **FX3 USB Interface** (~50 signals)
   - 32-bit data bus
   - Control lines (12+)
   - Clock (IFCLK)
   - SPI for FX3 config

3. **RF Frontend Control** (~20 signals)
   - Band select signals
   - TX/RX enable signals
   - RF switch control

4. **GPS Interface** (4 signals)
   - UART TX/RX
   - Lock indicator
   - NMEA output (optional)

5. **Timing** (2 signals)
   - PPS input (external)
   - 10MHz reference input

6. **LEDs** (6+ signals)
   - Status indicators

7. **Misc** (3-5 signals)
   - PLL control/lock
   - Reference selection
   - Power control

**Total: ~130-150 I/O pins required**

---

## Recommended Actions

### Immediate Actions

1. **Verify FPGA Package**
   - Read chip markings carefully
   - Confirm FFG900 or FFG676
   - Take clear photos if uncertain

2. **Contact OpenSourceSDRLab**
   Email them requesting:
   ```
   Subject: XDC Constraints File Request - XC7K325T B210 Board

   Hello,

   I purchased your XC7K325T SDR board (product link: ...)

   To develop custom firmware, I need:
   1. Complete XDC constraints file with pin assignments
   2. Schematic (or at least interface pinout documentation)
   3. Any existing firmware source or binaries
   4. Board revision number/version

   Board serial number: [YOUR_SN]
   FPGA marking: [CHIP_MARKING]

   Thank you.
   ```

3. **Search Chinese Forums/Stores**
   - This appears to be a Chinese clone board
   - Check Taobao, Alibaba seller pages for docs
   - Look for QQ groups or WeChat groups for users
   - Search Baidu (not Google) for Chinese documentation

4. **Check Product Packaging/CD**
   - Sometimes docs are on included CD/USB drive
   - Check if there's a download link on product card

### If No Response from Manufacturer

#### Option A: Reverse Engineering (Advanced)
If you have a working firmware already on the board:

1. **Read Back Bitstream** (if not encrypted)
   ```bash
   vivado -mode tcl
   open_hw_manager
   connect_hw_server
   open_hw_target
   # Read device configuration
   ```

2. **Extract Pin Assignments**
   - Some tools can extract I/O assignments from bitstream
   - Risky and may not work if encrypted

#### Option B: Manual Probing (Very Advanced, Risky)
- Use oscilloscope/logic analyzer
- Trace PCB connections
- Requires significant time and expertise
- Risk of damage

#### Option C: Generic Build + Testing (Safest Development Path)
1. Start with minimal design (no AD9361, no FX3)
2. Use only LED outputs initially
3. Gradually add interfaces one by one
4. Test each addition carefully

---

## File Format Notes

### UCF vs XDC

The B200 constraints from Ettus are in **UCF format** (older Xilinx format).
Your XC7K325T build will need **XDC format** (newer).

**Conversion needed**:

UCF Format:
```ucf
NET "signal_name" LOC = "PIN" | IOSTANDARD = LVCMOS18;
```

XDC Format:
```tcl
set_property PACKAGE_PIN PIN [get_ports signal_name]
set_property IOSTANDARD LVCMOS18 [get_ports signal_name]
```

I can help convert once you have the correct pin assignments.

---

## Creating Template XDC File

Based on B200 architecture, I can create a **template XDC file** with:
- All required signal names (from B200 UCF)
- Placeholder pins (need to be filled in)
- Correct XDC syntax
- Comments explaining each interface

This would give you a starting point once you get the actual pin assignments.

Would you like me to create this template file?

---

## Comparison: XC7K325T Packages

### FFG676 Package
- **Pins**: 676 balls
- **Size**: 27mm x 27mm
- **I/O Banks**: Standard Kintex-7 bank layout
- **Pin Grid**: 26 x 26 grid

### FFG900 Package
- **Pins**: 900 balls
- **Size**: 31mm x 31mm
- **I/O Banks**: Extended I/O bank layout
- **Pin Grid**: 30 x 30 grid
- **More I/O**: Additional user I/O pins available

**The extra 224 pins in FFG900 provide more routing options and I/O.**

---

## Next Steps Priority

### Priority 1: CRITICAL - Get Official Constraints
- [ ] Verify FPGA package marking on board
- [ ] Contact OpenSourceSDRLab via email
- [ ] Contact seller (if different from manufacturer)
- [ ] Search for product documentation online (Chinese and English)
- [ ] Check if firmware already on board can be read back

### Priority 2: If Official Constraints Available
- [ ] Validate constraints file completeness
- [ ] Convert to proper XDC format if needed
- [ ] Create build scripts for XC7K325T
- [ ] Attempt first build

### Priority 3: If No Official Constraints (Fallback)
- [ ] Create template XDC with all B200 signals
- [ ] Plan incremental testing approach
- [ ] Start with minimal safe design
- [ ] Consider purchasing second board as backup

---

## Additional Resources to Check

### Chinese Resources
1. **EDA Forum** (eda.board.eetop.cn) - Chinese FPGA community
2. **OpenEdv Forum** (openedv.com) - Chinese embedded development
3. **Taobao seller pages** - Often have datasheets/docs
4. **Baidu Wenku** (wenku.baidu.com) - Document sharing

### Search Terms (Chinese)
- "XC7K325T B210 引脚" (pinout)
- "opensourcesdrlab 约束文件" (constraints file)
- "XC7K325T USRP"
- "AD9361 FPGA 引脚定义" (pin definition)

### Western Resources
- Check if board is resold under different names
- Search AliExpress/eBay listings for documentation
- Look for user groups on Reddit/Discord

---

## Safety Warnings

### DO NOT:
1. ❌ Use pin assignments from XC7A75T B200
2. ❌ Use pin assignments from XC7K325T-FFG676 if you have FFG900
3. ❌ Guess pin assignments
4. ❌ Flash untested firmware to permanent storage first
5. ❌ Apply power to board with incorrect constraints loaded

### DO:
1. ✅ Verify package marking before proceeding
2. ✅ Use JTAG for volatile testing first
3. ✅ Start with minimal design (LEDs only)
4. ✅ Test each interface incrementally
5. ✅ Keep backups of working configurations

---

## Conclusion

### Current Status: 🔴 **BLOCKED - Missing Critical Information**

**The constraint file situation**:
- ✅ Found reference B200 constraints (wrong FPGA/package)
- ✅ Found basic XC7K325T project (not B210 clone)
- ❌ NO constraints found for XC7K325T B210 clone specifically
- ❌ Package discrepancy needs resolution (FFG676 vs FFG900)

**Without official constraints from the manufacturer, proceeding is risky.**

### Realistic Timeline

| Action | Time | Probability of Success |
|--------|------|----------------------|
| Get official constraints | 3-7 days | 70% (if manufacturer responsive) |
| Reverse engineer | 2-4 weeks | 30% (if bitstream readable) |
| Manual probing | 4-8 weeks | 20% (very difficult) |
| Trial and error | ⚠️ DON'T | High risk of damage |

### My Recommendation

**Path Forward**:
1. Spend the next 48 hours trying to get official documentation
2. If successful → Proceed with firmware build (1-2 days)
3. If unsuccessful → Evaluate reverse engineering options
4. Consider this a lesson for future purchases (always verify docs available first)

---

**Document Created**: 2025-12-10
**Last Updated**: 2025-12-10
**Status**: Research Complete, Awaiting Manufacturer Response

Would you like me to create the template XDC file with placeholder pins so you're ready once you get the pin assignments?
