`timescale 1ns/1ps

module tb_cpu_benchmark_select;
    reg clk = 0, rst_n = 0;
    reg [4:0] btn = 0;
    reg [15:0] sw = 16'h0002;
    wire [15:0] led;
    wire [7:0] seg_an, seg_cat;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync, uart_tx;
    wire [31:0] debug_pc;
    wire [7:0] debug_state;
    integer bench_status_commits = 0;
    always #5 clk = ~clk;
    always @(posedge clk)
        if (dut.dbus_en && dut.dbus_we && dut.dbus_addr == 32'hFFFF_FC44 &&
            dut.dbus_wdata == 32'h0000_011C)
            bench_status_commits <= bench_status_commits + 1;

    soc_top #(.CPU_MODE(0), .SYS_CLK_FREQ(300),
        .INST_INIT_FILE("C:/Users/28641/Desktop/Project-based Curriculum Stage/tests/demo/cpu_guess_game.hex")) dut (
        .clk(clk), .rst_n(rst_n), .led(led), .sw(sw), .btn(btn),
        .seg_an(seg_an), .seg_cat(seg_cat), .vga_r(vga_r), .vga_g(vga_g),
        .vga_b(vga_b), .vga_hsync(vga_hsync), .vga_vsync(vga_vsync),
        .uart_rx(1'b1), .uart_tx(uart_tx), .debug_pc(debug_pc), .debug_state(debug_state)
    );

    task press_key;
        input integer bit_index;
        integer timeout;
        begin
            btn[bit_index] = 1; repeat (8) @(posedge clk);
            btn[bit_index] = 0; repeat (8) @(posedge clk);
            timeout = 0;
            while (dut.button_mmio_inst.edge_latched == 0 && timeout < 20000) begin
                @(posedge clk); timeout = timeout + 1;
            end
            if (timeout >= 20000) $fatal(1, "benchmark button edge timeout");
            timeout = 0;
            while (dut.button_mmio_inst.edge_latched != 0 && timeout < 2000000) begin
                @(posedge clk); timeout = timeout + 1;
            end
            if (timeout >= 2000000) $fatal(1, "benchmark button ACK timeout pc=%h", debug_pc);
        end
    endtask

    task wait_benchmark_done;
        integer timeout;
        begin
            timeout = 0;
            while (dut.vga_bench_status != 1 && timeout < 3000000) begin
                @(posedge clk); timeout = timeout + 1;
            end
            if (timeout >= 3000000)
                $fatal(1, "benchmark completion timeout pc=%h id=%0d x9=%0d last_btn=%h writes=%0d status_cmds=%0d",
                       debug_pc, dut.vga_bench_id,
                       dut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[9],
                       dut.vga_last_button, dut.vga_write_count, bench_status_commits);
        end
    endtask

    integer timeout;
    initial begin
        repeat (5) @(posedge clk); rst_n = 1;
        timeout = 0;
        while (dut.vga_page != 2 && timeout < 20000) begin
            @(posedge clk); timeout = timeout + 1;
        end
        if (timeout >= 20000) $fatal(1, "performance page timeout");

        // Default selection 0 must execute the branch workload.
        press_key(4);
        wait_benchmark_done;
        if (dut.vga_bench_status != 1 || dut.vga_bench_normal == 0)
            $fatal(1, "branch benchmark did not publish result");

        press_key(1);
        if (dut.vga_bench_id != 1) $fatal(1, "memory selection failed");
        press_key(4);
        wait_benchmark_done;
        if (dut.vga_bench_normal == 0) $fatal(1, "memory benchmark did not publish result");

        press_key(1);
        if (dut.vga_bench_id != 2) $fatal(1, "MAC selection failed");
        press_key(4);
        wait_benchmark_done;
        if (dut.vga_bench_mac == 0 || dut.vga_speedup_x100 == 0)
            $fatal(1, "MAC benchmark did not publish comparison");
        $display("MAC BENCH: normal=%0d mac=%0d speedup_x100=%0d mac_count=%0d",
            dut.vga_bench_normal, dut.vga_bench_mac,
            dut.vga_speedup_x100, dut.vga_mac_count);
        if (dut.vga_bench_mac >= dut.vga_bench_normal)
            $fatal(1, "MAC benchmark is not faster normal=%0d mac=%0d",
                dut.vga_bench_normal, dut.vga_bench_mac);
        if (dut.vga_bench_status != 1 ||
            dut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[24] != 11200)
            $fatal(1, "MAC result mismatch status=%0d mac=%0d",
                dut.vga_bench_status,
                dut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[24]);

        press_key(1);
        if (dut.vga_bench_id != 3 || dut.vga_bench_status != 0)
            $fatal(1, "mixed selection did not reset result state");
        press_key(4);
        wait_benchmark_done;
        if (dut.vga_bench_normal == 0 || dut.vga_bench_status != 1)
            $fatal(1, "mixed benchmark did not publish result");

        $display("PASS: PERFORMANCE dispatches BRANCH/MEMORY/MAC/MIXED");
        $finish;
    end
endmodule
