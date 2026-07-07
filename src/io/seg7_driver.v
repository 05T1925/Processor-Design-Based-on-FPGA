//==============================================================================
// seg7_driver.v - 7-Segment Display Peripheral
//
// Based on: minisys_unified/rtl/peripheral/seg7.v
//
// 8-digit multiplexed common-anode 7-segment display.
// Active-low segment cathodes, active-low digit enables.
// ~3 kHz scan rate at 50 MHz.
// Unified bus slave at address 0xFFFF_FC20.
//==============================================================================

module seg7_driver (
    input  wire        clk,
    input  wire        rst_n,

    // Bus slave interface
    input  wire        bus_en,
    input  wire        bus_we,
    input  wire [3:0]  bus_addr,
    input  wire [31:0] bus_wdata,
    output reg  [31:0] bus_rdata,
    output wire        bus_ready,

    // 7-segment display outputs (Minisys common-anode, active-low)
    output wire [7:0]  seg_an,          // Digit enables (active-low)
    output wire [7:0]  seg_cat          // Segment cathodes (active-low)
);

    // Display data register
    // Each byte: [7]=DP, [6:0]=g,f,e,d,c,b,a (active-low)
    // seg_data[7:0]=rightmost, seg_data[31:24]=leftmost
    reg [31:0] seg_data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seg_data <= 32'hFFFF_FFFF;   // All segments off initially
        end else if (bus_en && bus_we && (bus_addr[3:0] == 4'h0)) begin
            seg_data <= bus_wdata;
        end
    end

    // Dynamic scanning counter: 50MHz / 2^17 ~ 381 Hz
    // Using bits [16:14] for 8-digit scanning
    reg [16:0] scan_cnt;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) scan_cnt <= 17'b0;
        else        scan_cnt <= scan_cnt + 1'b1;
    end

    wire [2:0] digit_sel = scan_cnt[16:14];

    // Digit multiplexing
    reg [7:0] seg_an_r;
    reg [7:0] seg_cat_r;

    always @(*) begin
        seg_an_r  = 8'hFF;   // All digits off
        seg_cat_r = 8'hFF;

        case (digit_sel)
            3'd0: begin seg_an_r = 8'b1111_1110; seg_cat_r = seg_data[7:0];   end
            3'd1: begin seg_an_r = 8'b1111_1101; seg_cat_r = seg_data[15:8];  end
            3'd2: begin seg_an_r = 8'b1111_1011; seg_cat_r = seg_data[23:16]; end
            3'd3: begin seg_an_r = 8'b1111_0111; seg_cat_r = seg_data[31:24]; end
            3'd4: begin seg_an_r = 8'b1110_1111; seg_cat_r = seg_data[7:0];   end
            3'd5: begin seg_an_r = 8'b1101_1111; seg_cat_r = seg_data[15:8];  end
            3'd6: begin seg_an_r = 8'b1011_1111; seg_cat_r = seg_data[23:16]; end
            3'd7: begin seg_an_r = 8'b0111_1111; seg_cat_r = seg_data[31:24]; end
        endcase
    end

    assign seg_an  = seg_an_r;
    assign seg_cat = seg_cat_r;

    // Read response
    always @(*) begin
        bus_rdata = 32'h0000_0000;
        if (bus_en && !bus_we) begin
            case (bus_addr[3:0])
                4'h0: bus_rdata = seg_data;
                default: bus_rdata = 32'h0000_0000;
            endcase
        end
    end

    assign bus_ready = bus_en;

endmodule
