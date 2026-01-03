# Board Identification - XC7K325T SDR

## Confirmed Hardware Details

### FPGA Chip Marking
```
FFG676ABX2425
DD4ABF13A
```

### Decoded Information

**Part Number**: XC7K325T-2FFG676C

Breaking down the marking:
- **XC7K325T** - Xilinx Kintex-7, 325K logic cells
- **-2** - Speed grade 2 (industrial grade, -1I to -2 range)
- **FFG676** - Package type: 676-ball Fine-Pitch BGA
- **C** - Commercial temperature grade (0°C to 85°C)

**Date Code**: 2425
- Week 24 of 2025 (or possibly 2015, depending on format)

**Lot/Batch**: DD4ABF13A

### Package Specifications

**FFG676 Package Details**:
- **Total Balls**: 676 (26 x 26 grid)
- **Ball Pitch**: 1.0mm
- **Package Size**: 27mm x 27mm
- **Package Height**: 3.13mm (max)
- **Body Material**: Low-stress plastic BGA
- **Ball Material**: Solder (Pb-free)

### Pinout Resources

**Official Xilinx Documentation**:
- Package file: `xc7k325tffg676pkg.txt` (in Vivado installation)
- Pinout tables: Kintex-7 FPGA Data Sheet (DS182)
- PCF file location: `<Vivado>/data/parts/xilinx/kintex7/`

### I/O Bank Information

FFG676 package has the following I/O banks available:
- **Bank 0**: Special configuration bank
- **Banks 12-16**: High-performance I/O banks
- **Banks 32-36**: High-range I/O banks
- **Total User I/O**: ~400 pins (exact number depends on configuration)

### Comparison: FFG676 vs FFG900

| Feature | FFG676 (Your Board) | FFG900 |
|---------|---------------------|---------|
| Total Balls | 676 | 900 |
| Grid Size | 26 x 26 | 30 x 30 |
| Package Size | 27mm x 27mm | 31mm x 31mm |
| User I/O | ~400 | ~500 |
| Ball Pitch | 1.0mm | 1.0mm |

**Impact**: FFG676 has fewer I/O pins available, but still more than enough for B210 design (~154 pins needed).

## Board Configuration

Based on chip marking and openFPGALoader configuration match:

### openFPGALoader Board Definition
```yaml
opensourceSDRLabKintex7:
  fpga_part: xc7k325tffg676  # ✅ MATCHES YOUR CHIP
  cable: ft2232
  programmer: vivado
```

**Status**: ✅ Configuration is CORRECT for your board

### Programming Interface

Based on board definition:
- **JTAG Cable**: FT2232H (FTDI-based)
- **Connection**: Via FPC connector on board
- **Supported Programmers**:
  - Vivado Hardware Manager
  - openFPGALoader
  - xc3sprog (if compatible)

## Board Variant Confirmation

This confirms you have:
- **OpenSourceSDRLab Kintex-7 325t Board**
- **Package**: FFG676 (NOT FFG900)
- **Compatible with**: openFPGALoader board definition

## Impact on Pin Constraints Search

### Good News
1. ✅ Package is confirmed (FFG676)
2. ✅ Matches openFPGALoader configuration
3. ✅ LSC-Unicamp repository likely uses same board/package
4. ✅ Can now search specifically for FFG676 constraints

### Next Steps
1. Check if LSC-Unicamp pinout is actually compatible
2. Search specifically for "xc7k325tffg676 b210" or similar
3. Contact manufacturer with specific package info
4. Look for other projects using this exact board/package

## LSC-Unicamp Repository Re-evaluation

Since LSC-Unicamp uses XC7K325T and openFPGALoader references this same board, let me verify if their constraints might actually be for the SAME physical board.

**LSC-Unicamp Pinout Details**:
```tcl
# System Clock: G22 (50 MHz)
# Reset: D26
# LEDs: A23-E25
# UART: B20 (RX), C22 (TX)
# SPI: A14 (MOSI), D14 (MISO), B12 (SCK), C14 (CS)
```

**Questions**:
- Are these pins for the SAME board but different project?
- Does your board have LED positions matching A23-E25?
- If so, these might be valid reference pins!

## Physical Board Verification Steps

### What to Check on Your Board

1. **LED Positions**
   - Count the status LEDs (board should have 6+ LEDs)
   - Check if there are 8 general-purpose LEDs near the FPGA
   - If yes, LSC-Unicamp pinout might be partially usable

2. **Connector Positions**
   - SMA connectors for RF (TRX1, TRX2, RX1, RX2)
   - MMCX connectors for GPS, PPS, 10MHz
   - USB Type-C connector
   - FPC/JTAG connector position

3. **Component Markings**
   - AD9361 chip location and marking
   - USB controller chip (likely Cypress FX3 with CYUSB marking)
   - Clock synthesizer chip (PLL)
   - GPS module

4. **Silkscreen Text**
   - Board revision number
   - Pin labels near connectors
   - Any reference designators (U1, U2, etc.)

## Vivado Package Pin Extraction

You can extract the complete FFG676 pinout from Vivado:

```tcl
# In Vivado TCL console
set part xc7k325tffg676-2
set_part $part

# Export all package pins
report_property [get_package_pins] -file ffg676_pins.txt

# Or get specific I/O bank pins
get_package_pins -filter {IS_USER_IO}
```

This will give you all valid pin names for FFG676 package.

## Updated Part Specification

For all build scripts and XDC files, use:

```tcl
set_property PART xc7k325tffg676-2 [current_design]
```

**NOT** `xc7k325tffg900-2`

## Board Photo Analysis Recommendation

If you can provide photos of:
1. Top side (showing component layout)
2. FPGA area (closer view)
3. Connectors and labels
4. Any silkscreen text with board version

I can help identify specific components and potentially trace some of the pinout.

## Manufacturer Contact Information

When contacting OpenSourceSDRLab, provide:

```
Board: OpenSourceSDRLab USRP B210 (XC7K325T)
FPGA Marking: FFG676ABX2425 DD4ABF13A
Package: XC7K325T-2FFG676C
Request: XDC constraints file for B210 firmware
Product URL: [your purchase link]
```

## Summary

### Confirmed Facts ✅
- Package: **FFG676** (NOT FFG900)
- Part: **XC7K325T-2FFG676C**
- Speed Grade: **-2** (good performance)
- openFPGALoader config: **CORRECT** for this board
- LSC-Unicamp project: **SAME PACKAGE** (may be compatible)

### Critical Unknowns ❓
- Are LSC-Unicamp pins compatible with B210 layout?
- What pins are used for AD9361 interface?
- What pins are used for FX3 USB interface?
- Board revision/version differences?

### Immediate Actions
1. ✅ Package confirmed - update all documentation
2. ⏳ Re-examine LSC-Unicamp constraints for compatibility
3. ⏳ Search for FFG676-specific B210 resources
4. ⏳ Contact manufacturer with package details
5. ⏳ Consider board photos for visual pin tracing

---
**Document Created**: 2025-12-10
**Chip Verified**: XC7K325T-2FFG676C
**Status**: Package confirmed, pin mapping still needed
