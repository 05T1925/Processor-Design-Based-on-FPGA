`timescale 1ns / 1ps

module tb_dot_product;

    reg clk;
    reg rst_n;
    integer i;
    integer errors;

    wire [31:0] normal_pc;
    wire [7:0]  normal_state;
    wire [31:0] mac_pc;
    wire [7:0]  mac_state;

    soc_top normal_soc (
        .clk(clk),
        .rst_n(rst_n),
        .led(),
        .sw(16'b0),
        .seg_an(),
        .seg_cat(),
        .uart_rx(1'b1),
        .uart_tx(),
        .debug_pc(normal_pc),
        .debug_state(normal_state)
    );

    soc_top mac_soc (
        .clk(clk),
        .rst_n(rst_n),
        .led(),
        .sw(16'b0),
        .seg_an(),
        .seg_cat(),
        .uart_rx(1'b1),
        .uart_tx(),
        .debug_pc(mac_pc),
        .debug_state(mac_state)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        errors = 0;

        for (i = 0; i < 8192; i = i + 1) begin
            normal_soc.inst_ram_inst.mem[i] = 32'b0;
            normal_soc.data_ram_inst.mem[i] = 32'b0;
            mac_soc.inst_ram_inst.mem[i] = 32'b0;
            mac_soc.data_ram_inst.mem[i] = 32'b0;
        end

        $readmemh("tests/mac/dot_normal.hex",
                  normal_soc.inst_ram_inst.mem, 0, 15);
        $readmemh("tests/mac/dot_mac.hex",
                  mac_soc.inst_ram_inst.mem, 0, 13);

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst_n = 1;
    end

    initial begin
        wait ((normal_state == 8'd5) && (mac_state == 8'd5));
        #20;

        $display("NORMAL: result=%0d cycle=%0d instret=%0d mac=%0d",
                 normal_soc.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[10],
                 normal_soc.perf_cycle_count,
                 normal_soc.perf_instret_count,
                 normal_soc.perf_mac_count);
        $display("MAC:    result=%0d cycle=%0d instret=%0d mac=%0d",
                 mac_soc.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[10],
                 mac_soc.perf_cycle_count,
                 mac_soc.perf_instret_count,
                 mac_soc.perf_mac_count);

        if (normal_soc.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[10] !== 32'd70) begin
            $display("FAIL: normal dot-product result");
            errors = errors + 1;
        end
        if (mac_soc.cpu_top_inst.gen_riscv_mc.riscv_mc_inst.u_cpu.u_regfile.regs[10] !== 32'd70) begin
            $display("FAIL: MAC dot-product result");
            errors = errors + 1;
        end
        if (normal_soc.perf_instret_count !== 32'd15) begin
            $display("FAIL: normal instret=%0d expected=15",
                     normal_soc.perf_instret_count);
            errors = errors + 1;
        end
        if (mac_soc.perf_instret_count !== 32'd13) begin
            $display("FAIL: MAC instret=%0d expected=13",
                     mac_soc.perf_instret_count);
            errors = errors + 1;
        end
        if (normal_soc.perf_mac_count !== 32'd0) begin
            $display("FAIL: normal mac_count=%0d expected=0",
                     normal_soc.perf_mac_count);
            errors = errors + 1;
        end
        if (mac_soc.perf_mac_count !== 32'd4) begin
            $display("FAIL: MAC mac_count=%0d expected=4",
                     mac_soc.perf_mac_count);
            errors = errors + 1;
        end
        if (mac_soc.perf_cycle_count >= normal_soc.perf_cycle_count) begin
            $display("FAIL: MAC cycle count is not lower");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL DOT-PRODUCT TESTS PASSED");
        else
            $display("DOT-PRODUCT TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

    initial begin
        #5000;
        $display("FAIL: dot-product timeout normal_state=%0d mac_state=%0d",
                 normal_state, mac_state);
        $finish;
    end

endmodule
