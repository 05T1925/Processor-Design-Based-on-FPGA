# CPU-driven VGA number guessing game and benchmark demo (RV32I + custom MAC)
# S1 previous digit/benchmark; S2 next; S3 increase; S4 decrease; S5 submit/run.
# SW[2:0] selects pages 000..011; 100 selects CPU-driven Tetris.
# x1 VGA, x2 BUTTON, x3 guess, x4 target, x5 attempts, x6 selection,
# x7 state, x8 hint, x9 page, x10 event, x12 PERF, x15 SWITCH, x16 BTB.
# x20 last cycle, x25 elapsed-low, x26 elapsed-high, x27 sample countdown,
# x18 holds the Tetris LFSR seed; x29 is a local helper return register.

start:
    addi x1, x0, -960
    addi x2, x1, 16
    addi x12, x1, 112
    addi x15, x1, -48
    addi x16, x1, 128
    lw   x4, 0(x12)
    andi x4, x4, 1023
    addi x13, x0, 1000
    blt  x4, x13, seed_range_ok
    sub  x4, x4, x13
seed_range_ok:
    bne  x4, x0, seed_nonzero
    addi x4, x0, 573
seed_nonzero:
    addi x3, x0, 0
    addi x5, x0, 0
    addi x6, x0, 0
    addi x7, x0, 1
    addi x8, x0, 0
    addi x9, x0, -1
    addi x27, x0, 0
    addi x20, x0, 0
    addi x25, x0, 0
    addi x26, x0, 0
    addi x29, x0, 0
    lw   x20, 0(x12)
    lw   x17, 0(x12)
    lw   x18, 4(x12)
    lw   x19, 8(x12)
    jal  x28, write_metrics
    jal  x30, render_game

main_loop:
    lw   x17, 0(x15)
    andi x17, x17, 7
    beq  x17, x9, page_same
    add  x9, x17, x0
    addi x13, x0, 0
    add  x14, x9, x0
    jal  x31, vga_write
    addi x11, x0, 4
    bne  x9, x11, page_same
    jal  x28, tetris_init
    jal  x0, tetris_loop
page_same:
    addi x11, x0, 4
    bne  x9, x11, normal_page_loop
    jal  x0, tetris_loop
normal_page_loop:
    # Give button events priority.  Performance sampling runs only while idle,
    # so the game remains responsive during acceptance demos.
    lw   x10, 4(x2)
    bne  x10, x0, handle_button

    # Poll elapsed time frequently; display metrics update once per second.
    addi x27, x27, -1
    bne  x27, x0, main_loop
    lui  x27, 0x10
    lw   x17, 0(x12)
    lw   x18, 4(x12)
    lw   x19, 8(x12)
    sub  x21, x17, x20
    add  x22, x25, x21
    sltu x23, x22, x25
    add  x26, x26, x23
    add  x25, x22, x0
    add  x20, x17, x0
    bne  x26, x0, timer_due
    # 30 seconds at 100 MHz = 3,000,000,000 = 0xB2D05E00.
    lui  x24, 0xB2D06
    addi x24, x24, -512
    bltu x25, x24, timer_not_due
timer_due:
    add  x11, x4, x0
    andi x4, x17, 1023
    addi x13, x0, 1000
    blt  x4, x13, new_target_range_ok
    sub  x4, x4, x13
new_target_range_ok:
    bne  x4, x0, new_target_nonzero
    addi x4, x0, 573
new_target_nonzero:
    bne  x4, x11, new_target_ready
    addi x4, x4, 1
    blt  x4, x13, new_target_ready
    addi x4, x0, 1
new_target_ready:
    addi x3, x0, 0
    addi x5, x0, 0
    addi x6, x0, 0
    addi x7, x0, 1
    addi x8, x0, 0
    addi x25, x0, 0
    addi x26, x0, 0
    addi x29, x0, 0
    jal  x30, render_game
    jal  x28, write_metrics
    addi x13, x0, 12
    add  x14, x19, x0
    jal  x31, vga_write
    jal  x0, main_loop
timer_not_due:
    # x29 tracks the low elapsed-cycle value used by the previous 1 s sample.
    sub  x23, x25, x29
    # 1 second at 100 MHz = 100,000,000 = 0x05F5E100.
    lui  x24, 0x5F5E
    addi x24, x24, 256
    bltu x23, x24, live_metrics_done
