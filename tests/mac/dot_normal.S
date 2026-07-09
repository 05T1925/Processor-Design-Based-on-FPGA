# RV32I software dot product baseline.
# A = [1,2,3,4], B = [5,6,7,8], result x10 = 70.
# The implemented ISA has no MUL, so fixed-count repeated addition is used.

    addi x10, x0, 0

    addi x1, x0, 5
    add  x10, x10, x1

    addi x1, x0, 6
    add  x10, x10, x1
    add  x10, x10, x1

    addi x1, x0, 7
    add  x10, x10, x1
    add  x10, x10, x1
    add  x10, x10, x1

    addi x1, x0, 8
    add  x10, x10, x1
    add  x10, x10, x1
    add  x10, x10, x1
    add  x10, x10, x1

    ebreak
