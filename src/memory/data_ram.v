//==============================================================================
// data_ram.v - Data Memory (BRAM with byte-enable write)
//
// Based on: minisys_unified/rtl/mem/data_ram.v
//
// Synchronous-write, combinational-read. Supports byte/half-word/word writes.
// Little-endian byte ordering.
//==============================================================================

module data_ram #(
    parameter RAM_SIZE = 32768          // Size in bytes (32KB default)
) (
    input  wire        clk,
    input  wire [31:0] addr,            // Byte address
    input  wire [31:0] wdata,           // Write data
    input  wire [3:0]  byte_sel,        // Byte enable (1=write this byte)
    input  wire        we,              // Write enable
    input  wire        en,              // Chip enable
    output reg  [31:0] rdata,           // Read data (combinational)
    output wire        ready            // Always ready (single-cycle BRAM)
);

    localparam RAM_DEPTH = RAM_SIZE / 4;
    localparam ADDR_WIDTH = $clog2(RAM_DEPTH);

    reg [31:0] mem [0:RAM_DEPTH-1];

    wire [ADDR_WIDTH-1:0] word_addr;
    assign word_addr = addr[ADDR_WIDTH+1:2];
    assign ready = 1'b1;

    // Write with byte-enable
    integer i;
    always @(posedge clk) begin
        if (en && we) begin
            for (i = 0; i < 4; i = i + 1) begin
                if (byte_sel[i])
                    mem[word_addr][i*8 +: 8] <= wdata[i*8 +: 8];
            end
        end
    end

    // Combinational read
    always @(*) begin
        if (en && !we)
            rdata = mem[word_addr];
        else
            rdata = 32'h0000_0000;
    end

endmodule
