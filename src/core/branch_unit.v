//==============================================================================
// branch_unit.v - RV32I Branch Condition Evaluator
//
// Evaluates BEQ, BNE, BLT, BGE, BLTU, BGEU conditions.
//==============================================================================

`include "public.vh"

module branch_unit (
    input  wire [31:0] rs1_data,
    input  wire [31:0] rs2_data,
    input  wire [2:0]  funct3,

    output reg         branch_taken
);

    always @(*) begin
        case (funct3)
            `RV_F3_BEQ:  branch_taken = (rs1_data == rs2_data);
            `RV_F3_BNE:  branch_taken = (rs1_data != rs2_data);
            `RV_F3_BLT:  branch_taken = ($signed(rs1_data) < $signed(rs2_data));
            `RV_F3_BGE:  branch_taken = ($signed(rs1_data) >= $signed(rs2_data));
            `RV_F3_BLTU: branch_taken = (rs1_data < rs2_data);
            `RV_F3_BGEU: branch_taken = (rs1_data >= rs2_data);
            default:      branch_taken = 1'b0;
        endcase
    end

endmodule
