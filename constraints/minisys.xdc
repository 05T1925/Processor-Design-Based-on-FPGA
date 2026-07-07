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
##   sw[15:0] : first 16 slide switches
##   led[15:0]: first 16 user LEDs
##   seg[7:0] : seven-segment cathode/DP bus, active low
##   an[7:0]  : seven-segment digit enable bus, active low

## Clock and reset
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

set_property -dict {PACKAGE_PIN P20 IOSTANDARD LVCMOS33} [get_ports rst_n]

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