refresh_metrics:
    add  x29, x25, x0
    # Reuse the existing fixed-point metric routine for live CPI/IPC/MIPS.
    jal  x28, write_metrics
    addi x13, x0, 12
    add  x14, x19, x0
    jal  x31, vga_write
live_metrics_done:
    jal  x0, main_loop
handle_button:
    addi x13, x0, 18
    addi x14, x0, 1
    jal  x31, vga_write
    addi x13, x0, 19
    addi x14, x2, 4
    jal  x31, vga_write
    addi x13, x0, 21
    add  x14, x10, x0
    jal  x31, vga_write
    addi x13, x0, 22
    addi x14, x0, 5
    jal  x31, vga_write
    addi x13, x0, 23
    add  x14, x10, x0
    jal  x31, vga_write
    addi x11, x0, 2
    beq  x9, x11, bench_input

game_input:
    andi x11, x10, 1
    bne  x11, x0, game_left
    andi x11, x10, 2
    bne  x11, x0, game_right
    andi x11, x10, 4
    bne  x11, x0, game_up
    andi x11, x10, 8
    bne  x11, x0, game_down
    andi x11, x10, 16
    bne  x11, x0, game_submit
    jal  x0, game_done
game_left:
    beq  x6, x0, game_done
    addi x6, x6, -1
    jal  x0, game_done
game_right:
    addi x11, x0, 2
    bge  x6, x11, game_done
    addi x6, x6, 1
    jal  x0, game_done
game_up:
    beq  x6, x0, game_add_100
    addi x11, x0, 1
    beq  x6, x11, game_add_10
    addi x3, x3, 1
    jal  x0, game_wrap_up
game_add_100:
    addi x3, x3, 100
    jal  x0, game_wrap_up
game_add_10:
    addi x3, x3, 10
game_wrap_up:
    addi x11, x0, 1000
    blt  x3, x11, game_done
    sub  x3, x3, x11
    jal  x0, game_done
game_down:
    beq  x6, x0, game_sub_100
    addi x11, x0, 1
    beq  x6, x11, game_sub_10
    addi x11, x0, 1
    jal  x0, game_sub_apply
game_sub_100:
    addi x11, x0, 100
    jal  x0, game_sub_apply
game_sub_10:
    addi x11, x0, 10
game_sub_apply:
    bge  x3, x11, game_sub_ready
    addi x3, x3, 1000
game_sub_ready:
    sub  x3, x3, x11
    jal  x0, game_done
game_submit:
    addi x5, x5, 1
    blt  x3, x4, guess_low
    blt  x4, x3, guess_high
    addi x7, x0, 4
    addi x8, x0, 3
    jal  x0, game_done
guess_low:
    addi x7, x0, 2
    addi x8, x0, 1
    jal  x0, game_done
guess_high:
    addi x7, x0, 3
    addi x8, x0, 2
game_done:
    jal  x30, render_game
    sw   x10, 12(x2)
    jal  x0, main_loop

bench_input:
    andi x11, x10, 1
    beq  x11, x0, bench_right_check
    beq  x6, x0, bench_ack
    addi x6, x6, -1
    jal  x0, bench_show
bench_right_check:
    andi x11, x10, 2
    beq  x11, x0, bench_run_check
    addi x11, x0, 3
    bge  x6, x11, bench_ack
    addi x6, x6, 1
bench_show:
    addi x13, x0, 24
    add  x14, x6, x0
    jal  x31, vga_write
    # A new benchmark selection invalidates the previous result snapshot.
    addi x13, x0, 25
    addi x14, x0, 0
    jal  x31, vga_write
    addi x13, x0, 26
    addi x14, x0, 0
    jal  x31, vga_write
    addi x13, x0, 27
    addi x14, x0, 0
    jal  x31, vga_write
    addi x13, x0, 28
    addi x14, x0, 0
    jal  x31, vga_write
    jal  x0, bench_ack
bench_run_check:
    andi x11, x10, 16
    beq  x11, x0, bench_ack
    # Publish a fresh RUNNING edge even when S5 repeats the same benchmark.
    addi x13, x0, 25
    addi x14, x0, 0
    jal  x31, vga_write
    addi x13, x0, 26
    addi x14, x0, 0
    jal  x31, vga_write
    addi x13, x0, 27
    addi x14, x0, 0
    jal  x31, vga_write
    addi x13, x0, 28
    addi x14, x0, 0
    jal  x31, vga_write
    beq  x6, x0, benchmark_branch
    addi x11, x0, 1
    beq  x6, x11, benchmark_memory
    addi x11, x0, 2
    beq  x6, x11, benchmark_mac
    jal  x0, benchmark_mixed

