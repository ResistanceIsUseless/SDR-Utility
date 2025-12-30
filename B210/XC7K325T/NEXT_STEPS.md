# Next Steps - XC7K325T B210 Firmware Development

## Current Status: PACKAGE CONFIRMED ✅

**Chip Marking**: `FFG676ABX2425 DD4ABF13A`
**Part Number**: `XC7K325T-2FFG676C`
**Package**: FFG676 (676-ball BGA, 27mm x 27mm)

### Confirmed Information
✅ FPGA package verified (FFG676, NOT FFG900)
✅ LSC-Unicamp project uses SAME package (xc7k325tffg676-2)
✅ openFPGALoader configuration matches your board
✅ Template XDC file updated with correct part number
✅ Board has sufficient I/O pins (~400 available, ~154 needed)

---

## Critical Path Forward

### Option 1: Contact Manufacturer (RECOMMENDED - Fastest if Successful)

**Priority**: 🔴 HIGHEST
**Time Estimate**: 2-7 days
**Success Probability**: 70%

**Action Items**:

1. **Email OpenSourceSDRLab Support**

Subject: XDC Constraints File Request - XC7K325T B210 Board Purchase

```
Hello,

I purchased your OpenSourceSDRLab USRP B210 (XC7K325T) development board
and need the XDC pin constraints file to develop custom firmware.

Board Details:
- Product: XC7K325T + AD9361 SDR Board with USB 3.0 Type-C
- FPGA Marking: FFG676ABX2425 DD4ABF13A
- Part Number: XC7K325T-2FFG676C
- Package: FFG676

Requested Files:
1. Complete XDC pin constraints file for Vivado
2. Schematic (or pinout documentation)
3. Example firmware or reference bitstream (if available)
4. Board revision/version number

This information is needed for firmware development using Xilinx Vivado
and the UHD framework.

Purchase Details:
- Order Number: [YOUR_ORDER_NUMBER]
- Purchase Date: [DATE]
- Seller: [SELLER_NAME]

Thank you for your assistance.

Best regards,
[YOUR_NAME]
```

2. **Contact Seller** (if different from manufacturer)
   - AliExpress/eBay/Amazon message
   - Request same information
   - Mention product link

3. **Check Product Resources**
   - Look for download links on product page
   - Check for QR codes on packaging
   - Search for included CD/USB drive with documentation

---

### Option 2: Reverse Engineer from Working Firmware (Advanced)

**Priority**: 🟡 MEDIUM (if firmware exists on board)
**Time Estimate**: 4-8 hours
**Success Probability**: 50% (depends on encryption)

**Prerequisites**:
- Board currently has working firmware loaded
- Firmware is NOT encrypted with bitstream encryption
- JTAG access available

**Steps**:

1. **Check Current Bitstream**
   ```bash
   # Connect via JTAG
   vivado -mode tcl
   ```

   ```tcl
   # In Vivado TCL console
   open_hw_manager
   connect_hw_server
   open_hw_target
   current_hw_device [get_hw_devices xc7k325t_0]
   refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]

   # Try to read configuration
   # If successful, this proves firmware exists and is readable
   ```

2. **Read Back Bitstream** (if not encrypted)
   ```tcl
   # This may fail if bitstream protection is enabled
   create_hw_bitstream -hw_device [lindex [get_hw_devices] 0] readback.bit
   write_hw_bitstream readback.bit
   ```

3. **Extract I/O Information** (if readback successful)
   - Use third-party tools to analyze bitstream
   - Some tools can extract I/O bank assignments
   - Risky and may violate terms of use

**⚠️ Legal Warning**: Reverse engineering firmware may violate intellectual property rights. Only proceed if you have the legal right to do so.

---

### Option 3: Incremental Development (SAFEST - Longest Time)

**Priority**: 🟢 LOW RISK
**Time Estimate**: 2-4 weeks
**Success Probability**: 90% (safe, methodical)

**Approach**: Build firmware incrementally, testing each interface one by one.

#### Phase 1: Minimal Test Design (Week 1)

**Goal**: Prove you can program FPGA and control basic I/O

**Steps**:

1. **Create Minimal Design**
   - Input: Reset button (if identifiable)
   - Outputs: LEDs only
   - No AD9361, no FX3, no complex interfaces

