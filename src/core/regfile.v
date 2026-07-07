//==============================================================================
// regfile.v - RV32I Register File (3-read, 1-write)
//
// Based on: NCUT regfile.v + MAC third read port
//
// 32 x 32-bit registers. x0 hardwired to zero.
// Internal write-after-read forwarding: if rd_addr matches rs1/rs2/rd_old,
// the new wdata is directly output (bypassing the write cycle).
//==============================================================================

`include "public.vh"

module regfile (
    input  wire        clk,
    input  wire        rst,

    // Read port 1
    input  wire [`REG_ADDR_WIDTH-1:0] rs1_addr,
    output wire [31:0]                rs1_data,

    // Read port 2
    input  wire [`REG_ADDR_WIDTH-1:0] rs2_addr,
    output wire [31:0]                rs2_data,

    // Read port 3 (MAC rd_old)
    input  wire [`REG_ADDR_WIDTH-1:0] rd_old_addr,
    output wire [31:0]                rd_old_data,

    // Write port
    input  wire                       reg_write,
    input  wire [`REG_ADDR_WIDTH-1:0] rd_addr,
    input  wire [31:0]                rd_wdata
);

    reg [31:0] regs [0:31];

    //--------------------------------------------------------------------------
    // Write (synchronous, posedge clk)
    // x0 is hardwired; writes to x0 are ignored
    //--------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            integer i;
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h00000000;
        end else if (reg_write && (rd_addr != `ZERO_REG)) begin
            regs[rd_addr] <= rd_wdata;
        end
    end

    //--------------------------------------------------------------------------
    // Read port 1 (combinational, with internal forwarding)
    //--------------------------------------------------------------------------
    assign rs1_data = (rs1_addr == `ZERO_REG) ? `ZERO_WORD :
                      (reg_write && (rs1_addr == rd_addr)) ? rd_wdata :
                      regs[rs1_addr];

    //--------------------------------------------------------------------------
    // Read port 2 (combinational, with internal forwarding)
    //--------------------------------------------------------------------------
    assign rs2_data = (rs2_addr == `ZERO_REG) ? `ZERO_WORD :
                      (reg_write && (rs2_addr == rd_addr)) ? rd_wdata :
                      regs[rs2_addr];

    //--------------------------------------------------------------------------
    // Read port 3: MAC rd_old (combinational, with internal forwarding)
    //--------------------------------------------------------------------------
    assign rd_old_data = (rd_old_addr == `ZERO_REG) ? `ZERO_WORD :
                         (reg_write && (rd_old_addr == rd_addr)) ? rd_wdata :
                         regs[rd_old_addr];

endmodule
