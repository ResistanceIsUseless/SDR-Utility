#!/bin/bash
# Script to apply float32 fix to B210 firmware

set -e

PROJECT_DIR="B210/firmware/Kintex-7 USRP_B210/固件源工程/B210_Project_Firmwire"
FIX_FILE="$PROJECT_DIR/B210_Project_Firmwire.srcs/sources_1/imports/B210_Project_Firmwire/lib/vita_200/iq_to_float.v"

echo "======================================"
echo "B210 Float32 Firmware Fixer"
echo "======================================"
echo ""

if [ ! -f "$FIX_FILE" ]; then
    echo "ERROR: Cannot find iq_to_float.v"
    echo "Make sure you're in the SDR-Utility directory"
    exit 1
fi

echo "Backing up original file..."
cp "$FIX_FILE" "$FIX_FILE.ORIGINAL"

echo "Applying float32 conversion fix..."

# Create the fixed version
cat > "$FIX_FILE.FIXED" <<'VERILOG'
//
// Copyright 2014 Ettus Research LLC
// Copyright 2018 Ettus Research, a National Instruments Company
//
// SPDX-License-Identifier: LGPL-3.0-or-later
//
// FIXED VERSION - Corrected exponent calculation for IEEE 754

module iq_to_float

  #(parameter BITS_IN =16,
    parameter BITS_OUT = 32
    )
   (
    input [15:0] in,
    output [31:0] out
    );

   //2s complement
   wire [15:0] unsigned_mag;

   //leading bit registers
   wire [15:0] lead;
   wire [15:0] reversed_mag;

   //16-4 encoder
   wire [3:0] binary_out;

   wire [22:0] fraction;
   wire [7:0] exponent;

   wire [15:0] binary_in;

   binary_encoder #(.SIZE(16))
   encoding (.in(binary_in),.out(binary_out));

   // Detect sign, if negative detected perform 2's complement
   assign unsigned_mag = (in[15] == 1)?((~in[15:0])+1'b1):in[15:0];

   //detect leading one
   wire [15:0] complement = ((~reversed_mag[BITS_IN-1:0])+1'b1);
   assign lead = complement & reversed_mag;

   // FIXED: Correct exponent calculation for 16-bit to float32
   // For 16-bit input: exponent = 127 + (15 - binary_out)
   // binary_out is the position of leading 1 from MSB (0-15)
   wire [15:0] pre_frac = unsigned_mag << (15 - binary_out);
   assign fraction = {pre_frac[14:0],8'h0};

   // FIXED: Corrected exponent formula
   wire [7:0] calculated_exp = 8'd127 + 8'd15 - {4'b0, binary_out};

   // Handle special cases
   wire is_zero = (in == 16'b0);
   wire is_overflow = (binary_out > 4'd15);

   assign exponent = is_zero ? 8'b0 :
                     is_overflow ? 8'hFF :
                     calculated_exp;

   // Construct output with overflow protection
   wire [22:0] frac_out = is_overflow ? 23'h7FFFFF : fraction;
   assign out = {in[15], exponent, frac_out};

   //reverse the signed input
   genvar r;
   generate
      for (r = 0; r < 16; r = r+1) begin:bit_reverse
	assign reversed_mag[r] = unsigned_mag[BITS_IN-r-1];
      end
   endgenerate

   //reversed the output of the detect the leading bit procedure
   genvar i;
   generate
     for (i= 0; i < 16; i = i+1) begin: i_rev
       assign binary_in[i] = lead[BITS_IN-i-1];
     end
   endgenerate

endmodule
VERILOG

# Apply the fix
mv "$FIX_FILE.FIXED" "$FIX_FILE"

echo ""
echo "✓ Fix applied successfully!"
echo ""
echo "Original file backed up to:"
echo "  $FIX_FILE.ORIGINAL"
echo ""
echo "Next steps:"
echo "  1. Open Vivado"
echo "  2. Load project: $PROJECT_DIR/B210_Project_Firmwire.xpr"
echo "  3. Run Synthesis"
echo "  4. Run Implementation"
echo "  5. Generate Bitstream"
echo ""
echo "After compilation, run:"
echo "  ./install_fixed_firmware.sh"
echo ""
