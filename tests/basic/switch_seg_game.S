#==============================================================================
# Stable Switch to 7-Segment Demo
#
# Flow:
# 1. Read S0-S3 continuously.
# 2. Mirror the low 4 bits to LED[3:0].
# 3. Display the corresponding digit on all 8 seven-segment digits.
# 4. Values 0-8 show decimal digits 0-8.
# 5. Values 9-F show "-" to indicate out-of-range.
#
# Note:
# The constants below are loaded as exact 32-bit repeated-byte patterns.
# This avoids the earlier immediate-construction mistakes that made some
# digits, especially 1/6/7, display incorrectly on board.
#
# MMIO:
#   0xFFFF_FC00 : LED
#   0xFFFF_FC10 : SWITCH
#   0xFFFF_FC20 : SEG7
#==============================================================================

    addi x1, x0, -1024        # x1 = 0xFFFF_FC00 (LED base)
    addi x3, x1, 32           # x3 = 0xFFFF_FC20 (SEG7 base)

loop:
    lw   x2, 16(x1)           # read switch MMIO
    andi x2, x2, 0xF          # use S0-S3 only
    sw   x2, 0(x1)            # mirror to LED

    addi x5, x0, 0
    beq  x2, x5, show0
    addi x5, x0, 1
    beq  x2, x5, show1
    addi x5, x0, 2
    beq  x2, x5, show2
    addi x5, x0, 3
    beq  x2, x5, show3
    addi x5, x0, 4
    beq  x2, x5, show4
    addi x5, x0, 5
    beq  x2, x5, show5
    addi x5, x0, 6
    beq  x2, x5, show6
    addi x5, x0, 7
    beq  x2, x5, show7
    addi x5, x0, 8
    beq  x2, x5, show8
    jal  x0, show_dash

show0:
    lui  x4, 0xC0C0C
    addi x4, x4, 192          # x4 = 0xC0C0_C0C0
    sw   x4, 0(x3)
    jal  x0, loop

show1:
    lui  x4, 0xF9FA0
    addi x4, x4, -1543        # exact x4 = 0xF9F9_F9F9
    sw   x4, 0(x3)
    jal  x0, loop

show2:
    lui  x4, 0xA4A4A
    addi x4, x4, 1188         # x4 = 0xA4A4_A4A4
    sw   x4, 0(x3)
    jal  x0, loop

show3:
    lui  x4, 0xB0B0B
    addi x4, x4, 176          # x4 = 0xB0B0_B0B0
    sw   x4, 0(x3)
    jal  x0, loop

show4:
    lui  x4, 0x9999A
    addi x4, x4, -1639        # x4 = 0x9999_9999
    sw   x4, 0(x3)
    jal  x0, loop

show5:
    lui  x4, 0x92929
    addi x4, x4, 658          # x4 = 0x9292_9292
    sw   x4, 0(x3)
    jal  x0, loop

show6:
    lui  x4, 0x82828
    addi x4, x4, 642          # exact x4 = 0x8282_8282
    sw   x4, 0(x3)
    jal  x0, loop

show7:
    lui  x4, 0xF8F90
    addi x4, x4, -1800        # exact x4 = 0xF8F8_F8F8
    sw   x4, 0(x3)
    jal  x0, loop

show8:
    lui  x4, 0x80808
    addi x4, x4, 128          # x4 = 0x8080_8080
    sw   x4, 0(x3)
    jal  x0, loop

show_dash:
    lui  x4, 0xBFBFC
    addi x4, x4, -1025        # x4 = 0xBFBF_BFBF
    sw   x4, 0(x3)
    jal  x0, loop
