# XC7K325T SDR Project TODO

## Completed Tasks
- [x] Research and analyze the XC7K325T SDR board architecture
- [x] Review GitHub repositories for B210 clone firmware examples
- [x] Document hardware differences between XC7A100T and XC7K325T boards
- [x] Create step-by-step firmware building guide
- [x] Document flashing procedures and troubleshooting
- [x] Sync documentation to local todo.md file
- [x] Search GitHub for XC7K325T pinout and constraints files
- [x] Analyze found constraints files for compatibility
- [x] Create detailed pinout research findings document
- [x] Create XDC constraints template for XC7K325T B210

## Next Steps for Implementation

### Critical Path Items
- [ ] Acquire correct pinout.xdc constraints file for XC7K325T board
  - Contact OpenSourceSDRLab directly
  - Or adapt from LSC-Unicamp repository
  - Verify against actual board revision

- [ ] Set up Vivado build environment
  - Download and install Xilinx Vivado 2019.1+
  - Verify WebPACK license supports XC7K325T
  - Configure environment variables

- [ ] Clone and prepare UHD repository
  - Clone UHD v4.6.0.0 or newer
  - Install all dependencies
  - Build host software first

### Build and Test
- [ ] Modify UHD B200 build for XC7K325T
  - Update part number in build scripts
  - Integrate correct pin constraints
  - Adjust timing constraints if needed

- [ ] First FPGA build attempt
  - Run synthesis and implementation
  - Check timing closure
  - Verify resource utilization

- [ ] Test firmware via JTAG
  - Program FPGA (volatile) first
  - Test with uhd_usrp_probe
  - Validate basic USB communication
  - Test AD9361 initialization

- [ ] Validate RF functionality
  - Test TX on all ports
  - Test RX on all ports
  - Verify frequency range
  - Check bandwidth capabilities
  - Test GPS/PPS functionality

### Optimization and Refinement
- [ ] Fine-tune timing constraints
- [ ] Optimize for power consumption
- [ ] Add custom features if needed
- [ ] Flash to permanent storage
- [ ] Create automated build scripts
- [ ] Document any board-specific quirks

## Resources Located

### GitHub Repositories Analyzed
1. LSC-Unicamp/processor-ci-controller - XC7K325T pinout and build files
2. lmesserStep/LibreSDRB210 - XC7A100T reference (installation process)
3. MicroPhase/antsdr_uhd - ANTSDR firmware architecture
4. alphafox02/LibreSDR_USRP - Binary distribution example
5. NustyFrozen/LibreSDR-UHD-B220-Mini - XC7A200T variant
6. tinylabs/libresdr_patch - Patching methodology

### Key Files Created
- XC7K325T_SDR_FIRMWARE_GUIDE.md - Complete firmware guide
- PINOUT_RESEARCH_FINDINGS.md - Detailed pinout research and analysis
- b210_xc7k325t_template.xdc - XDC constraints template with all B210 signals
- todo.md - This file (backup of TodoWrite state)

## Known Challenges

### Critical Issues
1. **No pre-built binaries available for XC7K325T**
   - Must build from source
   - Cannot use XC7A100T/XC7A75T binaries directly

2. **Pin constraints file needed - CRITICAL BLOCKER**
   - Critical for successful build
   - Must match exact board revision
   - Different from standard B210
   - **Package discrepancy**: Board uses FFG900 but openFPGALoader shows FFG676
   - Need to verify actual package on board
   - Template XDC created but needs actual pin assignments

3. **FPGA family difference**
   - Kintex-7 vs Artix-7
   - May require timing constraint adjustments
   - Different internal architecture

### Research Findings (2025-12-10)
- Found LSC-Unicamp XC7K325T project but it's NOT a B210 clone (basic RISC-V board)
- Found complete B200 UCF constraints from Ettus (XC7A75T-FGG484)
- Created template XDC with all ~154 pin assignments needed
- All pin numbers are placeholders marked "FIXME_XXX"
- Package verification needed: FFG900 vs FFG676

### Risks
- Incorrect pin mapping could damage hardware
- USB interface must be validated carefully
- AD9361 interface timing is critical
- GPS integration differs from standard B210

## Reference Information

### Board Specifications
- **FPGA**: Xilinx Kintex-7 XC7K325T-2FFG900C
- **RF**: AD9361BBCZ
- **Interface**: USB 3.0 Type-C
- **Bandwidth**: 56 MHz real-time
- **Special Features**: Onboard GPS, PPS input, 10MHz reference

### Software Versions
- **Recommended UHD**: v4.0 to v4.7
- **Vivado**: 2019.1 or newer
- **Build time**: 1-2 hours for FPGA synthesis/implementation

## Notes
- Documentation is stored in: XC7K325T_SDR_FIRMWARE_GUIDE.md
- Follow guide sections in order for best results
- Always test with JTAG (volatile) before permanent flash
- Keep backups of any working binaries
- See PINOUT_RESEARCH_FINDINGS.md for detailed analysis and next steps
- Template XDC available in b210_xc7k325t_template.xdc (needs pin assignments)

## Package Verification - COMPLETED ✅
**Chip Marking**: FFG676ABX2425 DD4ABF13A
**Confirmed Part**: XC7K325T-2FFG676C (676-ball BGA package)
**Match**: LSC-Unicamp project uses SAME package
**Known Working Pins**: Clock (G22), Reset (D26), LEDs (A23-E25)

## Immediate Action Required
1. ✅ DONE: Verify FPGA package → **Confirmed FFG676**
2. ✅ DONE: Contact OpenSourceSDRLab → **Messaged on Discord 2025-12-10**
3. ⏳ WAITING: Manufacturer response (24 hours)
4. ⏳ TODO: Send email if no Discord response after 24h
5. ⏳ OPTIONAL: Build LED test firmware using known pins (while waiting)
6. ⏳ OPTIONAL: Search Chinese forums for documentation (while waiting)

## Critical Files
- **BOARD_IDENTIFICATION.md** - Package verification details
- **NEXT_STEPS.md** - Complete action plan with 4 options
- **b210_xc7k325t_template.xdc** - Updated with correct FFG676 part number

---
Last updated: 2025-12-10
Chip verified: 2025-12-10
