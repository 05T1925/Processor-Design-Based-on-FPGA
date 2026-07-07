`timescale 1ns / 1ps

module minisys_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire [7:0]  seg,
    output wire [7:0]  an
);

    wire rst = ~rst_n;

`ifdef MINISYS_USE_SOC_TOP
    wire [15:0] led_o;
    wire [7:0]  seg_data_o;
    wire [7:0]  seg_sel_o;

    soc_top u_soc_top (
        .clk(clk),
        .rst(rst),
        .sw_i(sw),
        .led_o(led_o),
        .seg_data_o(seg_data_o),
        .seg_sel_o(seg_sel_o)
    );

    assign led = led_o;
    assign seg = seg_data_o;
    assign an  = seg_sel_o;
`else
    reg [23:0] heartbeat_cnt;

    always @(posedge clk) begin
        if (rst) begin
            heartbeat_cnt <= 24'd0;
        end else begin
            heartbeat_cnt <= heartbeat_cnt + 24'd1;
        end
    end

    assign led = {heartbeat_cnt[23], 7'h00, sw[7:0]};
    assign seg = 8'hff;
    assign an  = 8'hff;
`endif

endmodule
