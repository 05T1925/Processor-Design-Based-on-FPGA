# RV32I Basic Test Program
# Tests ADD, ADDI, LW, SW, BEQ, EBREAK
#
# Expected result: x5 = 1, done = 1, error = 0

# Initialize test values
addi x1, x0, 10        # x1 = 10
addi x2, x0, 20        # x2 = 20
add  x3, x1, x2       # x3 = 10 + 20 = 30

# Store and load test
sw   x3, 0(x0)        # mem[0] = 30
lw   x4, 0(x0)        # x4 = mem[0] = 30

# Branch test: x3 (30) should equal x4 (30)
beq  x3, x4, pass     # should branch
addi x5, x0, 0        # x5 = 0 (should be skipped)
ebreak                  # HALT (should be skipped)

pass:
addi x5, x0, 1        # x5 = 1 (PASS indicator)
ebreak                  # HALT - test complete

# Translation to hex (RV32I encoding):
# 0x00000000: 00A00093  addi x1, x0, 10
# 0x00000004: 01400113  addi x2, x0, 20
# 0x00000008: 002081B3  add  x3, x1, x2
# 0x0000000C: 00302023  sw   x3, 0(x0)
# 0x00000010: 00002203  lw   x4, 0(x0)
# 0x00000014: 00418263  beq  x3, x4, 4
# 0x00000018: 00000293  addi x5, x0, 0
# 0x0000001C: 00100073  ebreak
# 0x00000020: 00100293  addi x5, x0, 1
# 0x00000024: 00100073  ebreak
