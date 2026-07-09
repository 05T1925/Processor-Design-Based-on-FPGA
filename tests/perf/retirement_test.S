# Retirement coverage: ALU, STORE, LOAD, not-taken branch, taken branch, MAC.
# Expected: x4=1, data_ram[0]=1, instret_count=8, mac_count=1.

    addi x1, x0, 1
    lui  x6, 0x10000
    sw   x1, 0(x6)
    lw   x2, 0(x6)
    bne  x1, x2, 8
    addi x3, x0, 7
    beq  x1, x2, 8
    addi x3, x0, 99
    .word 0x0220820b       # mac x4, x1, x2
    ebreak
