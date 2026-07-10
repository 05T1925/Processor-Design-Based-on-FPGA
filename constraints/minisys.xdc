## Minisys board constraints for this project.
##
## Confirmed sources:
## - Minisys_Master.xdc from:
##   install package/minisys_MIPS_FPGA1/MIPS_FPGA/workspace/project_linux/
##   project_linux.srcs/constrs_1/new/Minisys_Master.xdc
## - Minisys Chinese lab constraints:
##   lab1/constr/flash_led_top.xdc
##   lab2/constrs_1/new/KEY_SEG.xdc
##   lab3/constr/uart.xdc
##
## Project top port policy:
##   clk      : 100 MHz clock, pin Y18
##   rst_n    : board reset button, pin P20; converted inside minisys_top
##   btn[4:0] : five user push-buttons, active high
##   sw[15:0] : first 16 slide switches
##   kbd_col_n[3:0] : 4x4 keypad sensed lines, active low when pressed
##   kbd_row_n[3:0] : 4x4 keypad scanned lines, active low drive
##   led[15:0]: first 16 user LEDs
##   seg[7:0] : seven-segment cathode/DP bus, active low
##   an[7:0]  : seven-segment digit enable bus, active low
##   vga_[rgb] : 12-bit VGA color bus
##   vga_hsync/vga_vsync : VGA sync signals

## Configuration bank voltage for Minisys board.
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Clock and reset
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

set_property -dict {PACKAGE_PIN P20 IOSTANDARD LVCMOS33} [get_ports rst_n]

## Push-buttons S1-S5
## Derived from Minisys hardware manual Fig. 1-3. These keys are driven high
## when pressed and sit on the 1.5 V bank.
set_property -dict {PACKAGE_PIN R1 IOSTANDARD LVCMOS15} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN P1 IOSTANDARD LVCMOS15} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN P5 IOSTANDARD LVCMOS15} [get_ports {btn[2]}]
set_property -dict {PACKAGE_PIN P4 IOSTANDARD LVCMOS15} [get_ports {btn[3]}]
set_property -dict {PACKAGE_PIN P2 IOSTANDARD LVCMOS15} [get_ports {btn[4]}]

## Slide switches SW0-SW15
set_property -dict {PACKAGE_PIN W4  IOSTANDARD LVCMOS15} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN R4  IOSTANDARD LVCMOS15} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN T4  IOSTANDARD LVCMOS15} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN T5  IOSTANDARD LVCMOS15} [get_ports {sw[3]}]
set_property -dict {PACKAGE_PIN U5  IOSTANDARD LVCMOS15} [get_ports {sw[4]}]
set_property -dict {PACKAGE_PIN W6  IOSTANDARD LVCMOS15} [get_ports {sw[5]}]
set_property -dict {PACKAGE_PIN W5  IOSTANDARD LVCMOS15} [get_ports {sw[6]}]
set_property -dict {PACKAGE_PIN U6  IOSTANDARD LVCMOS15} [get_ports {sw[7]}]
set_property -dict {PACKAGE_PIN V5  IOSTANDARD LVCMOS15} [get_ports {sw[8]}]
set_property -dict {PACKAGE_PIN R6  IOSTANDARD LVCMOS15} [get_ports {sw[9]}]
set_property -dict {PACKAGE_PIN T6  IOSTANDARD LVCMOS15} [get_ports {sw[10]}]
set_property -dict {PACKAGE_PIN Y6  IOSTANDARD LVCMOS15} [get_ports {sw[11]}]
set_property -dict {PACKAGE_PIN AA6 IOSTANDARD LVCMOS15} [get_ports {sw[12]}]
set_property -dict {PACKAGE_PIN V7  IOSTANDARD LVCMOS15} [get_ports {sw[13]}]
set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS15} [get_ports {sw[14]}]
set_property -dict {PACKAGE_PIN AB6 IOSTANDARD LVCMOS15} [get_ports {sw[15]}]

