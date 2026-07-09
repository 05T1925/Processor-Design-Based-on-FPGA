`timescale 1ns / 1ps

module tb_pipeline_basic;

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
        .CPU_MODE(5)                               // 5 = pipeline CPU
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

    always #5 clk = ~clk;                           // 100MHz

    initial begin
        clk = 0;
        rst_n = 0;
        sw = 16'h0000;
        uart_rx = 1'b1;

        // Clear instruction/data memories
        for (i = 0; i < 8192; i = i + 1) begin
            uut.inst_ram_inst.mem[i] = 32'h00000000;
            uut.data_ram_inst.mem[i] = 32'h00000000;
        end

        // Load basic test program (same as multi-cycle test)
        $readmemh(
            "sim/programs/basic_test.hex",
            uut.inst_ram_inst.mem,
            0,
            10
        );

        #20;
        rst_n = 1;
    end

    // Access pipeline CPU registers through the generate block
    wire [31:0] cpu_pc;
    wire        cpu_halted;
    wire [31:0] cpu_cycle;
    wire [31:0] cpu_instret;
    wire [31:0] reg_x3;
    wire [31:0] reg_x6;

    assign cpu_pc      = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.ibus_addr;
    assign cpu_cycle   = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.perf_cycle_count;
    assign cpu_instret = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.perf_instret_count;
    assign cpu_halted  = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.debug_state[4];

    // Register file access for verification
    assign reg_x3 = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.u_regfile.regs[3];
    assign reg_x6 = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.u_regfile.regs[6];

    // Check for halt and verify results
    initial begin
        // Wait for halt (timeout after 500 clock cycles)
        repeat (500) @(posedge clk);
        $display("TIMEOUT: Pipeline did not halt within 500 cycles");
        $display("debug_pc    = 0x%08X", debug_pc);
        $display("debug_state = 0x%02X", debug_state);
        $display("cpu_cycle   = %0d", cpu_cycle);
        $display("cpu_instret = %0d", cpu_instret);
        $display("data_ram[0x10000000] = 0x%08X", uut.data_ram_inst.mem[32'h10000000 >> 2]);
        $display("reg_x3 = 0x%08X", reg_x3);
        $display("reg_x6 = 0x%08X", reg_x6);
        $display("FAIL: timeout");
        $finish;
    end

    // Monitor for debug_state halt indication (state bit 4 = halted flag)
    wire halted_flag;
    assign halted_flag = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.debug_state[4];

    // Check for EBREAK in ID stage (cycle after which CPU will halt)
    reg halted_detected;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            halted_detected <= 0;
        else if (halted_flag)
            halted_detected <= 1;
    end

    // Wait a few cycles after halt detected, then check results
    reg [7:0] drain_count;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            drain_count <= 0;
        else if (halted_detected)
            drain_count <= drain_count + 1;
    end

    // After drain + a few extra cycles, verify results
    always @(posedge clk) begin
        if (drain_count == 8) begin
            $display("=== Pipeline Basic Test Results ===");
            $display("cpu_cycle   = %0d", cpu_cycle);
            $display("cpu_instret = %0d", cpu_instret);
            if (cpu_instret > 0)
                $display("CPI         = %0d/%0d = %.2f",
                         cpu_cycle, cpu_instret,
                         $itor(cpu_cycle) / $itor(cpu_instret));
            $display("data_ram[0x10000000] = 0x%08X",
                     uut.data_ram_inst.mem[32'h10000000 >> 2]);
            $display("reg_x3 = 0x%08X (expected 0x0000001E = 30)", reg_x3);
            $display("reg_x6 = 0x%08X (expected 0x0000001E = 30)", reg_x6);

            if (uut.data_ram_inst.mem[32'h10000000 >> 2] == 32'd30 &&
                reg_x3 == 32'd30 &&
                reg_x6 == 32'd30) begin
                $display("PASS: Pipeline CPU basic test passed");
            end else begin
                $display("FAIL: Pipeline CPU basic test failed");
            end
            $finish;
        end
    end

endmodule
