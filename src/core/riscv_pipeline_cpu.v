//==============================================================================
// riscv_pipeline_cpu.v - RV32I 5-Stage Pipeline CPU (P2 Sprint)
//
// Classic RISC 5-stage pipeline: IF → ID → EX → MEM → WB
//
// Features:
//   - Full forwarding (EX/MEM→EX, MEM/WB→EX, MEM/WB→MEM store data)
//   - Load-use hazard detection with 1-cycle stall
//   - BTB dynamic branch prediction (16-entry, 2-bit saturating counter)
//   - JAL/JALR resolved in ID, 1-cycle penalty
//   - MAC instruction fully supported with forwarding
//   - EBREAK → halt + pipeline drain
//   - Performance counters (cycle/instret/mac/br_total/br_mispred/btb_hit)
//
// Board: Minisys (XC7A100T-FGG484-1, 100MHz)
// Reuses: control_unit, regfile, alu, branch_unit, imm_gen, mac_unit,
//         csr_perf_counter
//==============================================================================

`include "public.vh"

module riscv_pipeline_cpu (
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
    output wire [31:0] perf_mac_count,

    // BTB branch prediction statistics
    output wire [31:0] perf_br_total_count,
    output wire [31:0] perf_br_mispred_count,
    output wire [31:0] perf_btb_hit_count
);

    //==========================================================================
    // Pipeline register structures (flat naming convention)
    //
    // Convention:
    //   if_id_*  = IF/ID pipeline register  (Fetch → Decode boundary)
    //   id_ex_*  = ID/EX pipeline register  (Decode → Execute boundary)
    //   ex_mem_* = EX/MEM pipeline register (Execute → Memory boundary)
    //   mem_wb_* = MEM/WB pipeline register (Memory → WriteBack boundary)
    //==========================================================================

    //--------------------------------------------------------------------------
    // IF/ID pipeline registers
    //--------------------------------------------------------------------------
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;
    reg        if_id_valid;       // 1 = valid instruction, 0 = bubble (NOP)
    reg        if_id_btb_pred;    // BTB prediction captured at IF stage

    //--------------------------------------------------------------------------
    // ID/EX pipeline registers
    //--------------------------------------------------------------------------
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_rs1_data;
    reg [31:0] id_ex_rs2_data;
    reg [31:0] id_ex_rd_old_data;
    reg [31:0] id_ex_imm;
    reg [4:0]  id_ex_rd_addr;
    reg [4:0]  id_ex_rs1_addr;      // For forwarding hazard detection
    reg [4:0]  id_ex_rs2_addr;      // For forwarding hazard detection
    reg [`ALUOP_BUS]   id_ex_alu_op;
    reg [`ALUTYPE_BUS] id_ex_alu_type;
    reg                id_ex_alu_src_imm;
    reg                id_ex_reg_write;
    reg                id_ex_mem_read;
    reg                id_ex_mem_write;
    reg [1:0]          id_ex_wb_sel;
    reg [2:0]          id_ex_branch_type;
    reg                id_ex_jump;
    reg                id_ex_jump_reg;
    reg                id_ex_is_mac;
    reg                id_ex_instret_pulse;
    reg                id_ex_mac_pulse;
    reg                id_ex_valid;
    reg                id_ex_btb_pred_taken; // BTB prediction for this instruction

    //--------------------------------------------------------------------------
    // EX/MEM pipeline registers
    //--------------------------------------------------------------------------
    reg [31:0] ex_mem_pc_plus_4;
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_rs2_data;       // Possibly forwarded store data
    reg [4:0]  ex_mem_rs2_addr;       // Store source register for MEM forwarding
    reg [4:0]  ex_mem_rd_addr;
    reg        ex_mem_reg_write;
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_write;
    reg [1:0]  ex_mem_wb_sel;
    reg        ex_mem_is_mac;
    reg        ex_mem_instret_pulse;
    reg        ex_mem_mac_pulse;
    reg        ex_mem_valid;

    //--------------------------------------------------------------------------
    // MEM/WB pipeline registers
    //--------------------------------------------------------------------------
    reg [31:0] mem_wb_wb_data;
    reg [4:0]  mem_wb_rd_addr;
    reg        mem_wb_reg_write;
    reg        mem_wb_is_mac;
    reg        mem_wb_instret_pulse;
    reg        mem_wb_mac_pulse;
    reg        mem_wb_valid;

    //==========================================================================
    // Wires — PC stage (IF) and target address calculation
    //==========================================================================
    reg  [31:0] pc_val;
    wire [31:0] pc_plus_4_w;
    wire [31:0] jal_target_w;       // JAL target (ID stage)
    wire [31:0] jalr_target_w;      // JALR target (EX stage, with forwarding)
    wire [31:0] branch_target_w;    // Branch target (EX stage)
    wire        stall_w;
    wire        jal_flush;          // JAL flush (ID stage)
    wire        jalr_flush;         // JALR flush (EX stage)
    wire        branch_flush;       // Taken branch flush (EX stage)

    assign pc_plus_4_w = pc_val + 32'd4;

    // JAL target (ID stage): PC + immediate (no forwarding needed)
    assign jal_target_w = if_id_pc + id_imm_w;

    // JALR target (EX stage): forwarded rs1 + immediate, LSB clear
    wire [31:0] jalr_target_sum_w;
    assign jalr_target_sum_w = forward_rs1_data + id_ex_imm;
    assign jalr_target_w = {jalr_target_sum_w[31:1], 1'b0};

    // Branch target (EX stage): ID/EX PC + immediate
    assign branch_target_w = id_ex_pc + id_ex_imm;

    // Next-PC priority: EX mispred recovery > EX JALR > ID JAL > BTB prediction > PC+4
    wire [31:0] pc_next;
    assign pc_next = branch_flush    ? branch_target_w :
                     jalr_flush      ? jalr_target_w   :
                     jal_flush       ? jal_target_w    :
                     use_btb_prediction ? btb_predict_target :
                                          pc_plus_4_w;

    //==========================================================================
    // Wires — ID stage
    //==========================================================================
    wire [31:0] id_instr_w;
    wire [31:0] id_rs1_data_w;
    wire [31:0] id_rs2_data_w;
    wire [31:0] id_rd_old_data_w;
    wire [31:0] id_imm_w;

    // Control unit outputs (combinational, driven by current IF/ID instruction)
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

    // ID stage register addresses (from instruction fields)
    wire [4:0] id_rs1_addr_w;
    wire [4:0] id_rs2_addr_w;
    wire [4:0] id_rd_addr_w;

    assign id_instr_w  = if_id_instr;
    assign id_rs1_addr_w = id_instr_w[`RV_RS1_RANGE];
    assign id_rs2_addr_w = id_instr_w[`RV_RS2_RANGE];
    assign id_rd_addr_w  = id_instr_w[`RV_RD_RANGE];

    //==========================================================================
    // Wires — EX stage (forwarding + ALU + branch)
    //==========================================================================
    wire [31:0] ex_alu_in_a;
    wire [31:0] ex_alu_in_b;
    wire [31:0] ex_alu_out;
    wire        ex_alu_zero;
    wire [31:0] ex_mac_result;
    wire        ex_br_taken;

    // Forwarding control (2-bit: 00=reg, 01=EX/MEM, 10=MEM/WB)
    reg  [1:0]  forward_rs1_sel;
    reg  [1:0]  forward_rs2_sel;
    wire [31:0] forward_rs1_data;
    wire [31:0] forward_rs2_data;

    //==========================================================================
    // Wires — MEM stage
    //==========================================================================
    wire [31:0] mem_rs2_forwarded;    // Forwarded store data from MEM/WB

    //==========================================================================
    // Wires — Hazard detection
    //==========================================================================
    wire load_use_hazard;
    wire ebreak_halt;

    //==========================================================================
    // Wires — performance
    //==========================================================================
    wire        halted_w;
    wire        perf_instret_pulse;
    wire        perf_mac_pulse;
    wire [31:0] cycle_cnt, instret_cnt, mac_cnt;

    //==========================================================================
    // BTB (Branch Target Buffer) — Dynamic Branch Prediction
    //
    // 16-entry direct-mapped BTB with 2-bit saturating counters.
    // Lookup in IF stage (combinational), update in EX stage (sequential).
    //
    // PC selection with BTB prediction:
    //   IF: BTB lookup → if predict taken, fetch from BTB target instead of PC+4
    //   EX: Branch resolves → verify prediction, flush if wrong, update BTB
    //
    // Misprediction penalty: 1 cycle (same as static prediction)
    // Benefit: fewer taken-branch flushes (only on misprediction, not every taken branch)
    //==========================================================================
    wire        btb_predict_taken;
    wire [31:0] btb_predict_target;
    wire [31:0] btb_lookup_cnt;
    wire [31:0] btb_hit_cnt;
    wire [31:0] btb_mispred_cnt;

    // BTB prediction is used for PC selection in IF stage
    // Only redirect when BTB predicts taken AND we haven't already taken a branch
    wire        use_btb_prediction;
    assign use_btb_prediction = btb_predict_taken && !branch_flush && !jalr_flush && !jal_flush;

    // BTB update: triggered when a conditional branch resolves in EX stage
    wire btb_update_valid;
    wire [31:0] btb_actual_target;
    assign btb_update_valid = id_ex_valid &&
                              (id_ex_alu_type == `ALUTYPE_JUMP) &&
                              !id_ex_jump && !id_ex_jump_reg;
    assign btb_actual_target = id_ex_pc + id_ex_imm;

    btb #(
        .ENTRIES(16)
    ) u_btb (
        .clk              (clk),
        .rst_n            (rst_n),
        .lookup_pc        (pc_val),
        .predict_taken    (btb_predict_taken),
        .predict_target   (btb_predict_target),
        .update_valid     (btb_update_valid),
        .update_pc        (id_ex_pc),
        .update_target    (btb_actual_target),
        .update_taken     (ex_br_taken),
        .btb_lookup_count (btb_lookup_cnt),
        .btb_hit_count    (btb_hit_cnt),
        .btb_mispred_count(btb_mispred_cnt)
    );

    // BTB misprediction: we predicted one way but branch resolved the other way.
    // This happens when BTB predicts "taken" but branch is not-taken,
    // OR BTB predicts "not-taken" (or misses) but branch is taken.
    // The latter case is identical to the existing branch_flush.
    // We track both for accuracy statistics.
    reg [31:0] br_total_cnt, br_mispred_cnt, btb_hit_cnt_r;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            br_total_cnt   <= 32'd0;
            br_mispred_cnt <= 32'd0;
            btb_hit_cnt_r  <= 32'd0;
        end else begin
            if (btb_update_valid) begin
                br_total_cnt <= br_total_cnt + 32'd1;
                // Misprediction: saved BTB prediction (from IF stage) vs actual outcome
                if (id_ex_btb_pred_taken != ex_br_taken)
                    br_mispred_cnt <= br_mispred_cnt + 32'd1;
                // BTB predicted taken for this branch
                if (id_ex_btb_pred_taken)
                    btb_hit_cnt_r <= btb_hit_cnt_r + 32'd1;
            end
        end
    end

    assign perf_br_total_count   = br_total_cnt;
    assign perf_br_mispred_count = br_mispred_cnt;
    assign perf_btb_hit_count    = btb_hit_cnt_r;

    //==========================================================================
    // Submodule: Control Unit (combinational, driven by IF/ID instruction)
    //==========================================================================
    control_unit u_control (
        .instr          (if_id_instr),
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
    // Submodule: Register File (3R1W, synchronous write)
    //==========================================================================
    regfile u_regfile (
        .clk            (clk),
        .rst            (~rst_n),
        .rs1_addr       (id_rs1_addr_w),
        .rs2_addr       (id_rs2_addr_w),
        .rd_old_addr    (id_rd_addr_w),
        .rs1_data       (id_rs1_data_w),
        .rs2_data       (id_rs2_data_w),
        .rd_old_data    (id_rd_old_data_w),
        .reg_write      (mem_wb_reg_write && mem_wb_valid),
        .rd_addr        (mem_wb_rd_addr),
        .rd_wdata       (mem_wb_wb_data)
    );

    //==========================================================================
    // Submodule: Immediate Generator
    //==========================================================================
    imm_gen u_imm_gen (
        .instr          (if_id_instr),
        .imm_sel        (ctrl_imm_sel),
        .imm            (id_imm_w)
    );

    //==========================================================================
    // Submodule: ALU
    //==========================================================================
    alu u_alu (
        .a              (forward_rs1_data),
        .b              (ex_alu_in_b),
        .alu_op         (id_ex_alu_op),
        .alu_type       (id_ex_alu_type),
        .result         (ex_alu_out),
        .zero           (ex_alu_zero)
    );

    // ALU B input (immediate or forwarded rs2)
    assign ex_alu_in_b = id_ex_alu_src_imm ? id_ex_imm : forward_rs2_data;

    // ALU A input (special cases for JALR, AUIPC, JAL)
    assign ex_alu_in_a = id_ex_jump_reg                    ? id_ex_rs1_data :    // JALR: rs1
                         (id_ex_alu_op == `ALUOP_AUIPC)    ? id_ex_pc :
                         (id_ex_alu_type == `ALUTYPE_JUMP) ? id_ex_pc :
                                                              forward_rs1_data;

    //==========================================================================
    // Submodule: Branch Unit
    //==========================================================================
    branch_unit u_branch (
        .rs1_data       (forward_rs1_data),
        .rs2_data       (forward_rs2_data),
        .funct3         (id_ex_branch_type),
        .branch_taken   (ex_br_taken)
    );

    //==========================================================================
    // Submodule: MAC Unit (combinational, uses forwarded operands if needed)
    //==========================================================================
    mac_unit u_mac (
        .rs1_data       (forward_rs1_data),
        .rs2_data       (forward_rs2_data),
        .rd_old_data    (id_ex_rd_old_data),
        .mac_result     (ex_mac_result)
    );

    //==========================================================================
    // Program Counter (inline — not pc_reg, for correct priority in pipeline)
    //
    // Priority: EX redirects (branch, JALR) > ID redirects (JAL) > PC+4
    //==========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_val <= `PC_INIT;
        end else if (!stall_w) begin
            pc_val <= pc_next;
        end
    end

    //==========================================================================
    // Submodule: Performance Counters
    //==========================================================================
    csr_perf_counter u_perf (
        .clk            (clk),
        .rst            (~rst_n),
        .halted         (halted_w),
        .instret_pulse  (perf_instret_pulse),
        .mac_pulse      (perf_mac_pulse),
        .cycle_count    (cycle_cnt),
        .instret_count  (instret_cnt),
        .mac_count      (mac_cnt)
    );

    //==========================================================================
    // Forwarding Logic (combinational)
    //
    // Priority: EX/MEM > MEM/WB (more recent result)
    // Forward from EX/MEM.alu_result or MEM/WB.wb_data to EX stage rs1/rs2
    //==========================================================================
    always @(*) begin
        // Default: no forwarding (use register file values from ID/EX)
        forward_rs1_sel = 2'b00;
        forward_rs2_sel = 2'b00;

        // Forward rs1 from EX/MEM
        if (ex_mem_reg_write && ex_mem_valid &&
            (ex_mem_rd_addr != 5'b0) &&
            (ex_mem_rd_addr == id_ex_rs1_addr)) begin
            forward_rs1_sel = 2'b01;    // EX/MEM forward
        end
        // Forward rs1 from MEM/WB (lower priority)
        else if (mem_wb_reg_write && mem_wb_valid &&
                 (mem_wb_rd_addr != 5'b0) &&
                 (mem_wb_rd_addr == id_ex_rs1_addr)) begin
            forward_rs1_sel = 2'b10;    // MEM/WB forward
        end

        // Forward rs2 from EX/MEM
        if (ex_mem_reg_write && ex_mem_valid &&
            (ex_mem_rd_addr != 5'b0) &&
            (ex_mem_rd_addr == id_ex_rs2_addr)) begin
            forward_rs2_sel = 2'b01;    // EX/MEM forward
        end
        // Forward rs2 from MEM/WB (lower priority)
        else if (mem_wb_reg_write && mem_wb_valid &&
                 (mem_wb_rd_addr != 5'b0) &&
                 (mem_wb_rd_addr == id_ex_rs2_addr)) begin
            forward_rs2_sel = 2'b10;    // MEM/WB forward
        end
    end

    // Forwarding multiplexers for EX stage inputs
    assign forward_rs1_data = (forward_rs1_sel == 2'b01) ? ex_mem_alu_result :
                              (forward_rs1_sel == 2'b10) ? mem_wb_wb_data :
                                                            id_ex_rs1_data;

    assign forward_rs2_data = (forward_rs2_sel == 2'b01) ? ex_mem_alu_result :
                              (forward_rs2_sel == 2'b10) ? mem_wb_wb_data :
                                                            id_ex_rs2_data;

    // MEM stage: forward store data from MEM/WB if needed
    // (when SW follows an ALU instruction that writes its rs2 source)
    assign mem_rs2_forwarded = (mem_wb_reg_write && mem_wb_valid &&
                                (mem_wb_rd_addr != 5'b0) &&
                                (mem_wb_rd_addr == ex_mem_rs2_addr)) ?
                                mem_wb_wb_data : ex_mem_rs2_data;

    //==========================================================================
    // Hazard Detection (combinational)
    //==========================================================================

    // Load-use hazard: LW in EX stage, next instruction in ID uses its rd
    assign load_use_hazard = id_ex_mem_read && id_ex_valid &&
                             (id_ex_rd_addr != 5'b0) &&
                             ((ctrl_reg_read_rs1 && (id_ex_rd_addr == id_rs1_addr_w)) ||
                              (ctrl_reg_read_rs2 && (id_ex_rd_addr == id_rs2_addr_w)));

    // JAL flush: detected in ID stage → redirect PC, flush IF/ID
    assign jal_flush = if_id_valid && ctrl_jump && !load_use_hazard;

    // JALR flush: JALR proceeds through ID→EX, resolved in EX with forwarding
    assign jalr_flush = id_ex_valid && id_ex_jump_reg;

    // Branch flush: taken branch in EX stage → flush IF/ID + ID/EX
    // With BTB: only flush if BTB did NOT predict taken (i.e., misprediction).
    // If BTB correctly predicted taken, the IF stage already fetched from target.
    assign branch_flush = id_ex_valid &&
                          (id_ex_alu_type == `ALUTYPE_JUMP) &&
                          !id_ex_jump && !id_ex_jump_reg &&
                          ex_br_taken &&
                          !id_ex_btb_pred_taken;  // BTB misprediction only

    // EBREAK halt: detected in ID stage
    assign ebreak_halt = if_id_valid && ctrl_halt;

    // Combined stall (load-use only)
    assign stall_w = load_use_hazard;

    //==========================================================================
    // Bus Interfaces
    //==========================================================================
    assign ibus_addr = pc_val;
    assign ibus_en   = !halted_w;

    assign dbus_addr     = ex_mem_alu_result;
    assign dbus_wdata    = mem_rs2_forwarded;
    assign dbus_byte_sel = 4'b1111;
    assign dbus_we       = ex_mem_mem_write && ex_mem_valid;
    assign dbus_en       = (ex_mem_mem_read || ex_mem_mem_write) && ex_mem_valid;

    //==========================================================================
    // Debug Outputs
    //==========================================================================
    assign debug_pc      = pc_val;
    // debug_state encoding: bit4=halted, bit3=stall, bit2=branch_flush,
    //                       bit1=jalr_flush, bit0=jal_flush
    assign debug_state   = {3'b0, halted_w, load_use_hazard, branch_flush, jalr_flush, jal_flush};
    assign debug_x10     = id_rs1_data_w;    // x10 = a0 for convenience
    assign debug_illegal = ctrl_illegal && if_id_valid;

    //==========================================================================
    // Performance Counter Pulses
    //
    // Instructions retire at different pipeline stages, matching multi-cycle
    // retirement semantics for consistent CPI comparison:
    //   - Branch: retires in EX (completes after branch resolution)
    //   - Store:  retires in MEM (data committed to memory)
    //   - Others: retire in WB (register written back)
    // EBREAK and illegal instructions never retire (instret_pulse stays 0).
    //==========================================================================
    wire ex_instret;
    wire mem_instret;
    wire wb_instret;

    assign ex_instret  = id_ex_instret_pulse && id_ex_valid &&
                         (id_ex_alu_type == `ALUTYPE_JUMP) &&
                         !id_ex_jump && !id_ex_jump_reg;          // branch only

    assign mem_instret = ex_mem_instret_pulse && ex_mem_valid &&
                         ex_mem_mem_write;                         // store only

    assign wb_instret  = mem_wb_instret_pulse && mem_wb_valid &&
                         mem_wb_reg_write;                         // ALU, load, JAL, etc.

    assign perf_instret_pulse = ex_instret || mem_instret || wb_instret;
    assign perf_mac_pulse     = mem_wb_valid && mem_wb_mac_pulse;

    assign perf_cycle_count   = cycle_cnt;
    assign perf_instret_count = instret_cnt;
    assign perf_mac_count     = mac_cnt;

    //==========================================================================
    // Halt State
    //==========================================================================
    reg halted_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            halted_r <= `FALSE;
        end else if (ebreak_halt) begin
            halted_r <= `TRUE;
        end
    end
    assign halted_w = halted_r;

    //==========================================================================
    // Pipeline Register Update (sequential)
    //
    // All pipeline registers update synchronously on posedge clk.
    // Stall:  IF/ID holds, ID/EX gets NOP (bubble)
    // Flush:  IF/ID gets NOP (jump/branch), ID/EX also gets NOP (branch)
    //==========================================================================

    // Combined flush for IF/ID: any redirect or halt
    wire flush_ifid = jal_flush || jalr_flush || branch_flush || ebreak_halt || halted_w;

    // Kill the younger ID-stage instruction after an EX-stage redirect. The
    // branch/JALR itself still advances independently into EX/MEM below.
    wire flush_idex = branch_flush || jalr_flush || ebreak_halt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all pipeline registers to NOP/bubble state
            if_id_pc    <= `PC_INIT;
            if_id_instr <= `RV_NOP;
            if_id_valid <= `FALSE;
            if_id_btb_pred <= `FALSE;

            id_ex_pc          <= `PC_INIT;
            id_ex_rs1_data    <= `ZERO_WORD;
            id_ex_rs2_data    <= `ZERO_WORD;
            id_ex_rd_old_data <= `ZERO_WORD;
            id_ex_imm         <= `ZERO_WORD;
            id_ex_rd_addr     <= 5'b0;
            id_ex_rs1_addr    <= 5'b0;
            id_ex_rs2_addr    <= 5'b0;
            id_ex_alu_op      <= `ALUOP_NOP;
            id_ex_alu_type    <= `ALUTYPE_NOP;
            id_ex_alu_src_imm <= `FALSE;
            id_ex_reg_write   <= `FALSE;
            id_ex_mem_read    <= `FALSE;
            id_ex_mem_write   <= `FALSE;
            id_ex_wb_sel      <= 2'b00;
            id_ex_branch_type <= `RV_F3_BEQ;
            id_ex_jump        <= `FALSE;
            id_ex_jump_reg    <= `FALSE;
            id_ex_is_mac      <= `FALSE;
            id_ex_instret_pulse <= `FALSE;
            id_ex_mac_pulse   <= `FALSE;
            id_ex_valid       <= `FALSE;
            id_ex_btb_pred_taken <= `FALSE;

            ex_mem_pc_plus_4    <= `ZERO_WORD;
            ex_mem_alu_result   <= `ZERO_WORD;
            ex_mem_rs2_data     <= `ZERO_WORD;
            ex_mem_rs2_addr     <= 5'b0;
            ex_mem_rd_addr      <= 5'b0;
            ex_mem_reg_write    <= `FALSE;
            ex_mem_mem_read     <= `FALSE;
            ex_mem_mem_write    <= `FALSE;
            ex_mem_wb_sel       <= 2'b00;
            ex_mem_is_mac       <= `FALSE;
            ex_mem_instret_pulse <= `FALSE;
            ex_mem_mac_pulse    <= `FALSE;
            ex_mem_valid        <= `FALSE;

            mem_wb_wb_data      <= `ZERO_WORD;
            mem_wb_rd_addr      <= 5'b0;
            mem_wb_reg_write    <= `FALSE;
            mem_wb_is_mac       <= `FALSE;
            mem_wb_instret_pulse <= `FALSE;
            mem_wb_mac_pulse    <= `FALSE;
            mem_wb_valid        <= `FALSE;

        end else begin
            //==============================================================
            // MEM/WB ← EX/MEM (always advances unless reset)
            //==============================================================
            if (ex_mem_mem_read && ex_mem_valid) begin
                // Load: writeback data comes from data bus
                mem_wb_wb_data <= dbus_rdata;
            end else if (ex_mem_wb_sel == 2'b10) begin
                // JAL/JALR: writeback data is PC+4
                mem_wb_wb_data <= ex_mem_pc_plus_4;
            end else begin
                // ALU / MAC result
                mem_wb_wb_data <= ex_mem_alu_result;
            end

            mem_wb_rd_addr      <= ex_mem_rd_addr;
            mem_wb_reg_write    <= ex_mem_reg_write;
            mem_wb_is_mac       <= ex_mem_is_mac;
            mem_wb_instret_pulse <= ex_mem_instret_pulse;
            mem_wb_mac_pulse    <= ex_mem_mac_pulse;
            mem_wb_valid        <= ex_mem_valid;

            //==============================================================
            // EX/MEM ← ID/EX (always advances — load proceeds to MEM)
            // During stall, ID/EX is the load, which needs to advance
            // to MEM so its data can be forwarded.
            //==============================================================
            ex_mem_pc_plus_4    <= id_ex_pc + 32'd4;
            ex_mem_alu_result   <= id_ex_is_mac ? ex_mac_result : ex_alu_out;
            ex_mem_rs2_data     <= forward_rs2_data;
            ex_mem_rs2_addr     <= id_ex_rs2_addr;
            ex_mem_rd_addr      <= id_ex_rd_addr;
            ex_mem_reg_write    <= id_ex_reg_write;
            ex_mem_mem_read     <= id_ex_mem_read;
            ex_mem_mem_write    <= id_ex_mem_write;
            ex_mem_wb_sel       <= id_ex_wb_sel;
            ex_mem_is_mac       <= id_ex_is_mac;
            ex_mem_instret_pulse <= id_ex_instret_pulse;
            ex_mem_mac_pulse    <= id_ex_mac_pulse;
            ex_mem_valid        <= id_ex_valid;

            //==============================================================
            // ID/EX ← IF/ID (NOP if stall, EX flush, or ebreak)
            //==============================================================
            if (stall_w || flush_idex) begin
                // Insert bubble (NOP)
                id_ex_pc          <= id_ex_pc;         // Keep PC (don't care)
                id_ex_rs1_data    <= `ZERO_WORD;
                id_ex_rs2_data    <= `ZERO_WORD;
                id_ex_rd_old_data <= `ZERO_WORD;
                id_ex_imm         <= `ZERO_WORD;
                id_ex_rd_addr     <= 5'b0;
                id_ex_rs1_addr    <= 5'b0;
                id_ex_rs2_addr    <= 5'b0;
                id_ex_alu_op      <= `ALUOP_NOP;
                id_ex_alu_type    <= `ALUTYPE_NOP;
                id_ex_alu_src_imm <= `FALSE;
                id_ex_reg_write   <= `FALSE;
                id_ex_mem_read    <= `FALSE;
                id_ex_mem_write   <= `FALSE;
                id_ex_wb_sel      <= 2'b00;
                id_ex_branch_type <= `RV_F3_BEQ;
                id_ex_jump        <= `FALSE;
                id_ex_jump_reg    <= `FALSE;
                id_ex_is_mac      <= `FALSE;
                id_ex_instret_pulse <= `FALSE;
                id_ex_mac_pulse   <= `FALSE;
                id_ex_valid       <= `FALSE;
                id_ex_btb_pred_taken <= `FALSE;
            end else begin
                // Normal advance: ID/EX gets IF/ID's decoded values
                id_ex_pc          <= if_id_pc;
                id_ex_rs1_data    <= id_rs1_data_w;
                id_ex_rs2_data    <= id_rs2_data_w;
                id_ex_rd_old_data <= id_rd_old_data_w;
                id_ex_imm         <= id_imm_w;
                id_ex_rd_addr     <= id_rd_addr_w;
                id_ex_rs1_addr    <= id_rs1_addr_w;
                id_ex_rs2_addr    <= id_rs2_addr_w;
                id_ex_alu_op      <= ctrl_alu_op;
                id_ex_alu_type    <= ctrl_alu_type;
                id_ex_alu_src_imm <= ctrl_alu_src_imm;
                id_ex_reg_write   <= ctrl_reg_write;
                id_ex_mem_read    <= ctrl_mem_read;
                id_ex_mem_write   <= ctrl_mem_write;
                id_ex_wb_sel      <= ctrl_wb_sel;
                id_ex_branch_type <= ctrl_branch_type;
                id_ex_jump        <= ctrl_jump;
                id_ex_jump_reg    <= ctrl_jump_reg;
                id_ex_is_mac      <= ctrl_is_mac;
                id_ex_instret_pulse <= ctrl_instret_pulse;
                id_ex_mac_pulse   <= ctrl_mac_pulse;
                id_ex_valid       <= if_id_valid;  // JAL itself must proceed to WB (rd←PC+4)
                id_ex_btb_pred_taken <= if_id_btb_pred;  // flow BTB prediction with instr
                // Note: jal_flush already handled PC redirect + IF/ID flush;
                // the bubble propagates naturally through the pipeline.
            end

            //==============================================================
            // IF/ID ← IF stage (NOP on flush/ebreak/halt, hold on stall)
            //==============================================================
            if (stall_w) begin
                // Hold IF/ID (don't change)
            end else if (flush_ifid) begin
                // Insert NOP in IF/ID (on any redirect or halt)
                if_id_instr <= `RV_NOP;
                if_id_valid <= `FALSE;
            end else begin
                // Normal advance: load new instruction from IF stage
                if_id_pc    <= pc_val;
                if_id_instr <= ibus_rdata;
                if_id_valid <= `TRUE;
                if_id_btb_pred <= btb_predict_taken;  // capture BTB prediction at IF
            end
        end
    end

endmodule
