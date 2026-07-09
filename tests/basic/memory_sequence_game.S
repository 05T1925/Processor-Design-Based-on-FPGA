#==============================================================================
# Memory Sequence Game
#
# Sequence playback: 1, 3, 2, 4
# Input method:
#   S0-S3 : 4-bit value input
#
# Game flow:
# 1. The seven-segment display slowly plays 1 -> blank -> 3 -> blank
#    -> 2 -> blank -> 4 -> blank.
# 2. During input, the display shows the current target number.
# 3. Player sets S0-S3 to the target value to clear that round.
# 4. After each round, player must return S0-S3 to 0 before the next round.
# 5. PASS: all LEDs on, seven-segment shows 0.
# 6. This version intentionally avoids a separate confirm key so board-side
#    testing only depends on the verified switch MMIO path.
#==============================================================================

    addi x1, x0, -1024        # x1 = 0xFFFF_FC00 (LED base)
    addi x3, x1, 32           # x3 = 0xFFFF_FC20 (SEG7 base)
    # Playback 1
    lui  x4, 0xF9FA0
    addi x4, x4, -103         # x4 = 0xF9F9_F9F9 (digit 1)
    sw   x4, 0(x3)
    jal  x31, delay
    addi x4, x0, -1           # blank / all off
    sw   x4, 0(x3)
    jal  x31, delay

    # Playback 3
    lui  x4, 0xB0B0B
    addi x4, x4, 176          # x4 = 0xB0B0_B0B0
    sw   x4, 0(x3)
    jal  x31, delay
    addi x4, x0, -1
    sw   x4, 0(x3)
    jal  x31, delay

    # Playback 2
    lui  x4, 0xA4A4A
    addi x4, x4, 1188         # x4 = 0xA4A4_A4A4
    sw   x4, 0(x3)
    jal  x31, delay
    addi x4, x0, -1
    sw   x4, 0(x3)
    jal  x31, delay

    # Playback 4
    lui  x4, 0x9999A
    addi x4, x4, -1639        # x4 = 0x9999_9999
    sw   x4, 0(x3)
    jal  x31, delay
    addi x4, x0, -1
    sw   x4, 0(x3)
    jal  x31, delay

    # Round 1: expect 1, then release back to 0
    lui  x4, 0xF9FA0
    addi x4, x4, -103
    sw   x4, 0(x3)
    addi x5, x0, 1
round1_wait:
    lw   x2, 16(x1)
    andi x2, x2, 0xF
    sw   x2, 0(x1)
    bne  x2, x5, round1_wait
round1_release:
    lw   x2, 16(x1)
    andi x2, x2, 0xF
    sw   x2, 0(x1)
    bne  x2, x0, round1_release

    # Round 2: expect 3, then release back to 0
    lui  x4, 0xB0B0B
    addi x4, x4, 176
    sw   x4, 0(x3)
    addi x5, x0, 3
round2_wait:
    lw   x2, 16(x1)
    andi x2, x2, 0xF
    sw   x2, 0(x1)
    bne  x2, x5, round2_wait
round2_release:
    lw   x2, 16(x1)
    andi x2, x2, 0xF
    sw   x2, 0(x1)
    bne  x2, x0, round2_release

    # Round 3: expect 2, then release back to 0
    lui  x4, 0xA4A4A
    addi x4, x4, 1188
    sw   x4, 0(x3)
    addi x5, x0, 2
round3_wait:
    lw   x2, 16(x1)
    andi x2, x2, 0xF
    sw   x2, 0(x1)
    bne  x2, x5, round3_wait
round3_release:
    lw   x2, 16(x1)
    andi x2, x2, 0xF
    sw   x2, 0(x1)
    bne  x2, x0, round3_release

    # Round 4: expect 4, then release back to 0
    lui  x4, 0x9999A
    addi x4, x4, -1639
    sw   x4, 0(x3)
    addi x5, x0, 4
round4_wait:
    lw   x2, 16(x1)
    andi x2, x2, 0xF
    sw   x2, 0(x1)
    bne  x2, x5, round4_wait
round4_release:
    lw   x2, 16(x1)
    andi x2, x2, 0xF
    sw   x2, 0(x1)
    bne  x2, x0, round4_release

pass:
    addi x6, x0, -1
    sw   x6, 0(x1)            # all LEDs on
    lui  x4, 0xC0C0C
    addi x4, x4, 192          # x4 = 0xC0C0_C0C0 (0)
    sw   x4, 0(x3)
pass_loop:
    jal  x0, pass_loop

delay:
    addi x15, x0, 3500
delay_outer:
    addi x14, x0, 3000
delay_inner:
    addi x14, x14, -1
    bne  x14, x0, delay_inner
    addi x15, x15, -1
    bne  x15, x0, delay_outer
    jalr x0, 0(x31)
