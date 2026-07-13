set out_dir build_cpu_vga_pipeline
file mkdir $out_dir

set src_files [concat \
    [glob src/core/*.v] \
    [list src/core/pipeline/btb.v] \
    [glob src/bus/*.v] \
    [glob src/memory/*.v] \
    [glob src/io/*.v] \
    [glob src/common/*.v] \
    [glob src/soc/*.v] \
    [glob src/board/*.v]]

read_verilog $src_files
read_mem processor_fpga/boot_rom.mem
read_xdc constraints/minisys.xdc

synth_design -top minisys_top -part xc7a100tfgg484-1 -generic CPU_MODE=5
write_checkpoint -force $out_dir/post_synth.dcp
report_utilization -file $out_dir/utilization_synth.rpt
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force $out_dir/post_route.dcp
report_utilization -file $out_dir/utilization_route.rpt
report_timing_summary -file $out_dir/timing_summary.rpt
report_drc -file $out_dir/drc.rpt
write_bitstream -force $out_dir/minisys_top_pipeline.bit
exit
