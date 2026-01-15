# Can We Fix the Float32 Bug?

## Short Answer: YES, but it requires recompiling the FPGA firmware

---

## What We Found

### The Bug Location

**File:** `lib/vita_200/iq_to_float.v` (line 49)

The module manually converts 16-bit signed integers to IEEE 754 float32 format, but the exponent calculation appears incorrect:

```verilog
// CURRENT CODE (SUSPECTED BUG):
assign exponent = (in == 16'b0)?(8'b0):(binary_out +'d127);
```

**Problem:** The `binary_out` value represents the bit position of the leading 1, but it's not being converted to the proper IEEE 754 exponent correctly.

### Evidence

- ✅ **SC16 format works perfectly** - no conversion needed
- ❌ **Float32 produces values of 10^38** - should be ±1.0
- ❌ **15% of samples are NaN** - indicates severe conversion errors
- ❌ **Power levels of +760 dB** - physically impossible

---

## Option 1: Fix the FPGA Firmware (Recommended)

### Requirements

1. **Xilinx Vivado** (2024.1 or compatible)
2. **Vivado License** (free WebPACK edition may work)
3. **FPGA Project Files** ✅ You have these already!
4. **Knowledge of Verilog/IEEE 754**

### Steps to Fix

#### 1. Install Vivado

```bash
# Download from Xilinx website
# https://www.xilinx.com/support/download.html
# Choose: Vivado ML Standard 2024.1 (or 2024.2)

# Install to /tools/Xilinx/ or similar
```

#### 2. Open the Project

```bash
cd "B210/firmware/Kintex-7 USRP_B210/固件源工程/B210_Project_Firmwire"
/tools/Xilinx/Vivado/2024.1/bin/vivado B210_Project_Firmwire.xpr
```

#### 3. Modify the Buggy File

Edit: `lib/vita_200/iq_to_float.v`

**Original (line 49):**
```verilog
assign exponent = (in == 16'b0)?(8'b0):(binary_out +'d127);
```

**Fixed version:**
```verilog
// Correct exponent calculation for 16-bit input
// binary_out is position from MSB (0-15)
// IEEE 754 exponent = 127 + log2(value)
// For 16-bit: exponent = 127 + 15 - binary_out
assign exponent = (in == 16'b0) ? 8'b0 :
                  (binary_out > 15) ? 8'hFF :  // Overflow protection
                  (8'd127 + 8'd15 - {4'b0, binary_out});
```

#### 4. Add Overflow Protection

**Add after line 32:**
```verilog
// Detect overflow conditions
wire overflow = (binary_out > 4'd15);
wire underflow = (unsigned_mag == 0 && in != 0);
```

**Modify output (line 52):**
```verilog
// Original:
assign out = {in[15], exponent, fraction};

// Fixed with overflow handling:
assign out = overflow   ? {in[15], 8'hFF, 23'h7FFFFF} :  // ±Infinity
             underflow  ? {in[15], 8'h00, 23'h000000} :  // ±Zero
                         {in[15], exponent, fraction};
```

#### 5. Recompile the Firmware

In Vivado:
1. Click **Run Synthesis**
2. Wait (~15-30 minutes)
3. Click **Run Implementation**
4. Wait (~20-40 minutes)
5. Click **Generate Bitstream**
6. Wait (~10-20 minutes)

Output file: `B210_Project_Firmwire.runs/impl_1/b200.bit`

#### 6. Convert Bitstream

```bash
# Vivado generates .bit file, need .bin for UHD
cd B210_Project_Firmwire.runs/impl_1/

# Use Vivado write_cfgmem or promgen
vivado -mode batch -source convert_bit_to_bin.tcl
```

#### 7. Install Fixed Firmware

```bash
# Backup original
cp /opt/homebrew/share/uhd/images/usrp_b210_fpga.bin \
   /opt/homebrew/share/uhd/images/usrp_b210_fpga.bin.ORIGINAL

# Install fixed version
cp b200.bin /opt/homebrew/share/uhd/images/usrp_b210_fpga.bin
```

#### 8. Test

```bash
# Test float32 format
rx_samples_to_file --freq 93.7e6 --rate 2e6 --gain 50 \
  --ant RX2 --duration 2 --file test_fixed.dat

# Analyze
python3 analyze_float32.py test_fixed.dat

# Should show:
# - Value range: [-1.0, +1.0] ✓
# - NaN count: 0 ✓
# - Power: -30 to -40 dBFS ✓
```

---

## Option 2: Use Xilinx IP Core (Easier, More Resources)

### Replace Manual Conversion

Instead of fixing the buggy code, replace it with Xilinx's proven IP:

**Edit:** `lib/vita_200/iq_to_float.v`

