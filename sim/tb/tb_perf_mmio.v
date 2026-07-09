`timescale 1ns / 1ps

module tb_perf_mmio;

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

        $readmemh("tests/perf/perf_mmio.hex",
                  uut.inst_ram_inst.mem, 0, 8);

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1;
    end

    initial begin
        wait (debug_state == 8'd5);
        #20;

        $display("MMIO snapshots: cycle=%0d instret=%0d mac=%0d",
                 uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[6],
                 uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[7],
                 uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[8]);

        if (uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[6] == 32'd0) begin
            $display("FAIL: cycle MMIO returned zero");
            errors = errors + 1;
        end
        if (uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[7] !== 32'd6) begin
            $display("FAIL: instret MMIO=%0d expected=6",
                     uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[7]);
            errors = errors + 1;
        end
        if (uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[8] !== 32'd1) begin
            $display("FAIL: mac MMIO=%0d expected=1",
                     uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[8]);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL PERFORMANCE MMIO TESTS PASSED");
        else
            $display("PERFORMANCE MMIO TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

    initial begin
        #3000;
        $display("FAIL: performance MMIO timeout pc=%08x state=%0d",
                 debug_pc, debug_state);
        $finish;
    end

endmodule
