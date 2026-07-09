# Custom-MAC dot product.
# A = [1,2,3,4], B = [5,6,7,8], result x10 = 70.
#
# MAC encoding:
#   funct7=0000001, funct3=000, opcode=0001011
#   semantics: rd = rd_old + rs1 * rs2
# GNU assemblers that do not know this custom instruction can use the .word
# values listed beside each MAC.

    addi x10, x0, 0

    addi x1, x0, 1
    addi x2, x0, 5
    .word 0x0220850b       # mac x10, x1, x2

    addi x1, x0, 2
    addi x2, x0, 6
    .word 0x0220850b       # mac x10, x1, x2

    addi x1, x0, 3
    addi x2, x0, 7
    .word 0x0220850b       # mac x10, x1, x2

    addi x1, x0, 4
    addi x2, x0, 8
    .word 0x0220850b       # mac x10, x1, x2

    ebreak
