//==============================================================================
// kbd4x4_scanner.v - Simple 4x4 keypad scanner for board bring-up
//
// Assumes a classic matrix keypad wiring:
//   - 4 row outputs, active-low scanned one-at-a-time
//   - 4 column inputs with external pull-ups, active-low when pressed
//
// The Minisys manual provides the board wiring but not a clean row/column
// table, so this module is intentionally minimal and used only for board I/O
// verification at the top level.
//==============================================================================

module kbd4x4_scanner (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] col_n,
    output reg  [3:0] row_n,
    output reg        key_valid,
    output reg  [1:0] key_row,
    output reg  [1:0] key_col,
    output reg  [3:0] key_code
);

    localparam integer SCAN_DIV = 16'd25000;
    localparam [1:0]   STABLE_FRAMES = 2'd2;

    reg [15:0] scan_cnt;
    reg [1:0]  scan_row;

    wire [3:0] col_hit = ~col_n;
    wire       any_hit = |col_hit;
    wire       single_hit = (col_hit == 4'b0001) ||
                            (col_hit == 4'b0010) ||
                            (col_hit == 4'b0100) ||
                            (col_hit == 4'b1000);

    reg [1:0] detected_col;
    reg       candidate_valid;
    reg [1:0] candidate_row;
    reg [1:0] candidate_col;
    reg [1:0] stable_count;
    reg       frame_seen_hit;
    reg [1:0] frame_hit_row;
    reg [1:0] frame_hit_col;

    always @(*) begin
        casez (col_hit)
            4'b???1: detected_col = 2'd0;
            4'b??10: detected_col = 2'd1;
            4'b?100: detected_col = 2'd2;
            4'b1000: detected_col = 2'd3;
            default: detected_col = 2'd0;
        endcase
    end

    always @(*) begin
        case (scan_row)
            2'd0: row_n = 4'b1110;
            2'd1: row_n = 4'b1101;
            2'd2: row_n = 4'b1011;
            default: row_n = 4'b0111;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_cnt   <= 16'd0;
            scan_row   <= 2'd0;
            key_valid  <= 1'b0;
            key_row    <= 2'd0;
            key_col    <= 2'd0;
            key_code   <= 4'd0;
            candidate_valid <= 1'b0;
            candidate_row   <= 2'd0;
            candidate_col   <= 2'd0;
            stable_count    <= 2'd0;
            frame_seen_hit  <= 1'b0;
            frame_hit_row   <= 2'd0;
            frame_hit_col   <= 2'd0;
        end else if (scan_cnt == SCAN_DIV - 1'b1) begin
            scan_cnt <= 16'd0;

            if (single_hit && !frame_seen_hit) begin
                frame_seen_hit <= 1'b1;
                frame_hit_row  <= scan_row;
                frame_hit_col  <= detected_col;
            end

            if (scan_row == 2'd3) begin
                if (frame_seen_hit) begin
                    if (candidate_valid &&
                        (candidate_row == frame_hit_row) &&
                        (candidate_col == frame_hit_col)) begin
                        if (stable_count != STABLE_FRAMES)
                            stable_count <= stable_count + 1'b1;
                    end else begin
                        candidate_valid <= 1'b1;
                        candidate_row   <= frame_hit_row;
                        candidate_col   <= frame_hit_col;
                        stable_count    <= 2'd0;
                    end

                    if (candidate_valid &&
                        (candidate_row == frame_hit_row) &&
                        (candidate_col == frame_hit_col) &&
                        (stable_count >= STABLE_FRAMES - 1'b1)) begin
                        key_valid <= 1'b1;
                        key_row   <= frame_hit_row;
                        key_col   <= frame_hit_col;
                        key_code  <= {frame_hit_row, 2'b00} + {2'b00, frame_hit_col};
                    end
                end else begin
                    candidate_valid <= 1'b0;
                    stable_count    <= 2'd0;
                    key_valid       <= 1'b0;
                end

                frame_seen_hit <= 1'b0;
            end

            scan_row <= scan_row + 1'b1;
        end else begin
            scan_cnt <= scan_cnt + 1'b1;
        end
    end

endmodule
