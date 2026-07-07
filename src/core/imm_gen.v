//==============================================================================
// imm_gen.v - RV32I Immediate Generator
//
// Generates sign-extended 32-bit immediates for all RV32I instruction formats:
// I-type, S-type, B-type, U-type, J-type
//==============================================================================

`include "public.vh"

module imm_gen (
    input  wire [31:0] instr,           // Full 32-bit instruction
    input  wire [2:0]  imm_sel,         // Immediate type selection

    output reg  [31:0] imm              // Sign-extended 32-bit immediate
);

    //--------------------------------------------------------------------------
    // Immediate type encoding (imm_sel)
    //   3'b000: I-type  (ADDI, LW, JALR, etc.)
    //   3'b001: S-type  (SW)
    //   3'b010: B-type  (BEQ, BNE, etc.)
    //   3'b011: U-type  (LUI, AUIPC)
    //   3'b100: J-type  (JAL)
    //--------------------------------------------------------------------------
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;

    always @(*) begin
        case (imm_sel)
            IMM_I: imm = {{20{instr[31]}}, instr[31:20]};
            IMM_S: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            IMM_B: imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            IMM_U: imm = {instr[31:12], 12'b0};
            IMM_J: imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            default: imm = `ZERO_WORD;
        endcase
    end

endmodule