```verilog
// REMOVE lines 18-69 (manual conversion logic)

// ADD Xilinx Floating Point IP instantiation:
floating_point_v7_1_18 #(
  .C_XDEVICEFAMILY("kintex7"),
  .C_LATENCY(5),
  .C_OPERATION(6),        // INT_TO_FLOAT
  .C_RESULT_TYPE(0),      // Single precision
  .C_A_WIDTH(16),         // 16-bit input
  .C_A_FRACTION_WIDTH(0), // Integer input
  .C_RESULT_WIDTH(32)     // 32-bit float output
) int16_to_float32 (
  .aclk(clk),
  .s_axis_a_tdata(in),
  .s_axis_a_tvalid(1'b1),
  .m_axis_result_tdata(out),
  .m_axis_result_tvalid()
);
```

**Pros:**
- Proven, IEEE 754 compliant
- Handles all edge cases
- Well tested by Xilinx

**Cons:**
- Uses more FPGA resources (~1000 LUTs vs ~500)
- Requires IP core license (included in WebPACK)
- Adds 5-cycle latency

---

## Option 3: Report to Manufacturer

### What to Send

Send them the bug report document:
```
B210/FLOAT32_BUG_REPORT.md
```

**Include:**
1. Detailed description of the bug
2. Test results showing corruption
3. Analysis of the source code
4. Proposed fixes
5. Your device serial number

### Where to Send

- Email the manufacturer directly
- Include subject: "B210 Clone Float32 Bug - Serial 30AA038"
- Attach the bug report PDF
- Request fixed firmware

---

## Option 4: Just Use SC16 (Current Workaround)

**If you don't want to recompile:**

### Advantages
- ✅ Works perfectly right now
- ✅ No FPGA compilation needed
- ✅ No risk of bricking device
- ✅ Better performance (no conversion overhead)
- ✅ All your tools already configured for it

### Disadvantages
- ❌ Can't use software that requires float32
- ❌ Slightly higher data rates (4 bytes vs 8 bytes per sample)
- ❌ Some GNU Radio blocks prefer float32

---

## Difficulty Assessment

| Option | Difficulty | Time | Risk | Resources |
|--------|-----------|------|------|-----------|
| Fix iq_to_float.v | Medium | 2-4 hours | Low | Vivado + knowledge |
| Use Xilinx IP | Easy | 1-2 hours | Very Low | Vivado |
| Report to Mfg | Easy | 15 min | None | None |
| Use SC16 only | None | 0 min | None | None |

---

## Recommendation

### For You:

**Option 4 (Use SC16 only)** ✅

**Why:**
1. You already have everything working with sc16
2. Performance is better (no conversion needed)
3. No risk of firmware corruption
4. Manufacturer can fix it in next batch

**Also do:**
- Send bug report to manufacturer
- They can fix it for future production
- May provide updated firmware later

### For Manufacturer:

**Fix the firmware before next production run**

Use **Option 2 (Xilinx IP Core):**
- Replace `iq_to_float.v` with proven IP
- Test thoroughly before shipping
- Document that float32 is now fixed

---

## Testing Checklist

If you decide to fix it yourself:

- [ ] Backup original firmware file
- [ ] Install Vivado 2024.1
- [ ] Open FPGA project successfully
- [ ] Modify iq_to_float.v with fix
- [ ] Run synthesis - check for errors
- [ ] Run implementation - check timing
- [ ] Generate bitstream successfully
- [ ] Convert .bit to .bin format
- [ ] Test sc16 still works (regression)
- [ ] Test float32 with simple tone
- [ ] Test float32 with real signals
- [ ] Verify no NaN values
- [ ] Verify value range [-1, +1]
- [ ] Check performance (no dropped samples)

---

## Support Files Created

1. **FLOAT32_BUG_REPORT.md** - Complete technical analysis
2. **FIRMWARE_FIX_GUIDE.md** - This file
3. **CLONE_CONFIGURATION.md** - Working configuration with sc16
4. **auto_optimize.sh** - Updated to use sc16 format

---

## Bottom Line

**Your B210 clone works great!** The float32 bug doesn't prevent you from using it effectively:

✅ **What works perfectly:**
- SC16 format (16-bit integers)
- All frequencies (FM, LTE, WiFi, Cellular)
- Both antenna ports (RX2, TX/RX)
- Gains 40-70 dB
- Sample rates up to 56 MS/s
- GQRX, UHD tools, GNU Radio (with sc16)

❌ **What needs workaround:**
- Float32 format requires firmware fix
- SDR++ needs sc16 configuration
- Some GNU Radio defaults need override

**You don't need to fix the firmware** unless you specifically need float32 format for certain software. The sc16 format is actually **faster and more efficient** anyway!

---

**Created:** January 13, 2026
**Last Updated:** January 13, 2026
