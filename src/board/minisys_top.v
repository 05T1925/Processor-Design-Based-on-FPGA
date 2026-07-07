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
    wire [7:0] soc_led;

    soc_top u_soc_top (
        .clk(clk),
        .rst(rst),
        .sw(sw),
        .led(soc_led),
        .seg(seg),
        .an(an)
    );

    assign led = {8'h00, soc_led};
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