benchmark_branch:
    lw   x17, 0(x12)
    lw   x18, 4(x12)
    lui  x20, 0x3
    addi x20, x20, 512
    addi x21, x0, 0
branch_loop:
    addi x21, x21, 1
    andi x22, x21, 1
    beq  x22, x0, branch_even
    addi x23, x23, 1
branch_even:
    addi x20, x20, -1
    bne  x20, x0, branch_loop
    jal  x0, benchmark_finish

benchmark_memory:
    lw   x17, 0(x12)
    lw   x18, 4(x12)
    lui  x20, 0x10000
    lui  x21, 0x1
    addi x21, x21, 1024
    addi x21, x21, 1024
    addi x21, x21, 256
memory_loop:
    sw   x21, 0(x20)
    lw   x22, 0(x20)
    addi x20, x20, 4
    addi x21, x21, -1
    bne  x21, x0, memory_loop
    jal  x0, benchmark_finish

benchmark_mac:
    lw   x17, 0(x12)
    addi x24, x0, 0
    addi x20, x0, 16
    slli x20, x20, 6
    addi x20, x20, 576
normal_mul_loop:
    addi x24, x24, 7
    addi x20, x20, -1
    bne  x20, x0, normal_mul_loop
    add  x27, x24, x0
    lw   x19, 0(x12)
    sub  x25, x19, x17
    lw   x17, 0(x12)
    addi x24, x0, 0
    addi x21, x0, 7
    addi x20, x0, 16
    addi x22, x0, 100
mac_loop:
    mac  x24, x21, x20
    addi x22, x22, -1
    bne  x22, x0, mac_loop
    lw   x19, 0(x12)
    sub  x26, x19, x17
    addi x14, x0, 1
    beq  x24, x27, mac_result_ok
    addi x14, x0, 0
mac_result_ok:
    addi x13, x0, 28
    jal  x31, vga_write
    addi x13, x0, 25
    add  x14, x25, x0
    jal  x31, vga_write
    lw   x14, 8(x12)
    addi x13, x0, 12
    jal  x31, vga_write
    addi x13, x0, 26
    add  x14, x26, x0
    jal  x31, vga_write
    slli x20, x25, 6
    slli x21, x25, 5
    add  x20, x20, x21
    slli x21, x25, 2
    add  x20, x20, x21
    addi x22, x0, 0
speedup_div:
    blt  x20, x26, speedup_done
    sub  x20, x20, x26
    addi x22, x22, 1
    jal  x0, speedup_div
speedup_done:
    addi x13, x0, 27
    add  x14, x22, x0
    jal  x31, vga_write
    jal  x0, bench_ack

benchmark_mixed:
    lw   x17, 0(x12)
    lw   x18, 4(x12)
    lui  x20, 0x10000
    addi x21, x0, 100
    addi x22, x0, 0
mixed_loop:
    lw   x23, 0(x20)
    addi x23, x23, 1
    sw   x23, 0(x20)
    add  x22, x22, x23
    andi x24, x22, 3
    bne  x24, x0, mixed_no_mac
    mac  x22, x22, x23
mixed_no_mac:
    addi x20, x20, 4
    andi x24, x20, 255
    bne  x24, x0, mixed_addr_ok
    lui  x20, 0x10000
mixed_addr_ok:
    addi x21, x21, -1
    bne  x21, x0, mixed_loop
    jal  x0, benchmark_finish

benchmark_finish:
    lw   x19, 0(x12)
    lw   x20, 4(x12)
    sub  x17, x19, x17
    sub  x18, x20, x18
    addi x13, x0, 25
    add  x14, x17, x0
    jal  x31, vga_write
    addi x13, x0, 28
    addi x14, x0, 1
    jal  x31, vga_write
    jal  x28, write_metrics
    lw   x14, 0(x16)
    addi x13, x0, 13
    jal  x31, vga_write
    lw   x14, 4(x16)
    addi x13, x0, 14
    jal  x31, vga_write
    addi x13, x0, 28
    addi x14, x0, 1
    jal  x31, vga_write
bench_ack:
    lw   x20, 0(x12)
    addi x27, x0, 0
    sw   x10, 12(x2)
    jal  x0, main_loop

# Tetris state: x20=x, x21=y, x22=piece, x23=next, x24=score,
# x25=state (1 running, 2 paused), x26=rotation, x27=drop countdown.
tetris_init:
    addi x20, x0, 3
    addi x21, x0, 0
    lw   x18, 0(x12)
    andi x18, x18, 2047
    bne  x18, x0, lfsr_seed_ok
    lui  x18, 0xB
    addi x18, x18, -799
