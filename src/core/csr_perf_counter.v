//==============================================================================
// csr_perf_counter.v - Performance Counters (RV32I CSR Style)
//
// Three counters exposed via MMIO:
//   cycle_count    (0xFFFF_FCB0): increments each clock while CPU is running
//   instret_count  (0xFFFF_FCB4): increments on instruction retirement
//   mac_count      (0xFFFF_FCB8): increments on MAC instruction execution
//
// Counters stop when CPU enters HALT state.
//==============================================================================

`include "public.vh"

module csr_perf_counter (
    input  wire        clk,
    input  wire        rst,

    // Control inputs from CPU
    input  wire        halted,           // CPU halted (stops cycle counter)
    input  wire        instret_pulse,    // 1-cycle pulse: instruction retired
    input  wire        mac_pulse,        // 1-cycle pulse: MAC completed

    // Counter values (exposed via MMIO read)
    output wire [31:0] cycle_count,
    output wire [31:0] instret_count,
    output wire [31:0] mac_count
);

    reg [31:0] cycle_cnt;
    reg [31:0] instret_cnt;
    reg [31:0] mac_cnt;

    // cycle_count: increments every clock unless halted
    always @(posedge clk) begin
        if (rst) begin
            cycle_cnt <= 32'd0;
        end else if (!halted) begin
            cycle_cnt <= cycle_cnt + 32'd1;
        end
    end

    // instret_count: increments on instruction retirement pulse
    always @(posedge clk) begin
        if (rst) begin
            instret_cnt <= 32'd0;
        end else if (instret_pulse) begin
            instret_cnt <= instret_cnt + 32'd1;
        end
    end

    // mac_count: increments on MAC execution pulse
    always @(posedge clk) begin
        if (rst) begin
            mac_cnt <= 32'd0;
        end else if (mac_pulse) begin
            mac_cnt <= mac_cnt + 32'd1;
        end
    end

    assign cycle_count   = cycle_cnt;
    assign instret_count = instret_cnt;
    assign mac_count     = mac_cnt;

endmodule