## 4x4 keypad
## Wiring derived from Minisys hardware manual Fig. 1-5. The figure does not
## provide a direct row/column table, so this revision swaps the previous test
## mapping: the lower four keypad lines are sensed as columns and the upper
## four pull-up lines are driven as scanned rows.
set_property -dict {PACKAGE_PIN M2 IOSTANDARD LVCMOS15} [get_ports {kbd_col_n[0]}]
set_property -dict {PACKAGE_PIN K3 IOSTANDARD LVCMOS15} [get_ports {kbd_col_n[1]}]
set_property -dict {PACKAGE_PIN L3 IOSTANDARD LVCMOS15} [get_ports {kbd_col_n[2]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS15} [get_ports {kbd_col_n[3]}]
set_property -dict {PACKAGE_PIN L4 IOSTANDARD LVCMOS15} [get_ports {kbd_row_n[0]}]
set_property -dict {PACKAGE_PIN L5 IOSTANDARD LVCMOS15} [get_ports {kbd_row_n[1]}]
set_property -dict {PACKAGE_PIN J6 IOSTANDARD LVCMOS15} [get_ports {kbd_row_n[2]}]
set_property -dict {PACKAGE_PIN K6 IOSTANDARD LVCMOS15} [get_ports {kbd_row_n[3]}]

## User LEDs LED0-LED15
set_property -dict {PACKAGE_PIN A21 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN E21 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS33} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS33} [get_ports {led[7]}]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS15} [get_ports {led[8]}]
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS15} [get_ports {led[9]}]
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS15} [get_ports {led[10]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS15} [get_ports {led[11]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS15} [get_ports {led[12]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS15} [get_ports {led[13]}]
set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS15} [get_ports {led[14]}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS15} [get_ports {led[15]}]

## Seven-segment digit enables, active low
set_property -dict {PACKAGE_PIN C19 IOSTANDARD LVCMOS33} [get_ports {an[0]}]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports {an[1]}]
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports {an[2]}]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {an[3]}]
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {an[4]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVCMOS33} [get_ports {an[5]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVCMOS33} [get_ports {an[6]}]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {an[7]}]

## Seven-segment segments plus decimal point, active low.
## Mapping follows the working Minisys lab2/lab3 constraints:
## seg[0]=CA, seg[1]=CB, seg[2]=CC, seg[3]=CD,
## seg[4]=CE, seg[5]=CF, seg[6]=CG, seg[7]=DP.
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS33} [get_ports {seg[0]}]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {seg[1]}]
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports {seg[2]}]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports {seg[3]}]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {seg[4]}]
set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports {seg[5]}]
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {seg[6]}]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports {seg[7]}]

## VGA output (12-bit RGB + HSYNC + VSYNC)
## These VGA pins share Bank 15 with several existing 1.5 V user I/Os on the
## Minisys board, so they must use LVCMOS15 to avoid VCCO conflicts.
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS15} [get_ports {vga_r[0]}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS15} [get_ports {vga_r[1]}]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS15} [get_ports {vga_r[2]}]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS15} [get_ports {vga_r[3]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS15} [get_ports {vga_g[0]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS15} [get_ports {vga_g[1]}]
set_property -dict {PACKAGE_PIN J22 IOSTANDARD LVCMOS15} [get_ports {vga_g[2]}]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS15} [get_ports {vga_g[3]}]
set_property -dict {PACKAGE_PIN H20 IOSTANDARD LVCMOS15} [get_ports {vga_b[0]}]
set_property -dict {PACKAGE_PIN G20 IOSTANDARD LVCMOS15} [get_ports {vga_b[1]}]
set_property -dict {PACKAGE_PIN K21 IOSTANDARD LVCMOS15} [get_ports {vga_b[2]}]
set_property -dict {PACKAGE_PIN K22 IOSTANDARD LVCMOS15} [get_ports {vga_b[3]}]
set_property -dict {PACKAGE_PIN M21 IOSTANDARD LVCMOS15} [get_ports vga_hsync]
set_property -dict {PACKAGE_PIN L21 IOSTANDARD LVCMOS15} [get_ports vga_vsync]
