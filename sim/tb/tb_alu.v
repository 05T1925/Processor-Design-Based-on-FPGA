`timescale 1ns / 1ps

`include "public.vh"

module tb_alu;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [`ALUOP_BUS]   alu_op;
    reg  [`ALUTYPE_BUS] alu_type;

    wire [31:0] result;
    wire        zero;

    integer errors;

    alu dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .alu_type(alu_type),
        .result(result),
        .zero(zero)
    );

    task check_result;
        input [31:0] in_a;
        input [31:0] in_b;
        input [`ALUOP_BUS] in_alu_op;
        input [`ALUTYPE_BUS] in_alu_type;
        input [31:0] expected_result;
        input expected_zero;
        input [127:0] test_name;
        begin
            a = in_a;
            b = in_b;
            alu_op = in_alu_op;
            alu_type = in_alu_type;
            #10;

            if (result !== expected_result || zero !== expected_zero) begin
                $display("FAIL: %s", test_name);
                $display("  a=%h b=%h alu_op=%h alu_type=%h", a, b, alu_op, alu_type);
                $display("  expected result=%h zero=%b", expected_result, expected_zero);
                $display("  actual   result=%h zero=%b", result, zero);
                errors = errors + 1;
            end else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin
        errors = 0;
        a = 0;
        b = 0;
        alu_op = 0;
        alu_type = 0;

        // ARITH
        check_result(32'd1, 32'd2, `ALUOP_ADD,  `ALUTYPE_ARITH, 32'd3, 1'b0, "ADD");
        check_result(32'd9, 32'd4, `ALUOP_SUB,  `ALUTYPE_ARITH, 32'd5, 1'b0, "SUB");
        check_result(32'd3, 32'd8, `ALUOP_SLT,  `ALUTYPE_ARITH, 32'd1, 1'b0, "SLT true");
        check_result(32'd9, 32'd2, `ALUOP_SLT,  `ALUTYPE_ARITH, 32'd0, 1'b1, "SLT false");
        check_result(32'h0000_0001, 32'hFFFF_FFFF, `ALUOP_SLTU, `ALUTYPE_ARITH, 32'd1, 1'b0, "SLTU true");

        // LOGIC
        check_result(32'hF0F0_0F0F, 32'h0FF0_FF00, `ALUOP_AND, `ALUTYPE_LOGIC, 32'h00F0_0F00, 1'b0, "AND");
        check_result(32'hF0F0_0F0F, 32'h0FF0_FF00, `ALUOP_OR,  `ALUTYPE_LOGIC, 32'hFFF0_FF0F, 1'b0, "OR");
        check_result(32'hAAAA_5555, 32'hFFFF_0000, `ALUOP_XOR, `ALUTYPE_LOGIC, 32'h5555_5555, 1'b0, "XOR");

        // SHIFT
        check_result(32'd4, 32'h0000_0003, `ALUOP_SLL, `ALUTYPE_SHIFT, 32'h0000_0030, 1'b0, "SLL");
        check_result(32'd3, 32'h0000_0040, `ALUOP_SRL, `ALUTYPE_SHIFT, 32'h0000_0008, 1'b0, "SRL");
        check_result(32'd3, 32'h8000_0000, `ALUOP_SRA, `ALUTYPE_SHIFT, 32'hF000_0000, 1'b0, "SRA");

        // MOVE
        check_result(32'h1234_5678, 32'hABCD_0000, `ALUOP_LUI,   `ALUTYPE_MOVE, 32'hABCD_0000, 1'b0, "LUI");
        check_result(32'h0000_1000, 32'h0000_2000, `ALUOP_AUIPC, `ALUTYPE_MOVE, 32'h0000_3000, 1'b0, "AUIPC");

        // JUMP
        check_result(32'h0000_1000, 32'h0000_0010, `ALUOP_ADD, `ALUTYPE_JUMP, 32'h0000_1010, 1'b0, "JUMP add");

        // MAC
        check_result(32'h1234_5678, 32'h8765_4321, `ALUOP_ADD, `ALUTYPE_MAC, 32'h1234_5678, 1'b0, "MAC pass-through");

        if (errors == 0) begin
            $display("ALL ALU TESTS PASSED");
        end else begin
            $display("ALU TESTS FAILED, errors = %0d", errors);
        end

        #1000;
        $finish;
    end

endmodule