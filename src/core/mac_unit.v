//==============================================================================
// mac_unit.v - MAC Multiply-Accumulate Unit (RV32I Custom Instruction)
//
// Custom instruction: MAC rd, rs1, rs2
//   Semantics: rd_new = rd_old + rs1 * rs2
//   Encoding:  funct7=0000001, rs2, rs1, funct3=000, rd, opcode=0001011
//
// Combinational implementation. First version takes low 32 bits of product.
// Synthesis will infer DSP48E1 on Artix-7.
//==============================================================================

`include "public.vh"

module mac_unit (
    input  wire [31:0] rs1_data,        // Multiplier A
    input  wire [31:0] rs2_data,        // Multiplier B
    input  wire [31:0] rd_old_data,     // Accumulator input (rd old value)

    output wire [31:0] mac_result       // rd_old + (rs1 * rs2)[31:0]
);

    // Full 64-bit multiply, take lower 32 bits for accumulation
    wire [63:0] product;
    assign product = $signed(rs1_data) * $signed(rs2_data);

    // Accumulate: rd_old + product[31:0]
    assign mac_result = rd_old_data + product[31:0];

endmodule
