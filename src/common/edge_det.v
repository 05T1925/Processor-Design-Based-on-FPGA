//==============================================================================
// edge_det.v - Edge Detector
//
// Based on: minisys_unified/rtl/common/edge_det.v
//
// Detects rising, falling, or any edge on the input signal.
//==============================================================================

module edge_det (
    input  wire clk,
    input  wire rst_n,
    input  wire sig_in,
    output wire pos_edge,     // Rising edge pulse
    output wire neg_edge,     // Falling edge pulse
    output wire any_edge      // Any edge pulse
);

    reg sig_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sig_d1 <= 1'b0;
        else
            sig_d1 <= sig_in;
    end

    assign pos_edge = sig_in && !sig_d1;
    assign neg_edge = !sig_in && sig_d1;
    assign any_edge = sig_in ^ sig_d1;

endmodule
