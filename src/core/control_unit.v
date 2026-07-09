//==============================================================================
// control_unit.v - RV32I Control Unit (Instruction Decoder)
//
// Based on: riscv-minisys-cpu + SEU minisys (minisys-master) id.v frameworks
//
// Decodes RV32I opcode/funct3/funct7 into control signals.
// Supports: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU,
//           ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU,
//           LUI, AUIPC, LW, SW, BEQ, BNE, BLT, BGE, BLTU, BGEU,
//           JAL, JALR, EBREAK, MAC (custom-0)
//==============================================================================

`include "public.vh"

module control_unit (
    input  wire [31:0] instr,

    // ALU control
    output reg  [`ALUOP_BUS]  alu_op,
    output reg  [`ALUTYPE_BUS] alu_type,
    output reg                 alu_src_imm,    // ALU B = imm vs rs2_data

    // Register file control
    output reg                 reg_write,
    output reg                 reg_read_rs1,    // Enable rs1 read
    output reg                 reg_read_rs2,    // Enable rs2 read
    output reg                 rd_old_read,     // Enable MAC rd_old read

    // Memory control
    output reg                 mem_read,
    output reg                 mem_write,

    // Write-back control
    output reg  [1:0]         wb_sel,         // 00=ALU, 01=MEM, 10=PC+4, 11=MAC

    // Branch/Jump control
    output reg  [2:0]         branch_type,    // funct3 for branch evaluation
    output reg                 jump,           // JAL
    output reg                 jump_reg,       // JALR

    // Immediate type
    output reg  [2:0]         imm_sel,        // I/S/B/U/J selection

    // Special signals
    output reg                 is_mac,         // MAC instruction detected
    output reg                 halt,           // EBREAK → HALT
    output reg                 illegal_instr,  // Unknown opcode

    // Performance counter pulses
    output reg                 instret_pulse,  // Instruction retired
    output reg                 mac_pulse       // MAC executed
);

    //--------------------------------------------------------------------------
    // Instruction field extraction (RV32I encoding)
    //--------------------------------------------------------------------------
    wire [6:0] opcode  = instr[`RV_OPCODE_RANGE];
    wire [2:0] funct3  = instr[`RV_FUNCT3_RANGE];
    wire [6:0] funct7  = instr[`RV_FUNCT7_RANGE];
    wire [4:0] rs1     = instr[`RV_RS1_RANGE];
    wire [4:0] rs2     = instr[`RV_RS2_RANGE];
    wire [4:0] rd      = instr[`RV_RD_RANGE];

    //--------------------------------------------------------------------------
    // Immediate type detection
    //--------------------------------------------------------------------------
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;

    //--------------------------------------------------------------------------
    // Write-back source selection
    //--------------------------------------------------------------------------
    localparam WB_ALU = 2'b00;
    localparam WB_MEM = 2'b01;
    localparam WB_PC4 = 2'b10;
    localparam WB_MAC = 2'b11;

    //--------------------------------------------------------------------------
    // Main decode: opcode → control signals
    //--------------------------------------------------------------------------
    always @(*) begin
        // Default values (safe: no operation)
        alu_op        = `ALUOP_NOP;
        alu_type      = `ALUTYPE_NOP;
        alu_src_imm   = `FALSE;
        reg_write     = `FALSE;
        reg_read_rs1  = `FALSE;
        reg_read_rs2  = `FALSE;
        rd_old_read   = `FALSE;
        mem_read      = `FALSE;
        mem_write     = `FALSE;
        wb_sel        = WB_ALU;
        branch_type   = `RV_F3_BEQ;
        jump          = `FALSE;
        jump_reg      = `FALSE;
        imm_sel       = IMM_I;
        is_mac        = `FALSE;
        halt          = `FALSE;
        illegal_instr = `FALSE;
        instret_pulse = `FALSE;
        mac_pulse     = `FALSE;

        case (opcode)
            //------------------------------------------------------------------
            // OP-IMM (ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
            //------------------------------------------------------------------
            `RV_OP_ARITHI: begin
                reg_write     = `TRUE;
                reg_read_rs1  = `TRUE;
                alu_src_imm   = `TRUE;
                imm_sel       = IMM_I;
                wb_sel        = WB_ALU;
                instret_pulse = `TRUE;

                case (funct3)
                    `RV_F3_ADDSUB: begin
                        alu_type = `ALUTYPE_ARITH;
                        alu_op   = `ALUOP_ADD;
                    end
                    `RV_F3_SLT: begin
                        alu_type = `ALUTYPE_ARITH;
                        alu_op   = `ALUOP_SLT;
                    end
                    `RV_F3_SLTU: begin
                        alu_type = `ALUTYPE_ARITH;
                        alu_op   = `ALUOP_SLTU;
                    end
                    `RV_F3_XOR: begin
                        alu_type = `ALUTYPE_LOGIC;
                        alu_op   = `ALUOP_XOR;
                    end
                    `RV_F3_OR: begin
                        alu_type = `ALUTYPE_LOGIC;
                        alu_op   = `ALUOP_OR;
                    end
                    `RV_F3_AND: begin
                        alu_type = `ALUTYPE_LOGIC;
                        alu_op   = `ALUOP_AND;
                    end
                    `RV_F3_SLL: begin
                        alu_type = `ALUTYPE_SHIFT;
                        alu_op   = `ALUOP_SLL;
                    end
                    `RV_F3_SRLSRA: begin
                        alu_type = `ALUTYPE_SHIFT;
                        alu_op   = (funct7 == `RV_F7_SRA) ? `ALUOP_SRA : `ALUOP_SRL;
                    end
                    default: illegal_instr = `TRUE;
                endcase
            end

            //------------------------------------------------------------------
            // OP (ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND)
            //------------------------------------------------------------------
            `RV_OP_ARITH: begin
                reg_write     = `TRUE;
                reg_read_rs1  = `TRUE;
                reg_read_rs2  = `TRUE;
                alu_src_imm   = `FALSE;
                wb_sel        = WB_ALU;
                instret_pulse = `TRUE;

                case (funct3)
                    `RV_F3_ADDSUB: begin
                        alu_type = `ALUTYPE_ARITH;
                        alu_op   = (funct7 == `RV_F7_SUB) ? `ALUOP_SUB : `ALUOP_ADD;
                    end
                    `RV_F3_SLL: begin
                        alu_type = `ALUTYPE_SHIFT;
                        alu_op   = `ALUOP_SLL;
                    end
                    `RV_F3_SLT: begin
                        alu_type = `ALUTYPE_ARITH;
                        alu_op   = `ALUOP_SLT;
                    end
                    `RV_F3_SLTU: begin
                        alu_type = `ALUTYPE_ARITH;
                        alu_op   = `ALUOP_SLTU;
                    end
                    `RV_F3_XOR: begin
                        alu_type = `ALUTYPE_LOGIC;
                        alu_op   = `ALUOP_XOR;
                    end
                    `RV_F3_SRLSRA: begin
                        alu_type = `ALUTYPE_SHIFT;
                        alu_op   = (funct7 == `RV_F7_SRA) ? `ALUOP_SRA : `ALUOP_SRL;
                    end
                    `RV_F3_OR: begin
                        alu_type = `ALUTYPE_LOGIC;
                        alu_op   = `ALUOP_OR;
                    end
                    `RV_F3_AND: begin
                        alu_type = `ALUTYPE_LOGIC;
                        alu_op   = `ALUOP_AND;
                    end
                    default: illegal_instr = `TRUE;
                endcase
            end

            //------------------------------------------------------------------
            // LUI
            //------------------------------------------------------------------
            `RV_OP_LUI: begin
                reg_write     = `TRUE;
                alu_src_imm   = `TRUE;
                imm_sel       = IMM_U;
                alu_type      = `ALUTYPE_MOVE;
                alu_op        = `ALUOP_LUI;
                wb_sel        = WB_ALU;
                instret_pulse = `TRUE;
            end

            //------------------------------------------------------------------
            // AUIPC
            //------------------------------------------------------------------
            `RV_OP_AUIPC: begin
                reg_write     = `TRUE;
                reg_read_rs1  = `TRUE;     // rs1 unused, but needed for PC passthrough
                alu_src_imm   = `TRUE;
                imm_sel       = IMM_U;
                alu_type      = `ALUTYPE_MOVE;
                alu_op        = `ALUOP_AUIPC;
                wb_sel        = WB_ALU;
                instret_pulse = `TRUE;
            end

            //------------------------------------------------------------------
            // JAL
            //------------------------------------------------------------------
            `RV_OP_JAL: begin
                reg_write     = `TRUE;
                jump          = `TRUE;
                imm_sel       = IMM_J;
                wb_sel        = WB_PC4;
                instret_pulse = `TRUE;
            end

            //------------------------------------------------------------------
            // JALR
            //------------------------------------------------------------------
            `RV_OP_JALR: begin
                reg_write     = `TRUE;
                reg_read_rs1  = `TRUE;
                jump_reg      = `TRUE;
                alu_src_imm   = `TRUE;
                imm_sel       = IMM_I;
                wb_sel        = WB_PC4;
                instret_pulse = `TRUE;
            end

            //------------------------------------------------------------------
            // BRANCH (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            //------------------------------------------------------------------
            `RV_OP_BRANCH: begin
                reg_read_rs1  = `TRUE;
                reg_read_rs2  = `TRUE;
                branch_type   = funct3;
                alu_src_imm   = `TRUE;
                imm_sel       = IMM_B;
                alu_type      = `ALUTYPE_JUMP;
                alu_op        = `ALUOP_NOP;
                instret_pulse = `TRUE;     // Count branch as retired even if not taken
            end

            //------------------------------------------------------------------
            // LOAD (LW)
            //------------------------------------------------------------------
            `RV_OP_LOAD: begin
                reg_write     = `TRUE;
                reg_read_rs1  = `TRUE;
                alu_src_imm   = `TRUE;
                imm_sel       = IMM_I;
                mem_read      = `TRUE;
                alu_type      = `ALUTYPE_ARITH;
                alu_op        = `ALUOP_ADD;  // address = rs1 + offset
                wb_sel        = WB_MEM;
                instret_pulse = `TRUE;

                if (funct3 != `RV_F3_LW) illegal_instr = `TRUE;  // Only LW supported
            end

            //------------------------------------------------------------------
            // STORE (SW)
            //------------------------------------------------------------------
            `RV_OP_STORE: begin
                reg_read_rs1  = `TRUE;
                reg_read_rs2  = `TRUE;
                alu_src_imm   = `TRUE;
                imm_sel       = IMM_S;
                mem_write     = `TRUE;
                alu_type      = `ALUTYPE_ARITH;
                alu_op        = `ALUOP_ADD;  // address = rs1 + offset
                instret_pulse = `TRUE;

                if (funct3 != `RV_F3_SW) illegal_instr = `TRUE;  // Only SW supported
            end

            //------------------------------------------------------------------
            // SYSTEM (EBREAK)
            //------------------------------------------------------------------
            `RV_OP_SYSTEM: begin
                if (instr == `RV_EBREAK) begin
                    halt = `TRUE;
                    // instret_pulse stays 0 when halted
                end else begin
                    illegal_instr = `TRUE;
                end
            end

            //------------------------------------------------------------------
            // MAC custom-0 instruction
            //------------------------------------------------------------------
            `RV_OP_MAC: begin
                is_mac        = `TRUE;
                reg_write     = `TRUE;
                reg_read_rs1  = `TRUE;
                reg_read_rs2  = `TRUE;
                rd_old_read   = `TRUE;
                alu_type      = `ALUTYPE_MAC;
                alu_op        = `ALUOP_MAC;
                wb_sel        = WB_MAC;
                instret_pulse = `TRUE;
                mac_pulse     = `TRUE;
            end

            //------------------------------------------------------------------
            // Unknown opcode
            //------------------------------------------------------------------
            default: begin
                illegal_instr = `TRUE;
            end
        endcase
    end

endmodule
