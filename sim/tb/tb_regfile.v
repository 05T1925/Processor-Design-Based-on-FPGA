`timescale 1ns / 1ps
`include "public.vh"

module tb_regfile;

    reg clk;
    reg rst;
    reg [`REG_ADDR_WIDTH-1:0] rs1_addr;
    reg [`REG_ADDR_WIDTH-1:0] rs2_addr;
    reg [`REG_ADDR_WIDTH-1:0] rd_old_addr;
    reg reg_write;
    reg [`REG_ADDR_WIDTH-1:0] rd_addr;
    reg [31:0] rd_wdata;

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] rd_old_data;

    regfile uut (
        .clk(clk),
        .rst(rst),
        .rs1_addr(rs1_addr),
        .rs1_data(rs1_data),
        .rs2_addr(rs2_addr),
        .rs2_data(rs2_data),
        .rd_old_addr(rd_old_addr),
        .rd_old_data(rd_old_data),
        .reg_write(reg_write),
        .rd_addr(rd_addr),
        .rd_wdata(rd_wdata)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        rs1_addr = 0;
        rs2_addr = 0;
        rd_old_addr = 0;
        reg_write = 0;
        rd_addr = 0;
        rd_wdata = 0;

        #20;
        rst = 0;

        // Test 1: x0 must always be zero
        reg_write = 1;
        rd_addr = 0;
        rd_wdata = 32'h12345678;
        rs1_addr = 0;
        #1;
        if (rs1_data !== 32'h00000000)
            $display("FAIL: x0 is not zero");
        else
            $display("PASS: x0 remains zero");

        #9;

        // Test 2: write x1 and read back
        reg_write = 1;
        rd_addr = 1;
        rd_wdata = 32'hA5A5A5A5;
        #10;

        reg_write = 0;
        rs1_addr = 1;
        #1;
        if (rs1_data !== 32'hA5A5A5A5)
            $display("FAIL: write/read x1");
        else
            $display("PASS: write/read x1");

        #9;

        // Test 3: write x2 and read from rs2
        reg_write = 1;
        rd_addr = 2;
        rd_wdata = 32'h5A5A5A5A;
        #10;

        reg_write = 0;
        rs2_addr = 2;
        #1;
        if (rs2_data !== 32'h5A5A5A5A)
            $display("FAIL: write/read x2");
        else
            $display("PASS: write/read x2");

        #9;

        // Test 4: read rd_old_data from x1
        rd_old_addr = 1;
        #1;
        if (rd_old_data !== 32'hA5A5A5A5)
            $display("FAIL: read rd_old_data");
        else
            $display("PASS: read rd_old_data");

        #9;

        // Test 5: forwarding on rs1
        reg_write = 1;
        rd_addr = 3;
        rd_wdata = 32'h11112222;
        rs1_addr = 3;
        #1;
        if (rs1_data !== 32'h11112222)
            $display("FAIL: forwarding rs1");
        else
            $display("PASS: forwarding rs1");

        #9;

        // Test 6: forwarding on rs2
        reg_write = 1;
        rd_addr = 4;
        rd_wdata = 32'h33334444;
        rs2_addr = 4;
        #1;
        if (rs2_data !== 32'h33334444)
            $display("FAIL: forwarding rs2");
        else
            $display("PASS: forwarding rs2");

        #9;

        // Test 7: forwarding on rd_old
        reg_write = 1;
        rd_addr = 5;
        rd_wdata = 32'h55556666;
        rd_old_addr = 5;
        #1;
        if (rd_old_data !== 32'h55556666)
            $display("FAIL: forwarding rd_old");
        else
            $display("PASS: forwarding rd_old");

        #9;
        $display("ALL REGFILE TESTS FINISHED");
        $finish;
    end

endmodule