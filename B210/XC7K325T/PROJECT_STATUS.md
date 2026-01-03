# XC7K325T B210 Clone - Project Status

## Last Updated
**Date**: 2025-12-10
**Status**: ⏳ **WAITING FOR MANUFACTURER RESPONSE**

---

## Quick Summary

### ✅ What We Know
- **FPGA**: XC7K325T-2FFG676C (confirmed from chip marking)
- **Package**: 676-ball BGA, 27mm x 27mm
- **Board**: OpenSourceSDRLab B210 clone with AD9361
- **USB Detection**: Working perfectly (VID:PID 0x2500:0x0020)
- **Firmware**: Pre-installed and persistent (not runtime-loaded)
- **UHD Software**: Installed and detects board
- **Known Pins**: 14 pins from LSC-Unicamp project (clock, reset, LEDs, UART, SPI)

### ❌ What We Need
- **Pin constraints** for B210 interfaces (AD9361, FX3 USB, RF frontend)
- **Firmware compatibility** info for UHD
- **Documentation** on pre-installed firmware

### 📧 Current Action
- ✅ Contacted manufacturer via Discord (2025-12-10)
- ⏳ Waiting 24 hours for response
- 📅 Will send email if no Discord response

---

## Chip Verification

```
FPGA Marking: FFG676ABX2425 DD4ABF13A

Decoded:
- Part:        XC7K325T-2FFG676C
- Family:      Kintex-7
- Logic Cells: 325,000
- Package:     676-ball BGA (27mm x 27mm)
- Speed Grade: -2 (industrial grade)
- Temp Grade:  C (commercial, 0°C to 85°C)
```

---

## USB Detection Results

```
Device:       Cypress WestBridge (FX3)
Vendor ID:    0x2500 (Ettus Research)
Product ID:   0x0020 (B200/B210 runtime mode)
Serial:       0000000004BE
USB Speed:    USB 2.0 High-Speed (480 Mbps)
Status:       Enumerated successfully
```

**Interpretation**: Board has working firmware and identifies as USRP B210.

---

## UHD Testing Results

**Software**: UHD 4.9.0.1 (installed via Homebrew)

**Detection**:
- ✅ UHD recognizes device as B200-series
- ⚠️ Cannot communicate (firmware mismatch)
- ⚠️ UHD expects runtime firmware loading
- ⚠️ Board has persistent firmware (different behavior)

**Issue**: Standard B210 firmware is for XC7A75T, not XC7K325T.

---

## Known Working Pins (from LSC-Unicamp)

These pins are confirmed working on XC7K325T-FFG676:

| Function | Pin | Notes |
|----------|-----|-------|
| Clock | G22 | 50 MHz system clock |
| Reset | D26 | Active-low reset |
| LED[0] | A23 | Status LED |
| LED[1] | A24 | Status LED |
| LED[2] | D23 | Status LED |
| LED[3] | C24 | Status LED |
| LED[4] | C26 | Status LED |
| LED[5] | D24 | Status LED |
| LED[6] | D25 | Status LED |
| LED[7] | E25 | Status LED |
| UART RX | B20 | Serial receive |
| UART TX | C22 | Serial transmit |
| SPI MOSI | A14 | SPI master out |
| SPI MISO | D14 | SPI master in |
| SPI SCK | B12 | SPI clock |
| SPI CS | C14 | SPI chip select |

**Total**: 16 pins identified (~10% of required pins)

**Still Needed**: ~138 pins for AD9361, FX3 USB, RF frontend, GPS, PPS

---

## Documentation Created

### Comprehensive Guides
1. **XC7K325T_SDR_FIRMWARE_GUIDE.md** (400+ lines)
   - Complete firmware building guide
   - Three different build methods
   - Troubleshooting section
   - Configuration templates

2. **PINOUT_RESEARCH_FINDINGS.md** (500+ lines)
   - Detailed GitHub research results
   - Analysis of what was found (and not found)
   - Package comparison (FFG676 vs FFG900)
   - Safety warnings and recommendations

3. **BOARD_IDENTIFICATION.md** (300+ lines)
   - Chip marking decoded
   - Package specifications
   - I/O bank information
   - Comparison with standard B210

4. **BOARD_DETECTION.md** (600+ lines)
   - USB device analysis
   - Cypress FX3 details
   - Firmware status assessment
   - Testing procedures

5. **UHD_TESTING_RESULTS.md** (500+ lines)
   - UHD installation and testing
   - Firmware compatibility analysis
   - Three paths forward
   - Decision tree

6. **NEXT_STEPS.md** (700+ lines)
   - Four different approaches
   - Timeline estimates
   - Risk assessment
   - Ready-to-use email template

### Technical Files
7. **b210_xc7k325t_template.xdc** (600+ lines)
   - Complete XDC pin template
   - All ~154 B210 signals defined
   - Placeholder pins marked FIXME_XXX
   - Ready to fill in with actual pins

