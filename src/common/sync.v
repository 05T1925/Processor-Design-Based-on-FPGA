//==============================================================================
// sync.v - Parameterized N-Stage Synchronizer
//
// Based on: minisys_unified/rtl/common/sync.v
//
// Prevents metastability by synchronizing async input through N flip-flops.
// Default: 2-stage (N=2).
//==============================================================================

module sync #(
    parameter STAGES = 2,
    parameter WIDTH  = 1
) (
    input  wire              clk,
    input  wire              rst_n,
    input  wire [WIDTH-1:0]  async_in,
    output wire [WIDTH-1:0]  sync_out
);

    reg [WIDTH-1:0] shift_reg [0:STAGES-1];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < STAGES; i = i + 1)
                shift_reg[i] <= {WIDTH{1'b0}};
        end else begin
            shift_reg[0] <= async_in;
            for (i = 1; i < STAGES; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
        end
    end

    assign sync_out = shift_reg[STAGES-1];

endmodule
