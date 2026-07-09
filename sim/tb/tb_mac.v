`timescale 1ns / 1ps

module tb_mac;

    reg  [31:0] rs1_data;
    reg  [31:0] rs2_data;
    reg  [31:0] rd_old_data;
    wire [31:0] mac_result;

    integer errors;

    mac_unit uut (
        .rs1_data    (rs1_data),
        .rs2_data    (rs2_data),
        .rd_old_data (rd_old_data),
        .mac_result  (mac_result)
    );

    task check;
        input [31:0] a;
        input [31:0] b;
        input [31:0] acc;
        input [31:0] expected;
        input [8*32-1:0] name;
        begin
            rs1_data    = a;
            rs2_data    = b;
            rd_old_data = acc;
            #1;
            if (mac_result !== expected) begin
                $display("FAIL: %0s result=%08x expected=%08x",
                         name, mac_result, expected);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s result=%08x", name, mac_result);
            end
        end
    endtask

    initial begin
        errors = 0;
        rs1_data = 0;
        rs2_data = 0;
        rd_old_data = 0;

        check(32'd2, 32'd3, 32'd4, 32'd10, "positive multiply-accumulate");
        check(32'd0, 32'd123, 32'd9, 32'd9, "zero multiplier");
        check(-32'sd2, 32'd3, 32'd10, 32'd4, "signed negative multiply");
        check(32'hffff_ffff, 32'd2, 32'd0, 32'hffff_fffe,
              "low 32-bit product");
        check(32'd1, 32'd1, 32'hffff_ffff, 32'h0000_0000,
              "accumulator wraparound");

        check(32'd2, 32'd5, 32'd0, 32'd10, "accumulation step 1");
        check(32'd3, 32'd7, mac_result, 32'd31, "accumulation step 2");

        if (errors == 0)
            $display("ALL MAC TESTS PASSED");
        else
            $display("MAC TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
