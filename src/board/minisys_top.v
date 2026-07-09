//==============================================================================
// minisys_top.v - Minisys Board-Level Top Module
//
// Based on: minisys_unified/rtl/top/top_minisys.v
// Adapted for: Minisys FPGA + EES-329B-V1.1, Xilinx Artix-7 XC7A100T
//
// Converts board-level rst_n (active-low) to internal rst (active-high).
// Selects between:
//   - UNIFIED_SOC: Full unified SoC with CPU + memory + bus + peripherals
//   - HEARTBEAT: Simple heartbeat placeholder for testing
//
// Pin mapping verified against constraints/minisys.xdc.
//==============================================================================

`timescale 1ns / 1ps
`include "../core/public.vh"

module minisys_top #(
    parameter CPU_MODE = `CPU_MODE_RISCV_MC   // CPU core selection
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire [7:0]  seg,
    output wire [7:0]  an
);

    //==========================================================================
    // Reset conversion: board rst_n (active-low) → internal rst (active-high)
    //==========================================================================
    wire rst = ~rst_n;

//==========================================================================
// Simple Heartbeat Placeholder (testing / board verification)
//==========================================================================
`ifdef MINISYS_USE_HEARTBEAT

    reg [23:0] heartbeat_cnt;

    always @(posedge clk) begin
        if (rst) begin
            heartbeat_cnt <= 24'd0;
        end else begin
            heartbeat_cnt <= heartbeat_cnt + 24'd1;
        end
    end

    // Show heartbeat on LED[7], display switch state on LED[7:0]
    assign led = {heartbeat_cnt[23], 7'h00, sw[7:0]};
    assign seg = 8'hFF;
    assign an  = 8'hFF;

//==========================================================================
// Unified SoC Mode (default)
//==========================================================================
`else

    // Clock and reset
    wire sys_clk  = clk;
    wire sys_rst_n = rst_n;

    // SoC integration
    wire [15:0] soc_led;
    wire [15:0] soc_sw;
    wire [7:0]  soc_seg_an;
    wire [7:0]  soc_seg_cat;
    wire [31:0] debug_pc;
    wire [7:0]  debug_state;

    assign soc_sw = sw;

    soc_top #(
        .CPU_MODE(CPU_MODE)
    ) u_soc_top (
        .clk            (sys_clk),
        .rst_n          (sys_rst_n),
        .led            (soc_led),
        .sw             (soc_sw),
        .seg_an         (soc_seg_an),
        .seg_cat        (soc_seg_cat),
        .uart_rx        (1'b1),
        .uart_tx        (),
        .debug_pc       (debug_pc),
        .debug_state    (debug_state)
    );

    assign led = soc_led;
    assign seg = soc_seg_cat;
    assign an  = soc_seg_an;

`endif

endmodule
