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

    localparam WB_ALU = 2'b00;
    localparam WB_MEM = 2'b01;
    localparam WB_PC4 = 2'b10;
    localparam WB_MAC = 2'b11;

    reg [2:0]  state, next_state;
    reg [31:0] pc;
    reg [31:0] instr;
    reg [31:0] alu_result;
    reg [31:0] mem_rdata;
    reg        halted;
    reg        illegal;

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
    wire [31:0] mac_result;
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

    assign pc_plus_4   = pc + 32'd4;
    assign jal_target  = pc + imm_val;
    assign br_target   = pc + imm_val;
    assign jalr_target = {alu_out[31:1], 1'b0};

    assign is_branch_instr = (ctrl_alu_type == `ALUTYPE_JUMP) && !ctrl_jump && !ctrl_jump_reg;

    assign next_pc_val = ctrl_jump_reg ? jalr_target :
                         ctrl_jump     ? jal_target  :
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
        .reg_write      (ctrl_reg_write && (state == S_WRITEBACK)),
        .rd_addr        (instr[`RV_RD_RANGE]),
        .rd_wdata       (wb_data)
    );

    imm_gen u_imm_gen (
        .instr          (instr),
        .imm_sel        (ctrl_imm_sel),
        .imm            (imm_val)
    );

    assign alu_in_a = ctrl_jump_reg                    ? rs1_data :
                      (ctrl_alu_op == `ALUOP_AUIPC)    ? pc       :
                      (ctrl_alu_type == `ALUTYPE_JUMP) ? pc       :
                                                         rs1_data;

    assign alu_in_b = ctrl_alu_src_imm ? imm_val : rs2_data;

    alu u_alu (
        .a              (alu_in_a),
        .b              (alu_in_b),
        .alu_op         (ctrl_alu_op),
        .alu_type       (ctrl_alu_type),
        .result         (alu_out),
        .zero           (alu_zero)
    );

    branch_unit u_branch (
        .rs1_data       (rs1_data),
        .rs2_data       (rs2_data),
        .funct3         (ctrl_branch_type),
        .branch_taken   (br_taken)
    );

    mac_unit u_mac (
        .rs1_data       (rs1_data),
        .rs2_data       (rs2_data),
        .rd_old_data    (rd_old_data),
        .mac_result     (mac_result)
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

    assign wb_data = (ctrl_wb_sel == WB_MEM) ? mem_rdata  :
                     (ctrl_wb_sel == WB_PC4) ? pc_plus_4  :
                     (ctrl_wb_sel == WB_MAC) ? alu_result :
                                               alu_result;

    assign ibus_addr = pc;
    assign ibus_en   = (state == S_FETCH);

    assign dbus_addr     = alu_result;
    assign dbus_wdata    = rs2_data;
    assign dbus_byte_sel = 4'b1111;
    assign dbus_we       = (state == S_MEMORY) && ctrl_mem_write;
    assign dbus_en       = (state == S_MEMORY) && (ctrl_mem_read || ctrl_mem_write);

    assign debug_pc      = pc;
    assign debug_state   = {5'b0, state};
    assign debug_x10     = rs1_data;
    assign debug_illegal = illegal;

    // Retire each legal instruction exactly once in its final execution state.
    // Register-writing instructions retire in WRITEBACK, stores in MEMORY, and
    // branches in EXECUTE. EBREAK and illegal instructions never assert the
    // decoder's instret pulse.
    assign perf_instret_pulse = ctrl_instret_pulse &&
                                (((state == S_WRITEBACK) && ctrl_reg_write) ||
                                 ((state == S_MEMORY) && ctrl_mem_write) ||
                                 ((state == S_EXECUTE) && is_branch_instr));
    assign perf_mac_pulse     = ctrl_mac_pulse && (state == S_WRITEBACK);

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
            halted       <= `FALSE;
            illegal      <= `FALSE;
        end else begin
            state <= next_state;

            case (state)
                S_FETCH: begin
                    instr <= ibus_rdata;
                end

                S_DECODE: begin
                    if (ctrl_halt) begin
                        halted <= `TRUE;
                    end else if (ctrl_illegal) begin
                        illegal <= `TRUE;
                        halted  <= `TRUE;
                    end
                end

                S_EXECUTE: begin
                    if (ctrl_is_mac)
                        alu_result <= mac_result;
                    else
                        alu_result <= alu_out;

                    if (!(ctrl_mem_read || ctrl_mem_write || ctrl_reg_write))
                        pc <= next_pc_val;
                end

                S_MEMORY: begin
                    if (ctrl_mem_read)
                        mem_rdata <= dbus_rdata;

                    if (!ctrl_reg_write)
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
                if (ctrl_mem_read || ctrl_mem_write)
                    next_state = S_MEMORY;
                else if (ctrl_reg_write)
                    next_state = S_WRITEBACK;
                else
                    next_state = S_FETCH;
            end

            S_MEMORY: begin
                if (ctrl_reg_write)
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
