//==============================================================================
// alu.v - RV32I Arithmetic Logic Unit
//
// Based on: SEU minisys (minisys-master) ALU classification + RV32I operations
//
// 6 operation categories: NOP, ARITH, LOGIC, MOVE, SHIFT, JUMP, MAC
//==============================================================================

`include "public.vh"

module alu (
    input  wire [31:0]        a,          // Operand A
    input  wire [31:0]        b,          // Operand B
    input  wire [`ALUOP_BUS]  alu_op,     // ALU operation
    input  wire [`ALUTYPE_BUS] alu_type,  // Operation category

    output reg  [31:0]        result,     // ALU result
    output wire               zero        // Result is zero flag
);

    assign zero = (result == 32'h0000_0000);

    always @(*) begin
        result = `ZERO_WORD;

        case (alu_type)
            `ALUTYPE_ARITH: begin
                case (alu_op)
                    `ALUOP_ADD:  result = $signed(a) + $signed(b);
                    `ALUOP_SUB:  result = $signed(a) - $signed(b);
                    `ALUOP_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
                    `ALUOP_SLTU: result = (a < b) ? 32'd1 : 32'd0;
                    default:     result = `ZERO_WORD;
                endcase
            end

            `ALUTYPE_LOGIC: begin
                case (alu_op)
                    `ALUOP_AND: result = a & b;
                    `ALUOP_OR:  result = a | b;
                    `ALUOP_XOR: result = a ^ b;
                    default:    result = `ZERO_WORD;
                endcase
            end

            `ALUTYPE_SHIFT: begin
                case (alu_op)
                    `ALUOP_SLL: result = b << a[4:0];
                    `ALUOP_SRL: result = b >> a[4:0];
                    `ALUOP_SRA: result = $signed(b) >>> a[4:0];
                    default:    result = `ZERO_WORD;
                endcase
            end

            `ALUTYPE_MOVE: begin
                case (alu_op)
                    `ALUOP_LUI:   result = b;             // Upper immediate
                    `ALUOP_AUIPC: result = a + b;         // PC + upper immediate
                    default:      result = `ZERO_WORD;
                endcase
            end

            `ALUTYPE_JUMP: begin
                result = a + b;     // PC + offset for JAL/JALR/branch
            end

            `ALUTYPE_MAC: begin
                result = a;         // MAC result handled by mac_unit
            end

            default: result = `ZERO_WORD;
        endcase
    end

endmodule
