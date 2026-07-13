`timescale 1ns/1ps

module tb_button_mmio;
    reg clk = 0;
    reg rst_n = 0;
    reg [4:0] btn = 0;
    reg bus_en = 0;
    reg bus_we = 0;
    reg [3:0] bus_addr = 0;
    reg [31:0] bus_wdata = 0;
    wire [31:0] bus_rdata;
    wire bus_ready;

    always #5 clk = ~clk;

    button_mmio #(.DEBOUNCE_CYCLES(3)) dut (
        .clk(clk), .rst_n(rst_n), .btn_in(btn), .bus_en(bus_en),
        .bus_we(bus_we), .bus_addr(bus_addr), .bus_wdata(bus_wdata),
        .bus_rdata(bus_rdata), .bus_ready(bus_ready)
    );

    task read_reg;
        input [3:0] addr;
        output [31:0] value;
        begin
            bus_en = 1; bus_we = 0; bus_addr = addr; #1;
            value = bus_rdata;
            @(posedge clk); #1; bus_en = 0;
        end
    endtask

    task ack;
        input [4:0] mask;
        begin
            bus_en = 1; bus_we = 1; bus_addr = 4'hC; bus_wdata = mask;
            @(posedge clk); #1; bus_en = 0; bus_we = 0;
        end
    endtask

    reg [31:0] value;
    initial begin
        repeat (3) @(posedge clk); rst_n = 1;

        // Mechanical bounce shorter than the debounce window.
        btn[2] = 1; @(posedge clk); btn[2] = 0; @(posedge clk);
        btn[2] = 1; @(posedge clk); btn[2] = 0; repeat (4) @(posedge clk);
        read_reg(4'h4, value);
        if (value != 0) $fatal(1, "bounce produced event: %h", value);

        btn[2] = 1; repeat (7) @(posedge clk);
        read_reg(4'h0, value);
        if (value[4:0] != 5'b00100) $fatal(1, "LEVEL wrong: %h", value);
        read_reg(4'h4, value);
        if (value[4:0] != 5'b00100) $fatal(1, "EDGE wrong: %h", value);
        read_reg(4'h8, value);
        if (value != 1) $fatal(1, "event count wrong: %h", value);

        // Holding the key must not generate more events.
        repeat (10) @(posedge clk);
        read_reg(4'h8, value);
        if (value != 1) $fatal(1, "held key repeated: %h", value);

        ack(5'b00100);
        read_reg(4'h4, value);
        if (value != 0) $fatal(1, "ACK failed: %h", value);
        read_reg(4'h0, value);
        if (value[2] != 1) $fatal(1, "ACK changed LEVEL");

        btn[2] = 0; repeat (7) @(posedge clk);
        $display("PASS: button_mmio debounce/level/edge/ack");
        $finish;
    end
endmodule
