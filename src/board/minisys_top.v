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
    input  wire [4:0]  btn,
    input  wire [15:0] sw,
    input  wire [3:0]  kbd_col_n,
    output wire [3:0]  kbd_row_n,
    output wire [15:0] led,
    output wire [7:0]  seg,
    output wire [7:0]  an,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    output wire        vga_hsync,
    output wire        vga_vsync
);

    wire [15:0] soc_led;
    wire [7:0]  soc_seg_an;
    wire [7:0]  soc_seg_cat;
    wire [31:0] debug_pc;
    wire [7:0]  debug_state;
    wire        sys_rst_n;
    wire        board_test_mode;
    wire [15:0] btn_demo_led;

    assign sys_rst_n = ~rst_n;
    assign board_test_mode = sw[15];

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

    // Board I/O bring-up:
    //   SW15 = 0 -> preserve the original SoC LED behavior
    //   SW15 = 1 -> show button/VGA demo state on LEDs
    assign led = board_test_mode
               ? btn_demo_led
               : soc_led;
    assign seg = soc_seg_cat;
    assign an  = soc_seg_an;

    // Keep keypad lines inactive now that input testing has moved to the
    // verified push-buttons.
    assign kbd_row_n = 4'b1111;

    vga_button_demo u_vga_button_demo (
        .clk       (clk),
        .rst_n     (sys_rst_n),
        .btn       (btn),
        .vga_r     (vga_r),
        .vga_g     (vga_g),
        .vga_b     (vga_b),
        .vga_hsync (vga_hsync),
        .vga_vsync (vga_vsync),
        .debug_led (btn_demo_led)
    );

endmodule
