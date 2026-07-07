//==============================================================================
// riscv_mc_cpu.v - RV32I Multi-Cycle FSM CPU (Primary P0 Baseline)
//
// Architecture: 6-state multi-cycle FSM
//   FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK → FETCH
//   HALT (EBREAK detected, stop fetching)
//
// Supported instructions: 31 RV32I + MAC custom extension
//   ALU R/I: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU
//   ALU Imm: ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU
//   Load/Store: LW, SW
//   Branch: BEQ, BNE, BLT, BGE, BLTU, BGEU
//   Jump: JAL, JALR
//   Upper: LUI, AUIPC
//   System: EBREAK (HALT)
//   Custom: MAC (rd_new = rd_old + rs1 * rs2)
//
// Based on: minisys_unified RISCV_SC + our custom MAC + perf_counter
//==============================================================================

`include "public.vh"

module riscv_mc_cpu (
    input  wire        clk,
    input  wire        rst_n,

    // Instruction bus (→ inst_ram)
    output wire [31:0] ibus_addr,
    input  wire [31:0] ibus_rdata,
    output wire        ibus_en,

    // Data bus (→ data_ram + peripherals)
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
    output wire        debug_illegal
);

    //==========================================================================
    // FSM State Encoding
    //==========================================================================
    localparam S_FETCH      = 3'd0;
    localparam S_DECODE     = 3'd1;
    localparam S_EXECUTE    = 3'd2;
    localparam S_MEMORY     = 3'd3;
    localparam S_WRITEBACK  = 3'd4;
    localparam S_HALT       = 3'd5;

    reg [2:0] state, next_state;

    //==========================================================================
    // Internal registers (pipeline-style, latched between states)
    //==========================================================================
    reg [31:0] pc;
    reg [31:0] instr;
    reg [31:0] alu_result;
    reg [31:0] mem_rdata;
    reg [31:0] writeback_data;
    reg        zero_flag;
    reg        branch_taken;
    reg        halted;
    reg        illegal;

    //==========================================================================
    // Control signals (from control_unit)
    //==========================================================================
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

    localparam WB_ALU = 2'b00;
    localparam WB_MEM = 2'b01;
    localparam WB_PC4 = 2'b10;
    localparam WB_MAC = 2'b11;

    //==========================================================================
    // Datapath wires
    //==========================================================================
    wire [31:0] rs1_data, rs2_data, rd_old_data;
    wire [31:0] imm_val;
    wire [31:0] alu_in_a, alu_in_b;
    wire [31:0] alu_out;
    wire [31:0] branch_target;
    wire [31:0] mac_result;
    wire        alu_zero;
    wire        br_taken;

    // Performance counter wires
    wire [31:0] cycle_cnt, instret_cnt, mac_cnt;
    wire        perf_instret_pulse;
    wire        perf_mac_pulse;

    //==========================================================================
    // Next PC logic
    //==========================================================================
    wire [31:0] pc_plus_4 = pc + 32'd4;

    // JAL target: pc + J-immediate
    wire [31:0] jal_target;
    assign jal_target = pc + imm_val;

    // JALR target: (rs1_data + I-immediate) & ~1
    wire [31:0] jalr_target;
    assign jalr_target = {alu_out[31:1], 1'b0};

    // Branch target: pc + B-immediate
    wire [31:0] br_target;
    assign br_target = pc + imm_val;

    wire [31:0] next_pc_val;
    assign next_pc_val = ctrl_jump_reg      ? jalr_target  :
                         ctrl_jump          ? jal_target   :
                         (branch_taken)     ? br_target    :
                         pc_plus_4;

    //==========================================================================
    // Control Unit Instance
    //==========================================================================
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

    //==========================================================================
    // Register File Instance (3-read, 1-write)
    //==========================================================================
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
        .rd_wdata       (writeback_data)
    );

    //==========================================================================
    // Immediate Generator Instance
    //==========================================================================
    imm_gen u_imm_gen (
        .instr          (instr),
        .imm_sel        (ctrl_imm_sel),
        .imm            (imm_val)
    );

    //==========================================================================
    // ALU Instance
    //==========================================================================
    // ALU input A: rs1_data for arithmetic, pc for AUIPC/JAL/branch
    assign alu_in_a = (state == S_EXECUTE) ? rs1_data : pc;

    // ALU input B: rs2_data or immediate
    assign alu_in_b = ctrl_alu_src_imm ? imm_val : rs2_data;

    alu u_alu (
        .a              (alu_in_a),
        .b              (alu_in_b),
        .alu_op         (ctrl_alu_op),
        .alu_type       (ctrl_alu_type),
        .result         (alu_out),
        .zero           (alu_zero)
    );

    //==========================================================================
    // Branch Unit Instance
    //==========================================================================
    branch_unit u_branch (
        .rs1_data       (rs1_data),
        .rs2_data       (rs2_data),
        .funct3         (ctrl_branch_type),
        .branch_taken   (br_taken)
    );

    //==========================================================================
    // MAC Unit Instance
    //==========================================================================
    mac_unit u_mac (
        .rs1_data       (rs1_data),
        .rs2_data       (rs2_data),
        .rd_old_data    (rd_old_data),
        .mac_result     (mac_result)
    );

    //==========================================================================
    // Performance Counter Instance
    //==========================================================================
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

    //==========================================================================
    // Bus interfaces
    //==========================================================================
    assign ibus_addr = pc;
    assign ibus_en   = (state == S_FETCH);

    assign dbus_addr      = alu_result;
    assign dbus_wdata     = rs2_data;
    assign dbus_byte_sel  = 4'b1111;     // Word access only
    assign dbus_we        = (state == S_MEMORY) && ctrl_mem_write;
    assign dbus_en        = (state == S_MEMORY) && (ctrl_mem_read || ctrl_mem_write);

    //==========================================================================
    // Debug outputs
    //==========================================================================
    assign debug_pc       = pc;
    assign debug_state    = {5'b0, state};
    assign debug_x10      = rs1_data;     // x10 = a0 (when rs1 is x10)
    assign debug_illegal  = illegal;

    //==========================================================================
    // FSM: State register
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_FETCH;
        end else begin
            state <= next_state;
        end
    end

    //==========================================================================
    // FSM: Next-state logic & state actions
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc             <= `PC_INIT;
            instr          <= `RV_NOP;
            alu_result     <= `ZERO_WORD;
            mem_rdata      <= `ZERO_WORD;
            writeback_data <= `ZERO_WORD;
            zero_flag      <= `FALSE;
            branch_taken   <= `FALSE;
            halted         <= `FALSE;
            illegal        <= `FALSE;
            next_state     <= S_FETCH;
        end else begin
            case (state)
                //------------------------------------------------------------------
                // FETCH: Read instruction from inst_ram
                //------------------------------------------------------------------
                S_FETCH: begin
                    instr      <= ibus_rdata;
                    next_state <= S_DECODE;
                end

                //------------------------------------------------------------------
                // DECODE: Control unit decodes instruction
                //------------------------------------------------------------------
                S_DECODE: begin
                    if (ctrl_halt) begin
                        halted     <= `TRUE;
                        next_state <= S_HALT;
                    end else if (ctrl_illegal) begin
                        illegal    <= `TRUE;
                        halted     <= `TRUE;
                        next_state <= S_HALT;
                    end else begin
                        next_state <= S_EXECUTE;
                    end
                end

                //------------------------------------------------------------------
                // EXECUTE: ALU, MAC, branch evaluation, address calculation
                //------------------------------------------------------------------
                S_EXECUTE: begin
                    alu_result <= alu_out;

                    // Branch evaluation
                    branch_taken <= (ctrl_jump || ctrl_jump_reg) ? `FALSE : br_taken;

                    // MAC execution happens combinationally; result used in WB
                    if (ctrl_is_mac) begin
                        alu_result <= mac_result;
                    end

                    // Next state
                    if (ctrl_mem_read || ctrl_mem_write)
                        next_state <= S_MEMORY;
                    else if (ctrl_reg_write)
                        next_state <= S_WRITEBACK;
                    else begin
                        // No writeback, no memory → update PC and go to FETCH
                        pc         <= next_pc_val;
                        next_state <= S_FETCH;
                    end
                end

                //------------------------------------------------------------------
                // MEMORY: LW (read from dbus) or SW (write to dbus)
                //------------------------------------------------------------------
                S_MEMORY: begin
                    if (ctrl_mem_read) begin
                        mem_rdata <= dbus_rdata;
                    end

                    if (ctrl_reg_write)
                        next_state <= S_WRITEBACK;
                    else begin
                        pc         <= next_pc_val;
                        next_state <= S_FETCH;
                    end
                end

                //------------------------------------------------------------------
                // WRITEBACK: Write result to register file
                //------------------------------------------------------------------
                S_WRITEBACK: begin
                    // Select writeback data source
                    case (ctrl_wb_sel)
                        WB_MEM: writeback_data <= mem_rdata;
                        WB_PC4: writeback_data <= pc_plus_4;
                        WB_MAC: writeback_data <= mac_result;
                        default: writeback_data <= alu_result;  // WB_ALU
                    endcase

                    // Update PC for next instruction
                    pc         <= next_pc_val;
                    next_state <= S_FETCH;
                end

                //------------------------------------------------------------------
                // HALT: Stop operation
                //------------------------------------------------------------------
                S_HALT: begin
                    halted     <= `TRUE;
                    next_state <= S_HALT;
                end

                default: next_state <= S_FETCH;
            endcase
        end
    end

    //==========================================================================
    // Performance counter pulse generation (1-cycle pulse in WRITEBACK)
    //==========================================================================
    assign perf_instret_pulse = ctrl_instret_pulse && (state == S_WRITEBACK);
    assign perf_mac_pulse     = ctrl_mac_pulse && (state == S_WRITEBACK);

endmodule
