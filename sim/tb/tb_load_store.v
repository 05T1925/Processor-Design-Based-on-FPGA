`timescale 1ns / 1ps

module tb_load_store;

    reg         clk;
    reg         rst_n;
    reg  [15:0] sw;
    reg         uart_rx;
    integer     i;
    integer     errors;

    wire [15:0] led;
    wire [7:0]  seg_an;
    wire [7:0]  seg_cat;
    wire        uart_tx;
    wire [31:0] debug_pc;
    wire [7:0]  debug_state;

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
        errors = 0;

        for (i = 0; i < 8192; i = i + 1) begin
            uut.inst_ram_inst.mem[i] = 32'h0000_0000;
            uut.data_ram_inst.mem[i] = 32'h0000_0000;
        end

        $readmemh("C:/Users/rolle/Processor-Design-Based-on-FPGA/tests/load_store/lw_sw_test.hex",
                  uut.inst_ram_inst.mem, 0, 8);

        #20;
        rst_n = 1;
    end

    initial begin
        wait (debug_state == 8'd5);
        #20;

        $display("LOAD/STORE: mem0=%0d mem1=%0d x3=%0d x4=%0d x5=%0d",
                 uut.data_ram_inst.mem[0],
                 uut.data_ram_inst.mem[1],
                 uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[3],
                 uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[4],
                 uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[5]);

        if (uut.data_ram_inst.mem[0] !== 32'd42) errors = errors + 1;
        if (uut.data_ram_inst.mem[1] !== 32'd99) errors = errors + 1;
        if (uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[3] !== 32'd42) errors = errors + 1;
        if (uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[4] !== 32'd99) errors = errors + 1;
        if (uut.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[5] !== 32'd141) errors = errors + 1;

        if (errors == 0)
            $display("PASS: load/store test passed");
        else
            $display("FAIL: load/store test failed with %0d error(s)", errors);

        $finish;
    end

    initial begin
        #1200;
        $display("FAIL: load/store timeout pc=%08x state=%0d",
                 debug_pc, debug_state);
        $finish;
    end

endmodule
