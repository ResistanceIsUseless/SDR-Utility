# ==============================================================================
# XC7K325T-FFG900 USRP B210 Clone - Pin Constraints Template
# ==============================================================================
#
# IMPORTANT: This is a TEMPLATE file with PLACEHOLDER pins marked as "FIXME_XXX"
#
# DO NOT USE THIS FILE WITHOUT REPLACING ALL PLACEHOLDERS WITH ACTUAL PINS!
# Using incorrect pins can damage your hardware!
#
# Based on: Ettus B200 architecture (XC7A75T) adapted for XC7K325T-FFG900
# Source: UHD fpga/usrp3/top/b200/b200.ucf
#
# Pin assignments MUST be obtained from:
#   1. Board manufacturer (OpenSourceSDRLab)
#   2. Board schematic
#   3. Reverse engineering from working bitstream
#
# ==============================================================================

# ==============================================================================
# PART SPECIFICATION
# ==============================================================================
# CONFIRMED: Board uses FFG676 package (verified from chip marking)
# Chip marking: FFG676ABX2425 DD4ABF13A
set_property PART xc7k325tffg676-2 [current_design]

# ==============================================================================
# AD9361 (CATALINA) RF TRANSCEIVER INTERFACE
# ==============================================================================

# ------------------------------------------------------------------------------
# AD9361 SPI Interface (4 signals)
# ------------------------------------------------------------------------------
# Used for: AD9361 configuration and control

set_property PACKAGE_PIN FIXME_AD9361_SPI_CE [get_ports cat_ce]
set_property IOSTANDARD LVCMOS18 [get_ports cat_ce]

set_property PACKAGE_PIN FIXME_AD9361_SPI_MISO [get_ports cat_miso]
set_property IOSTANDARD LVCMOS18 [get_ports cat_miso]

set_property PACKAGE_PIN FIXME_AD9361_SPI_MOSI [get_ports cat_mosi]
set_property IOSTANDARD LVCMOS18 [get_ports cat_mosi]

set_property PACKAGE_PIN FIXME_AD9361_SPI_SCLK [get_ports cat_sclk]
set_property IOSTANDARD LVCMOS18 [get_ports cat_sclk]

# ------------------------------------------------------------------------------
# AD9361 Control Signals (9 signals)
# ------------------------------------------------------------------------------

# Enable AD9361
set_property PACKAGE_PIN FIXME_AD9361_ENABLE [get_ports codec_enable]
set_property IOSTANDARD LVCMOS18 [get_ports codec_enable]

# Enable AGC (Automatic Gain Control)
set_property PACKAGE_PIN FIXME_AD9361_EN_AGC [get_ports codec_en_agc]
set_property IOSTANDARD LVCMOS18 [get_ports codec_en_agc]

# Reset AD9361 (active low)
set_property PACKAGE_PIN FIXME_AD9361_RESET [get_ports codec_reset]
set_property IOSTANDARD LVCMOS18 [get_ports codec_reset]

# Sync signal for timing alignment
set_property PACKAGE_PIN FIXME_AD9361_SYNC [get_ports codec_sync]
set_property IOSTANDARD LVCMOS18 [get_ports codec_sync]

# TX/RX mode select
set_property PACKAGE_PIN FIXME_AD9361_TXRX [get_ports codec_txrx]
set_property IOSTANDARD LVCMOS18 [get_ports codec_txrx]

