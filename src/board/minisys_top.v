//==============================================================================
// minisys_top.v - Minisys Board-Level Top Module
//==============================================================================

`timescale 1ns / 1ps
`include "../core/public.vh"

module minisys_top #(
    parameter CPU_MODE = `CPU_MODE_RISCV_MC
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire [7:0]  seg,
    output wire [7:0]  an
);

    wire [15:0] soc_led;
    wire [7:0]  soc_seg_an;
    wire [7:0]  soc_seg_cat;
    wire [31:0] debug_pc;
    wire [7:0]  debug_state;
    wire        sys_rst_n;

    assign sys_rst_n = ~rst_n;

    soc_top #(
        .CPU_MODE(CPU_MODE)
    ) u_soc_top (
        .clk         (clk),
        .rst_n       (sys_rst_n),
        .led         (soc_led),
        .sw          (sw),
        .seg_an      (soc_seg_an),
        .seg_cat     (soc_seg_cat),
        .uart_rx     (1'b1),
        .uart_tx     (),
        .debug_pc    (debug_pc),
        .debug_state (debug_state)
    );

    assign led = soc_led;
    assign seg = soc_seg_cat;
    assign an  = soc_seg_an;

endmodule
