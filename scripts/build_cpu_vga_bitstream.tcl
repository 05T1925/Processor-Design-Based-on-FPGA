open_project processor_fpga/processor_fpga.xpr
set_property top minisys_top [current_fileset]
catch {set_property top_auto_set false [current_fileset]}
update_compile_order -fileset sources_1
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property STATUS [get_runs synth_1]] != "synth_design Complete!"} {
    error "synth_1 failed: [get_property STATUS [get_runs synth_1]]"
}
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
open_run impl_1
report_utilization -file reports/vivado/cpu_vga_utilization.rpt
report_timing_summary -file reports/vivado/cpu_vga_timing_summary.rpt
report_drc -file reports/vivado/cpu_vga_drc.rpt
report_power -file reports/vivado/cpu_vga_power.rpt
close_project
exit
