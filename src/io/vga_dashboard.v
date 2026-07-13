//==============================================================================
// vga_dashboard.v - 640x480 CPU/MMIO game and performance dashboard
//
// TRACE ONLY inputs (tap_pc/tap_instr/tap_stage) are visual observers.  They do
// not participate in game state, button handling, or MMIO register updates.
//==============================================================================

`timescale 1ns / 1ps

module vga_dashboard #(
    parameter integer CPU_MODE = 0,
    parameter integer CLK_FREQ_HZ = 100_000_000,
    // Board default: one stable performance snapshot per second.
    // A positive value is retained for accelerated simulation tests.
    parameter integer PERF_REFRESH_HZ = 1
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  page,
    input  wire [3:0]  game_state,
    input  wire [31:0] guess,
    input  wire [31:0] attempts,
    input  wire [3:0]  hint,
    input  wire [3:0]  selected,
    input  wire [31:0] cycles,
    input  wire [31:0] instret,
    input  wire [31:0] cpi_x100,
    input  wire [31:0] ipc_x100,
    input  wire [31:0] mips_x10,
    input  wire [31:0] mac_count,
    input  wire [31:0] branches,
    input  wire [31:0] branch_miss,
    input  wire [31:0] pred_acc_x100,
    input  wire [31:0] bus_op,
    input  wire [31:0] bus_addr_trace,
    input  wire [31:0] bus_wdata_trace,
    input  wire [31:0] bus_rdata_trace,
    input  wire [31:0] bus_device,
    input  wire [31:0] last_button,
    input  wire [31:0] bench_id,
    input  wire [31:0] bench_normal,
    input  wire [31:0] bench_mac,
    input  wire [31:0] speedup_x100,
    input  wire [31:0] bench_status,
    input  wire [31:0] write_count,
    input  wire [31:0] x3_guess,
    input  wire [31:0] x5_count,
    input  wire [31:0] x4_target,
    input  wire [31:0] tap_pc,
    input  wire [31:0] tap_instr,
    input  wire [7:0]  tap_stage,
    input  wire [4:0]  tetris_x,
    input  wire [4:0]  tetris_y,
    input  wire [2:0]  tetris_piece,
    input  wire [2:0]  tetris_next,
    input  wire [1:0]  tetris_rotation,
    input  wire [31:0] tetris_score,
    input  wire [2:0]  tetris_state,
    input  wire [31:0] tetris_lock_count,
    input  wire [31:0] tetris_clear_count,
    input  wire [31:0] tetris_speed,
    input  wire [31:0] live_cycle_count,
    input  wire [31:0] live_instret_count,
    output reg         tetris_collision,
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b,
    output wire        vga_hsync,
    output wire        vga_vsync
);

    reg [1:0] pix_div;
    reg [9:0] h_cnt;
    reg [9:0] v_cnt;
    wire pix_tick = (pix_div == 2'd3);
    wire h_last = (h_cnt == 10'd799);
    wire v_last = (v_cnt == 10'd524);
    wire video_on = (h_cnt < 10'd640) && (v_cnt < 10'd480);
    wire frame_start = pix_tick && h_last && v_last;

    localparam [32:0] PERF_TICKS = (PERF_REFRESH_HZ > 0) ?
                                    CLK_FREQ_HZ / PERF_REFRESH_HZ :
                                    33'd60 * CLK_FREQ_HZ;
    reg [32:0] perf_tick_count;
    reg [31:0] pending_cycles, pending_instret, pending_cpi, pending_ipc;
    reg [31:0] pending_mips, pending_mac, pending_branches, pending_miss;
    reg [31:0] pending_pred, pending_writes;
    reg [31:0] pending_bench_normal, pending_bench_mac, pending_speedup;
    reg [31:0] pending_bench_status, pending_pc, pending_instr, pending_stage;
    reg [31:0] disp_cycles, disp_instret, disp_cpi, disp_ipc;
    reg [31:0] disp_mips, disp_mac, disp_branches, disp_miss;
    reg [31:0] disp_pred, disp_writes;
    reg [31:0] disp_bench_normal, disp_bench_mac, disp_speedup;
    reg [31:0] disp_bench_status, disp_pc, disp_instr, disp_stage;
    reg [2:0] disp_page;
    reg [3:0] disp_state, disp_hint, disp_selected;
    reg [31:0] disp_guess, disp_attempts, disp_target;
    reg [15:0] cleared_lines;
    reg [31:0] tetris_prev_cycles, tetris_prev_instret;
    reg [31:0] tetris_live_mips;
    wire [31:0] tetris_inst_delta = live_instret_count - tetris_prev_instret;
    // 42 / 2^22 approximates 1 / 100000 with +0.14% error at 100 MHz.
    wire [37:0] tetris_mips_scaled = ({6'b0, tetris_inst_delta} << 5) +
                                      ({6'b0, tetris_inst_delta} << 3) +
                                      ({6'b0, tetris_inst_delta} << 1);

    // Counters continue running at CPU speed. Their display copies are sampled
    // once per second and committed together at the start of a VGA frame.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            perf_tick_count <= 0;
            pending_cycles <= 0; pending_instret <= 0; pending_cpi <= 0;
            pending_ipc <= 0; pending_mips <= 0; pending_mac <= 0;
            pending_branches <= 0; pending_miss <= 0; pending_pred <= 0;
            pending_writes <= 0;
            pending_bench_normal <= 0; pending_bench_mac <= 0;
            pending_speedup <= 0; pending_bench_status <= 0;
            pending_pc <= 0; pending_instr <= 0; pending_stage <= 0;
            disp_cycles <= 0; disp_instret <= 0; disp_cpi <= 0;
            disp_ipc <= 0; disp_mips <= 0; disp_mac <= 0;
            disp_branches <= 0; disp_miss <= 0; disp_pred <= 0;
            disp_writes <= 0; disp_page <= 0; disp_state <= 0;
            disp_bench_normal <= 0; disp_bench_mac <= 0;
            disp_speedup <= 0; disp_bench_status <= 0;
            disp_pc <= 0; disp_instr <= 0; disp_stage <= 0;
            disp_hint <= 0; disp_selected <= 0; disp_guess <= 0;
            disp_attempts <= 0; disp_target <= 0;
            tetris_prev_cycles <= 0; tetris_prev_instret <= 0;
            tetris_live_mips <= 0;
        end else begin
            if (perf_tick_count == PERF_TICKS - 1) begin
                perf_tick_count <= 0;
                pending_cycles <= cycles; pending_instret <= instret;
                pending_cpi <= cpi_x100; pending_ipc <= ipc_x100;
                pending_mips <= mips_x10; pending_mac <= mac_count;
                pending_branches <= branches; pending_miss <= branch_miss;
                pending_pred <= pred_acc_x100; pending_writes <= write_count;
                pending_bench_normal <= bench_normal;
                pending_bench_mac <= bench_mac;
                pending_speedup <= speedup_x100;
                pending_bench_status <= bench_status;
                pending_pc <= tap_pc;
                pending_instr <= tap_instr;
                pending_stage <= {24'b0, tap_stage};
                tetris_live_mips <= {16'b0, tetris_mips_scaled[37:22]};
                tetris_prev_cycles <= live_cycle_count;
                tetris_prev_instret <= live_instret_count;
            end else begin
                perf_tick_count <= perf_tick_count + 1'b1;
            end
            // User-triggered benchmark transitions should be visible on the
            // next frame without changing the periodic live-counter cadence.
            if (bench_status != pending_bench_status ||
                bench_normal != pending_bench_normal ||
                bench_mac != pending_bench_mac ||
                speedup_x100 != pending_speedup) begin
                pending_bench_normal <= bench_normal;
                pending_bench_mac <= bench_mac;
                pending_speedup <= speedup_x100;
                pending_bench_status <= bench_status;
            end
            if (frame_start) begin
                disp_page <= page; disp_state <= game_state; disp_hint <= hint;
                disp_selected <= selected; disp_guess <= guess;
                disp_attempts <= attempts; disp_target <= x4_target;
                disp_cycles <= pending_cycles; disp_instret <= pending_instret;
                disp_cpi <= pending_cpi; disp_ipc <= pending_ipc;
                disp_mips <= pending_mips; disp_mac <= pending_mac;
                disp_branches <= pending_branches; disp_miss <= pending_miss;
                disp_pred <= pending_pred; disp_writes <= pending_writes;
                disp_bench_normal <= pending_bench_normal;
                disp_bench_mac <= pending_bench_mac;
                disp_speedup <= pending_speedup;
                disp_bench_status <= pending_bench_status;
                disp_pc <= pending_pc;
                disp_instr <= pending_instr;
                disp_stage <= pending_stage;
            end
        end
    end

    assign vga_hsync = ~((h_cnt >= 10'd656) && (h_cnt < 10'd752));
    assign vga_vsync = ~((v_cnt >= 10'd490) && (v_cnt < 10'd492));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pix_div <= 0; h_cnt <= 0; v_cnt <= 0;
        end else begin
            pix_div <= pix_div + 1'b1;
            if (pix_tick) begin
                if (h_last) begin
                    h_cnt <= 0;
                    if (v_last) v_cnt <= 0;
                    else v_cnt <= v_cnt + 1'b1;
                end else h_cnt <= h_cnt + 1'b1;
            end
        end
    end

    function [7:0] str_char;
        input [127:0] text;
        input integer index;
        reg [127:0] shifted_text;
        begin
            shifted_text = text >> ((15-index) * 8);
            str_char = shifted_text[7:0];
        end
    endfunction

    function [7:0] hex_char;
        input [3:0] nibble;
        begin
            hex_char = (nibble < 10) ? ("0" + nibble) : ("A" + nibble - 10);
        end
    endfunction

    function [7:0] word_hex_char;
        input [31:0] value;
        input integer index;
        reg [31:0] shifted_value;
        begin
            shifted_value = value >> ((7-index) * 4);
            word_hex_char = hex_char(shifted_value[3:0]);
        end
    endfunction

    function [7:0] decimal4_char;
        input [31:0] value;
        input integer index;
        begin
            case (index)
                0: decimal4_char = hex_char((value / 1000) % 10);
                1: decimal4_char = hex_char((value / 100) % 10);
                2: decimal4_char = hex_char((value / 10) % 10);
                3: decimal4_char = hex_char(value % 10);
                default: decimal4_char = " ";
            endcase
        end
    endfunction

    function [7:0] na_char;
        input integer index;
        begin
            case (index)
                0: na_char = "N";
                1: na_char = "/";
                2: na_char = "A";
                default: na_char = " ";
            endcase
        end
    endfunction

    function [7:0] dashboard_char;
        input [2:0] p;
        input [5:0] row;
        input [6:0] col;
        reg [127:0] label;
        reg [31:0] value;
        integer base;
        begin
            dashboard_char = " "; label = "                "; value = 0; base = 20;
            case (p)
                2'd0: begin
                    case (row)
                        6'd2:  label = "CPU NUMBER GUESS";
                        6'd6:  label = "GUESS THE NUMBER";
                        6'd33: begin
                            if (disp_hint == 1) label = "TOO LOW";
                            else if (disp_hint == 2) label = "TOO HIGH";
                            else if (disp_hint == 3) label = "CORRECT";
                            else label = "READY";
                        end
                        6'd38: begin label = "ATTEMPTS"; value = disp_attempts; end
                        6'd42: label = (disp_hint == 3) ? "TARGET REVEALED" : "TARGET HIDDEN";
                        6'd50: label = "S1 LEFT S2 RIGHT";
                        6'd52: label = "S3 PLUS S4 MINUS";
                        6'd54: label = "S5 CONFIRM";
                        6'd57: label = "BTN MMIO LW CPU";
                        6'd59: label = "CPU SW VGA";
                        default: ;
                    endcase
                end
                2'd1: begin
                    case (row)
                        6'd2:  label = "CPU REGISTER SNAP";
                        6'd5:  label = "ONE SECOND HOLD";
                        6'd9:  label = (CPU_MODE == 5) ? "MODE PIPE" : "MODE MULTI";
                        6'd13: begin label = "PC"; value = disp_pc; end
                        6'd17: begin label = "INSTR"; value = disp_instr; end
                        6'd21: begin label = "STAGE"; value = disp_stage; end
                        6'd27: begin label = "X3 GUESS"; value = x3_guess; end
                        6'd31: begin label = "X4 TARGET"; value = x4_target; end
                        6'd35: begin label = "X5 TRY"; value = x5_count; end
                        6'd41: begin label = "X6 DIGIT"; value = {28'b0, disp_selected}; end
                        6'd45: begin label = "X7 STATE"; value = {28'b0, disp_state}; end
                        6'd49: begin label = "X8 HINT"; value = {28'b0, disp_hint}; end
                        6'd56: label = "CPU WRITES VGA MMIO";
                        default: ;
                    endcase
                end
                2'd2: begin
                    case (row)
                        6'd2:  label = "CPU EFFICIENCY";
                        6'd5:  label = (disp_bench_status == 0) ? "PRESS S5 RUN TEST" :
                                      (bench_id == 0) ? "BRANCH COMPLETE" :
                                       (bench_id == 1) ? "MEMORY COMPLETE" :
                                       (bench_id == 2) ? "MAC BENCH COMPLETE" : "MIXED BENCH DONE";
                        6'd10: label = (disp_bench_status == 0) ? "MIPS X10" : "SPEEDUP X100";
                        6'd22: begin label = "CPI X100"; value = disp_cpi; end
                        6'd26: begin label = "IPC X100"; value = disp_ipc; end
                        6'd31: begin label = "NORMAL CYC"; value = disp_bench_normal; end
                        6'd35: begin label = "MAC CYC"; value = disp_bench_mac; end
                        6'd39: begin label = "MAC COUNT"; value = disp_mac; end
                        6'd45: begin label = "INSTRET"; value = disp_instret; end
                        6'd49: begin label = "CYCLES"; value = disp_cycles; end
                        6'd55: begin label = "VGA WRITES"; value = disp_writes; end
                        6'd59: label = "CPU SAMPLE 1S HOLD";
                        default: ;
                    endcase
                end
                3'd3: begin
                    case (row)
                        6'd2:  label = "BUS TRACE";
                        6'd7:  begin label = "LAST OP"; value = bus_op; end
                        6'd11: begin label = "BUS ADDR"; value = bus_addr_trace; end
                        6'd15: begin label = "WRITE DATA"; value = bus_wdata_trace; end
                        6'd19: begin label = "READ DATA"; value = bus_rdata_trace; end
                        6'd23: begin label = "DEVICE"; value = bus_device; end
                        6'd27: begin label = "LAST BTN"; value = last_button; end
                        6'd34: label = "BTN MMIO LW CPU";
                        6'd36: label = "BRANCH SW VGA";
                        default: ;
                    endcase
                end
                3'd4: begin
                    case (row)
                        6'd2:  label = "CPU TETRIS";
                        6'd5:  label = "NEXT PIECE";
                        6'd10: label = (tetris_state == 3) ? "GAME OVER RESTART" : "                ";
                        6'd16: begin label = "SCORE"; value = tetris_score; end
                        6'd20: begin label = "LINES"; value = {16'b0, cleared_lines}; end
                        6'd24: label = (tetris_state == 2) ? "PAUSED" :
                                         (tetris_state == 3) ? "GAME OVER" : "RUNNING";
                        6'd28: begin label = "MIPS X10"; value = tetris_live_mips; end
                        6'd32: begin label = "CPU CYCLES"; value = live_cycle_count; end
                        6'd36: label = (CPU_MODE == 5) ? "CPU PIPELINE" : "CPU MULTI FSM";
                        6'd38: begin label = "SPEED LV"; value = tetris_speed; end
                        6'd41: label = "S1 LEFT S2 RIGHT";
                        6'd45: label = "S3 DROP S4 ROTATE";
                        6'd49: label = "S5 PAUSE RESUME";
                        6'd53: label = "PAUSE S3 RESTART";
                        6'd57: label = "CPU MMIO VGA";
                        default: ;
                    endcase
                end
                default: ;
            endcase

            if (col >= 2 && col < 18)
                dashboard_char = str_char(label, col - 2);
            if (((p == 0 && row == 38) ||
                 (p == 1 && (row == 13 || row == 17 || row == 21 || row == 27 ||
                             row == 31 || row == 35 || row == 41 || row == 45 ||
                             row == 49)) ||
                 (p == 2 && (row == 31 || row == 35 || row == 39 || row == 45 ||
                             row == 49 || row == 55)) ||
                 (p == 3 && (row == 7 || row == 11 || row == 15 || row == 19 ||
                             row == 23 || row == 27))) && col >= base && col < base + 8)
                dashboard_char = word_hex_char(value, col - base);
            if (p == 4 && (row == 16 || row == 20 || row == 32) && col >= 20 && col < 28)
                dashboard_char = word_hex_char(value, col - 20);
            if (p == 4 && row == 28 && col >= 16 && col < 20)
                dashboard_char = decimal4_char(value, col - 16);
            if (p == 4 && row == 38 && col >= 16 && col < 20)
                dashboard_char = decimal4_char(value, col - 16);
            if (p == 0 && row == 38 && col >= 20 && col < 24)
                dashboard_char = decimal4_char(disp_attempts, col - 20);
            if (p == 0 && row == 42 && col >= 20 && col < 24)
                dashboard_char = (disp_hint == 3) ? decimal4_char(disp_target, col - 20) : "?";
            if (p == 2 && (row == 22 || row == 26) &&
                col >= 20 && col < 24)
                dashboard_char = decimal4_char(value, col - 20);
            if (p == 2 && row == 10 && col >= 20 && col < 24)
                dashboard_char = decimal4_char((disp_bench_status == 0) ? disp_mips : disp_speedup, col - 20);
        end
    endfunction

    function base_piece_cell;
        input [2:0] piece;
        input [1:0] cx;
        input [1:0] cy;
        begin
            base_piece_cell = 1'b0;
            case (piece)
                3'd1: base_piece_cell = ((cy == 0) && (cx == 1)) ||
                                             ((cy == 1) && (cx < 3));
                3'd2: base_piece_cell = (cx < 2) && (cy < 2);
                3'd3: base_piece_cell = (cy == 1) && (cx < 4);
                3'd4: base_piece_cell = ((cy == 0) && (cx == 1 || cx == 2)) ||
                                   ((cy == 1) && (cx == 0 || cx == 1));
                3'd5: base_piece_cell = ((cy == 0) && (cx == 0 || cx == 1)) ||
                                   ((cy == 1) && (cx == 1 || cx == 2));
                3'd6: base_piece_cell = ((cx == 0) && (cy < 3)) ||
                                         ((cy == 2) && (cx == 1));
                3'd7: base_piece_cell = ((cx == 1) && (cy < 3)) ||
                                         ((cy == 2) && (cx == 0));
                default: base_piece_cell = 1'b0;
            endcase
        end
    endfunction

    function piece_cell;
        input [2:0] piece;
        input [1:0] rotation;
        input [1:0] cx;
        input [1:0] cy;
        reg [1:0] tx, ty;
        begin
            tx = cx; ty = cy;
            if (piece == 2) begin
                piece_cell = base_piece_cell(piece, cx, cy);
            end else if (piece == 3) begin
                case (rotation)
                    2'd1: begin tx = cy; ty = 3 - cx; end
                    2'd2: begin tx = 3 - cx; ty = 3 - cy; end
                    2'd3: begin tx = 3 - cy; ty = cx; end
                    default: ;
                endcase
                piece_cell = base_piece_cell(piece, tx, ty);
            end else if (cx < 3 && cy < 3) begin
                case (rotation)
                    2'd1: begin tx = cy; ty = 2 - cx; end
                    2'd2: begin tx = 2 - cx; ty = 2 - cy; end
                    2'd3: begin tx = 2 - cy; ty = cx; end
                    default: ;
                endcase
                piece_cell = base_piece_cell(piece, tx, ty);
            end else begin
                piece_cell = 1'b0;
            end
        end
    endfunction

    function [3:0] piece_row_mask;
        input [2:0] piece;
        input [1:0] rotation;
        input [1:0] row_index;
        begin
            piece_row_mask = {piece_cell(piece, rotation, 2'd3, row_index),
                              piece_cell(piece, rotation, 2'd2, row_index),
                              piece_cell(piece, rotation, 2'd1, row_index),
                              piece_cell(piece, rotation, 2'd0, row_index)};
        end
    endfunction

    reg [9:0] tetris_board_rows [0:19];
    reg [31:0] seen_lock_count, seen_clear_count;
    reg [4:0] line_scan;
    integer bi, by;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seen_lock_count <= 0;
            seen_clear_count <= 0;
            cleared_lines <= 0;
            line_scan <= 0;
            for (bi = 0; bi < 20; bi = bi + 1) tetris_board_rows[bi] <= 0;
        end else begin
            if (tetris_clear_count != seen_clear_count) begin
                seen_clear_count <= tetris_clear_count;
                cleared_lines <= 0;
                line_scan <= 0;
                for (bi = 0; bi < 20; bi = bi + 1) tetris_board_rows[bi] <= 0;
            end else if (tetris_lock_count != seen_lock_count) begin
                seen_lock_count <= tetris_lock_count;
                for (by = 0; by < 4; by = by + 1)
                    if ((tetris_y + by < 20) &&
                        (piece_row_mask(tetris_piece, tetris_rotation, by[1:0]) != 0))
                        tetris_board_rows[tetris_y + by] <=
                            tetris_board_rows[tetris_y + by] |
                            (piece_row_mask(tetris_piece, tetris_rotation, by[1:0]) << tetris_x);
            end else if (tetris_board_rows[line_scan] == 10'h3FF) begin
                for (bi = 19; bi > 0; bi = bi - 1)
                    if (bi <= line_scan)
                        tetris_board_rows[bi] <= tetris_board_rows[bi-1];
                tetris_board_rows[0] <= 0;
                cleared_lines <= cleared_lines + 1'b1;
            end else if (line_scan == 19) begin
                line_scan <= 0;
            end else begin
                line_scan <= line_scan + 1'b1;
            end
        end
    end

    integer collision_x, collision_y;
    always @(*) begin
        tetris_collision = 1'b0;
        for (collision_y = 0; collision_y < 4; collision_y = collision_y + 1)
            for (collision_x = 0; collision_x < 4; collision_x = collision_x + 1)
                if (piece_cell(tetris_piece, tetris_rotation,
                               collision_x[1:0], collision_y[1:0])) begin
                    if ((tetris_x + collision_x >= 10) ||
                        (tetris_y + collision_y >= 20))
                        tetris_collision = 1'b1;
                    else if (tetris_board_rows[tetris_y + collision_y]
                                                 [tetris_x + collision_x])
                        tetris_collision = 1'b1;
                end
    end

    wire [6:0] text_col = h_cnt[9:3];
    wire [5:0] text_row = v_cnt[8:3];
    wire [7:0] current_char = dashboard_char(disp_page, text_row, text_col);
    wire [7:0] font_pixels;
    font_rom u_font_rom(.char_code(current_char), .row(v_cnt[2:0]), .pixels(font_pixels));
    wire text_on = font_pixels[7-h_cnt[2:0]];
    wire game_digit_area = (disp_page == 2'd0) && (v_cnt >= 10'd136) &&
                           (v_cnt < 10'd200) &&
                           (((h_cnt >= 184) && (h_cnt < 248)) ||
                            ((h_cnt >= 272) && (h_cnt < 336)) ||
                            ((h_cnt >= 360) && (h_cnt < 424)));
    wire [1:0] game_digit_index = (h_cnt < 10'd272) ? 0 :
                                  (h_cnt < 10'd360) ? 1 : 2;
    wire [9:0] digit_origin_x = (game_digit_index == 0) ? 10'd184 :
                                (game_digit_index == 1) ? 10'd272 : 10'd360;
    wire [2:0] big_font_x = (h_cnt - digit_origin_x) >> 3;
    wire [2:0] big_font_y = (v_cnt - 10'd136) >> 3;
    wire [7:0] big_digit_char = (game_digit_index == 0) ?
        hex_char((disp_guess / 100) % 10) : (game_digit_index == 1) ?
        hex_char((disp_guess / 10) % 10) : hex_char(disp_guess % 10);
    wire [7:0] big_digit_pixels;
    font_rom u_big_font(.char_code(big_digit_char), .row(big_font_y), .pixels(big_digit_pixels));
    wire big_digit_on = game_digit_area && big_digit_pixels[7-big_font_x];
    wire perf_big_area = (disp_page == 2'd2) && (v_cnt >= 10'd96) &&
                         (v_cnt < 10'd128) &&
                         (((h_cnt >= 64) && (h_cnt < 96)) ||
                          ((h_cnt >= 104) && (h_cnt < 136)) ||
                          ((h_cnt >= 144) && (h_cnt < 176)) ||
                          ((h_cnt >= 184) && (h_cnt < 216)));
    wire [1:0] perf_digit_index = (h_cnt < 104) ? 0 :
                                  (h_cnt < 144) ? 1 :
                                  (h_cnt < 184) ? 2 : 3;
    wire [9:0] perf_digit_origin = (perf_digit_index == 0) ? 64 :
                                   (perf_digit_index == 1) ? 104 :
                                   (perf_digit_index == 2) ? 144 : 184;
    wire [2:0] perf_font_x = (h_cnt - perf_digit_origin) >> 2;
    wire [2:0] perf_font_y = (v_cnt - 10'd96) >> 2;
    wire [7:0] perf_digit_char = (perf_digit_index == 0) ?
        hex_char((((disp_bench_status == 0) ? disp_mips : disp_speedup) / 1000) % 10) :
        (perf_digit_index == 1) ?
        hex_char((((disp_bench_status == 0) ? disp_mips : disp_speedup) / 100) % 10) :
        (perf_digit_index == 2) ?
        hex_char((((disp_bench_status == 0) ? disp_mips : disp_speedup) / 10) % 10) :
        hex_char(((disp_bench_status == 0) ? disp_mips : disp_speedup) % 10);
    wire [7:0] perf_digit_pixels;
    font_rom u_perf_font(.char_code(perf_digit_char), .row(perf_font_y), .pixels(perf_digit_pixels));
    wire perf_big_digit_on = perf_big_area && perf_digit_pixels[7-perf_font_x];
    wire game_card_on = (disp_page == 2'd0) && (v_cnt >= 10'd120) &&
                        (v_cnt < 10'd216) &&
                        (((h_cnt >= 10'd176) && (h_cnt < 10'd256)) ||
                         ((h_cnt >= 10'd264) && (h_cnt < 10'd344)) ||
                         ((h_cnt >= 10'd352) && (h_cnt < 10'd432)));
    wire card_border_on = game_card_on &&
                          ((v_cnt < 10'd124) || (v_cnt >= 10'd212) ||
                           ((h_cnt >= 176) && (h_cnt < 180)) ||
                           ((h_cnt >= 252) && (h_cnt < 256)) ||
                           ((h_cnt >= 264) && (h_cnt < 268)) ||
                           ((h_cnt >= 340) && (h_cnt < 344)) ||
                           ((h_cnt >= 352) && (h_cnt < 356)) ||
                           ((h_cnt >= 428) && (h_cnt < 432)));
    wire selected_bar_on = (disp_page == 2'd0) && (v_cnt >= 10'd220) &&
                           (v_cnt < 10'd226) &&
                           (((disp_selected == 0) && h_cnt >= 176 && h_cnt < 256) ||
                            ((disp_selected == 1) && h_cnt >= 264 && h_cnt < 344) ||
                            ((disp_selected == 2) && h_cnt >= 352 && h_cnt < 432));
    wire header_on = video_on && (v_cnt < 10'd40);
    wire border_on = video_on && ((h_cnt < 4) || (h_cnt >= 636) ||
                                  (v_cnt < 4) || (v_cnt >= 476));
    wire perf_band_on = video_on && (disp_page == 2'd2) && (h_cnt >= 10'd136) &&
                        (h_cnt < 10'd624) &&
                        ((text_row == 6'd10) || (text_row == 6'd18) ||
                         (text_row == 6'd26) || (text_row == 6'd34) ||
                         (text_row == 6'd42) || (text_row == 6'd50));
    wire perf_separator_on = video_on && (disp_page == 2'd2) && (h_cnt >= 10'd136) &&
                              (h_cnt < 10'd624) && (v_cnt[2:0] == 3'd7) &&
                               ((text_row == 6'd10) || (text_row == 6'd18) ||
                                (text_row == 6'd26) || (text_row == 6'd34) ||
                                (text_row == 6'd42) || (text_row == 6'd50));
    wire tetris_board_area = (disp_page == 3'd4) && h_cnt >= 240 && h_cnt < 400 &&
                             v_cnt >= 72 && v_cnt < 392;
    wire [3:0] tetris_col = (h_cnt - 240) >> 4;
    wire [4:0] tetris_row = (v_cnt - 72) >> 4;
    wire [1:0] tetris_local_x = tetris_col - tetris_x;
    wire [1:0] tetris_local_y = tetris_row - tetris_y;
    wire tetris_active_cell = tetris_board_area && tetris_col >= tetris_x &&
                              tetris_col < tetris_x + 4 && tetris_row >= tetris_y &&
                              tetris_row < tetris_y + 4 &&
                              piece_cell(tetris_piece, tetris_rotation,
                                         tetris_local_x, tetris_local_y);
    wire tetris_locked_cell = tetris_board_area ?
                               tetris_board_rows[tetris_row][tetris_col] : 1'b0;
    wire tetris_grid_on = tetris_board_area &&
                          (((h_cnt - 240) & 15) == 0 || ((v_cnt - 72) & 15) == 0);
    wire tetris_frame_on = (disp_page == 3'd4) &&
                           (((h_cnt >= 236 && h_cnt < 240) || (h_cnt >= 400 && h_cnt < 404)) &&
                            v_cnt >= 68 && v_cnt < 396 ||
                            ((v_cnt >= 68 && v_cnt < 72) || (v_cnt >= 392 && v_cnt < 396)) &&
                            h_cnt >= 236 && h_cnt < 404);
    wire tetris_next_area = (disp_page == 3'd4) && h_cnt >= 48 && h_cnt < 112 &&
                            v_cnt >= 56 && v_cnt < 120;
    wire [1:0] tetris_next_x = (h_cnt - 48) >> 4;
    wire [1:0] tetris_next_y = (v_cnt - 56) >> 4;
    wire tetris_next_cell = tetris_next_area &&
                            piece_cell(tetris_next, 2'd0, tetris_next_x, tetris_next_y);
    wire tetris_next_grid = tetris_next_area &&
                            (((h_cnt - 48) & 15) == 0 || ((v_cnt - 56) & 15) == 0);
    wire tetris_game_over_on = (disp_page == 3'd4) && (tetris_state == 3) &&
                               tetris_board_area;

    always @(*) begin
        vga_r = 0; vga_g = 0; vga_b = 0;
        if (video_on) begin
            vga_r = 4'h1; vga_g = 4'h1; vga_b = 4'h1;
            if (header_on) begin vga_r = 4'h1; vga_g = 4'h3; vga_b = 4'h5; end
            if (perf_band_on) begin vga_r = 4'h1; vga_g = 4'h2; vga_b = 4'h3; end
            if (perf_separator_on) begin vga_r = 4'h2; vga_g = 4'h5; vga_b = 4'h6; end
            if (tetris_board_area) begin vga_r = 4'h0; vga_g = 4'h1; vga_b = 4'h2; end
            if (tetris_grid_on) begin vga_r = 4'h1; vga_g = 4'h3; vga_b = 4'h4; end
            if (tetris_frame_on) begin vga_r = 4'h3; vga_g = 4'hD; vga_b = 4'hF; end
            if (tetris_next_area) begin vga_r=4'h1; vga_g=4'h2; vga_b=4'h3; end
            if (tetris_next_grid) begin vga_r=4'h3; vga_g=4'h5; vga_b=4'h6; end
            if (tetris_next_cell) begin vga_r=4'hF; vga_g=4'hD; vga_b=4'h3; end
            if (tetris_locked_cell || tetris_active_cell) begin
                case (tetris_active_cell ? tetris_piece : 3'd3)
                    3'd1: begin vga_r=4'hB; vga_g=4'h4; vga_b=4'hF; end
                    3'd2: begin vga_r=4'hF; vga_g=4'hD; vga_b=4'h2; end
                    3'd3: begin vga_r=4'h2; vga_g=4'hE; vga_b=4'hF; end
                    3'd4: begin vga_r=4'h3; vga_g=4'hE; vga_b=4'h7; end
                    3'd5: begin vga_r=4'hF; vga_g=4'h3; vga_b=4'h4; end
                    3'd6: begin vga_r=4'hF; vga_g=4'h8; vga_b=4'h2; end
                    default: begin vga_r=4'h3; vga_g=4'h7; vga_b=4'hF; end
                endcase
            end
            if (tetris_game_over_on) begin vga_r=4'hA; vga_g=4'h1; vga_b=4'h1; end
            if (border_on) begin
                case (disp_page)
                    2'd0: begin
                        if (disp_hint == 4'd3) begin vga_r=4'h2; vga_g=4'hF; vga_b=4'h4; end
                        else if (disp_hint == 4'd2) begin vga_r=4'hF; vga_g=4'h3; vga_b=4'h1; end
                        else begin vga_r=4'h1; vga_g=4'h8; vga_b=4'hF; end
                    end
                    2'd1: begin vga_r=4'hF; vga_g=4'hD; vga_b=4'h2; end
                    2'd2: begin vga_r=4'h2; vga_g=4'hE; vga_b=4'hB; end
                    3'd4: begin vga_r=4'h3; vga_g=4'hD; vga_b=4'hF; end
                    default: begin vga_r=4'hD; vga_g=4'h7; vga_b=4'hF; end
                endcase
            end
            if (game_card_on) begin vga_r=4'h1; vga_g=4'h2; vga_b=4'h3; end
            if (card_border_on) begin vga_r=4'h3; vga_g=4'h7; vga_b=4'h9; end
            if (selected_bar_on) begin vga_r=4'hF; vga_g=4'hD; vga_b=4'h2; end
            if (text_on) begin vga_r=4'hD; vga_g=4'hE; vga_b=4'hF; end
            if (big_digit_on) begin
                if (disp_hint == 3) begin vga_r=4'h3; vga_g=4'hF; vga_b=4'h7; end
                else begin vga_r=4'hF; vga_g=4'hF; vga_b=4'hF; end
            end
            if (perf_big_digit_on) begin vga_r=4'h3; vga_g=4'hF; vga_b=4'hC; end
        end
    end

endmodule
