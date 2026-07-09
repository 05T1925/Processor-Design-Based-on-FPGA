`timescale 1ns / 1ps

module tb_perf_integration;

    reg clk;
    reg rst_n;
    integer i;
    integer errors;

    wire [31:0] debug_pc;
    wire [7:0]  debug_state;

    soc_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .led(),
        .sw(16'b0),
        .seg_an(),
        .seg_cat(),
        .uart_rx(1'b1),
        .uart_tx(),
        .debug_pc(debug_pc),
        .debug_state(debug_state)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        errors = 0;

        for (i = 0; i < 8192; i = i + 1) begin
            uut.inst_ram_inst.mem[i] = 32'b0;
            uut.data_ram_inst.mem[i] = 32'b0;
        end

        $readmemh("tests/perf/retirement_test.hex",
                  uut.inst_ram_inst.mem, 0, 9);

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1;
    end

    initial begin
        wait (debug_state == 8'd5);
        #20;

        $display("PERF: cycle=%0d instret=%0d mac=%0d",
                 uut.perf_cycle_count,
                 uut.perf_instret_count,
                 uut.perf_mac_count);

        if (uut.data_ram_inst.mem[0] !== 32'd1) begin
            $display("FAIL: STORE result=%0d expected=1",
                     uut.data_ram_inst.mem[0]);
            errors = errors + 1;
        end
        if (uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[3] !== 32'd7) begin
            $display("FAIL: branch flow x3=%0d expected=7",
                     uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[3]);
            errors = errors + 1;
        end
        if (uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[4] !== 32'd1) begin
            $display("FAIL: MAC writeback x4=%0d expected=1",
                     uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[4]);
            errors = errors + 1;
        end
        if (uut.perf_instret_count !== 32'd8) begin
            $display("FAIL: instret=%0d expected=8", uut.perf_instret_count);
            errors = errors + 1;
        end
        if (uut.perf_mac_count !== 32'd1) begin
            $display("FAIL: mac_count=%0d expected=1", uut.perf_mac_count);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL PERFORMANCE INTEGRATION TESTS PASSED");
        else
            $display("PERFORMANCE INTEGRATION TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

    initial begin
        #3000;
        $display("FAIL: performance integration timeout pc=%08x state=%0d",
                 debug_pc, debug_state);
        $finish;
    end

endmodule