2. **Use LSC-Unicamp Pins as Starting Point**
   ```tcl
   # Known working pins from LSC-Unicamp:
   Clock:  G22
   Reset:  D26
   LED[0]: A23
   LED[1]: A24
   LED[2]: D23
   LED[3]: C24
   LED[4]: C26
   LED[5]: D24
   LED[6]: D25
   LED[7]: E25
   ```

3. **Create Simple LED Blinker**
   ```verilog
   module led_test (
       input wire clk,      // G22 - 50 MHz from oscillator
       input wire rst_n,    // D26 - Reset button
       output reg [7:0] led // A23-E25 - LEDs
   );
       reg [31:0] counter;

       always @(posedge clk or negedge rst_n) begin
           if (!rst_n) begin
               counter <= 0;
               led <= 8'h00;
           end else begin
               counter <= counter + 1;
               // Blink LEDs at different rates
               led[0] <= counter[22];  // Slow blink
               led[1] <= counter[21];
               led[2] <= counter[20];
               led[3] <= counter[19];
               led[4] <= counter[18];
               led[5] <= counter[17];
               led[6] <= counter[16];
               led[7] <= counter[15];  // Fast blink
           end
       end
   endmodule
   ```

4. **Build and Test**
   ```bash
   vivado -mode batch -source build_led_test.tcl
   openFPGALoader -b opensourceSDRLabKintex7 led_test.bit
   ```

5. **Verify**
   - Power on board
   - LEDs should blink at different rates
   - If successful: ✅ Proves board programming works
   - If failure: pins may be wrong or board needs different config

#### Phase 2: Identify USB Controller (Week 1-2)

**Goal**: Find FX3 USB controller pins through testing

**Approach**:
1. Visual inspection - locate FX3 chip on board
2. Check datasheets for package type
3. Use oscilloscope/logic analyzer to trace USB signals
4. Test communication with simple GPIO toggles

**Tools Needed**:
- Logic analyzer (8+ channels)
- Oscilloscope
- Multimeter (continuity check)

#### Phase 3: Identify AD9361 Interface (Week 2-3)

**Goal**: Map AD9361 pins through testing and tracing

**Approach**:
1. Locate AD9361 chip (should be prominent, likely BGA package)
2. Reference AD9361 datasheet for pin functions
3. Use logic analyzer during known operation (if firmware exists)
4. Trace PCB connections (difficult with BGA, but possible)

#### Phase 4: Full Integration (Week 3-4)

**Goal**: Integrate UHD firmware with discovered pins

**Steps**:
1. Update XDC template with discovered pins
2. Build B200 firmware from UHD
3. Test incrementally (USB first, then AD9361)
4. Debug and refine

**Risk**: High time investment, requires electronics skills

---

### Option 4: Community Search (PARALLEL - Do Alongside Others)

**Priority**: 🟣 PARALLEL ACTIVITY
**Time Estimate**: Ongoing
**Success Probability**: 30%

**Chinese Forums** (Most Likely to Have Info):

1. **EETOP (电子工程专辑)**
   - URL: https://bbs.eetop.cn
   - Search: "XC7K325T B210" or "opensourcesdrlab"
   - Register required (free)

2. **OpenEdv Forum** (正点原子)
   - URL: http://www.openedv.com/forum.php
   - FPGA section
   - Active community for Chinese FPGA boards

3. **Baidu Tieba** (百度贴吧)
   - Search: "FPGA吧" or "USRP吧"
   - Look for posts about clone boards

4. **Taobao Seller Q&A**
   - Find original seller listing
   - Check product Q&A section
   - Previous buyers may have asked for docs

**Western Forums**:

1. **Reddit**
   - r/RTLSDR
   - r/FPGA
   - r/amateurradio

2. **GitHub Issues**
   - Search existing issues in UHD repo
   - Check LibreSDR project issues
   - Post question in relevant repos

3. **GNU Radio Mailing List**
   - Ask if anyone has this board
   - Users may have solved this already

**Search Terms**:
- English: "xc7k325t ffg676 b210 pinout"
- Chinese: "XC7K325T 引脚约束" "opensourcesdrlab B210"

---

## Recommended Strategy

