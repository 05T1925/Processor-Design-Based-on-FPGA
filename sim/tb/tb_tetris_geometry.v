`timescale 1ns/1ps

module tb_tetris_geometry;
    reg clk = 0, rst_n = 0;
    reg [2:0] page = 4;
    reg [4:0] tx = 3, ty = 0;
    reg [2:0] piece = 1, next_piece = 2, state = 1;
    reg [1:0] rotation = 0;
    wire collision;
    always #5 clk = ~clk;

    vga_dashboard #(.CLK_FREQ_HZ(1000), .PERF_REFRESH_HZ(1)) dut (
        .clk(clk), .rst_n(rst_n), .page(page),
        .game_state(0), .guess(0), .attempts(0), .hint(0), .selected(0),
        .cycles(0), .instret(0), .cpi_x100(0), .ipc_x100(0), .mips_x10(0),
        .mac_count(0), .branches(0), .branch_miss(0), .pred_acc_x100(0),
        .bus_op(0), .bus_addr_trace(0), .bus_wdata_trace(0),
        .bus_rdata_trace(0), .bus_device(0), .last_button(0), .bench_id(0),
        .bench_normal(0), .bench_mac(0), .speedup_x100(0), .bench_status(0),
        .write_count(0), .x3_guess(0), .x5_count(0), .x4_target(0),
        .tap_pc(0), .tap_instr(0), .tap_stage(0),
        .tetris_x(tx), .tetris_y(ty), .tetris_piece(piece),
        .tetris_next(next_piece), .tetris_rotation(rotation),
        .tetris_score(0), .tetris_state(state), .tetris_lock_count(0),
        .tetris_clear_count(0), .live_cycle_count(0), .live_instret_count(0),
        .tetris_collision(collision)
    );

    integer p, r, x, y, cells, max_y;
    initial begin
        repeat (3) @(posedge clk); rst_n = 1;
        for (p = 1; p <= 7; p = p + 1) begin
            for (r = 0; r < 4; r = r + 1) begin
                piece = p; rotation = r; cells = 0; max_y = 0;
                for (y = 0; y < 4; y = y + 1)
                    for (x = 0; x < 4; x = x + 1)
                        if (dut.piece_cell(p, r, x, y)) begin
                            cells = cells + 1;
                            if (y > max_y) max_y = y;
                        end
                if (cells != 4)
                    $fatal(1, "piece %0d rotation %0d has %0d cells", p, r, cells);
                ty = 19 - max_y; #1;
                if (collision) $fatal(1, "piece %0d rot %0d cannot reach bottom", p, r);
                ty = 20 - max_y; #1;
                if (!collision) $fatal(1, "piece %0d rot %0d passed bottom", p, r);
                ty = 0;
            end
        end
        dut.tetris_board_rows[19] = 10'h3FF;
        repeat (25) @(posedge clk);
        if (dut.tetris_board_rows[19] != 0 || dut.cleared_lines != 1)
            $fatal(1, "full-row clear failed row=%h lines=%0d",
                   dut.tetris_board_rows[19], dut.cleared_lines);
        $display("PASS: all 7 pieces x 4 rotations retain four cells and reach row 19");
        $finish;
    end
endmodule