lfsr_seed_ok:
    jal  x29, lfsr_next
    add  x22, x13, x0
    jal  x29, lfsr_next
    add  x23, x13, x0
    addi x24, x0, 0
    addi x25, x0, 1
    addi x26, x0, 0
    jal  x29, tetris_speed_reset
    addi x13, x0, 48
    addi x14, x0, 1
    jal  x31, vga_write
    jal  x30, tetris_render
    jalr x0, 0(x28)

tetris_loop:
    lw   x17, 0(x15)
    andi x17, x17, 7
    addi x11, x0, 4
    bne  x17, x11, tetris_leave
    lw   x10, 4(x2)
    bne  x10, x0, tetris_button
    addi x11, x0, 1
    bne  x25, x11, tetris_loop
    addi x27, x27, -1
    bne  x27, x0, tetris_loop
    jal  x29, tetris_speed_reset
    jal  x0, tetris_drop
tetris_leave:
    addi x25, x0, 0
    jal  x0, main_loop
tetris_button:
    andi x11, x10, 16
    bne  x11, x0, tetris_pause
    addi x11, x0, 1
    beq  x25, x11, tetris_running_input
    andi x11, x10, 4
    beq  x11, x0, tetris_ack
    jal  x28, tetris_init
    jal  x0, tetris_ack
tetris_running_input:
    andi x11, x10, 1
    bne  x11, x0, tetris_left
    andi x11, x10, 2
    bne  x11, x0, tetris_right
    andi x11, x10, 4
    bne  x11, x0, tetris_drop
    andi x11, x10, 8
    bne  x11, x0, tetris_rotate
    jal  x0, tetris_ack
tetris_left:
    beq  x20, x0, tetris_ack
    addi x20, x20, -1
    jal  x30, tetris_render
    lw   x11, 12(x1)
    andi x11, x11, 2
    beq  x11, x0, tetris_ack
    addi x20, x20, 1
    jal  x0, tetris_changed
tetris_right:
    addi x20, x20, 1
    jal  x30, tetris_render
    lw   x11, 12(x1)
    andi x11, x11, 2
    beq  x11, x0, tetris_ack
    addi x20, x20, -1
    jal  x0, tetris_changed
tetris_rotate:
    addi x26, x26, 1
    andi x26, x26, 3
    jal  x30, tetris_render
    lw   x11, 12(x1)
    andi x11, x11, 2
    beq  x11, x0, tetris_ack
    # Basic wall kick: try one cell left, then one cell right of the origin.
    beq  x20, x0, tetris_kick_right
    addi x20, x20, -1
    jal  x30, tetris_render
    lw   x11, 12(x1)
    andi x11, x11, 2
    beq  x11, x0, tetris_ack
    addi x20, x20, 1
tetris_kick_right:
    addi x20, x20, 1
    jal  x30, tetris_render
    lw   x11, 12(x1)
    andi x11, x11, 2
    beq  x11, x0, tetris_ack
    addi x20, x20, -1
    addi x26, x26, -1
    andi x26, x26, 3
    jal  x0, tetris_changed
tetris_pause:
    addi x11, x0, 1
    beq  x25, x11, tetris_set_paused
    addi x25, x0, 1
    jal  x0, tetris_changed
tetris_set_paused:
    addi x25, x0, 2
    jal  x0, tetris_changed
tetris_drop:
    addi x21, x21, 1
    jal  x30, tetris_render
    lw   x11, 12(x1)
    andi x11, x11, 2
    beq  x11, x0, tetris_ack
    addi x21, x21, -1
    jal  x30, tetris_render
    jal  x0, tetris_lock
tetris_lock:
    addi x13, x0, 47
    addi x14, x0, 1
    jal  x31, vga_write
    addi x24, x24, 10
    add  x22, x23, x0
    jal  x29, lfsr_next
    add  x23, x13, x0
tetris_piece_ok:
    addi x20, x0, 3
    addi x21, x0, 0
    addi x26, x0, 0
    jal  x29, tetris_speed_reset
    jal  x30, tetris_render
    lw   x11, 12(x1)
    andi x11, x11, 2
    beq  x11, x0, tetris_ack
    addi x25, x0, 3
tetris_changed:
    jal  x30, tetris_render
tetris_ack:
    sw   x10, 12(x2)
    jal  x0, tetris_loop

