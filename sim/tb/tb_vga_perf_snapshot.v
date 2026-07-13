`timescale 1ns/1ps

module tb_vga_perf_snapshot;
    reg clk = 0, rst_n = 0;
    reg [1:0] page = 2;
    reg [31:0] cycles = 0, instret = 0, cpi = 0, ipc = 0, mips = 0;
    reg [31:0] bench_normal = 0, bench_mac = 0, speedup = 0, bench_status = 0;
    wire [3:0] r, g, b;
    wire hs, vs;
    always #5 clk = ~clk;

    vga_dashboard #(.CLK_FREQ_HZ(8), .PERF_REFRESH_HZ(1)) dut (
        .clk(clk), .rst_n(rst_n), .page(page), .game_state(0), .guess(0),
        .attempts(0), .hint(0), .selected(0), .cycles(cycles),
        .instret(instret), .cpi_x100(cpi), .ipc_x100(ipc), .mips_x10(mips),
        .mac_count(0), .branches(0), .branch_miss(0), .pred_acc_x100(0),
        .bus_op(0), .bus_addr_trace(0), .bus_wdata_trace(0),
        .bus_rdata_trace(0), .bus_device(0), .last_button(0), .bench_id(0),
        .bench_normal(bench_normal), .bench_mac(bench_mac),
        .speedup_x100(speedup), .bench_status(bench_status),
        .write_count(0), .x3_guess(0), .x4_target(0), .x5_count(0),
        .tap_pc(0), .tap_instr(0), .tap_stage(0), .vga_r(r), .vga_g(g),
        .vga_b(b), .vga_hsync(hs), .vga_vsync(vs)
    );

    initial begin
        #12 rst_n = 1;
        cycles = 10; instret = 6; cpi = 166; ipc = 60; mips = 600;
        repeat (7) @(posedge clk);
        if (dut.pending_cycles != 0) $fatal(1, "snapshot updated too early");
        @(posedge clk); #1;
        if (dut.pending_cycles != 10 || dut.disp_cycles != 0)
            $fatal(1, "tick or frame isolation failed");
        cycles = 99; instret = 77;
        force dut.frame_start = 1'b1;
        @(posedge clk); #1;
        release dut.frame_start;
        if (dut.disp_cycles != 10 || dut.disp_instret != 6)
            $fatal(1, "atomic frame commit failed");
        repeat (2) @(posedge clk);
        if (dut.disp_cycles != 10) $fatal(1, "display changed between commits");

        bench_normal = 500; bench_mac = 100; speedup = 500; bench_status = 1;
        @(posedge clk); #1;
        if (dut.pending_bench_mac != 100 || dut.pending_bench_status != 1)
            $fatal(1, "benchmark completion was not captured immediately");
        bench_mac = 90;
        @(posedge clk); #1;
        if (dut.pending_bench_mac != 90)
            $fatal(1, "repeated MAC benchmark update was ignored");
        $display("PASS: performance snapshot tick/stability/atomic frame commit");
        $finish;
    end
endmodule
