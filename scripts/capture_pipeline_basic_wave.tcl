# Run from the Tcl Console after opening tb_pipeline_basic behavioral simulation.

set repo_root "C:/Users/rolle/Processor-Design-Based-on-FPGA"
set wave_file "$repo_root/reports/vivado/pipeline_basic.wcfg"
set cpu "/tb_pipeline_basic/uut/cpu_top_inst/gen_riscv_pipe/riscv_pipe_inst/u_cpu"

proc add_signal_if_present {path} {
    set objects [get_objects -quiet $path]
    if {[llength $objects] > 0} {
        add_wave $objects
    } else {
        puts "SKIP: waveform object not found: $path"
    }
}

restart

add_wave_divider "Basic"
foreach signal {
    /tb_pipeline_basic/clk
    /tb_pipeline_basic/rst_n
    /tb_pipeline_basic/debug_pc
    /tb_pipeline_basic/cpu_cycle
    /tb_pipeline_basic/cpu_instret
} {
    add_signal_if_present $signal
}

add_wave_divider "Pipeline Registers"
foreach signal {
    if_id_pc if_id_instr if_id_valid
    id_ex_pc id_ex_instr id_ex_valid
    ex_mem_pc ex_mem_alu_result ex_mem_valid
    mem_wb_pc mem_wb_rd_addr mem_wb_wb_data mem_wb_reg_write mem_wb_valid
} {
    add_signal_if_present "$cpu/$signal"
}

add_wave_divider "Hazard Control"
foreach signal {
    forward_rs1_sel forward_rs2_sel load_use_hazard stall_w
    branch_flush jal_flush jalr_flush
} {
    add_signal_if_present "$cpu/$signal"
}

add_wave_divider "Results"
foreach signal {
    /tb_pipeline_basic/reg_x3
    /tb_pipeline_basic/reg_x6
    /tb_pipeline_basic/cpu_halted
} {
    add_signal_if_present $signal
}

log_wave -recursive /tb_pipeline_basic
run all
save_wave_config $wave_file
puts "Saved waveform configuration: $wave_file"
