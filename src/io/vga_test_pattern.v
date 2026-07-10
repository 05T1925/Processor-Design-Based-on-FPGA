//==============================================================================
// vga_test_pattern.v - 640x480@60Hz VGA bring-up pattern
//
// Generates a color-bar background and a small key-driven color tile in the
// upper-left corner. This is intended for quick board-side verification that
// VGA timing is correct and keypad input is reaching the FPGA.
//==============================================================================

module vga_test_pattern (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       key_valid,
    input  wire [3:0] key_code,
    output reg  [3:0] vga_r,
    output reg  [3:0] vga_g,
    output reg  [3:0] vga_b,
    output wire       vga_hsync,
    output wire       vga_vsync
);

    reg [1:0] pix_div;
    wire      pix_tick = (pix_div == 2'd3);

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    wire h_last = (h_cnt == 10'd799);
    wire v_last = (v_cnt == 10'd524);

    wire video_on = (h_cnt < 10'd640) && (v_cnt < 10'd480);
    wire tile_on  = (h_cnt < 10'd160) && (v_cnt < 10'd120);
    wire border_on = ((h_cnt < 10'd4) || (h_cnt >= 10'd636) ||
                      (v_cnt < 10'd4) || (v_cnt >= 10'd476));

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

    always @(*) begin
        vga_r = 4'h0;
        vga_g = 4'h0;
        vga_b = 4'h0;

        if (video_on) begin
            if (border_on) begin
                vga_r = 4'hF;
                vga_g = 4'hF;
                vga_b = 4'hF;
            end else if (tile_on && key_valid) begin
                vga_r = {key_code[3:2], key_code[3:2]};
                vga_g = {key_code[2:1], key_code[2:1]};
                vga_b = {key_code[1:0], key_code[1:0]};
            end else if (h_cnt < 10'd80) begin
                vga_r = 4'hF; vga_g = 4'h0; vga_b = 4'h0;
            end else if (h_cnt < 10'd160) begin
                vga_r = 4'hF; vga_g = 4'h8; vga_b = 4'h0;
            end else if (h_cnt < 10'd240) begin
                vga_r = 4'hF; vga_g = 4'hF; vga_b = 4'h0;
            end else if (h_cnt < 10'd320) begin
                vga_r = 4'h0; vga_g = 4'hF; vga_b = 4'h0;
            end else if (h_cnt < 10'd400) begin
                vga_r = 4'h0; vga_g = 4'hF; vga_b = 4'hF;
            end else if (h_cnt < 10'd480) begin
                vga_r = 4'h0; vga_g = 4'h0; vga_b = 4'hF;
            end else if (h_cnt < 10'd560) begin
                vga_r = 4'h8; vga_g = 4'h0; vga_b = 4'hF;
            end else begin
                vga_r = 4'hF; vga_g = 4'h0; vga_b = 4'hF;
            end
        end
    end

endmodule
