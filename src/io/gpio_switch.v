//==============================================================================
// gpio_switch.v - DIP Switch Input Peripheral
//
// Based on: minisys_unified/rtl/peripheral/gpio_switch.v
//
// 16-bit DIP switch input with 2-stage synchronizer. Read-only.
// Unified bus slave at address 0xFFFF_FC10.
//==============================================================================

module gpio_switch (
    input  wire        clk,
    input  wire        rst_n,

    // Bus slave interface
    input  wire        bus_en,
    input  wire        bus_we,
    input  wire [3:0]  bus_addr,
    input  wire [31:0] bus_wdata,
    output reg  [31:0] bus_rdata,
    output wire        bus_ready,

    // External switch inputs
    input  wire [15:0] sw_in
);

    // 2-stage synchronizer for metastability protection
    reg [15:0] sw_sync1;
    reg [15:0] sw_sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sw_sync1 <= 16'b0;
            sw_sync2 <= 16'b0;
        end else begin
            sw_sync1 <= sw_in;
            sw_sync2 <= sw_sync1;
        end
    end

    // Read response
    always @(*) begin
        bus_rdata = 32'h0000_0000;
        if (bus_en && !bus_we) begin
            case (bus_addr[3:0])
                4'h0: bus_rdata = {16'b0, sw_sync2};
                default: bus_rdata = 32'h0000_0000;
            endcase
        end
    end

    assign bus_ready = bus_en;

endmodule
