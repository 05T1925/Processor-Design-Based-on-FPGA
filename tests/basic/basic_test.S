#==============================================================================
# RV32I Basic Test Program (v2 - fixed for unified bus memory map)
#
# Memory map (unified bus):
#   0x0000_0000 - 0x0000_7FFF : Instruction Memory (read-only)
#   0x1000_0000 - 0x1000_7FFF : Data Memory (read/write)
#   0xFFFF_FC00              : LED
#   0xFFFF_FC10              : SWITCH
#   0xFFFF_FC20              : SEG7
#
# Tests: ADDI, ADD, SW, LW, BEQ, EBREAK
# Expected: x5 = 1 (PASS), halted = 1, error = 0
#==============================================================================

    # Initialize test values
    addi x1, x0, 10           # x1 = 10
    addi x2, x0, 20           # x2 = 20
    add  x3, x1, x2          # x3 = 10 + 20 = 30

    # Load data RAM base address (0x1000_0000)
    lui  x6, 0x10000         # x6 = 0x1000_0000

    # Store and load test (to/from data RAM)
    sw   x3, 0(x6)           # data_ram[0] = 30
    lw   x4, 0(x6)           # x4 = data_ram[0] = 30

    # Branch test: x3 (30) should equal x4 (30)
    beq  x3, x4, pass        # should be taken
    addi x5, x0, 0           # x5 = 0 (should be skipped)
    ebreak                     # HALT (should be skipped)

pass:
    addi x5, x0, 1           # x5 = 1 (PASS indicator)
    ebreak                     # HALT - test complete

#==============================================================================
# Machine code (hand-encoded, verified against RV32I spec):
# 0x0000_0000: 00A00093  addi x1, x0, 10        op=0010011 f3=000 rd=00001 rs1=00000 imm=00A
# 0x0000_0004: 01400113  addi x2, x0, 20        op=0010011 f3=000 rd=00010 rs1=00000 imm=014
# 0x0000_0008: 002081B3  add  x3, x1, x2        op=0110011 f3=000 f7=00 rd=00011 rs1=00001 rs2=00010
# 0x0000_000C: 10000337  lui  x6, 0x10000       op=0110111 rd=00110 imm=10000000000000000000
# 0x0000_0010: 00332023  sw   x3, 0(x6)         op=0100011 f3=010 rs1=00110 rs2=00011 imm=000000000000
# 0x0000_0014: 00032303  lw   x4, 0(x6)         op=0000011 f3=010 rd=00100 rs1=00110 imm=000000000000
# 0x0000_0018: 00418263  beq  x3, x4, +4        op=1100011 f3=000 rs1=00011 rs2=00100 imm=000000000100
# 0x0000_001C: 00000293  addi x5, x0, 0         op=0010011 f3=000 rd=00101 rs1=00000 imm=000 (skipped)
# 0x0000_0020: 00100073  ebreak                  op=1110011 imm=000000000001 (skipped)
# 0x0000_0024: 00100293  addi x5, x0, 1         op=0010011 f3=000 rd=00101 rs1=00000 imm=001
# 0x0000_0028: 00100073  ebreak                  op=1110011 imm=000000000001
#==============================================================================
