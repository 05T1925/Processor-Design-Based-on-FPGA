//==============================================================================
// riscv_mc_cpu.v - RV32I Multi-Cycle FSM CPU (Primary P0 Baseline)
//==============================================================================

`include "public.vh"

module riscv_mc_cpu (
    input  wire        clk,
    input  wire        rst_n,

    // Instruction bus
    output wire [31:0] ibus_addr,
    input  wire [31:0] ibus_rdata,
    output wire        ibus_en,

    // Data bus
    output wire [31:0] dbus_addr,
    output wire [31:0] dbus_wdata,
    input  wire [31:0] dbus_rdata,
    output wire [3:0]  dbus_byte_sel,
    output wire        dbus_we,
    output wire        dbus_en,

    // Debug outputs
    output wire [31:0] debug_pc,
    output wire [7:0]  debug_state,
    output wire [31:0] debug_x10,
    output wire        debug_illegal,

    // Performance counters
    output wire [31:0] perf_cycle_count,
    output wire [31:0] perf_instret_count,
    output wire [31:0] perf_mac_count
);

    localparam S_FETCH      = 3'd0;
    localparam S_DECODE     = 3'd1;
    localparam S_EXECUTE    = 3'd2;
    localparam S_MEMORY     = 3'd3;
    localparam S_WRITEBACK  = 3'd4;
    localparam S_HALT       = 3'd5;
    localparam S_MAC        = 3'd6;

    localparam WB_ALU = 2'b00;
    localparam WB_MEM = 2'b01;
    localparam WB_PC4 = 2'b10;
    localparam WB_MAC = 2'b11;

    reg [2:0]  state, next_state;
    reg [31:0] pc;
    reg [31:0] instr;
    reg [31:0] alu_result;
    reg [31:0] mem_rdata;
    reg [31:0] mac_product_low;
    reg        halted;
    reg        illegal;
    reg [4:0]  dec_rd_addr;
    reg [31:0] dec_rs1_data;
    reg [31:0] dec_rs2_data;
    reg [31:0] dec_rd_old_data;
    reg [31:0] dec_imm_val;
    reg [`ALUOP_BUS]   dec_alu_op;
    reg [`ALUTYPE_BUS] dec_alu_type;
    reg                dec_alu_src_imm;
    reg                dec_reg_write;
    reg                dec_mem_read;
    reg                dec_mem_write;
    reg [1:0]          dec_wb_sel;
    reg [2:0]          dec_branch_type;
    reg                dec_jump;
    reg                dec_jump_reg;
    reg                dec_is_mac;
    reg                dec_instret_pulse;
    reg                dec_mac_pulse;

    wire [`ALUOP_BUS]   ctrl_alu_op;
    wire [`ALUTYPE_BUS] ctrl_alu_type;
    wire                ctrl_alu_src_imm;
    wire                ctrl_reg_write;
    wire                ctrl_reg_read_rs1;
    wire                ctrl_reg_read_rs2;
    wire                ctrl_rd_old_read;
    wire                ctrl_mem_read;
    wire                ctrl_mem_write;
    wire [1:0]          ctrl_wb_sel;
    wire [2:0]          ctrl_branch_type;
    wire                ctrl_jump;
    wire                ctrl_jump_reg;
    wire [2:0]          ctrl_imm_sel;
    wire                ctrl_is_mac;
    wire                ctrl_halt;
    wire                ctrl_illegal;
    wire                ctrl_instret_pulse;
    wire                ctrl_mac_pulse;

    wire [31:0] rs1_data, rs2_data, rd_old_data;
    wire [31:0] imm_val;
    wire [31:0] alu_in_a, alu_in_b;
    wire [31:0] alu_out;
    wire [31:0] mac_result_unused;
    wire [31:0] mac_product_comb;
    wire        alu_zero;
    wire        br_taken;

    wire [31:0] cycle_cnt, instret_cnt, mac_cnt;
    wire        perf_instret_pulse;
    wire        perf_mac_pulse;

    wire [31:0] pc_plus_4;
    wire [31:0] jal_target;
    wire [31:0] jalr_target;
    wire [31:0] br_target;
    wire [31:0] next_pc_val;
    wire [31:0] wb_data;
    wire        is_branch_instr;

    mac_unit u_mac (
        // Use operands latched in DECODE. Reading the register file directly
        // here created an instruction-to-DSP critical path at 100 MHz.
        .rs1_data   (dec_rs1_data),
        .rs2_data   (dec_rs2_data),
        .rd_old_data(dec_rd_old_data),
        .mac_result (mac_result_unused),
        .product_low(mac_product_comb)
    );

    assign pc_plus_4   = pc + 32'd4;
    assign jal_target  = pc + dec_imm_val;
    assign br_target   = pc + dec_imm_val;
    assign jalr_target = {alu_out[31:1], 1'b0};

    assign is_branch_instr = (dec_alu_type == `ALUTYPE_JUMP) && !dec_jump && !dec_jump_reg;

    assign next_pc_val = dec_jump_reg ? jalr_target :
                         dec_jump     ? jal_target  :
                         is_branch_instr && br_taken ? br_target :
                                         pc_plus_4;

    control_unit u_control (
        .instr          (instr),
        .alu_op         (ctrl_alu_op),
        .alu_type       (ctrl_alu_type),
        .alu_src_imm    (ctrl_alu_src_imm),
        .reg_write      (ctrl_reg_write),
        .reg_read_rs1   (ctrl_reg_read_rs1),
        .reg_read_rs2   (ctrl_reg_read_rs2),
        .rd_old_read    (ctrl_rd_old_read),
        .mem_read       (ctrl_mem_read),
        .mem_write      (ctrl_mem_write),
        .wb_sel         (ctrl_wb_sel),
        .branch_type    (ctrl_branch_type),
        .jump           (ctrl_jump),
        .jump_reg       (ctrl_jump_reg),
        .imm_sel        (ctrl_imm_sel),
        .is_mac         (ctrl_is_mac),
        .halt           (ctrl_halt),
        .illegal_instr  (ctrl_illegal),
        .instret_pulse  (ctrl_instret_pulse),
        .mac_pulse      (ctrl_mac_pulse)
    );

    regfile u_regfile (
        .clk            (clk),
        .rst            (~rst_n),
        .rs1_addr       (instr[`RV_RS1_RANGE]),
        .rs2_addr       (instr[`RV_RS2_RANGE]),
        .rd_old_addr    (instr[`RV_RD_RANGE]),
        .rs1_data       (rs1_data),
        .rs2_data       (rs2_data),
        .rd_old_data    (rd_old_data),
        .reg_write      (dec_reg_write && (state == S_WRITEBACK)),
        .rd_addr        (dec_rd_addr),
        .rd_wdata       (wb_data)
    );

    imm_gen u_imm_gen (
        .instr          (instr),
        .imm_sel        (ctrl_imm_sel),
        .imm            (imm_val)
    );

    assign alu_in_a = (dec_alu_type == `ALUTYPE_SHIFT) ?
                        (dec_alu_src_imm ? dec_imm_val : dec_rs2_data) :
                      dec_jump_reg                    ? dec_rs1_data :
                      (dec_alu_op == `ALUOP_AUIPC)    ? pc           :
                      (dec_alu_type == `ALUTYPE_JUMP) ? pc           :
                                                         dec_rs1_data;

    assign alu_in_b = (dec_alu_type == `ALUTYPE_SHIFT) ? dec_rs1_data :
                      dec_alu_src_imm ? dec_imm_val : dec_rs2_data;

    alu u_alu (
        .a              (alu_in_a),
        .b              (alu_in_b),
        .alu_op         (dec_alu_op),
        .alu_type       (dec_alu_type),
        .result         (alu_out),
        .zero           (alu_zero)
    );

    branch_unit u_branch (
        .rs1_data       (dec_rs1_data),
        .rs2_data       (dec_rs2_data),
        .funct3         (dec_branch_type),
        .branch_taken   (br_taken)
    );

    csr_perf_counter u_perf (
        .clk            (clk),
        .rst            (~rst_n),
        .halted         (halted),
        .instret_pulse  (perf_instret_pulse),
        .mac_pulse      (perf_mac_pulse),
        .cycle_count    (cycle_cnt),
        .instret_count  (instret_cnt),
        .mac_count      (mac_cnt)
    );

    assign wb_data = (dec_wb_sel == WB_MEM) ? mem_rdata :
                     (dec_wb_sel == WB_PC4) ? pc_plus_4 :
                                               alu_result;

    assign ibus_addr = pc;
    assign ibus_en   = (state == S_FETCH);

    assign dbus_addr     = alu_result;
    assign dbus_wdata    = dec_rs2_data;
    assign dbus_byte_sel = 4'b1111;
    assign dbus_we       = (state == S_MEMORY) && dec_mem_write;
    assign dbus_en       = (state == S_MEMORY) && (dec_mem_read || dec_mem_write);

    assign debug_pc      = pc;
    assign debug_state   = {5'b0, state};
    assign debug_x10     = rs1_data;
    assign debug_illegal = illegal;

    // Retire each legal instruction exactly once in its final execution state.
    // Register-writing instructions retire in WRITEBACK, stores in MEMORY, and
    // branches in EXECUTE. EBREAK and illegal instructions never assert the
    // decoder's instret pulse.
    assign perf_instret_pulse = dec_instret_pulse &&
                                (((state == S_WRITEBACK) && dec_reg_write) ||
                                 ((state == S_MEMORY) && dec_mem_write) ||
                                 ((state == S_EXECUTE) && is_branch_instr));
    assign perf_mac_pulse     = dec_mac_pulse && (state == S_WRITEBACK);

    assign perf_cycle_count   = cycle_cnt;
    assign perf_instret_count = instret_cnt;
    assign perf_mac_count     = mac_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_FETCH;
            pc           <= `PC_INIT;
            instr        <= `RV_NOP;
            alu_result   <= `ZERO_WORD;
            mem_rdata    <= `ZERO_WORD;
            mac_product_low <= `ZERO_WORD;
            halted       <= `FALSE;
            illegal      <= `FALSE;
            dec_rd_addr  <= 5'b0;
            dec_rs1_data <= `ZERO_WORD;
            dec_rs2_data <= `ZERO_WORD;
            dec_rd_old_data <= `ZERO_WORD;
            dec_imm_val  <= `ZERO_WORD;
            dec_alu_op   <= `ALUOP_NOP;
            dec_alu_type <= `ALUTYPE_NOP;
            dec_alu_src_imm <= `FALSE;
            dec_reg_write <= `FALSE;
            dec_mem_read <= `FALSE;
            dec_mem_write <= `FALSE;
            dec_wb_sel <= WB_ALU;
            dec_branch_type <= `RV_F3_BEQ;
            dec_jump <= `FALSE;
            dec_jump_reg <= `FALSE;
            dec_is_mac <= `FALSE;
            dec_instret_pulse <= `FALSE;
            dec_mac_pulse <= `FALSE;
        end else begin
            state <= next_state;

            case (state)
                S_FETCH: begin
                    instr <= ibus_rdata;
                end

                S_DECODE: begin
                    dec_rd_addr       <= instr[`RV_RD_RANGE];
                    dec_rs1_data      <= rs1_data;
                    dec_rs2_data      <= rs2_data;
                    dec_rd_old_data   <= rd_old_data;
                    dec_imm_val       <= imm_val;
                    dec_alu_op        <= ctrl_alu_op;
                    dec_alu_type      <= ctrl_alu_type;
                    dec_alu_src_imm   <= ctrl_alu_src_imm;
                    dec_reg_write     <= ctrl_reg_write;
                    dec_mem_read      <= ctrl_mem_read;
                    dec_mem_write     <= ctrl_mem_write;
                    dec_wb_sel        <= ctrl_wb_sel;
                    dec_branch_type   <= ctrl_branch_type;
                    dec_jump          <= ctrl_jump;
                    dec_jump_reg      <= ctrl_jump_reg;
                    dec_is_mac        <= ctrl_is_mac;
                    dec_instret_pulse <= ctrl_instret_pulse;
                    dec_mac_pulse     <= ctrl_mac_pulse;

                    if (ctrl_halt) begin
                        halted <= `TRUE;
                    end else if (ctrl_illegal) begin
                        illegal <= `TRUE;
                        halted  <= `TRUE;
                    end
                end

                S_EXECUTE: begin
                    if (dec_is_mac)
                        mac_product_low <= mac_product_comb;
                    else
                        alu_result <= alu_out;

                    if (!(dec_mem_read || dec_mem_write || dec_reg_write))
                        pc <= next_pc_val;
                end

                S_MAC: begin
                    alu_result <= dec_rd_old_data + mac_product_low;
                end

                S_MEMORY: begin
                    if (dec_mem_read)
                        mem_rdata <= dbus_rdata;

                    if (!dec_reg_write)
                        pc <= next_pc_val;
                end

                S_WRITEBACK: begin
                    pc <= next_pc_val;
                end

                S_HALT: begin
                    halted <= `TRUE;
                end

                default: begin
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;

        case (state)
            S_FETCH: begin
                next_state = S_DECODE;
            end

            S_DECODE: begin
                if (ctrl_halt || ctrl_illegal)
                    next_state = S_HALT;
                else
                    next_state = S_EXECUTE;
            end

            S_EXECUTE: begin
                if (dec_is_mac)
                    next_state = S_MAC;
                else if (dec_mem_read || dec_mem_write)
                    next_state = S_MEMORY;
                else if (dec_reg_write)
                    next_state = S_WRITEBACK;
                else
                    next_state = S_FETCH;
            end

            S_MAC: begin
                next_state = S_WRITEBACK;
            end

            S_MEMORY: begin
                if (dec_reg_write)
                    next_state = S_WRITEBACK;
                else
                    next_state = S_FETCH;
            end

            S_WRITEBACK: begin
                next_state = S_FETCH;
            end

            S_HALT: begin
                next_state = S_HALT;
            end

            default: begin
                next_state = S_FETCH;
            end
        endcase
    end

endmodule
