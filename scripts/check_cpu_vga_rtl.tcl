open_project processor_fpga/processor_fpga.xpr
update_compile_order -fileset sources_1
synth_design -rtl -name rtl_1 -top minisys_top -part xc7a100tfgg484-1
report_drc -file reports/vivado/cpu_vga_rtl_drc.rpt
close_project
exit