# Control input signals from AD9361 (4-bit)
set_property PACKAGE_PIN FIXME_AD9361_CTRL_IN_0 [get_ports {codec_ctrl_in[0]}]
set_property PACKAGE_PIN FIXME_AD9361_CTRL_IN_1 [get_ports {codec_ctrl_in[1]}]
set_property PACKAGE_PIN FIXME_AD9361_CTRL_IN_2 [get_ports {codec_ctrl_in[2]}]
set_property PACKAGE_PIN FIXME_AD9361_CTRL_IN_3 [get_ports {codec_ctrl_in[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {codec_ctrl_in[*]}]

# Control output signals to AD9361 (8-bit)
set_property PACKAGE_PIN FIXME_AD9361_CTRL_OUT_0 [get_ports {codec_ctrl_out[0]}]
set_property PACKAGE_PIN FIXME_AD9361_CTRL_OUT_1 [get_ports {codec_ctrl_out[1]}]
set_property PACKAGE_PIN FIXME_AD9361_CTRL_OUT_2 [get_ports {codec_ctrl_out[2]}]
set_property PACKAGE_PIN FIXME_AD9361_CTRL_OUT_3 [get_ports {codec_ctrl_out[3]}]
set_property PACKAGE_PIN FIXME_AD9361_CTRL_OUT_4 [get_ports {codec_ctrl_out[4]}]
set_property PACKAGE_PIN FIXME_AD9361_CTRL_OUT_5 [get_ports {codec_ctrl_out[5]}]
set_property PACKAGE_PIN FIXME_AD9361_CTRL_OUT_6 [get_ports {codec_ctrl_out[6]}]
set_property PACKAGE_PIN FIXME_AD9361_CTRL_OUT_7 [get_ports {codec_ctrl_out[7]}]
set_property IOSTANDARD LVCMOS18 [get_ports {codec_ctrl_out[*]}]

# ------------------------------------------------------------------------------
# AD9361 TX Data Interface (12-bit parallel data)
# ------------------------------------------------------------------------------
# Transmit data from FPGA to AD9361

set_property PACKAGE_PIN FIXME_AD9361_TX_D0 [get_ports {tx_codec_d[0]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D1 [get_ports {tx_codec_d[1]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D2 [get_ports {tx_codec_d[2]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D3 [get_ports {tx_codec_d[3]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D4 [get_ports {tx_codec_d[4]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D5 [get_ports {tx_codec_d[5]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D6 [get_ports {tx_codec_d[6]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D7 [get_ports {tx_codec_d[7]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D8 [get_ports {tx_codec_d[8]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D9 [get_ports {tx_codec_d[9]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D10 [get_ports {tx_codec_d[10]}]
set_property PACKAGE_PIN FIXME_AD9361_TX_D11 [get_ports {tx_codec_d[11]}]
set_property IOSTANDARD LVCMOS18 [get_ports {tx_codec_d[*]}]
set_property DRIVE 2 [get_ports {tx_codec_d[*]}]

# ------------------------------------------------------------------------------
# AD9361 RX Data Interface (12-bit parallel data)
# ------------------------------------------------------------------------------
# Receive data from AD9361 to FPGA

set_property PACKAGE_PIN FIXME_AD9361_RX_D0 [get_ports {rx_codec_d[0]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D1 [get_ports {rx_codec_d[1]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D2 [get_ports {rx_codec_d[2]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D3 [get_ports {rx_codec_d[3]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D4 [get_ports {rx_codec_d[4]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D5 [get_ports {rx_codec_d[5]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D6 [get_ports {rx_codec_d[6]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D7 [get_ports {rx_codec_d[7]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D8 [get_ports {rx_codec_d[8]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D9 [get_ports {rx_codec_d[9]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D10 [get_ports {rx_codec_d[10]}]
set_property PACKAGE_PIN FIXME_AD9361_RX_D11 [get_ports {rx_codec_d[11]}]
set_property IOSTANDARD LVCMOS18 [get_ports {rx_codec_d[*]}]
set_property DRIVE 2 [get_ports {rx_codec_d[*]}]

# ------------------------------------------------------------------------------
# AD9361 Clock Signals
# ------------------------------------------------------------------------------

# Clock output from AD9361 to FPGA (data valid reference)
set_property PACKAGE_PIN FIXME_AD9361_CLK_OUT [get_ports cat_clkout_fpga]
set_property IOSTANDARD LVCMOS18 [get_ports cat_clkout_fpga]

# Data clock (used for sampling TX/RX data)
set_property PACKAGE_PIN FIXME_AD9361_DATA_CLK [get_ports codec_data_clk_p]
set_property IOSTANDARD LVCMOS18 [get_ports codec_data_clk_p]

# Feedback clock from FPGA to AD9361
set_property PACKAGE_PIN FIXME_AD9361_FB_CLK [get_ports codec_fb_clk_p]
set_property IOSTANDARD LVCMOS18 [get_ports codec_fb_clk_p]
set_property DRIVE 2 [get_ports codec_fb_clk_p]

# Main reference clock to AD9361 (LVDS differential pair)
set_property PACKAGE_PIN FIXME_AD9361_MAIN_CLK_P [get_ports codec_main_clk_p]
set_property PACKAGE_PIN FIXME_AD9361_MAIN_CLK_N [get_ports codec_main_clk_n]
set_property IOSTANDARD LVDS_25 [get_ports codec_main_clk_p]
set_property IOSTANDARD LVDS_25 [get_ports codec_main_clk_n]

# ------------------------------------------------------------------------------
# AD9361 Frame Signals
# ------------------------------------------------------------------------------

# RX frame signal (indicates valid RX data)
set_property PACKAGE_PIN FIXME_AD9361_RX_FRAME [get_ports rx_frame_p]
set_property IOSTANDARD LVCMOS18 [get_ports rx_frame_p]

# TX frame signal (indicates valid TX data)
set_property PACKAGE_PIN FIXME_AD9361_TX_FRAME [get_ports tx_frame_p]
set_property IOSTANDARD LVCMOS18 [get_ports tx_frame_p]
set_property DRIVE 2 [get_ports tx_frame_p]

# ==============================================================================
# CYPRESS FX3 USB 3.0 INTERFACE (GPIF II)
# ==============================================================================

# ------------------------------------------------------------------------------
# FX3 Clock and Interrupt
# ------------------------------------------------------------------------------

# GPIF interface clock (100 MHz from FX3)
set_property PACKAGE_PIN FIXME_FX3_IFCLK [get_ports IFCLK]
set_property IOSTANDARD LVCMOS18 [get_ports IFCLK]
set_property DRIVE 8 [get_ports IFCLK]
set_property SLEW SLOW [get_ports IFCLK]

# External interrupt to FX3
set_property PACKAGE_PIN FIXME_FX3_EXTINT [get_ports FX3_EXTINT]
set_property IOSTANDARD LVCMOS18 [get_ports FX3_EXTINT]

# ------------------------------------------------------------------------------
# FX3 SPI Interface (for FX3 configuration)
# ------------------------------------------------------------------------------

set_property PACKAGE_PIN FIXME_FX3_SPI_CE [get_ports fx3_ce]
set_property IOSTANDARD LVCMOS18 [get_ports fx3_ce]

set_property PACKAGE_PIN FIXME_FX3_SPI_MISO [get_ports fx3_miso]
set_property IOSTANDARD LVCMOS18 [get_ports fx3_miso]

set_property PACKAGE_PIN FIXME_FX3_SPI_MOSI [get_ports fx3_mosi]
set_property IOSTANDARD LVCMOS18 [get_ports fx3_mosi]

set_property PACKAGE_PIN FIXME_FX3_SPI_SCLK [get_ports fx3_sclk]
set_property IOSTANDARD LVCMOS18 [get_ports fx3_sclk]

# ------------------------------------------------------------------------------
# FX3 GPIF Control Lines (13 signals)
# ------------------------------------------------------------------------------

set_property PACKAGE_PIN FIXME_FX3_CTL0 [get_ports GPIF_CTL0]
set_property PACKAGE_PIN FIXME_FX3_CTL1 [get_ports GPIF_CTL1]
set_property PACKAGE_PIN FIXME_FX3_CTL2 [get_ports GPIF_CTL2]
set_property PACKAGE_PIN FIXME_FX3_CTL3 [get_ports GPIF_CTL3]
set_property PACKAGE_PIN FIXME_FX3_CTL4 [get_ports GPIF_CTL4]
set_property PACKAGE_PIN FIXME_FX3_CTL5 [get_ports GPIF_CTL5]
set_property PACKAGE_PIN FIXME_FX3_CTL6 [get_ports GPIF_CTL6]
set_property PACKAGE_PIN FIXME_FX3_CTL7 [get_ports GPIF_CTL7]
set_property PACKAGE_PIN FIXME_FX3_CTL8 [get_ports GPIF_CTL8]
set_property PACKAGE_PIN FIXME_FX3_CTL9 [get_ports GPIF_CTL9]
# GPIF_CTL10 is FPGA_CFG_DONE (defined later)
set_property PACKAGE_PIN FIXME_FX3_CTL11 [get_ports GPIF_CTL11]
set_property PACKAGE_PIN FIXME_FX3_CTL12 [get_ports GPIF_CTL12]
set_property IOSTANDARD LVCMOS18 [get_ports GPIF_CTL*]

# ------------------------------------------------------------------------------
# FX3 GPIF Data Bus (32-bit)
# ------------------------------------------------------------------------------

set_property PACKAGE_PIN FIXME_FX3_D0 [get_ports {GPIF_D[0]}]
set_property PACKAGE_PIN FIXME_FX3_D1 [get_ports {GPIF_D[1]}]
set_property PACKAGE_PIN FIXME_FX3_D2 [get_ports {GPIF_D[2]}]
set_property PACKAGE_PIN FIXME_FX3_D3 [get_ports {GPIF_D[3]}]
set_property PACKAGE_PIN FIXME_FX3_D4 [get_ports {GPIF_D[4]}]
set_property PACKAGE_PIN FIXME_FX3_D5 [get_ports {GPIF_D[5]}]
set_property PACKAGE_PIN FIXME_FX3_D6 [get_ports {GPIF_D[6]}]
set_property PACKAGE_PIN FIXME_FX3_D7 [get_ports {GPIF_D[7]}]
set_property PACKAGE_PIN FIXME_FX3_D8 [get_ports {GPIF_D[8]}]
set_property PACKAGE_PIN FIXME_FX3_D9 [get_ports {GPIF_D[9]}]
set_property PACKAGE_PIN FIXME_FX3_D10 [get_ports {GPIF_D[10]}]
set_property PACKAGE_PIN FIXME_FX3_D11 [get_ports {GPIF_D[11]}]
set_property PACKAGE_PIN FIXME_FX3_D12 [get_ports {GPIF_D[12]}]
set_property PACKAGE_PIN FIXME_FX3_D13 [get_ports {GPIF_D[13]}]
set_property PACKAGE_PIN FIXME_FX3_D14 [get_ports {GPIF_D[14]}]
set_property PACKAGE_PIN FIXME_FX3_D15 [get_ports {GPIF_D[15]}]
set_property PACKAGE_PIN FIXME_FX3_D16 [get_ports {GPIF_D[16]}]
set_property PACKAGE_PIN FIXME_FX3_D17 [get_ports {GPIF_D[17]}]
set_property PACKAGE_PIN FIXME_FX3_D18 [get_ports {GPIF_D[18]}]
set_property PACKAGE_PIN FIXME_FX3_D19 [get_ports {GPIF_D[19]}]
set_property PACKAGE_PIN FIXME_FX3_D20 [get_ports {GPIF_D[20]}]
set_property PACKAGE_PIN FIXME_FX3_D21 [get_ports {GPIF_D[21]}]
set_property PACKAGE_PIN FIXME_FX3_D22 [get_ports {GPIF_D[22]}]
set_property PACKAGE_PIN FIXME_FX3_D23 [get_ports {GPIF_D[23]}]
set_property PACKAGE_PIN FIXME_FX3_D24 [get_ports {GPIF_D[24]}]
set_property PACKAGE_PIN FIXME_FX3_D25 [get_ports {GPIF_D[25]}]
set_property PACKAGE_PIN FIXME_FX3_D26 [get_ports {GPIF_D[26]}]
set_property PACKAGE_PIN FIXME_FX3_D27 [get_ports {GPIF_D[27]}]
set_property PACKAGE_PIN FIXME_FX3_D28 [get_ports {GPIF_D[28]}]
set_property PACKAGE_PIN FIXME_FX3_D29 [get_ports {GPIF_D[29]}]
set_property PACKAGE_PIN FIXME_FX3_D30 [get_ports {GPIF_D[30]}]
set_property PACKAGE_PIN FIXME_FX3_D31 [get_ports {GPIF_D[31]}]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIF_D[*]}]
set_property DRIVE 2 [get_ports {GPIF_D[*]}]
set_property SLEW SLOW [get_ports {GPIF_D[*]}]

# ==============================================================================
# PLL (CLOCK SYNTHESIZER) INTERFACE
# ==============================================================================

# PLL SPI Interface (for clock chip configuration)
set_property PACKAGE_PIN FIXME_PLL_CE [get_ports pll_ce]
set_property IOSTANDARD LVCMOS18 [get_ports pll_ce]

set_property PACKAGE_PIN FIXME_PLL_MOSI [get_ports pll_mosi]
set_property IOSTANDARD LVCMOS18 [get_ports pll_mosi]

set_property PACKAGE_PIN FIXME_PLL_SCLK [get_ports pll_sclk]
set_property IOSTANDARD LVCMOS18 [get_ports pll_sclk]

# PLL lock indicator
set_property PACKAGE_PIN FIXME_PLL_LOCK [get_ports pll_lock]
set_property IOSTANDARD LVCMOS18 [get_ports pll_lock]

# ==============================================================================
# GPS MODULE INTERFACE
# ==============================================================================

# GPS Lock indicator LED/signal
set_property PACKAGE_PIN FIXME_GPS_LOCK [get_ports gps_lock]
set_property IOSTANDARD LVCMOS33 [get_ports gps_lock]

# GPS UART receive (from GPS module to FPGA)
set_property PACKAGE_PIN FIXME_GPS_RXD [get_ports gps_rxd]
set_property IOSTANDARD LVCMOS33 [get_ports gps_rxd]

# GPS UART transmit (from FPGA to GPS module)
set_property PACKAGE_PIN FIXME_GPS_TXD [get_ports gps_txd]
set_property IOSTANDARD LVCMOS33 [get_ports gps_txd]
set_property PULLUP true [get_ports gps_txd]

# GPS NMEA output (optional secondary output)
set_property PACKAGE_PIN FIXME_GPS_TXD_NMEA [get_ports gps_txd_nmea]
set_property IOSTANDARD LVCMOS33 [get_ports gps_txd_nmea]
set_property PULLUP true [get_ports gps_txd_nmea]

# ==============================================================================
# TIMING INPUTS
# ==============================================================================

# External PPS (Pulse Per Second) input
set_property PACKAGE_PIN FIXME_PPS_EXT [get_ports PPS_IN_EXT]
set_property IOSTANDARD LVCMOS33 [get_ports PPS_IN_EXT]

# Internal PPS (from GPS module)
set_property PACKAGE_PIN FIXME_PPS_INT [get_ports PPS_IN_INT]
set_property IOSTANDARD LVCMOS33 [get_ports PPS_IN_INT]

# ==============================================================================
# STATUS LEDS
# ==============================================================================

# RX1 LED (RX activity on channel 1)
set_property PACKAGE_PIN FIXME_LED_RX1 [get_ports LED_RX1]
set_property IOSTANDARD LVCMOS18 [get_ports LED_RX1]

# RX2 LED (RX activity on channel 2)
set_property PACKAGE_PIN FIXME_LED_RX2 [get_ports LED_RX2]
set_property IOSTANDARD LVCMOS18 [get_ports LED_RX2]

# TXRX1 TX LED (TX activity on TRX1)
set_property PACKAGE_PIN FIXME_LED_TXRX1_TX [get_ports LED_TXRX1_TX]
set_property IOSTANDARD LVCMOS18 [get_ports LED_TXRX1_TX]

# TXRX2 RX LED (RX activity on TRX2)
set_property PACKAGE_PIN FIXME_LED_TXRX2_RX [get_ports LED_TXRX2_RX]
set_property IOSTANDARD LVCMOS18 [get_ports LED_TXRX2_RX]

# TXRX1 RX LED (RX activity on TRX1)
set_property PACKAGE_PIN FIXME_LED_TXRX1_RX [get_ports LED_TXRX1_RX]
set_property IOSTANDARD LVCMOS18 [get_ports LED_TXRX1_RX]

# TXRX2 TX LED (TX activity on TRX2)
set_property PACKAGE_PIN FIXME_LED_TXRX2_TX [get_ports LED_TXRX2_TX]
set_property IOSTANDARD LVCMOS18 [get_ports LED_TXRX2_TX]

# ==============================================================================
# RF FRONTEND CONTROL
# ==============================================================================

# ------------------------------------------------------------------------------
# RF Switch Control (Front-End Switching)
# ------------------------------------------------------------------------------

# SMA FD X1 (Full Duplex 1) - RX path
set_property PACKAGE_PIN FIXME_RF_SFDX1_RX [get_ports SFDX1_RX]
set_property IOSTANDARD LVCMOS33 [get_ports SFDX1_RX]

# SMA FD X1 (Full Duplex 1) - TX path
set_property PACKAGE_PIN FIXME_RF_SFDX1_TX [get_ports SFDX1_TX]
set_property IOSTANDARD LVCMOS33 [get_ports SFDX1_TX]

# SMA FD X2 (Full Duplex 2) - RX path
set_property PACKAGE_PIN FIXME_RF_SFDX2_RX [get_ports SFDX2_RX]
set_property IOSTANDARD LVCMOS33 [get_ports SFDX2_RX]

# SMA FD X2 (Full Duplex 2) - TX path
set_property PACKAGE_PIN FIXME_RF_SFDX2_TX [get_ports SFDX2_TX]
set_property IOSTANDARD LVCMOS33 [get_ports SFDX2_TX]

# SMA RX1 (Receive Only 1) - RX path
set_property PACKAGE_PIN FIXME_RF_SRX1_RX [get_ports SRX1_RX]
set_property IOSTANDARD LVCMOS33 [get_ports SRX1_RX]

# SMA RX1 (Receive Only 1) - TX path control
set_property PACKAGE_PIN FIXME_RF_SRX1_TX [get_ports SRX1_TX]
set_property IOSTANDARD LVCMOS33 [get_ports SRX1_TX]

# SMA RX2 (Receive Only 2) - RX path
set_property PACKAGE_PIN FIXME_RF_SRX2_RX [get_ports SRX2_RX]
set_property IOSTANDARD LVCMOS33 [get_ports SRX2_RX]

# SMA RX2 (Receive Only 2) - TX path control
set_property PACKAGE_PIN FIXME_RF_SRX2_TX [get_ports SRX2_TX]
set_property IOSTANDARD LVCMOS33 [get_ports SRX2_TX]

# ------------------------------------------------------------------------------
# Band Select (Frontend Filter Selection)
# ------------------------------------------------------------------------------

# TX band select A (low/high band switching)
set_property PACKAGE_PIN FIXME_RF_TX_BANDSEL_A [get_ports tx_bandsel_a]
set_property IOSTANDARD LVCMOS33 [get_ports tx_bandsel_a]

# TX band select B
set_property PACKAGE_PIN FIXME_RF_TX_BANDSEL_B [get_ports tx_bandsel_b]
set_property IOSTANDARD LVCMOS33 [get_ports tx_bandsel_b]

# RX band select A
set_property PACKAGE_PIN FIXME_RF_RX_BANDSEL_A [get_ports rx_bandsel_a]
set_property IOSTANDARD LVCMOS33 [get_ports rx_bandsel_a]

# RX band select B
set_property PACKAGE_PIN FIXME_RF_RX_BANDSEL_B [get_ports rx_bandsel_b]
set_property IOSTANDARD LVCMOS33 [get_ports rx_bandsel_b]

# RX band select C
set_property PACKAGE_PIN FIXME_RF_RX_BANDSEL_C [get_ports rx_bandsel_c]
set_property IOSTANDARD LVCMOS33 [get_ports rx_bandsel_c]

# ------------------------------------------------------------------------------
# TX Enable (Power Amplifier Enable)
# ------------------------------------------------------------------------------

# TX1 enable
set_property PACKAGE_PIN FIXME_RF_TX_ENABLE1 [get_ports tx_enable1]
set_property IOSTANDARD LVCMOS18 [get_ports tx_enable1]

# TX2 enable
set_property PACKAGE_PIN FIXME_RF_TX_ENABLE2 [get_ports tx_enable2]
set_property IOSTANDARD LVCMOS18 [get_ports tx_enable2]

# ==============================================================================
# MISCELLANEOUS CONTROL
# ==============================================================================

# Reference clock select (internal/external)
set_property PACKAGE_PIN FIXME_REF_SEL [get_ports ref_sel]
set_property IOSTANDARD LVCMOS18 [get_ports ref_sel]

# Auxiliary power control
set_property PACKAGE_PIN FIXME_AUX_PWR_ON [get_ports AUX_PWR_ON]
set_property IOSTANDARD LVCMOS33 [get_ports AUX_PWR_ON]

# ==============================================================================
# DEBUG INTERFACE (Optional - for development)
# ==============================================================================

# Uncomment if using debug header
# set_property PACKAGE_PIN FIXME_DEBUG_0 [get_ports {debug[0]}]
# set_property PACKAGE_PIN FIXME_DEBUG_1 [get_ports {debug[1]}]
# ... (continue for debug[0:31] if needed)
# set_property IOSTANDARD LVCMOS33 [get_ports {debug[*]}]
# set_property DRIVE 2 [get_ports {debug[*]}]

# Debug clocks
# set_property PACKAGE_PIN FIXME_DEBUG_CLK0 [get_ports {debug_clk[0]}]
# set_property PACKAGE_PIN FIXME_DEBUG_CLK1 [get_ports {debug_clk[1]}]
# set_property IOSTANDARD LVCMOS33 [get_ports {debug_clk[*]}]

# ==============================================================================
# UART HEADER (Optional - for debugging)
# ==============================================================================

# FPGA UART receive
set_property PACKAGE_PIN FIXME_FPGA_RXD0 [get_ports FPGA_RXD0]
set_property IOSTANDARD LVCMOS18 [get_ports FPGA_RXD0]
set_property PULLUP true [get_ports FPGA_RXD0]

# FPGA UART transmit
set_property PACKAGE_PIN FIXME_FPGA_TXD0 [get_ports FPGA_TXD0]
set_property IOSTANDARD LVCMOS18 [get_ports FPGA_TXD0]
set_property PULLUP true [get_ports FPGA_TXD0]

# ==============================================================================
# TIMING CONSTRAINTS
# ==============================================================================

# ------------------------------------------------------------------------------
# Clock Definitions
# ------------------------------------------------------------------------------

# IFCLK from FX3 (typically 100 MHz)
# create_clock -period 10.000 -name IFCLK [get_ports IFCLK]

# AD9361 data clock (typically 40 MHz when using 56 MHz bandwidth)
# create_clock -period 25.000 -name codec_data_clk [get_ports codec_data_clk_p]

# AD9361 clock output to FPGA
# create_clock -period 25.000 -name cat_clkout [get_ports cat_clkout_fpga]

# ------------------------------------------------------------------------------
# Input Delays
# ------------------------------------------------------------------------------

# AD9361 RX data input delays (relative to codec_data_clk)
# set_input_delay -clock [get_clocks codec_data_clk] -min 2.000 [get_ports {rx_codec_d[*]}]
# set_input_delay -clock [get_clocks codec_data_clk] -max 8.000 [get_ports {rx_codec_d[*]}]
# set_input_delay -clock [get_clocks codec_data_clk] -min 2.000 [get_ports rx_frame_p]
# set_input_delay -clock [get_clocks codec_data_clk] -max 8.000 [get_ports rx_frame_p]

# FX3 GPIF data input delays (relative to IFCLK)
# set_input_delay -clock [get_clocks IFCLK] -min 1.000 [get_ports {GPIF_D[*]}]
# set_input_delay -clock [get_clocks IFCLK] -max 8.000 [get_ports {GPIF_D[*]}]

# ------------------------------------------------------------------------------
# Output Delays
# ------------------------------------------------------------------------------

# AD9361 TX data output delays (relative to codec_data_clk)
# set_output_delay -clock [get_clocks codec_data_clk] -min 1.000 [get_ports {tx_codec_d[*]}]
# set_output_delay -clock [get_clocks codec_data_clk] -max 5.000 [get_ports {tx_codec_d[*]}]
# set_output_delay -clock [get_clocks codec_data_clk] -min 1.000 [get_ports tx_frame_p]
# set_output_delay -clock [get_clocks codec_data_clk] -max 5.000 [get_ports tx_frame_p]

# FX3 GPIF data output delays (relative to IFCLK)
# set_output_delay -clock [get_clocks IFCLK] -min 1.000 [get_ports {GPIF_D[*]}]
# set_output_delay -clock [get_clocks IFCLK] -max 5.000 [get_ports {GPIF_D[*]}]

# ------------------------------------------------------------------------------
# Clock Domain Crossings
# ------------------------------------------------------------------------------

# Asynchronous clock domains - set false paths
# set_false_path -from [get_clocks IFCLK] -to [get_clocks codec_data_clk]
# set_false_path -from [get_clocks codec_data_clk] -to [get_clocks IFCLK]

# ==============================================================================
# BITSTREAM CONFIGURATION
# ==============================================================================

# SPI flash configuration (based on board's flash chip)
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# ==============================================================================
# END OF CONSTRAINTS
# ==============================================================================

# Pin Assignment Summary:
# - AD9361 Interface: ~40 pins (SPI, control, data, clocks)
# - FX3 USB Interface: ~50 pins (GPIF data bus, control, SPI)
# - PLL Control: ~4 pins (SPI + lock)
# - GPS Interface: ~4 pins (UART + lock)
# - Timing: ~2 pins (PPS inputs)
# - LEDs: ~6 pins (status indicators)
# - RF Frontend: ~15 pins (switches, band select, enables)
# - Misc: ~5 pins (ref select, power control, UART debug)
# - Debug: ~34 pins (optional, can be omitted)
#
# TOTAL REQUIRED: ~120-130 pins (excluding debug)
# TOTAL WITH DEBUG: ~154 pins
#
# XC7K325T-FFG900 has plenty of I/O for this design.
