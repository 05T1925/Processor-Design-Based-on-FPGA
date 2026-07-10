#==============================================================================
# RV32I Load/Store Test
#
# Purpose:
# 1. Store two values into data RAM.
# 2. Load them back into registers.
# 3. Check the loaded values by observing x3/x4 and x5 = x3 + x4.
#
# Expected after HALT:
#   data_ram[0] = 42
#   data_ram[1] = 99
#   x3 = 42
#   x4 = 99
#   x5 = 141
#==============================================================================

    addi x1, x0, 42           # x1 = 42
    addi x2, x0, 99           # x2 = 99
    lui  x6, 0x10000          # x6 = 0x1000_0000 (data RAM base)

    sw   x1, 0(x6)            # mem[0] = 42
    sw   x2, 4(x6)            # mem[1] = 99

    lw   x3, 0(x6)            # x3 = 42
    lw   x4, 4(x6)            # x4 = 99
    add  x5, x3, x4           # x5 = 141

    ebreak