### Parallel Approach (BEST ROI)

Execute these simultaneously:

**Week 1**:
- ✅ Contact manufacturer (Option 1) - 2 hours
- ✅ Search forums/communities (Option 4) - 2 hours
- ✅ Build LED test firmware (Option 3, Phase 1) - 4 hours
- ⏳ Wait for manufacturer response

**Week 2**:
- If manufacturer responds with docs → Proceed to full build
- If no response → Continue incremental development
- Continue forum searches daily

**Week 3-4**:
- If still no docs → Commit to incremental development
- Consider reverse engineering if skilled

---

## Tools You'll Need

### Software (Free)
- ✅ Xilinx Vivado 2019.1+ (WebPACK license)
- ✅ UHD host drivers
- ✅ Git
- ✅ openFPGALoader

### Hardware (If Doing Incremental Development)
- 🔲 Logic analyzer ($20-200)
  - Budget: Saleae clone from AliExpress
  - Good: Original Saleae Logic 8
  - Professional: Saleae Logic Pro 16
- 🔲 Oscilloscope (if available)
- 🔲 Multimeter with continuity check
- 🔲 Good quality JTAG cable (may be included with board)

---

## Risk Assessment

### Option 1 (Manufacturer Contact)
- ✅ Lowest risk
- ✅ Fastest if successful
- ❌ Depends on manufacturer cooperation
- ❌ May take days/weeks for response

### Option 2 (Reverse Engineering)
- ⚠️ Medium risk
- ✅ Fast if firmware is readable
- ❌ May fail if bitstream encrypted
- ❌ Legal/ethical concerns

### Option 3 (Incremental Development)
- ✅ Lowest technical risk
- ✅ Educational value
- ❌ Very time consuming
- ❌ Requires test equipment
- ❌ May never achieve full functionality

### Option 4 (Community Search)
- ✅ No risk
- ✅ No cost
- ❌ Low probability of success
- ✅ Good parallel activity

---

## Decision Tree

```
START
  |
  ├─→ Contact Manufacturer
  |     ├─→ Response with docs? → BUILD FIRMWARE ✅
  |     └─→ No response after 7 days?
  |           └─→ Try forums/community search
  |                 ├─→ Found docs? → BUILD FIRMWARE ✅
  |                 └─→ Still nothing?
  |                       └─→ Incremental Development (2-4 weeks)
  |                             OR
  |                       └─→ Reverse Engineering (if possible)
  |
  └─→ Parallel: LED Test (proves board works)
        └─→ LEDs blink? → Continue with plan
        └─→ LEDs don't work? → Check power/JTAG connection
```

---

## What You Have Right Now

### ✅ Completed Documentation
1. **XC7K325T_SDR_FIRMWARE_GUIDE.md** - Complete firmware building guide
2. **PINOUT_RESEARCH_FINDINGS.md** - Research analysis and what was found
3. **BOARD_IDENTIFICATION.md** - Your specific board details
4. **b210_xc7k325t_template.xdc** - XDC template (needs pin assignments)
5. **NEXT_STEPS.md** - This document

### ✅ Confirmed Facts
- Part: XC7K325T-2FFG676C
- Package: 676-ball BGA, 27mm x 27mm
- openFPGALoader compatible: ✅
- LSC-Unicamp uses same board: ✅
- Known working pins: Clock (G22), Reset (D26), 8 LEDs (A23-E25)

### ❌ Missing Critical Information
- AD9361 interface pins (~40 signals)
- FX3 USB interface pins (~50 signals)
- RF frontend control pins (~15 signals)
- GPS/PPS pins (~6 signals)

---

## Immediate Action (Next 24 Hours)

### Priority 1: Contact Manufacturer
- [ ] Draft email to OpenSourceSDRLab
- [ ] Send email to manufacturer
- [ ] Message original seller
- [ ] Check product page for documentation

### Priority 2: Test Basic Functionality
- [ ] Build LED blinker test design
- [ ] Program via openFPGALoader
- [ ] Verify LEDs respond
- [ ] Confirms board is functional

### Priority 3: Community Search
- [ ] Post on r/FPGA subreddit
- [ ] Search Chinese FPGA forums
- [ ] Check Taobao seller Q&A
- [ ] Search GitHub for similar projects

