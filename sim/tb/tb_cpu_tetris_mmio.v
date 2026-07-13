`timescale 1ns/1ps

module tb_cpu_tetris_mmio;
    reg clk = 0;
    reg rst_n = 0;
    reg [4:0] btn = 0;
    reg [15:0] sw = 16'h0004;
    wire [15:0] led;
    wire [7:0] seg_an, seg_cat;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync, uart_tx;
    wire [31:0] debug_pc;
    wire [7:0] debug_state;

    always #5 clk = ~clk;

    soc_top #(
        .CPU_MODE(0), .SYS_CLK_FREQ(300),
        .INST_INIT_FILE("C:/Users/28641/Desktop/Project-based Curriculum Stage/tests/demo/cpu_guess_game.hex")
    ) dut (
        .clk(clk), .rst_n(rst_n), .led(led), .sw(sw), .btn(btn),
        .seg_an(seg_an), .seg_cat(seg_cat), .vga_r(vga_r), .vga_g(vga_g),
        .vga_b(vga_b), .vga_hsync(vga_hsync), .vga_vsync(vga_vsync),
        .uart_rx(1'b1), .uart_tx(uart_tx), .debug_pc(debug_pc),
        .debug_state(debug_state)
    );

    task press_key;
        input integer bit_index;
        integer timeout;
        begin
            btn[bit_index] = 1'b1;
            repeat (8) @(posedge clk);
            btn[bit_index] = 1'b0;
            repeat (8) @(posedge clk);
            timeout = 0;
            while (dut.button_mmio_inst.edge_latched != 0 && timeout < 5000) begin
                @(posedge clk); timeout = timeout + 1;
            end
            if (timeout >= 5000) $fatal(1, "Tetris button ACK timeout");
            repeat (12) @(posedge clk);
        end
    endtask

    integer timeout;
    integer i;
    initial begin
        repeat (5) @(posedge clk); rst_n = 1;
        timeout = 0;
        while ((dut.vga_page != 4 || dut.vga_tetris_state != 1) && timeout < 20000) begin
            @(posedge clk); timeout = timeout + 1;
        end
        if (timeout >= 20000) $fatal(1, "Tetris initialization timeout pc=%h", debug_pc);
        if (dut.vga_tetris_x != 3 || dut.vga_tetris_y != 0)
            $fatal(1, "bad spawn x=%0d y=%0d", dut.vga_tetris_x, dut.vga_tetris_y);

        press_key(0);
        if (dut.vga_tetris_x != 2) $fatal(1, "left failed");
        press_key(0);
        press_key(0);
        if (dut.vga_tetris_x != 0) $fatal(1, "left edge failed x=%0d", dut.vga_tetris_x);
        press_key(3);
        if (dut.vga_tetris_rotation != 1) $fatal(1, "rotate failed");
        press_key(2);
        if (dut.vga_tetris_y != 1) $fatal(1, "soft drop failed");
        press_key(4);
        if (dut.vga_tetris_state != 2) $fatal(1, "pause failed");
        press_key(4);
        if (dut.vga_tetris_state != 1) $fatal(1, "resume failed");

        for (i = 0; i < 18; i = i + 1) press_key(2);
        if (dut.vga_tetris_lock_count == 0 || dut.vga_tetris_score != 10)
            $fatal(1, "lock/score failed locks=%0d score=%0d x=%0d y=%0d rot=%0d coll=%0d pc=%h",
                   dut.vga_tetris_lock_count, dut.vga_tetris_score,
                   dut.vga_tetris_x, dut.vga_tetris_y, dut.vga_tetris_rotation,
                   dut.vga_tetris_collision, debug_pc);

        // Pause then S3 performs a real restart and clears score/board state.
        press_key(4);
        press_key(2);
        if (dut.vga_tetris_state != 1 || dut.vga_tetris_score != 0 ||
            dut.vga_tetris_clear_count == 0)
            $fatal(1, "restart failed state=%0d score=%0d clears=%0d",
                   dut.vga_tetris_state, dut.vga_tetris_score,
                   dut.vga_tetris_clear_count);

        $display("PASS: SW=100 -> CPU Tetris input/state -> VGA MMIO");
        $finish;
    end
endmodule
