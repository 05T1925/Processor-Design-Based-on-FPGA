`timescale 1ns / 1ps

module tb_pipeline_hazard;
    reg clk;
    reg rst_n;
    reg [15:0] sw;
    reg uart_rx;

    wire [15:0] led;
    wire [7:0] seg_an;
    wire [7:0] seg_cat;
    wire uart_tx;
    wire [31:0] debug_pc;
    wire [7:0] debug_state;

    integer i;
    integer forward_exmem_count;
    integer forward_memwb_count;
    integer load_stall_count;
    integer branch_flush_count;
    integer jal_flush_count;
    integer jalr_flush_count;
    reg test_done;

    soc_top #(.CPU_MODE(5)) uut (
        .clk(clk), .rst_n(rst_n), .led(led), .sw(sw),
        .seg_an(seg_an), .seg_cat(seg_cat),
        .uart_rx(uart_rx), .uart_tx(uart_tx),
        .debug_pc(debug_pc), .debug_state(debug_state)
    );

    always #5 clk = ~clk;

    wire halted = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.debug_state[4];
    wire [1:0] forward_rs1_sel = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.forward_rs1_sel;
    wire [1:0] forward_rs2_sel = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.forward_rs2_sel;
    wire load_use_hazard = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.load_use_hazard;
    wire branch_flush = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.branch_flush;
    wire jal_flush = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.jal_flush;
    wire jalr_flush = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.jalr_flush;
    wire [31:0] cycle_count = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.perf_cycle_count;
    wire [31:0] instret_count = uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.perf_instret_count;

    initial begin
        clk = 0;
        rst_n = 0;
        sw = 0;
        uart_rx = 1;
        forward_exmem_count = 0;
        forward_memwb_count = 0;
        load_stall_count = 0;
        branch_flush_count = 0;
        jal_flush_count = 0;
        jalr_flush_count = 0;
        test_done = 0;

        for (i = 0; i < 8192; i = i + 1) begin
            uut.inst_ram_inst.mem[i] = 32'h0000_0000;
            uut.data_ram_inst.mem[i] = 32'h0000_0000;
        end
        $readmemh(
            "C:/Users/rolle/Processor-Design-Based-on-FPGA/tests/pipeline/hazard_test.hex",
            uut.inst_ram_inst.mem,
            0,
            23
        );
        #20 rst_n = 1;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            if (forward_rs1_sel == 2'b01 || forward_rs2_sel == 2'b01)
                forward_exmem_count = forward_exmem_count + 1;
            if (forward_rs1_sel == 2'b10 || forward_rs2_sel == 2'b10)
                forward_memwb_count = forward_memwb_count + 1;
            if (load_use_hazard)
                load_stall_count = load_stall_count + 1;
            if (branch_flush)
                branch_flush_count = branch_flush_count + 1;
            if (jal_flush)
                jal_flush_count = jal_flush_count + 1;
            if (jalr_flush)
                jalr_flush_count = jalr_flush_count + 1;
        end
    end

    task report_results;
    begin
        $display("=== Pipeline Hazard Test Results ===");
        $display("cycle_count         = %0d", cycle_count);
        $display("instret_count       = %0d", instret_count);
        $display("EX/MEM forwards     = %0d", forward_exmem_count);
        $display("MEM/WB forwards     = %0d", forward_memwb_count);
        $display("load-use stalls     = %0d", load_stall_count);
        $display("branch flushes      = %0d", branch_flush_count);
        $display("JAL flushes         = %0d", jal_flush_count);
        $display("JALR flushes        = %0d", jalr_flush_count);
        for (i = 0; i < 8; i = i + 1)
            $display("data_ram[%0d] = 0x%08X", i, uut.data_ram_inst.mem[i]);

        if (uut.data_ram_inst.mem[0] == 32'd5  &&
            uut.data_ram_inst.mem[1] == 32'd8  &&
            uut.data_ram_inst.mem[2] == 32'd9  &&
            uut.data_ram_inst.mem[3] == 32'd15 &&
            uut.data_ram_inst.mem[4] == 32'd0  &&
            uut.data_ram_inst.mem[5] == 32'd42 &&
            uut.data_ram_inst.mem[6] == 32'd0  &&
            uut.data_ram_inst.mem[7] == 32'd88 &&
            forward_exmem_count > 0 &&
            forward_memwb_count > 0 &&
            load_stall_count == 1 &&
            branch_flush_count > 0 &&
            jal_flush_count > 0) begin
            $display("PASS: Pipeline hazard handling passed");
        end else begin
            $display("FAIL: Pipeline hazard handling failed");
        end
        test_done = 1'b1;
    end
    endtask

    reg halt_seen;
    reg [3:0] drain_count;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            halt_seen <= 1'b0;
            drain_count <= 4'd0;
        end else begin
            if (debug_state[4])
                halt_seen <= 1'b1;
            if (halt_seen)
                drain_count <= drain_count + 1'b1;
            if (drain_count == 4'd8)
                report_results;
        end
    end

    // Keep $finish in a normal procedural block so Vivado can resolve the
    // source location correctly when the simulation ends.
    always @(posedge clk) begin
        if (test_done)
            $finish;
    end

    initial begin
        repeat (1000) @(posedge clk);
        if (test_done)
            $finish;
        $display("FAIL: Pipeline hazard test timeout");
        $display("debug_pc            = 0x%08X", debug_pc);
        $display("debug_state         = 0x%02X", debug_state);
        $display("cycle_count         = %0d", cycle_count);
        $display("instret_count       = %0d", instret_count);
        $display("IF/ID pc,instr      = 0x%08X 0x%08X",
                 uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.if_id_pc,
                 uut.cpu_top_inst.gen_riscv_pipe.riscv_pipe_inst.u_cpu.if_id_instr);
        $display("EX/MEM forwards     = %0d", forward_exmem_count);
        $display("MEM/WB forwards     = %0d", forward_memwb_count);
        $display("load-use stalls     = %0d", load_stall_count);
        $display("branch flushes      = %0d", branch_flush_count);
        $display("JAL flushes         = %0d", jal_flush_count);
        $display("JALR flushes        = %0d", jalr_flush_count);
        for (i = 0; i < 8; i = i + 1)
            $display("data_ram[%0d] = 0x%08X", i, uut.data_ram_inst.mem[i]);
        $finish;
    end
endmodule
