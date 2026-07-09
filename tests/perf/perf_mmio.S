# Read all three performance counters through MMIO.
# x6 = cycle snapshot, x7 = instret snapshot, x8 = mac_count (=1).

    addi x10, x0, 0
    addi x1, x0, 2
    addi x2, x0, 3
    .word 0x0220850b       # mac x10, x1, x2

    addi x5, x0, -848      # 0xFFFF_FCB0
    lw   x6, 0(x5)
    lw   x7, 4(x5)
    lw   x8, 8(x5)
    ebreak