tetris_render:
    addi x13, x0, 40
    add  x14, x20, x0
    jal  x31, vga_write
    addi x13, x0, 41
    add  x14, x21, x0
    jal  x31, vga_write
    addi x13, x0, 42
    add  x14, x22, x0
    jal  x31, vga_write
    addi x13, x0, 43
    add  x14, x23, x0
    jal  x31, vga_write
    addi x13, x0, 44
    add  x14, x24, x0
    jal  x31, vga_write
    addi x13, x0, 45
    add  x14, x25, x0
    jal  x31, vga_write
    addi x13, x0, 46
    add  x14, x26, x0
    jal  x31, vga_write
    jalr x0, 0(x30)

render_game:
    addi x13, x0, 1
    add  x14, x7, x0
    jal  x31, vga_write
    addi x13, x0, 2
    add  x14, x3, x0
    jal  x31, vga_write
    addi x13, x0, 3
    add  x14, x5, x0
    jal  x31, vga_write
    addi x13, x0, 4
    add  x14, x8, x0
    jal  x31, vga_write
    addi x13, x0, 5
    add  x14, x6, x0
    jal  x31, vga_write
    addi x13, x0, 29
    add  x14, x3, x0
    jal  x31, vga_write
    addi x13, x0, 30
    add  x14, x4, x0
    jal  x31, vga_write
    addi x13, x0, 31
    add  x14, x5, x0
    jal  x31, vga_write
    jalr x0, 0(x30)

write_metrics:
    addi x13, x0, 7
    add  x14, x17, x0
    jal  x31, vga_write
    addi x13, x0, 8
    add  x14, x18, x0
    jal  x31, vga_write
    beq  x18, x0, metrics_done
    beq  x17, x0, metrics_done
    slli x23, x17, 6
    slli x21, x17, 5
    add  x23, x23, x21
    slli x21, x17, 2
    add  x23, x23, x21
    addi x24, x0, 0
cpi_div:
    blt  x23, x18, cpi_done
    sub  x23, x23, x18
    addi x24, x24, 1
    jal  x0, cpi_div
cpi_done:
    addi x13, x0, 9
    add  x14, x24, x0
    jal  x31, vga_write
    slli x23, x18, 6
    slli x21, x18, 5
    add  x23, x23, x21
    slli x21, x18, 2
    add  x23, x23, x21
    addi x24, x0, 0
ipc_div:
    blt  x23, x17, ipc_done
    sub  x23, x23, x17
    addi x24, x24, 1
    jal  x0, ipc_div
ipc_done:
    addi x13, x0, 10
    add  x14, x24, x0
    jal  x31, vga_write
    slli x23, x18, 10
    slli x21, x18, 4
    sub  x23, x23, x21
    slli x21, x18, 3
    sub  x23, x23, x21
    addi x24, x0, 0
mips_div:
    blt  x23, x17, mips_done
    sub  x23, x23, x17
    addi x24, x24, 1
    jal  x0, mips_div
mips_done:
    addi x13, x0, 11
    add  x14, x24, x0
    jal  x31, vga_write
metrics_done:
    jalr x0, 0(x28)

vga_write:
    sw   x14, 0(x1)
    ori  x13, x13, 256
    sw   x13, 4(x1)
    jalr x0, 0(x31)

lfsr_next:
    srli x11, x18, 2
    xor  x11, x11, x18
    srli x13, x18, 3
    xor  x11, x11, x13
    srli x13, x18, 5
    xor  x11, x11, x13
    andi x11, x11, 1
    srli x18, x18, 1
    slli x11, x11, 15
    or   x18, x18, x11
    andi x13, x18, 7
    bne  x13, x0, lfsr_done
    addi x13, x0, 1
lfsr_done:
    jalr x0, 0(x29)

tetris_speed_reset:
    lw   x17, 0(x15)
    srli x11, x17, 3
    andi x11, x11, 3
    addi x13, x0, 49
    add  x14, x11, x0
    jal  x31, vga_write
    beq  x11, x0, speed_slow
    addi x13, x0, 1
    beq  x11, x13, speed_medium
    addi x13, x0, 2
    beq  x11, x13, speed_fast
    lui  x27, 0x100
    jalr x0, 0(x29)
speed_slow:
    lui  x27, 0x600
    jalr x0, 0(x29)
speed_medium:
    lui  x27, 0x400
    jalr x0, 0(x29)
speed_fast:
    lui  x27, 0x200
    jalr x0, 0(x29)
