//==============================================================================
// public.vh - Global Definitions for Unified RV32I+MIPS CPU Project
//
// Based on: minisys_unified + SEU minisys (minisys-master) public.v + define.v
// Adapted for RV32I-primary with MAC extension and MIPS compatibility modes.
//
// Usage: `include "public.vh" in all RTL modules
//==============================================================================

`ifndef PUBLIC_VH
`define PUBLIC_VH

`timescale 1ns / 1ps

//------------------------------------------------------------------------------
// Global Boolean Constants
//------------------------------------------------------------------------------
`define ENABLE          1'b1
`define DISABLE         1'b0
`define READ            1'b0
`define WRITE           1'b1
`define TRUE            1'b1
`define FALSE           1'b0
`define CHIP_ENABLE     1'b1
`define CHIP_DISABLE    1'b0

//------------------------------------------------------------------------------
// Reset and Clock
//------------------------------------------------------------------------------
`define RST_ENABLE      1'b1
`define RST_DISABLE     1'b0

//------------------------------------------------------------------------------
// Data Path Widths
//------------------------------------------------------------------------------
`define WORD_BUS        31:0
`define WORD_LENGTH     32
`define ZERO_WORD       32'h00000000
`define ZERO_DWORD      64'h00000000_00000000
`define REG_COUNT       32
`define REG_ADDR_BUS    4:0
`define REG_ADDR_WIDTH  5
`define REG_NOP         5'b00000        // x0 / $0 hardwired to zero
`define ZERO_REG        5'b00000
`define PC_INIT         32'h00000000

//------------------------------------------------------------------------------
// Instruction Field Ranges (RV32I primary, MIPS alternative in comments)
//------------------------------------------------------------------------------
// RV32I encoding
`define RV_OPCODE_RANGE  6:0
`define RV_RD_RANGE      11:7
`define RV_FUNCT3_RANGE  14:12
`define RV_RS1_RANGE     19:15
`define RV_RS2_RANGE     24:20
`define RV_FUNCT7_RANGE  31:25

// MIPS encoding (for compatibility modes)
`define MIPS_OP_RANGE    31:26
`define MIPS_RS_RANGE    25:21
`define MIPS_RT_RANGE    20:16
`define MIPS_RD_RANGE    15:11
`define MIPS_SHAMT_RANGE 10:6
`define MIPS_FUNCT_RANGE 5:0
`define MIPS_IMM_RANGE   15:0
`define MIPS_ADDR_RANGE  25:0

//------------------------------------------------------------------------------
// ALU Operation Types (6-category classification from SEU minisys)
//------------------------------------------------------------------------------
`define ALUOP_BUS        7:0
`define ALUTYPE_BUS      2:0

`define ALUTYPE_NOP      3'b000
`define ALUTYPE_ARITH    3'b001   // Arithmetic (ADD/SUB/SLT)
`define ALUTYPE_LOGIC    3'b010   // Logic (AND/OR/XOR)
`define ALUTYPE_MOVE     3'b011   // Move/load immediate (LUI/AUIPC)
`define ALUTYPE_SHIFT    3'b100   // Shift (SLL/SRL/SRA)
`define ALUTYPE_JUMP     3'b101   // Jump/branch address calc
`define ALUTYPE_MAC      3'b110   // MAC multiply-accumulate

// RV32I ALU Operations
`define ALUOP_ADD        8'h01
`define ALUOP_SUB        8'h02
`define ALUOP_AND        8'h03
`define ALUOP_OR         8'h04
`define ALUOP_XOR        8'h05
`define ALUOP_SLL        8'h06
`define ALUOP_SRL        8'h07
`define ALUOP_SRA        8'h08
`define ALUOP_SLT        8'h09
`define ALUOP_SLTU       8'h0A
`define ALUOP_LUI        8'h0B
`define ALUOP_AUIPC      8'h0C
`define ALUOP_MAC        8'h0D   // rd_new = rd_old + rs1 * rs2
`define ALUOP_MUL        8'h0E   // M extension: MUL
`define ALUOP_DIV        8'h0F   // M extension: DIV
`define ALUOP_NOP        8'h00

//------------------------------------------------------------------------------
// RV32I Opcodes
//------------------------------------------------------------------------------
`define RV_OP_LUI        7'b0110111
`define RV_OP_AUIPC      7'b0010111
`define RV_OP_JAL        7'b1101111
`define RV_OP_JALR       7'b1100111
`define RV_OP_BRANCH     7'b1100011
`define RV_OP_LOAD       7'b0000011
`define RV_OP_STORE      7'b0100011
`define RV_OP_ARITHI     7'b0010011   // Immediate arithmetic/logic
`define RV_OP_ARITH      7'b0110011   // Register arithmetic/logic
`define RV_OP_MAC        7'b0001011   // Custom-0: MAC instruction
`define RV_OP_SYSTEM     7'b1110011   // SYSTEM (EBREAK/CSR)

// RV32I Funct3
`define RV_F3_ADDSUB     3'b000
`define RV_F3_SLL        3'b001
`define RV_F3_SLT        3'b010
`define RV_F3_SLTU       3'b011
`define RV_F3_XOR        3'b100
`define RV_F3_SRLSRA     3'b101
`define RV_F3_OR         3'b110
`define RV_F3_AND        3'b111
`define RV_F3_BEQ        3'b000
`define RV_F3_BNE        3'b001
`define RV_F3_BLT        3'b100
`define RV_F3_BGE        3'b101
`define RV_F3_BLTU       3'b110
`define RV_F3_BGEU       3'b111
`define RV_F3_LW         3'b010
`define RV_F3_SW         3'b010
`define RV_F3_JALR       3'b000