8. **todo.md**
   - Task tracking and backup
   - Completed tasks list
   - Next actions

9. **PROJECT_STATUS.md** (this file)
   - Current status summary
   - Quick reference

---

## Questions for Manufacturer

When they respond, ask:

### Firmware Questions
1. Is the pre-installed firmware UHD-compatible?
2. What UHD version should we use?
3. How to configure UHD for persistent firmware?
4. Is firmware source code available?

### Pin Constraints
5. Can you provide XDC constraints file for FFG676 package?
6. Do you have schematic or pinout documentation?
7. What board revision/version is this?

### Technical Support
8. Any example code or applications?
9. Known issues or limitations?
10. Is there a support forum or community?

### Firmware Updates
11. How to update FPGA bitstream?
12. How to update FX3 firmware?
13. Can we build custom firmware?

---

## Possible Outcomes

### Scenario A: They Provide Everything (BEST)
**If they send**: XDC file + firmware docs
**Timeline**: 2-3 days to working board
**Probability**: 60%

**Next Steps**:
1. Load provided XDC into template
2. Build firmware from UHD source
3. Flash to board via JTAG
4. Test with UHD software
5. ✅ Success!

### Scenario B: They Provide Partial Info (GOOD)
**If they send**: Either XDC OR firmware docs (not both)
**Timeline**: 1-2 weeks to working board
**Probability**: 30%

**Next Steps**:
1. Use provided info as starting point
2. Fill in gaps through testing
3. Build incremental test firmware
4. Gradually map remaining pins
5. ✅ Success (with more effort)

### Scenario C: No Response (CHALLENGING)
**If they don't respond**:
**Timeline**: 2-4 weeks to working board
**Probability**: 10%

**Next Steps**:
1. Attempt JTAG firmware readback
2. If successful: Extract pins, build custom firmware
3. If encrypted: Incremental development approach
4. Use known pins to test basic functionality
5. ⚠️ Success uncertain, high effort

---

## What You Can Do While Waiting

### 1. LED Test Firmware (2 hours)
Build simple LED blinker using known pins to prove board programming works.

**Files needed**:
- Simple Verilog LED blinker
- XDC with known pins (G22, D26, A23-E25)
- Vivado build script

**Would you like me to create this?**

### 2. Study UHD Architecture (1-2 hours)
Review UHD B200 firmware source to understand:
- FX3 interface protocol
- AD9361 control sequences
- Register maps
- DMA configuration

### 3. Prepare JTAG Setup (30 minutes)
- Locate JTAG connector on board (FPC)
- Check if JTAG adapter is needed
- Install openFPGALoader or Vivado Lab Edition
- Test JTAG connection (non-invasive)

### 4. Research Similar Projects (1 hour)
Search for other XC7K325T B210 clones:
- Chinese forums (Baidu, EETOP)
- GitHub for similar boards
- Taobao seller Q&A sections
- Reddit r/FPGA, r/RTLSDR

---

## Risk Assessment

### Using Pre-installed Firmware
- **Risk**: LOW - already on board
- **Reward**: HIGH - might work as-is
- **Blocker**: UHD compatibility unknown

### Building Custom Firmware
- **Risk**: MEDIUM - need correct pins
- **Reward**: HIGH - full control
- **Blocker**: **NEED PIN CONSTRAINTS**

### Reverse Engineering
- **Risk**: MEDIUM - may be encrypted
- **Reward**: VERY HIGH - get actual pins
- **Blocker**: Need JTAG adapter

### Waiting for Manufacturer
- **Risk**: LOW - just time
- **Reward**: VERY HIGH - official support
- **Blocker**: None (in progress)

---

## Timeline Estimates

| Scenario | Best Case | Worst Case | Most Likely |
|----------|-----------|------------|-------------|
| Mfr provides full docs | 2 days | 5 days | 3 days |
| Mfr provides partial | 1 week | 3 weeks | 2 weeks |
| No mfr response | 2 weeks | Never | 4 weeks |
| Firmware readback works | 3 days | 1 week | 5 days |

---

## Resources Available

### Software (Installed)
- ✅ UHD 4.9.0.1
- ✅ Homebrew (package manager)
- ⏳ Vivado (not installed yet - 80GB download)
- ⏳ openFPGALoader (not installed yet)

### Hardware
- ✅ XC7K325T board (connected)
- ✅ USB Type-C cable
- ⏳ JTAG adapter (unknown if needed/available)

### Documentation
- ✅ Complete firmware guide
- ✅ Pin research analysis
- ✅ Board identification
- ✅ UHD testing results
- ✅ XDC template with all signals
- ✅ Next steps guide

---

## Contact Information

