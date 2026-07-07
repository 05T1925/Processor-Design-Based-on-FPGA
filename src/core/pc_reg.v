//==============================================================================
// pc_reg.v - Program Counter (RV32I)
//
// Based on: SEU-Class2 pc.v + NCUT pc_reg.v
//
// Default: pc = pc + 4 (byte-addressable, word-aligned instructions)
// Branch/Jump: pc = next_pc (from alu_addr or {pc+4[31:28], J-imm})
//==============================================================================

`include "public.vh"

module pc_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        stall,              // Pipeline stall (unused in multi-cycle)

    input  wire        branch_taken,
    input  wire        jump,               // JAL
    input  wire        jump_reg,           // JALR

    input  wire [31:0] branch_target,      // PC-relative branch target
    input  wire [31:0] jump_target,        // JAL target
    input  wire [31:0] jump_reg_target,    // JALR target (rs1 + imm)

    output reg  [31:0] pc,
    output wire        ce                  // Instruction memory enable
);

    // ce is deasserted during reset, asserted otherwise
    always @(posedge clk) begin
        if (rst)       ce <= `DISABLE;
        else           ce <= `ENABLE;
    end

    // Next-PC logic
    wire [31:0] pc_plus_4 = pc + 32'd4;

    wire [31:0] next_pc;
    assign next_pc = jump_reg      ? {jump_reg_target[31:1], 1'b0} :  // JALR (LSB clear)
                     jump          ? jump_target :
                     branch_taken  ? branch_target :
                     pc_plus_4;

    always @(posedge clk) begin
        if (rst) begin
            pc <= `PC_INIT;
        end else if (!stall) begin
            pc <= next_pc;
        end
    end

endmodule
