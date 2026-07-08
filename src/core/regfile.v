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
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h00000000;
        end else if (reg_write && (rd_addr != `ZERO_REG)) begin
            regs[rd_addr] <= rd_wdata;
        end
    end

    assign rs1_data = (rs1_addr == `ZERO_REG) ? `ZERO_WORD :
                      (reg_write && (rs1_addr == rd_addr)) ? rd_wdata :
                      regs[rs1_addr];

    assign rs2_data = (rs2_addr == `ZERO_REG) ? `ZERO_WORD :
                      (reg_write && (rs2_addr == rd_addr)) ? rd_wdata :
                      regs[rs2_addr];

    assign rd_old_data = (rd_old_addr == `ZERO_REG) ? `ZERO_WORD :
                         (reg_write && (rd_old_addr == rd_addr)) ? rd_wdata :
                         regs[rd_old_addr];

endmodule