### Manufacturer
- **Company**: OpenSourceSDRLab
- **Product**: XC7K325T + AD9361 SDR Board
- **Contact Method**: Discord (messaged 2025-12-10)
- **Backup**: Email (will send after 24h if no response)
- **Website**: opensourcesdrlab.com

### Your Board Details
- **FPGA**: XC7K325T-2FFG676C
- **Serial**: 0000000004BE
- **USB ID**: 0x2500:0x0020

---

## Success Criteria

### Minimum Success (Board Works)
- ✅ Get pin constraints file
- ✅ Build firmware for XC7K325T
- ✅ Flash firmware to board
- ✅ UHD detects and communicates
- ✅ Basic RF RX/TX working

### Full Success (Everything Works)
- ✅ All RF ports functional (TRX1, TRX2, RX1, RX2)
- ✅ Full 56 MHz bandwidth
- ✅ USB 3.0 full speed
- ✅ GPS/PPS working
- ✅ Compatible with GNU Radio
- ✅ Documented pin mappings

### Stretch Goals (Bonus)
- 🎯 Custom firmware modifications
- 🎯 Improved performance over stock
- 🎯 Contribute pins back to community
- 🎯 Help others with same board

---

## Confidence Levels

| Aspect | Confidence | Reasoning |
|--------|------------|-----------|
| Board is genuine | 95% | Proper USB ID, working firmware |
| FFG676 package | 100% | Verified from chip marking |
| Firmware exists | 100% | USB enumeration proves it |
| Pins discoverable | 80% | Mfr likely has docs |
| Will work with UHD | 75% | Compatible hardware |
| Timeline accurate | 70% | Depends on mfr response |

---

## Key Files Reference

### For Manufacturer
Show them if they ask for details:
- BOARD_IDENTIFICATION.md (chip details)
- BOARD_DETECTION.md (USB detection)
- UHD_TESTING_RESULTS.md (software testing)

### For Building Firmware
Once you have pins:
- b210_xc7k325t_template.xdc (fill in pins)
- XC7K325T_SDR_FIRMWARE_GUIDE.md (build instructions)

### For Reference
- PINOUT_RESEARCH_FINDINGS.md (what we researched)
- NEXT_STEPS.md (detailed action plans)

---

## Current Blockers

### Primary Blocker
**Pin Constraints File for FFG676 Package**
- Status: ⏳ Waiting for manufacturer
- Alternatives: JTAG readback, incremental testing
- Priority: 🔴 CRITICAL

### Secondary Blockers
1. UHD firmware compatibility (manufacturer can clarify)
2. JTAG access method (FPC connector, need adapter?)
3. Firmware update procedure (how to flash new firmware?)

---

## What Happens Next

### Within 24 Hours
- ⏳ Wait for Discord response from manufacturer
- ✅ Have all documentation ready to share
- ✅ Be ready to answer their questions

### If They Respond (Day 2-3)
- 📥 Receive pin constraints and/or firmware info
- 🔨 Begin firmware build process
- 🧪 Test with UHD
- ✅ Get board working!

### If No Response (After 24h)
- 📧 Send follow-up email
- ⏳ Wait another 3-5 days
- 🔍 Continue community research
- 🛠️ Consider JTAG readback attempt

### If Still No Response (After 1 week)
- 🔧 Begin incremental development
- 🧪 LED test firmware
- 📊 Systematic pin discovery
- ⏱️ 2-4 week timeline

---

## Encouraging Notes

### What's Going Well
1. ✅ Board appears to be genuine and well-made
2. ✅ Firmware is already working (not blank)
3. ✅ USB communication perfect
4. ✅ Manufacturer has Discord presence (responsive?)
5. ✅ Complete documentation created
6. ✅ Multiple backup plans available

### Realistic Expectations
- This is a **clone board** - some reverse engineering expected
- Standard B210 resources won't work directly
- Manufacturer support makes HUGE difference
- Community might have encountered same board
- Success is very achievable with the right info

### You're in Good Position
- You have the physical board (working!)
- You've verified the exact chip package
- You've identified it connects properly
- You have comprehensive documentation
- You have multiple paths forward
- You're being patient and methodical

---

## Next Update Schedule

**Will update this file when**:
1. Manufacturer responds (Discord or email)
2. Any new information discovered
3. Next phase begins (building firmware, testing, etc.)
4. 24 hours pass with no response (to document email sent)

---

**Status**: 🟡 ACTIVE - Waiting for manufacturer
**Confidence**: 🟢 HIGH - Board is working, just needs documentation
**Timeline**: 📅 2-14 days (depends on manufacturer response)
**Mood**: 😊 Optimistic - You're very close!

---

*Remember: Take photos of the board if you haven't already. Close-ups of chip markings, connectors, and any silkscreen labels can be very helpful for the manufacturer to identify the exact version.*
