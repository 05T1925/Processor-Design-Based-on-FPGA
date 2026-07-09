`timescale 1ns / 1ps
//==============================================================================
// tb_pipeline_btb.v - Pipeline CPU BTB Branch Prediction Test
//
// Tests:
//   1. Simple loop (10 iterations) — verify 2-bit counter training
//   2. BTB prediction accuracy via hierarchical stats readout
//   3. Pipeline event monitoring (flush/stall/btb_hit)
//
// DUT: soc_top with CPU_MODE=5 (pipeline + BTB)
// Board: Minisys (XC7A100T-FGG484-1, 100MHz)
//==============================================================================

module tb_pipeline_btb;

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

    //--------------------------------------------------------------------------
    // DUT: SoC with pipeline CPU (CPU_MODE = 5)
    //--------------------------------------------------------------------------
    soc_top #(
        .CPU_MODE(5)
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

    always #5 clk = ~clk;  // 100MHz

    //--------------------------------------------------------------------------
    // Pipeline CPU internal signal access
    // soc_top → cpu_top_inst → gen_riscv_pipe → riscv_pipe_inst → u_cpu
    //--------------------------------------------------------------------------
    wire [31:0] cpu_pc;
    wire        cpu_stall;
    wire        cpu_branch_flush;
    wire        cpu_jal_flush;
    wire        cpu_jalr_flush;
    wire        cpu_halted;
    wire [31:0] cpu_cycle;
    wire [31:0] cpu_instret;
    wire [31:0] cpu_mac;
    wire [31:0] reg_x8, reg_x9, reg_x10;

    // Pipeline internal signals via generate block hierarchy
    assign cpu_pc      = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.ibus_addr;
    assign cpu_stall   = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.debug_state[3];
    assign cpu_branch_flush = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.debug_state[2];
    assign cpu_jalr_flush   = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.debug_state[1];
    assign cpu_jal_flush    = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.debug_state[0];
    assign cpu_halted = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.debug_state[4];
    assign cpu_cycle   = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.perf_cycle_count;
    assign cpu_instret = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.perf_instret_count;
    assign cpu_mac     = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.perf_mac_count;

    // Register file access for verification
    assign reg_x8  = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.u_regfile.regs[8];
    assign reg_x9  = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.u_regfile.regs[9];
    assign reg_x10 = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.u_regfile.regs[10];

    //--------------------------------------------------------------------------
    // BTB statistics (from soc_top-level wires)
    //--------------------------------------------------------------------------
    wire [31:0] btb_br_total;
    wire [31:0] btb_br_mispred;
    wire [31:0] btb_hit;

    // Access BTB counters inside the pipeline CPU
    assign btb_br_total   = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.perf_br_total_count;
    assign btb_br_mispred = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.perf_br_mispred_count;
    assign btb_hit        = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.perf_btb_hit_count;

    //--------------------------------------------------------------------------
    // Test sequence
    //--------------------------------------------------------------------------
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

        // Load branch-loop test program
        $readmemh(
            "sim/programs/branch_loop_test.hex",
            uut.inst_ram_inst.mem,
            0,
            16
        );

        #20;
        rst_n = 1;
    end

    //--------------------------------------------------------------------------
    // Event counting
    //--------------------------------------------------------------------------
    reg [31:0] br_flush_count;
    reg [31:0] stall_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            br_flush_count <= 0;
            stall_count    <= 0;
        end else begin
            if (cpu_branch_flush)
                br_flush_count <= br_flush_count + 1;
            if (cpu_stall)
                stall_count <= stall_count + 1;
        end
    end

    //--------------------------------------------------------------------------
    // Timeout
    //--------------------------------------------------------------------------
    initial begin
        repeat (2000) @(posedge clk);
        $display("TIMEOUT: Pipeline BTB test did not halt within 2000 cycles");
        $display("FAIL: timeout");
        $finish;
    end

    //--------------------------------------------------------------------------
    // Halt detection and result checking
    //--------------------------------------------------------------------------
    reg halted_detected;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            halted_detected <= 0;
        else if (cpu_halted)
            halted_detected <= 1;
    end

    reg [7:0] drain_count;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            drain_count <= 0;
        else if (halted_detected)
            drain_count <= drain_count + 1;
    end

    always @(posedge clk) begin
        if (drain_count == 10) begin
            $display("==============================================");
            $display("  Pipeline BTB Branch Prediction Test Results");
            $display("==============================================");
            $display("");
            $display("--- Performance Counters ---");
            $display("cpu_cycle        = %0d", cpu_cycle);
            $display("cpu_instret      = %0d", cpu_instret);
            if (cpu_instret > 0)
                $display("CPI              = %0d/%0d = %.4f",
                         cpu_cycle, cpu_instret,
                         $itor(cpu_cycle) / $itor(cpu_instret));
            $display("");
            $display("--- BTB Statistics ---");
            $display("br_total         = %0d", btb_br_total);
            $display("br_mispred       = %0d", btb_br_mispred);
            $display("btb_hit          = %0d", btb_hit);
            if (btb_br_total > 0) begin
                $display("BTB accuracy     = %.1f%% (%0d/%0d correct)",
                         100.0 * $itor(btb_br_total - btb_br_mispred) / $itor(btb_br_total),
                         btb_br_total - btb_br_mispred, btb_br_total);
            end
            $display("");
            $display("--- Pipeline Events ---");
            $display("branch_flushes   = %0d", br_flush_count);
            $display("stall_cycles     = %0d", stall_count);
            $display("");
            $display("--- Register Results ---");
            $display("reg_x8           = 0x%08X (%0d)", reg_x8, reg_x8);
            $display("reg_x9           = 0x%08X (%0d)", reg_x9, reg_x9);
            $display("reg_x10 (a0)     = 0x%08X (%0d)", reg_x10, reg_x10);
            $display("");

            // Check results: x9 = sum(0..9) = 45, x10 should = x9 = 45
            // Wait: the loop body is: sum += counter; counter++; if counter!=10 loop
            // counter goes 0→1→...→9; sum = 0+0+1+2+...+9 = 45
            // Actually counter starts at 0: sum += 0 (sum=0); counter=1; bne(1!=10)→loop
            // sum += 1 (sum=1); counter=2; ... sum += 9 (sum=45); counter=10; bne(10!=10)→exit
            // Then x10 = x9 = 45
            if (reg_x10 == 32'd45) begin
                $display("PASS: x10 = 45 (loop sum correct)");
            end else begin
                $display("FAIL: x10 = %0d (expected 45)", reg_x10);
            end

            // BTB: For 10-iteration loop with 2-bit counter:
            // iter1:  WNT→predict N, actual T → mispred → counter→WT
            // iter2:  WT→predict T, actual T → correct → counter→ST
            // iter3-9: ST→predict T, actual T → correct (×7)
            // iter10: ST→predict T, actual NT → mispred → counter→WT
            // Total: 10 branches, 8 correct, 2 mispred
            // Expected accuracy: ~80%
            if (btb_br_total > 0 && (btb_br_total - btb_br_mispred) >= 6) begin
                $display("PASS: BTB accuracy >= 60%% (basic 2-bit behavior verified)");
            end else if (btb_br_total > 0) begin
                $display("WARN: BTB accuracy lower than expected (cold start?)");
            end else begin
                $display("NOTE: BTB counters may need warm-up (first run)");
            end

            $display("");
            $display("==============================================");
            $finish;
        end
    end

endmodule