---

## Success Criteria

### Minimum Success
- ✅ LED test works (proves board is functional)
- ✅ Manufacturer provides documentation
- ✅ Can build and flash custom firmware

### Full Success
- ✅ Complete B210 firmware working
- ✅ All RF ports functional
- ✅ USB 3.0 full speed operation
- ✅ GPS/PPS working
- ✅ Compatible with GNU Radio / UHD

---

## Timeline Estimates

| Scenario | Timeline | Effort |
|----------|----------|--------|
| Manufacturer provides docs immediately | 2-3 days | Low |
| Manufacturer provides docs after delay | 1-2 weeks | Low |
| Community finds solution | 1-3 weeks | Medium |
| Incremental development | 2-4 weeks | High |
| Reverse engineering | 1-2 weeks | Very High |

---

## Budget Considerations

### Minimum Cost (Manufacturer Docs Path)
- $0 - Everything you need is free software

### Maximum Cost (Full Incremental Development)
- Logic analyzer: $50-200
- Test equipment: $100-300
- Time investment: 40-80 hours
- **Total**: $150-500 + significant time

**Recommendation**: Try manufacturer contact first (free, fast if successful)

---

## Questions to Ask Yourself

1. **Do I have the physical board in hand?**
   - If no → Order it first, then wait for docs
   - If yes → Start with manufacturer contact + LED test

2. **What's my deadline?**
   - Urgent (1 week) → Manufacturer contact + reverse engineering
   - Normal (1 month) → Try all options in parallel
   - Flexible → Incremental development okay

3. **What's my skill level?**
   - Beginner → Wait for docs, don't reverse engineer
   - Intermediate → Try LED test, manufacturer contact
   - Expert → All options available

4. **Do I have test equipment?**
   - No → Must get docs from manufacturer
   - Yes → Incremental development feasible

---

## My Recommendation

**Based on your situation, I recommend**:

### Week 1 Strategy:
1. ✅ **Send email to manufacturer** (30 minutes, do today)
2. ✅ **Build LED test firmware** (2 hours, proves board works)
3. ✅ **Post on forums** (1 hour, low effort, might get lucky)
4. ⏳ **Wait 3-5 days for manufacturer response**

### Week 2 Decision Point:
- **If manufacturer responds** → Full speed ahead with firmware build
- **If no response** → Decide between:
  - More aggressive community search
  - Incremental development
  - Consider buying second board as backup

---

**Document Created**: 2025-12-10
**Status**: Ready for manufacturer contact and LED testing
**Next Update**: After manufacturer response or successful LED test

---

## Appendix: Manufacturer Contact Template (Ready to Use)

Save this as a draft email:

**To**: support@opensourcesdrlab.com (or find actual contact)
**Subject**: XDC Constraints File Request - XC7K325T B210 Board

**Body**:
```
Hello OpenSourceSDRLab Team,

I recently purchased your XC7K325T + AD9361 USRP B210 compatible SDR
development board and would like to develop custom firmware for it.

To proceed with firmware development using Xilinx Vivado and the UHD
framework, I need the following technical documentation:

REQUESTED FILES:
1. XDC pin constraints file (Vivado format)
2. Schematic or pinout documentation
3. Board revision/version information
4. Example firmware or reference bitstream (if available)

BOARD INFORMATION:
- FPGA Chip Marking: FFG676ABX2425 DD4ABF13A
- Confirmed Part: XC7K325T-2FFG676C
- Product: USB 3.0 Type-C SDR with AD9361
- Board matches openFPGALoader "opensourceSDRLabKintex7" definition

PURCHASE DETAILS:
- Order Number: [FILL IN]
- Purchase Date: [FILL IN]
- Seller/Platform: [FILL IN]

I'm happy to sign an NDA if required for accessing technical documentation.

Thank you for your assistance. I look forward to hearing from you.

Best regards,
[YOUR NAME]
[YOUR EMAIL]
```

**Alternate email addresses to try**:
- info@opensourcesdrlab.com
- sales@opensourcesdrlab.com
- Check their website contact form
- Check AliExpress/eBay seller messages

---

Good luck! Let me know how the manufacturer contact goes or if you want help with the LED test firmware.
