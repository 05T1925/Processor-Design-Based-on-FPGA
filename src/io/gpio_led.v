//==============================================================================
// gpio_led.v - LED Output Peripheral
//
// Based on: minisys_unified/rtl/peripheral/gpio_led.v
//
// 16-bit LED output register. Write-only.
// Unified bus slave at address 0xFFFF_FC00.
//==============================================================================

module gpio_led (
    input  wire        clk,
    input  wire        rst_n,

    // Bus slave interface
    input  wire        bus_en,
    input  wire        bus_we,
    input  wire [3:0]  bus_addr,
    input  wire [31:0] bus_wdata,
    output reg  [31:0] bus_rdata,
    output wire        bus_ready,

    // External LED outputs
    output reg  [15:0] led_out
);

    // LED register (write-only, reads back current state)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_out <= 16'b0;
        end else if (bus_en && bus_we && (bus_addr[3:0] == 4'h0)) begin
            led_out <= bus_wdata[15:0];
        end
    end

    // Read response
    always @(*) begin
        bus_rdata = 32'h0000_0000;
        if (bus_en && !bus_we) begin
            case (bus_addr[3:0])
                4'h0: bus_rdata = {16'b0, led_out};
                default: bus_rdata = 32'h0000_0000;
            endcase
        end
    end

    assign bus_ready = bus_en;

endmodule
