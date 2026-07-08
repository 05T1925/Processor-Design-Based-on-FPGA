`timescale 1ns / 1ps

module tb_cpu_basic;

    reg         clk;
    reg         rst_n;
    reg  [15:0] sw;
    reg         uart_rx;

    wire [15:0] led;
    wire [7:0]  seg_an;
    wire [7:0]  seg_cat;
    wire        uart_tx;
    wire [31:0] debug_pc;
    wire [7:0]  debug_state;

    integer i;

    soc_top #(
        .CPU_MODE(0)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .led(led),
        .sw(sw),
        .seg_an(seg_an),
        .seg_cat(seg_cat),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .debug_pc(debug_pc),
        .debug_state(debug_state)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        sw = 16'h0000;
        uart_rx = 1'b1;

        // Clear instruction/data memories first
        for (i = 0; i < 8192; i = i + 1) begin
            uut.inst_ram_inst.mem[i] = 32'h00000000;
            uut.data_ram_inst.mem[i] = 32'h00000000;
        end

        // Load test program
        $readmemh(
            "C:/Users/rolle/Processor-Design-Based-on-FPGA/sim/programs/basic_test.hex",
            uut.inst_ram_inst.mem
        );

        #20;
        rst_n = 1;
    end

    initial begin
        // Wait until CPU enters HALT state
        wait (debug_state == 8'd5);
        #20;

        $display("CPU HALTED");
        $display("debug_pc = 0x%08X", debug_pc);
        $display("data_ram[0] = 0x%08X", uut.data_ram_inst.mem[0]);
        $display("x3 = 0x%08X",
                 uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[3]);
        $display("x6 = 0x%08X",
                 uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[6]);

        if (uut.data_ram_inst.mem[0] == 32'd30 &&
            uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[3] == 32'd30 &&
            uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[6] == 32'd30)
            $display("PASS: CPU basic test passed");
        else
            $display("FAIL: CPU basic test failed");

        $finish;
    end

  initial begin
        #1000;
        $display("FAIL: timeout, CPU did not halt");
        $display("debug_pc    = 0x%08X", debug_pc);
        $display("debug_state = 0x%08X", debug_state);
        $display("data_ram[0] = 0x%08X", uut.data_ram_inst.mem[0]);
        $display("x1 = 0x%08X", uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[1]);
        $display("x2 = 0x%08X", uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[2]);
        $display("x3 = 0x%08X", uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[3]);
        $display("x5 = 0x%08X", uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[5]);
        $display("x6 = 0x%08X", uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[6]);
        $finish;
    end

endmodule