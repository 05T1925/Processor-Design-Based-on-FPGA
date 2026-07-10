#==============================================================================
# RV32I BEQ/BNE Test
#
# Purpose:
# 1. Verify BEQ taken.
# 2. Verify BNE taken.
# 3. Verify BEQ not taken.
# 4. Verify BNE not taken.
#
# Expected after HALT:
#   x10 = 12
#
# Reason:
#   +1 branch path should be skipped
#   +2 branch path should be skipped
#   +4 branch path should execute
#   +8 branch path should execute
#   final x10 = 4 + 8 = 12
#==============================================================================

    addi x1,  x0, 5           # x1 = 5
    addi x2,  x0, 5           # x2 = 5
    addi x3,  x0, 7           # x3 = 7
    addi x10, x0, 0           # accumulator

    beq  x1, x2, beq_taken
    addi x10, x10, 1          # should be skipped

beq_taken:
    bne  x1, x3, bne_taken
    addi x10, x10, 2          # should be skipped

bne_taken:
    beq  x1, x3, beq_not_taken_target
    addi x10, x10, 4          # should execute

beq_not_taken_target:
    bne  x1, x2, bne_not_taken_target
    addi x10, x10, 8          # should execute

bne_not_taken_target:
    ebreak
