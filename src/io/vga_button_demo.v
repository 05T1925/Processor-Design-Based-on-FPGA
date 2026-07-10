//==============================================================================
// vga_button_demo.v - Guess-the-number game skeleton for VGA bring-up
//
// Board button mapping used by this demo:
//   btn[0] = S1 = right
//   btn[1] = S2 = left
//   btn[2] = S3 = up
//   btn[3] = S4 = action / confirm
//   btn[4] = S5 = down
//
// This is a UI skeleton rather than a final game:
//   - START: press S4 to enter
//   - PLAY: left/right select one of 3 digits, up/down edit, S4 submit
//   - RESULT: border color shows low/high/win, S4 returns to PLAY
//
// A fixed target value is used for now so we can validate the full front-end
// interaction before adding randomness and richer game flow.
//==============================================================================

module vga_button_demo (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [4:0]  btn,
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b,
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [15:0] debug_led
);

    localparam [1:0] ST_START  = 2'd0;
    localparam [1:0] ST_PLAY   = 2'd1;
    localparam [1:0] ST_RESULT = 2'd2;

    localparam [1:0] RES_LOW  = 2'd0;
    localparam [1:0] RES_HIGH = 2'd1;
    localparam [1:0] RES_WIN  = 2'd2;

    localparam [9:0] TARGET_VALUE = 10'd573;

    localparam integer DIGIT_W = 80;
    localparam integer DIGIT_H = 140;
    localparam integer DIGIT_T = 12;
    localparam integer DIGIT0_X = 140;
    localparam integer DIGIT1_X = 280;
    localparam integer DIGIT2_X = 420;
    localparam integer DIGIT_Y  = 150;

    reg [1:0] pix_div;
    wire      pix_tick = (pix_div == 2'd3);

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;
    reg [5:0] frame_ctr;

    reg [4:0] btn_ff0;
    reg [4:0] btn_ff1;
    reg [4:0] btn_prev;

    reg [1:0] game_state;
    reg [1:0] result_state;
    reg [1:0] cursor_idx;
    reg [3:0] digit_hundreds;
    reg [3:0] digit_tens;
    reg [3:0] digit_ones;

    wire [4:0] btn_sync = btn_ff1;
    wire [4:0] btn_press = btn_sync & ~btn_prev;

    wire press_right  = btn_press[0];
    wire press_left   = btn_press[1];
    wire press_up     = btn_press[2];
    wire press_action = btn_press[3];
    wire press_down   = btn_press[4];

    wire h_last = (h_cnt == 10'd799);
    wire v_last = (v_cnt == 10'd524);
    wire frame_tick = pix_tick && h_last && v_last;

    wire video_on  = (h_cnt < 10'd640) && (v_cnt < 10'd480);
    wire border_on = ((h_cnt < 10'd4) || (h_cnt >= 10'd636) ||
                      (v_cnt < 10'd4) || (v_cnt >= 10'd476));

    wire [9:0] guess_value = (digit_hundreds * 10'd100) +
                             (digit_tens     * 10'd10)  +
                              digit_ones;

    //--------------------------------------------------------------------------
    // VGA timing
    //--------------------------------------------------------------------------
    assign vga_hsync = ~((h_cnt >= 10'd656) && (h_cnt < 10'd752));
    assign vga_vsync = ~((v_cnt >= 10'd490) && (v_cnt < 10'd492));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pix_div <= 2'd0;
            h_cnt   <= 10'd0;
            v_cnt   <= 10'd0;
        end else begin
            pix_div <= pix_div + 1'b1;

            if (pix_tick) begin
                if (h_last) begin
                    h_cnt <= 10'd0;
                    if (v_last)
                        v_cnt <= 10'd0;
                    else
                        v_cnt <= v_cnt + 1'b1;
                end else begin
                    h_cnt <= h_cnt + 1'b1;
                end
            end
        end
    end

    //--------------------------------------------------------------------------
    // Button sync + edge detect
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_ff0  <= 5'b0;
            btn_ff1  <= 5'b0;
            btn_prev <= 5'b0;
        end else begin
            btn_ff0 <= btn;
            btn_ff1 <= btn_ff0;
            if (frame_tick)
                btn_prev <= btn_sync;
        end
    end

    //--------------------------------------------------------------------------
    // Game state machine
    //--------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            frame_ctr      <= 6'd0;
            game_state     <= ST_START;
            result_state   <= RES_LOW;
            cursor_idx     <= 2'd0;
            digit_hundreds <= 4'd0;
            digit_tens     <= 4'd0;
            digit_ones     <= 4'd0;
        end else if (frame_tick) begin
            frame_ctr <= frame_ctr + 1'b1;

            case (game_state)
                ST_START: begin
                    if (press_action) begin
                        game_state     <= ST_PLAY;
                        cursor_idx     <= 2'd0;
                        digit_hundreds <= 4'd0;
                        digit_tens     <= 4'd0;
                        digit_ones     <= 4'd0;
                    end
                end

                ST_PLAY: begin
                    if (press_left && (cursor_idx != 2'd0))
                        cursor_idx <= cursor_idx - 1'b1;
                    else if (press_right && (cursor_idx != 2'd2))
                        cursor_idx <= cursor_idx + 1'b1;

                    if (press_up) begin
                        case (cursor_idx)
                            2'd0: digit_hundreds <= (digit_hundreds == 4'd9) ? 4'd0 : digit_hundreds + 1'b1;
                            2'd1: digit_tens     <= (digit_tens     == 4'd9) ? 4'd0 : digit_tens     + 1'b1;
                            default: digit_ones  <= (digit_ones     == 4'd9) ? 4'd0 : digit_ones     + 1'b1;
                        endcase
                    end else if (press_down) begin
                        case (cursor_idx)
                            2'd0: digit_hundreds <= (digit_hundreds == 4'd0) ? 4'd9 : digit_hundreds - 1'b1;
                            2'd1: digit_tens     <= (digit_tens     == 4'd0) ? 4'd9 : digit_tens     - 1'b1;
                            default: digit_ones  <= (digit_ones     == 4'd0) ? 4'd9 : digit_ones     - 1'b1;
                        endcase
                    end

                    if (press_action) begin
                        if (guess_value < TARGET_VALUE)
                            result_state <= RES_LOW;
                        else if (guess_value > TARGET_VALUE)
                            result_state <= RES_HIGH;
                        else
                            result_state <= RES_WIN;
                        game_state <= ST_RESULT;
                    end
                end

                default: begin
                    if (press_action) begin
                        if (result_state == RES_WIN) begin
                            game_state     <= ST_START;
                            digit_hundreds <= 4'd0;
                            digit_tens     <= 4'd0;
                            digit_ones     <= 4'd0;
                        end else begin
                            game_state <= ST_PLAY;
                        end
                    end
                end
            endcase
        end
    end

    assign debug_led = {game_state, result_state, cursor_idx, btn_sync, digit_hundreds[1:0], digit_tens[1:0], digit_ones[1:0]};

    //--------------------------------------------------------------------------
    // Digit drawing helpers
    //--------------------------------------------------------------------------
    function [6:0] seg_mask;
        input [3:0] value;
        begin
            case (value)
                4'd0: seg_mask = 7'b1111110;
                4'd1: seg_mask = 7'b0110000;
                4'd2: seg_mask = 7'b1101101;
                4'd3: seg_mask = 7'b1111001;
                4'd4: seg_mask = 7'b0110011;
                4'd5: seg_mask = 7'b1011011;
                4'd6: seg_mask = 7'b1011111;
                4'd7: seg_mask = 7'b1110000;
                4'd8: seg_mask = 7'b1111111;
                4'd9: seg_mask = 7'b1111011;
                default: seg_mask = 7'b0000001;
            endcase
        end
    endfunction

    function digit_pixel_on;
        input [9:0] px;
        input [9:0] py;
        input integer base_x;
        input integer base_y;
        input [3:0] value;
        reg [9:0] lx;
        reg [9:0] ly;
        reg [6:0] mask;
        begin
            digit_pixel_on = 1'b0;
            if ((px >= base_x) && (px < base_x + DIGIT_W) &&
                (py >= base_y) && (py < base_y + DIGIT_H)) begin
                lx = px - base_x;
                ly = py - base_y;
                mask = seg_mask(value);

                if (mask[6] && (ly < DIGIT_T) &&
                    (lx >= DIGIT_T) && (lx < DIGIT_W - DIGIT_T))
                    digit_pixel_on = 1'b1; // A
                else if (mask[5] && (lx >= DIGIT_W - DIGIT_T) &&
                         (ly >= DIGIT_T) && (ly < (DIGIT_H/2)))
                    digit_pixel_on = 1'b1; // B
                else if (mask[4] && (lx >= DIGIT_W - DIGIT_T) &&
                         (ly >= (DIGIT_H/2)) && (ly < DIGIT_H - DIGIT_T))
                    digit_pixel_on = 1'b1; // C
                else if (mask[3] && (ly >= DIGIT_H - DIGIT_T) &&
                         (lx >= DIGIT_T) && (lx < DIGIT_W - DIGIT_T))
                    digit_pixel_on = 1'b1; // D
                else if (mask[2] && (lx < DIGIT_T) &&
                         (ly >= (DIGIT_H/2)) && (ly < DIGIT_H - DIGIT_T))
                    digit_pixel_on = 1'b1; // E
                else if (mask[1] && (lx < DIGIT_T) &&
                         (ly >= DIGIT_T) && (ly < (DIGIT_H/2)))
                    digit_pixel_on = 1'b1; // F
                else if (mask[0] &&
                         (ly >= (DIGIT_H/2) - (DIGIT_T/2)) &&
                         (ly <  (DIGIT_H/2) + (DIGIT_T/2)) &&
                         (lx >= DIGIT_T) && (lx < DIGIT_W - DIGIT_T))
                    digit_pixel_on = 1'b1; // G
            end
        end
    endfunction

    wire digit0_on = digit_pixel_on(h_cnt, v_cnt, DIGIT0_X, DIGIT_Y, digit_hundreds);
    wire digit1_on = digit_pixel_on(h_cnt, v_cnt, DIGIT1_X, DIGIT_Y, digit_tens);
    wire digit2_on = digit_pixel_on(h_cnt, v_cnt, DIGIT2_X, DIGIT_Y, digit_ones);

    wire cursor0_on = (cursor_idx == 2'd0) &&
                      (h_cnt >= DIGIT0_X - 10) && (h_cnt < DIGIT0_X + DIGIT_W + 10) &&
                      (v_cnt >= DIGIT_Y + DIGIT_H + 8) && (v_cnt < DIGIT_Y + DIGIT_H + 18);
    wire cursor1_on = (cursor_idx == 2'd1) &&
                      (h_cnt >= DIGIT1_X - 10) && (h_cnt < DIGIT1_X + DIGIT_W + 10) &&
                      (v_cnt >= DIGIT_Y + DIGIT_H + 8) && (v_cnt < DIGIT_Y + DIGIT_H + 18);
    wire cursor2_on = (cursor_idx == 2'd2) &&
                      (h_cnt >= DIGIT2_X - 10) && (h_cnt < DIGIT2_X + DIGIT_W + 10) &&
                      (v_cnt >= DIGIT_Y + DIGIT_H + 8) && (v_cnt < DIGIT_Y + DIGIT_H + 18);

    wire start_panel_on = (h_cnt >= 160) && (h_cnt < 480) &&
                          (v_cnt >= 150) && (v_cnt < 330);
    wire start_button_on = (h_cnt >= 220) && (h_cnt < 420) &&
                           (v_cnt >= 245) && (v_cnt < 295);
    wire start_button_blink = frame_ctr[5];

    wire status_bar_on = (v_cnt >= 50) && (v_cnt < 90) &&
                         (h_cnt >= 100) && (h_cnt < 540);

    //--------------------------------------------------------------------------
    // Rendering
    //--------------------------------------------------------------------------
    always @(*) begin
        vga_r = 4'h0;
        vga_g = 4'h0;
        vga_b = 4'h0;

        if (video_on) begin
            if (border_on) begin
                case (game_state)
                    ST_START:  begin vga_r = 4'h4; vga_g = 4'h8; vga_b = 4'hF; end
                    ST_PLAY:   begin vga_r = 4'hF; vga_g = 4'hF; vga_b = 4'hF; end
                    default: begin
                        case (result_state)
                            RES_LOW:  begin vga_r = 4'h2; vga_g = 4'h6; vga_b = 4'hF; end
                            RES_HIGH: begin vga_r = 4'hF; vga_g = 4'h3; vga_b = 4'h3; end
                            default:  begin vga_r = 4'h3; vga_g = 4'hF; vga_b = 4'h5; end
                        endcase
                    end
                endcase
            end else if (game_state == ST_START) begin
                if (start_panel_on) begin
                    vga_r = 4'h1;
                    vga_g = 4'h1;
                    vga_b = 4'h1;
                end
                if (start_button_on && start_button_blink) begin
                    vga_r = 4'h3;
                    vga_g = 4'hC;
                    vga_b = 4'hF;
                end
                if (digit0_on || digit1_on || digit2_on) begin
                    vga_r = 4'h8;
                    vga_g = 4'h8;
                    vga_b = 4'h8;
                end
            end else begin
                if (status_bar_on) begin
                    if (game_state == ST_PLAY) begin
                        vga_r = 4'h6;
                        vga_g = 4'h6;
                        vga_b = 4'h0;
                    end else begin
                        case (result_state)
                            RES_LOW:  begin vga_r = 4'h1; vga_g = 4'h4; vga_b = 4'hF; end
                            RES_HIGH: begin vga_r = 4'hF; vga_g = 4'h2; vga_b = 4'h2; end
                            default:  begin vga_r = 4'h2; vga_g = 4'hF; vga_b = 4'h4; end
                        endcase
                    end
                end

                if (digit0_on || digit1_on || digit2_on) begin
                    if (game_state == ST_RESULT && result_state == RES_WIN) begin
                        vga_r = 4'h3;
                        vga_g = 4'hF;
                        vga_b = 4'h5;
                    end else begin
                        vga_r = 4'hF;
                        vga_g = 4'hF;
                        vga_b = 4'hF;
                    end
                end

                if (cursor0_on || cursor1_on || cursor2_on) begin
                    vga_r = 4'hF;
                    vga_g = 4'hD;
                    vga_b = 4'h2;
                end
            end
        end
    end

endmodule
