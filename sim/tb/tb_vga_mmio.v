`timescale 1ns/1ps

module tb_vga_mmio;
    reg clk = 0, rst_n = 0, bus_en = 0, bus_we = 0;
    reg [3:0] bus_addr = 0;
    reg [31:0] bus_wdata = 0;
    wire [31:0] bus_rdata;
    wire bus_ready;
    wire [2:0] page;
    wire [3:0] game_state, hint, selected;
    wire [31:0] guess, attempts, cycles, instret, cpi_x100, ipc_x100;
    wire [31:0] mips_x10, mac_count, branches, branch_miss, stalls, flushes;
    wire [31:0] pred_acc_x100, bus_op, bus_addr_trace, bus_wdata_trace;
    wire [31:0] bus_rdata_trace, bus_device, last_button, bench_id;
    wire [31:0] bench_normal, bench_mac, speedup_x100, x3_guess, x4_target;
    wire [31:0] bench_status;
    wire [31:0] x5_count, trace_pc, trace_instr, trace_stage, write_count;
    always #5 clk = ~clk;

    vga_mmio_regs dut (
        .clk(clk), .rst_n(rst_n), .bus_en(bus_en), .bus_we(bus_we),
        .bus_addr(bus_addr), .bus_wdata(bus_wdata), .bus_rdata(bus_rdata),
        .bus_ready(bus_ready), .page(page), .game_state(game_state),
        .guess(guess), .attempts(attempts), .hint(hint), .selected(selected),
        .cycles(cycles), .instret(instret), .cpi_x100(cpi_x100),
        .ipc_x100(ipc_x100), .mips_x10(mips_x10), .mac_count(mac_count),
        .branches(branches), .branch_miss(branch_miss), .stalls(stalls),
        .flushes(flushes), .pred_acc_x100(pred_acc_x100), .bus_op(bus_op),
        .bus_addr_trace(bus_addr_trace), .bus_wdata_trace(bus_wdata_trace),
        .bus_rdata_trace(bus_rdata_trace), .bus_device(bus_device),
        .last_button(last_button), .bench_id(bench_id),
        .bench_normal(bench_normal), .bench_mac(bench_mac),
        .speedup_x100(speedup_x100), .x3_guess(x3_guess),
        .bench_status(bench_status),
        .x4_target(x4_target), .x5_count(x5_count), .trace_pc(trace_pc),
        .trace_instr(trace_instr), .trace_stage(trace_stage),
        .write_count(write_count)
    );

    task write_reg;
        input [3:0] addr;
        input [31:0] value;
        begin
            bus_en=1; bus_we=1; bus_addr=addr; bus_wdata=value;
            @(posedge clk); #1; bus_en=0; bus_we=0;
        end
    endtask

    task write_field;
        input [7:0] field_id;
        input [31:0] value;
        begin
            write_reg(4'h0, value);
            write_reg(4'h4, {23'b0, 1'b1, field_id});
        end
    endtask

    initial begin
        repeat (3) @(posedge clk); rst_n=1;
        write_field(8'd2, 32'h0000_0037);
        if (guess !== 32'h37) $fatal(1, "GUESS field failed");
        write_field(8'd3, 32'd5);
        if (attempts !== 5) $fatal(1, "ATTEMPTS field failed");
        write_field(8'd0, 32'd4);
        if (page !== 4) $fatal(1, "PAGE field failed");

        write_field(8'd200, 32'hDEAD_BEEF);
        if (guess !== 32'h37 || attempts !== 5 || page !== 4)
            $fatal(1, "illegal field corrupted shadow state");
        if (write_count !== 4) $fatal(1, "write count wrong: %0d", write_count);

        $display("PASS: vga_mmio command/data shadow registers");
        $finish;
    end
endmodule
