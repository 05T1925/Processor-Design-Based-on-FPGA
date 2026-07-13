//==============================================================================
// vga_mmio_regs.v - CPU-owned VGA shadow registers
//
// The CPU writes WDATA first, then writes CMD with a field id.  The renderer
// only sees these shadow registers; it has no button or game decision input.
// Slot base: 0xFFFF_FC40
//   +0x0 WDATA   write staging value
//   +0x4 CMD     field id in [7:0], commit in bit 8
//   +0x8 CTRL    page/control bits
//   +0xC STATUS  read-only status
//==============================================================================

`timescale 1ns / 1ps

module vga_mmio_regs (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        bus_en,
    input  wire        bus_we,
    input  wire [3:0]  bus_addr,
    input  wire [31:0] bus_wdata,
    input  wire        tetris_collision,
    output reg  [31:0] bus_rdata,
    output wire        bus_ready,

    output reg  [2:0]  page,
    output reg  [3:0]  game_state,
    output reg  [31:0] guess,
    output reg  [31:0] attempts,
    output reg  [3:0]  hint,
    output reg  [3:0]  selected,
    output reg  [31:0] cycles,
    output reg  [31:0] instret,
    output reg  [31:0] cpi_x100,
    output reg  [31:0] ipc_x100,
    output reg  [31:0] mips_x10,
    output reg  [31:0] mac_count,
    output reg  [31:0] branches,
    output reg  [31:0] branch_miss,
    output reg  [31:0] stalls,
    output reg  [31:0] flushes,
    output reg  [31:0] pred_acc_x100,
    output reg  [31:0] bus_op,
    output reg  [31:0] bus_addr_trace,
    output reg  [31:0] bus_wdata_trace,
    output reg  [31:0] bus_rdata_trace,
    output reg  [31:0] bus_device,
    output reg  [31:0] last_button,
    output reg  [31:0] bench_id,
    output reg  [31:0] bench_normal,
    output reg  [31:0] bench_mac,
    output reg  [31:0] speedup_x100,
    output reg  [31:0] bench_status,
    output reg  [31:0] x3_guess,
    output reg  [31:0] x4_target,
    output reg  [31:0] x5_count,
    output reg  [31:0] trace_pc,
    output reg  [31:0] trace_instr,
    output reg  [31:0] trace_stage,
    output reg  [31:0] write_count,
    output reg  [4:0]  tetris_x,
    output reg  [4:0]  tetris_y,
    output reg  [2:0]  tetris_piece,
    output reg  [2:0]  tetris_next,
    output reg  [1:0]  tetris_rotation,
    output reg  [31:0] tetris_score,
    output reg  [2:0]  tetris_state,
    output reg  [31:0] tetris_lock_count,
    output reg  [31:0] tetris_clear_count,
    output reg  [31:0] tetris_speed
);

    reg [31:0] wdata_reg;
    reg [7:0] last_field;
    reg [31:0] ctrl_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            page <= 3'd0; game_state <= 4'd0; guess <= 0; attempts <= 0;
            hint <= 0; selected <= 0; cycles <= 0; instret <= 0;
            cpi_x100 <= 0; ipc_x100 <= 0; mips_x10 <= 0; mac_count <= 0;
            branches <= 0; branch_miss <= 0; stalls <= 0; flushes <= 0;
            pred_acc_x100 <= 0; bus_op <= 0; bus_addr_trace <= 0;
            bus_wdata_trace <= 0; bus_rdata_trace <= 0; bus_device <= 0;
            last_button <= 0; bench_id <= 0; bench_normal <= 0;
            bench_mac <= 0; speedup_x100 <= 0; bench_status <= 0; x3_guess <= 0;
            x4_target <= 0; x5_count <= 0; trace_pc <= 0;
            trace_instr <= 0; trace_stage <= 0; write_count <= 0;
            tetris_x <= 0; tetris_y <= 0; tetris_piece <= 1;
            tetris_next <= 2; tetris_rotation <= 0; tetris_score <= 0;
            tetris_state <= 0; tetris_lock_count <= 0; tetris_clear_count <= 0;
            tetris_speed <= 0;
            wdata_reg <= 0; last_field <= 0; ctrl_reg <= 0;
        end else if (bus_en && bus_we) begin
            case (bus_addr)
                4'h0: wdata_reg <= bus_wdata;
                4'h4: begin
                    last_field <= bus_wdata[7:0];
                    if (bus_wdata[8]) begin
                        case (bus_wdata[7:0])
                            8'd0:  page <= wdata_reg[2:0];
                            8'd1:  game_state <= wdata_reg[3:0];
                            8'd2:  guess <= wdata_reg;
                            8'd3:  attempts <= wdata_reg;
                            8'd4:  hint <= wdata_reg[3:0];
                            8'd5:  selected <= wdata_reg[3:0];
                            8'd7:  cycles <= wdata_reg;
                            8'd8:  instret <= wdata_reg;
                            8'd9:  cpi_x100 <= wdata_reg;
                            8'd10: ipc_x100 <= wdata_reg;
                            8'd11: mips_x10 <= wdata_reg;
                            8'd12: mac_count <= wdata_reg;
                            8'd13: branches <= wdata_reg;
                            8'd14: branch_miss <= wdata_reg;
                            8'd15: stalls <= wdata_reg;
                            8'd16: flushes <= wdata_reg;
                            8'd17: pred_acc_x100 <= wdata_reg;
                            8'd18: bus_op <= wdata_reg;
                            8'd19: bus_addr_trace <= wdata_reg;
                            8'd20: bus_wdata_trace <= wdata_reg;
                            8'd21: bus_rdata_trace <= wdata_reg;
                            8'd22: bus_device <= wdata_reg;
                            8'd23: last_button <= wdata_reg;
                            8'd24: bench_id <= wdata_reg;
                            8'd25: bench_normal <= wdata_reg;
                            8'd26: bench_mac <= wdata_reg;
                            8'd27: speedup_x100 <= wdata_reg;
                            8'd28: bench_status <= wdata_reg;
                            8'd29: x3_guess <= wdata_reg;
                            8'd30: x4_target <= wdata_reg;
                            8'd31: x5_count <= wdata_reg;
                            8'd32: trace_pc <= wdata_reg;
                            8'd33: trace_instr <= wdata_reg;
                            8'd34: trace_stage <= wdata_reg;
                            8'd40: tetris_x <= wdata_reg[4:0];
                            8'd41: tetris_y <= wdata_reg[4:0];
                            8'd42: tetris_piece <= wdata_reg[2:0];
                            8'd43: tetris_next <= wdata_reg[2:0];
                            8'd44: tetris_score <= wdata_reg;
                            8'd45: tetris_state <= wdata_reg[2:0];
                            8'd46: tetris_rotation <= wdata_reg[1:0];
                            8'd47: tetris_lock_count <= tetris_lock_count + 1'b1;
                            8'd48: tetris_clear_count <= tetris_clear_count + 1'b1;
                            8'd49: tetris_speed <= wdata_reg;
                            default: ;
                        endcase
                        write_count <= write_count + 1'b1;
                    end
                end
                4'h8: ctrl_reg <= bus_wdata;
                default: ;
            endcase
        end
    end

    always @(*) begin
        bus_rdata = 32'b0;
        if (bus_en && !bus_we) begin
            case (bus_addr)
                4'h0: bus_rdata = wdata_reg;
                4'h4: bus_rdata = {24'b0, last_field};
                4'h8: bus_rdata = ctrl_reg;
                4'hC: bus_rdata = {write_count[15:0], 6'b0, page, 5'b0,
                                    tetris_collision, 1'b1};
                default: bus_rdata = 32'b0;
            endcase
        end
    end

    assign bus_ready = bus_en;

endmodule