// RV32I Funct7
`define RV_F7_ADD        7'b0000000
`define RV_F7_SUB        7'b0100000
`define RV_F7_SRL        7'b0000000
`define RV_F7_SRA        7'b0100000
`define RV_F7_MAC        7'b0000001   // MAC funct7

// Special Instructions
`define RV_EBREAK        32'h00100073
`define RV_NOP           32'h00000013   // ADDI x0, x0, 0

//------------------------------------------------------------------------------
// MIPS Opcodes (for compatibility modes)
//------------------------------------------------------------------------------
`define MIPS_OP_RTYPE    6'b000000
`define MIPS_OP_ADDI     6'b001000
`define MIPS_OP_ADDIU    6'b001001
`define MIPS_OP_ANDI     6'b001100
`define MIPS_OP_ORI      6'b001101
`define MIPS_OP_XORI     6'b001110
`define MIPS_OP_LUI      6'b001111
`define MIPS_OP_LW       6'b100011
`define MIPS_OP_SW       6'b101011
`define MIPS_OP_BEQ      6'b000100
`define MIPS_OP_BNE      6'b000101
`define MIPS_OP_J        6'b000010
`define MIPS_OP_JAL      6'b000011
`define MIPS_OP_JR       6'b000000

//------------------------------------------------------------------------------
// Bus Interface Widths
//------------------------------------------------------------------------------
`define BUS_ADDR_WIDTH   32
`define BUS_DATA_WIDTH   32
`define BUS_BYTE_SEL_WIDTH 4

//------------------------------------------------------------------------------
// Unified Bus Signals (SEU minisys standard)
// ibus (instruction bus): CPU -> inst_ram (read-only)
//   ibus_addr[31:0]   output  instruction address
//   ibus_rdata[31:0]  input   instruction data
//   ibus_en           output  read enable
//   ibus_ready        input   ready flag
//
// dbus (data bus): CPU <-> data_ram/peripherals (read/write)
//   dbus_addr[31:0]   output  data address
//   dbus_wdata[31:0]  output  write data
//   dbus_rdata[31:0]  input   read data
//   dbus_byte_sel[3:0] output byte enable
//   dbus_we           output  write enable (1=write, 0=read)
//   dbus_en           output  bus enable
//   dbus_ready        input   ready flag
//   dbus_error        input   error flag
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// Memory Map (Unified)
//------------------------------------------------------------------------------
`define MM_INST_BASE        32'h0000_0000
`define MM_INST_SIZE        32768           // 32 KB
`define MM_DATA_BASE        32'h1000_0000
`define MM_DATA_SIZE        32768           // 32 KB
`define MM_PERIPH_BASE      32'hFFFF_FC00

//------------------------------------------------------------------------------
// Peripheral Address Decoding (addr[9:4] selects peripheral)
// Each peripheral gets a 16-byte slot in 0xFFFF_FCxx region
//------------------------------------------------------------------------------
`define PERIPH_LED          6'b00_0000      // 0xFFFF_FC00  LED output
`define PERIPH_SWITCH       6'b00_0001      // 0xFFFF_FC10  DIP switch input
`define PERIPH_SEG7         6'b00_0010      // 0xFFFF_FC20  7-segment display
`define PERIPH_UART         6'b00_0011      // 0xFFFF_FC30  UART
`define PERIPH_VGA          6'b00_0100      // 0xFFFF_FC40  VGA (reserved)
`define PERIPH_KBD4X4       6'b00_0101      // 0xFFFF_FC50  4x4 keypad (reserved)
`define PERIPH_PS2          6'b00_0110      // 0xFFFF_FC60  PS/2 (reserved)
`define PERIPH_TIMER        6'b00_0111      // 0xFFFF_FC70  Timer
`define PERIPH_PWM          6'b00_1000      // 0xFFFF_FC80  PWM
`define PERIPH_BUZZER       6'b00_1001      // 0xFFFF_FC90  Buzzer
`define PERIPH_WDT          6'b00_1010      // 0xFFFF_FCA0  Watchdog
`define PERIPH_PERF         6'b00_1011      // 0xFFFF_FCB0  Performance counters
`define PERIPH_RESULT       6'b00_1100      // 0xFFFF_FCC0  Result register (R/W)

//------------------------------------------------------------------------------
// CPU Mode Selection
//------------------------------------------------------------------------------
`define CPU_MODE_RISCV_MC   0   // RV32I multi-cycle FSM (P0 baseline) ★ PRIMARY
`define CPU_MODE_RISCV_SC   1   // RV32I single-cycle (from BUPT/riscv-minisys)
`define CPU_MODE_MIPS_SC    2   // MIPS single-cycle (from SUSTech CS202)
`define CPU_MODE_MIPS_PIPE  3   // MIPS 5-stage pipeline basic (from NCUT)
`define CPU_MODE_MIPS_ADV   4   // MIPS 5-stage pipeline advanced (from SEU)

`endif  // PUBLIC_VH
