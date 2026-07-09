#==============================================================================
# branch_loop_test.S — BTB Branch Prediction Accuracy Test
#
# Tests:
#   1. Simple counting loop (10 iterations) — verifies 2-bit counter training
#   2. BTB prediction accuracy observable via branch_flush events
#
# Expected results:
#   x8  = 10 (loop counter after exit)
#   x9  = 45 (sum 0+1+2+...+9 = 45)
#   x10 = 45 (a0 = result copied from x9)
#
# BTB 2-bit saturating counter behavior (10 iterations):
#   Iter 1:  counter=01(WNT) predict=N, actual=T → mispred, counter→10(WT)
#   Iter 2:  counter=10(WT)  predict=T, actual=T → correct, counter→11(ST)
#   Iter 3-9: counter=11(ST)  predict=T, actual=T → correct (×7)
#   Iter 10: counter=11(ST)  predict=T, actual=NT → mispred, counter→10(WT)
#
#   Total: 10 branches, 8 correct, 2 mispred → 80% accuracy
#   branch_flush events: 2 (only on misprediction with BTB)
#   vs. static not-taken: 9 branch_flush events (every taken iteration)
#==============================================================================

.text
.org 0x00000000

_start:
    # Initialize registers
    addi  x8,  x0,  0       # x8  = counter (i = 0)
    addi  x9,  x0,  0       # x9  = sum accumulator
    addi  x10, x0,  10      # x10 = loop limit (10 iterations)

loop_body:
    add   x9,  x9,  x8      # sum += counter
    addi  x8,  x8,  1       # counter++
    bne   x8,  x10, loop_body  # if counter != 10, loop back
                              # BTB trained: predicts taken for iterations 2-9

    # Move result to a0 (x10) for verification
    add   x10, x0,  x9      # x10 = sum = 45

    # Halt
    ebreak

#==============================================================================
# Machine Code (verified):
#   0x00000413  addi x8, x0, 0
#   0x00000493  addi x9, x0, 0
#   0x00A00513  addi x10, x0, 10
#   0x008484B3  add x9, x9, x8
#   0x00140413  addi x8, x8, 1
#   0xFEA41CE3  bne x8, x10, -8   (target = 0x0C = loop_body)
#   0x00900533  add x10, x0, x9
#   0x00100073  ebreak
#==============================================================================
