//==============================================================================
// debounce.v - Button Debounce Module
//
// Based on: minisys_unified/rtl/common/debounce.v
//
// 20ms debounce period at 50 MHz (~1,000,000 cycles).
//==============================================================================

module debounce #(
    parameter DEBOUNCE_CYCLES = 1000000    // 20ms @ 50MHz
) (
    input  wire clk,
    input  wire rst_n,
    input  wire key_in,           // Raw button input
    output wire key_out           // Debounced output
);

    reg [19:0] counter;           // 20-bit counter for ~1M cycles
    reg        key_state;
    reg        key_stable;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter    <= 20'd0;
            key_state  <= 1'b1;
            key_stable <= 1'b1;
        end else begin
            if (key_in != key_state) begin
                counter   <= counter + 20'd1;
                if (counter >= DEBOUNCE_CYCLES) begin
                    key_state  <= key_in;
                    key_stable <= key_in;
                    counter    <= 20'd0;
                end
            end else begin
                counter <= 20'd0;
            end
        end
    end

    assign key_out = key_stable;

endmodule
