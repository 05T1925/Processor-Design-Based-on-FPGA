//==============================================================================
// inst_ram.v - Instruction Memory (BRAM)
//
// Based on: minisys_unified/rtl/mem/inst_ram.v
//
// Combinational read, single-cycle access instruction memory.
// Can be initialized via UART bootloader write port.
//==============================================================================

module inst_ram #(
    parameter RAM_SIZE = 32768,         // Size in bytes (32KB default)
    parameter INIT_FILE = "boot_rom.mem"
) (
    input  wire        clk,
    input  wire [31:0] addr,            // Byte address from CPU
    output reg  [31:0] rdata,           // Instruction data
    input  wire        en,              // Read enable

    // UART bootloader write port
    input  wire        upg_clk,
    input  wire        upg_rst_n,
    input  wire        upg_wen,
    input  wire [13:0] upg_addr,        // Word address (14-bit = 16K words)
    input  wire [31:0] upg_wdata
);

    localparam RAM_DEPTH = RAM_SIZE / 4;

    // Vivado 2017.4 / 2018.3 compatible $clog2 replacement
    function integer clog2;
        input integer v;
        integer t;
        begin
            t = v - 1;
            for (clog2 = 0; t > 0; clog2 = clog2 + 1)
                t = t >> 1;
        end
    endfunction
    localparam ADDR_WIDTH = clog2(RAM_DEPTH);

    reg [31:0] mem [0:RAM_DEPTH-1];

    // Initialize program memory from a hex file for simulation and synthesis.
    initial begin
        $readmemh(INIT_FILE, mem);
    end

    // CPU read port (combinational)
    wire [ADDR_WIDTH-1:0] cpu_word_addr;
    assign cpu_word_addr = addr[ADDR_WIDTH+1:2];

    always @(*) begin
        if (en)
            rdata = mem[cpu_word_addr];
        else
            rdata = 32'h0000_0000;
    end

    // UART bootloader write port
    always @(posedge upg_clk) begin
        if (upg_wen)
            mem[upg_addr] <= upg_wdata;
    end

endmodule
