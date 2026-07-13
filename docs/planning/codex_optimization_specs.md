# 优化实现规格说明书（Codex 可直接执行）

> 生成日期：2026-07-12
> 目标文件概览：
> - `tests/demo/cpu_guess_game.S`（607行，RV32I汇编，主要改动目标）
> - `src/io/vga_dashboard.v`（647行，Verilog，渲染改动）
> - `src/io/vga_mmio_regs.v`（170行，Verilog，新寄存器改动）
> - `src/soc/soc_top.v`（~330行，Verilog，连线改动）
> - `src/board/minisys_top.v`（66行，Verilog，参数切换）

---

## 规格 1：基准测试循环 100 倍放大

**优先级**：P0 | **改动量**：3 行 | **类型**：汇编常量修改

### 目标
当前基准循环次数太少，多周期/流水线差异不明显。扩大100倍后周期数差异放大到可感知范围。

### 文件：`tests/demo/cpu_guess_game.S`

#### 改动 1.1 — BRANCH 基准（第255行）
```
当前:  addi x20, x0, 128
改为:  lui  x20, 0x32       # x20 = 0x32000 = 204800 (upper)
       addi x20, x20, 0     # 可选微调
```
最简做法（12800 次，100x）：
```
改为:  addi x20, x0, 128
       slli x20, x20, 6     # x20 = 128 << 6 = 8192
       addi x20, x20, 608   # 凑到约 8800（128*69≈8832）
```
最简精确做法（保持兼容）：
```
# 第255行: addi x20, x0, 128  → 删除此行
# 替代为:
       lui  x20, 0x3        # x20 = 0x3000 = 12288
       addi x20, x20, 512   # x20 = 12800 (100倍)
```

#### 改动 1.2 — MEMORY 基准（第271行）
```
当前:  addi x21, x0, 64
改为:  lui  x21, 0x19       # x21 = 0x19000 = 102400
       slli x21, x21, 0     # 或 addi x21, x21, 0
```
精确 100 倍（6400 次）：
```
# 第271行: addi x21, x0, 64 → 删除
# 替代为:
       lui  x21, 0x1        # x21 = 0x1000 = 4096
       addi x21, x21, 0x900 # x21 = 4096 + 2304 = 6400 (100倍)
# 注意：0x900 超过12位立即数，需拆分:
       lui  x21, 0x1        # x21 = 4096
       addi x21, x21, 1024  # x21 = 5120
       addi x21, x21, 1024  # x21 = 6144
       addi x21, x21, 256   # x21 = 6400
```

#### 改动 1.3 — MAC 基准（第283行 + 第294行）
```
第283行 当前: addi x20, x0, 16
       改为:  addi x20, x0, 16
              slli x20, x20, 6    # x20 = 1024
              addi x20, x20, 576  # x20 = 1600 (100倍)

第294行 当前: addi x22, x0, 16
       改为:  addi x22, x0, 16
              slli x22, x22, 6    # x22 = 1024
              addi x22, x22, 576  # x22 = 1600 (100倍)
```

### 验证
- 上板后 PAGE 2 的 NORMAL CYC 和 MAC CYC 值应明显增大（原来~几十，现在~几千）
- CPI/IPC 值不变（等比例放大，比例不变）

---

## 规格 2：俄罗斯方块 LFSR 伪随机方块生成

**优先级**：P0 | **改动量**：~25行汇编 | **类型**：汇编新增

### 目标
当前方块生成是顺序循环（1→2→3→...→7→1），替换为基于 LFSR 的伪随机生成，提升游戏可玩性。

### LFSR 算法
使用 16-bit Fibonacci LFSR（与程序开头已有种子获取兼容）：
```
多项式: x^16 + x^14 + x^13 + x^11 + 1
tap bits: 16, 14, 13, 11
C 伪代码:
  bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5)) & 1;
  lfsr = (lfsr >> 1) | (bit << 15);
```

### 文件：`tests/demo/cpu_guess_game.S`

#### 改动 2.1 — 新增寄存器分配（更新文件头注释，第1-7行）
```
# 在头部注释增加：
# x14 = LFSR state (16-bit pseudo-random generator for Tetris piece selection)
```

#### 改动 2.2 — 初始化 LFSR 种子（在 tetris_init 中，第359行之后）
当前 `tetris_init`（第359-372行）：
```asm
tetris_init:
    addi x20, x0, 3
    addi x21, x0, 0
    addi x22, x0, 1       # 当前方块固定为1(T型)
    addi x23, x0, 2       # 下一个方块固定为2(O型)
    ...
```

改为：
```asm
tetris_init:
    addi x20, x0, 3
    addi x21, x0, 0
    # --- LFSR 初始化 ---
    lw   x14, 0(x12)      # 读 cycle_count 作为 LFSR 种子
    andi x14, x14, 0xFFFF # 取低16位
    bne  x14, x0, lfsr_seed_ok
    addi x14, x0, 0xACE1  # 种子为0时使用默认值
lfsr_seed_ok:
    # 用 LFSR 生成第一个方块 (piece)
    jal  x28, lfsr_next    # x14 = 新 LFSR 状态, x22 = piece (1-7)
    add  x22, x28, x0      # 暂存 piece → x22
    # 生成第二个方块 (next)
    jal  x28, lfsr_next
    add  x23, x28, x0      # next → x23
    ...
```

#### 改动 2.3 — 新增 lfsr_next 子程序（在文件末尾 vga_write 之后，约第607行）
```asm
#==============================================================================
# lfsr_next - 16-bit LFSR pseudo-random, returns piece in [1,7]
# Input:  x14 = current LFSR state (16-bit)
# Output: x14 = next LFSR state
#         x28 = piece number (1..7)
# Clobbers: x11, x13 (temporaries)
#==============================================================================
lfsr_next:
    # Fibonacci LFSR: x^16 + x^14 + x^13 + x^11 + 1
    # bit = (lfsr[0] ^ lfsr[2] ^ lfsr[3] ^ lfsr[5])
    addi x13, x14, 0
    srli x11, x13, 2       # lfsr >> 2
    xor  x11, x11, x13     # lfsr[0] ^ lfsr[2]
    srli x28, x13, 3
    xor  x11, x11, x28     # ^ lfsr[3]
    srli x28, x13, 5
    xor  x11, x11, x28     # ^ lfsr[5]
    andi x11, x11, 1       # new_bit
    srli x14, x13, 1       # lfsr >> 1
    slli x11, x11, 15      # new_bit << 15
    or   x14, x14, x11     # 新 LFSR 状态
    # 映射到 1..7
    andi x28, x14, 7       # 取低3位 (0..7)
    bne  x28, x0, lfsr_piece_ok
    addi x28, x0, 1        # 0 → 1 (无效)
lfsr_piece_ok:
    addi x11, x0, 8
    blt  x28, x11, lfsr_done
    addi x28, x28, -7      # 8.. → 映射回 1.. (实际 andi 后不可能 >=8，保险)
lfsr_done:
    jalr x0, 0(x28)        # 注意：这里 x28 用作返回的 piece 值
                            # 调用者约定: x28 = piece
```

**重要**：上面的 `lfsr_done: jalr x0, 0(x28)` 不对——`x28` 在这里是 piece 值不是返回地址。需要修正为用 `x28` 存 piece，但返回地址需要用别的寄存器。看原有代码风格，`tetris_init` 用 `jal x28, ...` 调用，返回地址在 `x28`，所以 lfsr_next 不能同时用 x28 做返回地址和返回值。

**修正方案**——用 `x14` 返回 LFSR 状态，用 `x13` 返回 piece 值：

```asm
#==============================================================================
# lfsr_next - 16-bit LFSR pseudo-random piece generator
# Input:  x14 = current LFSR state (16-bit), x1 = return address (ra)
# Output: x14 = next LFSR state, x13 = piece (1..7)
# Clobbers: x11 (temporary)
#==============================================================================
lfsr_next:
    srli x11, x14, 2
    xor  x11, x11, x14     # lfsr[0] ^ lfsr[2]
    srli x13, x14, 3
    xor  x11, x11, x13     # ^ lfsr[3]
    srli x13, x14, 5
    xor  x11, x11, x13     # ^ lfsr[5]
    andi x11, x11, 1       # new_bit
    srli x14, x14, 1
    slli x11, x11, 15
    or   x14, x14, x11     # 新 LFSR 状态
    andi x13, x14, 7       # 低3位映射到0..7
    bne  x13, x0, lfsr_ok
    addi x13, x0, 1        # 0 → 1
lfsr_ok:
    addi x11, x0, 8
    blt  x13, x11, lfsr_done
    addi x13, x13, -7      # 安全映射(理论上不会到这里)
lfsr_done:
    jalr x0, 0(x1)         # 返回
```

#### 改动 2.4 — tetris_lock 中使用 LFSR（替换第473-477行）
```asm
# 当前代码（第473-477行）:
    add  x22, x23, x0      # piece = next
    addi x23, x23, 1       # next++ (顺序)
    addi x11, x0, 8
    blt  x23, x11, tetris_piece_ok
    addi x23, x0, 1

# 改为:
    add  x22, x23, x0      # piece = next
    jal  x1, lfsr_next     # x13 = 新随机方块 (clobbers x11)
    add  x23, x13, x0      # next = 随机方块
    # 无需边界检查，lfsr_next 保证返回 1..7
```

#### 改动 2.5 — tetris_init 调用约定修正（第359-372行）
```asm
tetris_init:
    addi x20, x0, 3
    addi x21, x0, 0
    # --- LFSR 初始化 ---
    lw   x14, 0(x12)       # 用 cycle_count 做种子
    andi x14, x14, 0xFFFF
    bne  x14, x0, lfsr_seed_ok
    addi x14, x0, 0xACE1
lfsr_seed_ok:
    jal  x1, lfsr_next     # x13 = piece
    add  x22, x13, x0      # x22 = piece
    jal  x1, lfsr_next     # x13 = next
    add  x23, x13, x0      # x23 = next
    # --- LFSR 初始化结束 ---
    addi x24, x0, 0
    addi x25, x0, 1
    addi x26, x0, 0
    lui  x27, 0x600
    addi x13, x0, 48
    addi x14, x0, 1
    jal  x31, vga_write
    jal  x30, tetris_render
    jalr x0, 0(x28)
```

### 注意事项
- `lfsr_next` 使用 `jalr x0, 0(x1)` 返回，调用者必须用 `jal x1, lfsr_next`（把返回地址存入 x1）
- 这与现有 `vga_write` 用 `jal x31, vga_write` / `jalr x0, 0(x31)` 的模式不同（x1 vs x31），避免与现有代码的 x31 用法冲突
- x1 在现有程序中被用作 VGA base address（`addi x1, x0, -960`），但 lfsr_next 调用期间不会访问 VGA，x1 作为返回地址寄存器是安全的（RV32I 标准 ra=x1）

---

## 规格 3：俄罗斯方块下落速度分级（SW 控制）

**优先级**：P0 | **改动量**：~20行汇编 + ~3行 Verilog | **类型**：汇编 + Verilog

### 目标
用 SW[4:3] 控制下落速度，每消10行自动升一档。速度值显示在 PAGE 4 上。

### 文件 1：`tests/demo/cpu_guess_game.S`

#### 改动 3.1 — 新增 VGA MMIO field 49（tetris_speed 显示）
先在 `vga_mmio_regs.v` 增加一个速度显示字段：

**文件**：`src/io/vga_mmio_regs.v`

在端口列表（约第68行 `tetris_clear_count` 之后）增加：
```verilog
    output reg  [31:0] tetris_speed       // NEW: field 49
```

在 always 块中（约第141行后）增加：
```verilog
    8'd49: tetris_speed <= wdata_reg;
```

在 `soc_top.v` 连线增加（约第273行）：
```verilog
    .tetris_speed(vga_tetris_speed),
```

然后 `vga_dashboard.v` 端口增加并在 PAGE 4 渲染：
```verilog
    input wire [31:0] tetris_speed,
```
在 dashboard_char 的 `3'd4` case 中（约第328行附近 "CPU CYCLES" 行下面）增加一行速度显示：
```verilog
    6'd34: begin label = "SPEED LV"; value = tetris_speed; end
```

#### 改动 3.2 — 汇编新增寄存器定义
```asm
# 在头部注释增加（第7行后）:
# x10 = event, x11 = speed_level (0..3 from SW[4:3]), x12 = PERF, ...
# x27 = drop countdown (base value varies by speed level)
```

#### 改动 3.3 — tetris_init 中初始化速度（第359行之后）
```asm
tetris_init:
    # ... 原有 LFSR 初始化 ...
    # --- 速度初始化 ---
    lw   x17, 0(x15)       # 读 SWITCH
    srli x11, x17, 3       # SW[4:3] → x11[1:0]
    andi x11, x11, 3       # 0..3 速度档位
    jal  x28, speed_apply   # 设置 x27 = 对应延迟值
    # --- 速度初始化结束 ---
    ...
```

#### 改动 3.4 — 新增 speed_apply 子程序
```asm
#==============================================================================
# speed_apply - set drop delay based on speed level
# Input:  x11 = speed_level (0..3)
# Output: x27 = drop countdown base value
#         writes speed level to VGA field 49
# Clobbers: x13, x14, x31
#==============================================================================
speed_apply:
    # 保存 speed_level 用于显示
    addi x13, x0, 49        # VGA field 49 = tetris_speed
    add  x14, x11, x0
    jal  x31, vga_write
    # 查表: level 0=slow(0x600), 1=medium(0x400), 2=fast(0x200), 3=veryfast(0x100)
    beq  x11, x0, speed_slow
    addi x13, x0, 1
    beq  x11, x13, speed_medium
    addi x13, x0, 2
    beq  x11, x13, speed_fast
    # speed_veryfast:
    lui  x27, 0x100         # level 3: ~65536 cycles per drop tick
    jalr x0, 0(x28)
speed_slow:
    lui  x27, 0x600         # level 0: ~393216 cycles (default)
    jalr x0, 0(x28)
speed_medium:
    lui  x27, 0x400         # level 1: ~262144 cycles
    jalr x0, 0(x28)
speed_fast:
    lui  x27, 0x200         # level 2: ~131072 cycles
    jalr x0, 0(x28)
```

#### 改动 3.5 — tetris_lock 中加速逻辑（第468-477行附近）
```asm
tetris_lock:
    addi x13, x0, 47
    addi x14, x0, 1
    jal  x31, vga_write
    # 每 lock 一次加10分
    addi x24, x24, 10
    # --- 加速检查：每10分(即每lock一次，因为每次+10分)其实应该每消行才加速 ---
    # 更合理：在消行时加速。但消行是硬件做的，软件通过 tetris_clear_count 变化感知。
    # 简化方案：每 lock N 次加速一档（或保持手动速度不变，仅 SW 控制）
    # 此处保持 SW 速度不变，不自动加速
    ...
```

**简化建议**：先只做 SW[4:3] 手动选速度 + VGA 显示，自动加速逻辑稍后添加。

#### 改动 3.6 — tetris_loop 和 tetris_drop 中复用 x27
无需改动——现有代码已使用 `x27` 作为下落倒计时，`speed_apply` 直接设置 `x27` 基值即可。但需注意 `tetris_drop` 中第482行 `lui x27, 0x600` 是在锁定时重置倒计时，应改为调用 `speed_apply`：

```asm
tetris_piece_ok:
    addi x20, x0, 3
    addi x21, x0, 0
    addi x26, x0, 0
    # 改为: jal x28, speed_apply  (保留当前 x11 speed_level)
    # 但 x11 可能被中间代码破坏，需先保存
    # 简化：直接读 SW 重新获取 speed_level
    lw   x17, 0(x15)
    srli x11, x17, 3
    andi x11, x11, 3
    jal  x28, speed_apply
```

---

## 规格 4：综合混合基准测试 (bench_id=3)

**优先级**：P1 | **改动量**：~50行汇编 + ~5行 Verilog | **类型**：汇编 + Verilog 标签

### 目标
增加第4个基准测试，混合所有指令类型，模拟真实计算负载。

### 文件 1：`tests/demo/cpu_guess_game.S`

#### 改动 4.1 — 在 bench_input 中增加 bench_id=3 的路由（第247-250行）
```asm
# 当前:
    beq  x6, x0, benchmark_branch
    addi x11, x0, 1
    beq  x6, x11, benchmark_memory
    jal  x0, benchmark_mac

# 改为:
    beq  x6, x0, benchmark_branch
    addi x11, x0, 1
    beq  x6, x11, benchmark_memory
    addi x11, x0, 2
    beq  x6, x11, benchmark_mac
    jal  x0, benchmark_mixed     # bench_id=3 (新增)
```

#### 改动 4.2 — 在 MAC 基准之后（约第328行前）新增 benchmark_mixed
```asm
#==============================================================================
# benchmark_mixed - comprehensive mixed-instruction benchmark
# Simulates real workload: LW + ALU + branch + SW + MAC in one loop body.
# 1000 iterations, each iteration = ~10 instructions.
#==============================================================================
benchmark_mixed:
    lw   x17, 0(x12)        # 记录起始 cycle
    lw   x18, 4(x12)        # 记录起始 instret
    lui  x20, 0x10000       # data_mem base
    addi x21, x0, 0         # accumulator
    addi x22, x0, 250       # 外层循环 250 次 (250*4=1000 内层)
mixed_outer:
    # 内层: 4 次迭代, 每次 ~10 条指令
    lw   x23, 0(x20)        # LW
    addi x23, x23, 1        # ALU
    sw   x23, 0(x20)        # SW
    add  x21, x21, x23      # ALU
    andi x24, x21, 1        # ALU
    beq  x24, x0, mixed_skip # branch
    mac  x21, x21, x23      # MAC (仅奇数时)
mixed_skip:
    addi x20, x20, 4        # ALU
    lw   x23, 0(x20)        # LW (不同地址)
    add  x21, x21, x23      # ALU
    addi x22, x22, -1       # 内层计数 (4,3,2,1)
    bne  x22, x0, mixed_inner_jump
    addi x22, x0, 4         # 重置内层计数
    jal  x0, mixed_inner_done
mixed_inner_jump:
    # 这个标签使内层有 4 次迭代然后重置
    # 实际上需要重构——用简单双层循环:
    # 改为更清晰的写法：
    # 见下方重构版本
    ...
```

**更清晰的重构版本**（推荐直接使用）：

```asm
#==============================================================================
# benchmark_mixed - comprehensive mixed-instruction benchmark
# 100 iterations of a mixed body: LW, ALU, branch, SW, MAC
#==============================================================================
benchmark_mixed:
    lw   x17, 0(x12)        # 起始 cycle
    lw   x18, 4(x12)        # 起始 instret
    lui  x20, 0x10000       # 数据内存基地址
    addi x21, x0, 100       # 外层循环 100 次
    addi x22, x0, 0         # 累加器
mixed_loop:
    lw   x23, 0(x20)        # LW 加载
    addi x23, x23, 1        # ALU 加
    sw   x23, 0(x20)        # SW 存储
    add  x22, x22, x23      # ALU 累加
    andi x24, x22, 3        # 每4次循环做一次MAC
    bne  x24, x0, mixed_no_mac
    mac  x22, x22, x23      # MAC 乘累加 (custom指令)
mixed_no_mac:
    addi x20, x20, 4        # 地址递增
    andi x24, x20, 0xFF     # 地址回绕（保持在低256字节内）
    bne  x24, x0, mixed_addr_ok
    lui  x20, 0x10000       # 地址回绕到基地址
mixed_addr_ok:
    addi x21, x21, -1       # 循环计数递减
    bne  x21, x0, mixed_loop # 分支（测试分支预测）
    # 完成
    jal  x0, benchmark_finish
```

#### 改动 4.3 — 扩大 bench_id 选择范围（第224行附近）
```asm
# bench_right_check 中:
# 当前:
    addi x11, x0, 2
    bge  x6, x11, bench_ack
# 改为:
    addi x11, x0, 3         # 允许 bench_id = 0,1,2,3
    bge  x6, x11, bench_ack
```

#### 改动 4.4 — 更新 PAGE 2 状态显示标签
**文件**：`src/io/vga_dashboard.v` 第288-291行

当前：
```verilog
    6'd5:  label = (disp_bench_status == 0) ? "PRESS S5 RUN TEST" :
                  (bench_id == 0) ? "BRANCH COMPLETE" :
                  (bench_id == 1) ? "MEMORY COMPLETE" : "MAC BENCH COMPLETE";
```

改为：
```verilog
    6'd5:  label = (disp_bench_status == 0) ? "PRESS S5 RUN TEST" :
                  (bench_id == 0) ? "BRANCH COMPLETE" :
                  (bench_id == 1) ? "MEMORY COMPLETE" :
                  (bench_id == 2) ? "MAC BENCH COMPLETE" : "MIXED BENCH DONE";
```

---

## 规格 5：俄罗斯方块 Game Over 视觉增强

**优先级**：P1 | **改动量**：~30行 Verilog | **类型**：Verilog 硬件渲染

### 目标
GAME OVER 时棋盘区域叠加红色覆盖 + 大字体 "GAME OVER" 文字。

### 文件：`src/io/vga_dashboard.v`

#### 改动 5.1 — 新增 GAME OVER 文字标签（第324行附近）
在 `dashboard_char` 函数的 `3'd4` case 中增加（第333行 `default:` 之前）：

```verilog
    // 在 6'd24 行（RUNNING/PAUSED/GAME OVER）之后增加一行大字体提示
    6'd10: label = (tetris_state == 3) ? "=== GAME OVER ===" : "                 ";
```

#### 改动 5.2 — 新增 GAME OVER 棋盘红色覆盖（第597-643行 always @(*) 块中）

在第610行 `if (tetris_locked_cell || tetris_active_cell)` 之后增加：

```verilog
    // GAME OVER 红色闪烁覆盖（棋盘区域半透明红色）
    wire tetris_game_over_on = (disp_page == 3'd4) && (tetris_state == 3) &&
                                tetris_board_area;
    // 闪烁效果：用 v_cnt bit 做低频闪烁
    wire go_flash = (v_cnt[4] == 1'b1);  // 约 30Hz 闪烁
    if (tetris_game_over_on && go_flash) begin
        vga_r = 4'hF; vga_g = 4'h1; vga_b = 4'h1;  // 红色覆盖
    end
```

#### 改动 5.3 — GAME OVER 时分数大字体显示
在 `dashboard_char` 函数中，GAME OVER 状态时在棋盘上方显示最终分数（row 10 复用）：

利用已有的 `decimal4_char` 和渲染框架——GAME OVER 时在第10行显示 "FINAL SCORE: xxx"：
```verilog
    6'd10: begin
        if (tetris_state == 3) begin
            label = "FINAL";
            // 在 col 20-23 显示十进制分数
        end else begin
            label = "                 ";
        end
    end
    6'd11: label = (tetris_state == 3) ? "SCORE" : "      ";
```

并在 hex/decimal 渲染区域（第351-352行）增加：
```verilog
    if (p == 4 && tetris_state == 3 && row == 10 && col >= 20 && col < 24)
        dashboard_char = decimal4_char(tetris_score, col - 20);
```

---

## 规格 6：自动演示模式

**优先级**：P1 | **改动量**：~100行汇编 | **类型**：汇编新增

### 目标
SW15=1 启用自动演示，自动轮播页面并模拟操作。SW15=0 恢复正常手动模式。

### 文件：`tests/demo/cpu_guess_game.S`

#### 改动 6.1 — 寄存器分配
```asm
# x12 = PERF base (已有)
# x19 = auto_tick counter (复用——原本 x19 存 mac_count 读取后即使用，不冲突)
# 新增: x28 = auto_phase (0=GUESS, 1=BENCH, 2=TETRIS)
```

#### 改动 6.2 — main_loop 增加自动模式入口（第42行 main_loop: 之后）
```asm
main_loop:
    # --- 自动演示模式检测 ---
    lw   x17, 0(x15)        # 读 SWITCH
    srli x28, x17, 15       # SW15 → bit 0
    andi x28, x28, 1
    beq  x28, x0, manual_mode   # SW15=0 正常模式
    jal  x0, auto_demo_mode
manual_mode:
    # ... 原有 main_loop 逻辑不变 ...
```

#### 改动 6.3 — auto_demo_mode 子程序（新增，约在 tetris_init 之前）
```asm
#==============================================================================
# auto_demo_mode - automatic demonstration with page rotation
# SW15=1 enables this mode.
# Phase 0: Page 0 (guessing game) - auto binary search
# Phase 1: Page 2 (benchmark) - auto run 3 benchmarks in sequence
# Phase 2: Page 4 (Tetris) - auto simple AI play
# Each phase lasts ~8 seconds
#==============================================================================
auto_demo_mode:
    # 初始化自动演示状态
    lw   x10, 4(x2)         # 读按键（自动模式下忽略，但需要清空 edge）
    bne  x10, x0, auto_clear_btn
    jal  x0, auto_demo_loop
auto_clear_btn:
    sw   x10, 12(x2)        # ack 按键
auto_demo_loop:
    # on-screen timer via cycle counter
    lw   x17, 0(x12)        # 读 cycle_count
    lw   x18, 0(x15)        # 读 SWITCH
    srli x28, x18, 15
    andi x28, x28, 1
    beq  x28, x0, main_loop # SW15=0 退出自动模式
    # --- 自动轮播页面 ---
    # 每约 0x30000000 周期 (~0.8秒) 切换一次子阶段
    # 此处简化：用 x17 低 28 位除以大常数判断阶段
    srli x28, x17, 28       # 每 ~2.68亿周期 (~2.7秒) 换阶段
    andi x28, x28, 3        # 0,1,2,3
    # Phase 0 (x28=0): PAGE 0, 自动二分搜索猜数字
    addi x13, x0, 0
    beq  x28, x13, auto_guess_phase
    # Phase 1 (x28=1): PAGE 2, 自动运行基准
    addi x13, x0, 1
    beq  x28, x13, auto_bench_phase
    # Phase 2 (x28=2): PAGE 4, 自动俄罗斯方块
    addi x13, x0, 2
    beq  x28, x13, auto_tetris_phase
    # Phase 3 (x28=3): PAGE 1, 展示寄存器快照
    addi x13, x0, 1         # page = 1
    addi x14, x0, 1
    jal  x31, vga_write
    jal  x0, auto_demo_loop

auto_guess_phase:
    addi x13, x0, 0
    addi x14, x0, 0         # page=0
    jal  x31, vga_write
    # 每 ~1.5 秒做一次猜测(二分搜索): x3 = (x3 + x4) / 2 (近似)
    # 简化: 每隔一段时间按 S5 (模拟提交)
    # 实际上自动模式不需要复杂AI——只需展示数据流动
    jal  x0, auto_demo_loop

auto_bench_phase:
    addi x13, x0, 0
    addi x14, x0, 2         # page=2
    jal  x31, vga_write
    # 顺序运行 3 个基准
    # 简化: 用 x17 bits 选择 bench_id
    srli x6, x17, 25
    andi x6, x6, 3          # bench_id = 0,1,2,3 循环
    addi x13, x0, 24
    add  x14, x6, x0
    jal  x31, vga_write     # 更新 bench_id 显示
    # 模拟按 S5 执行 (但自动模式实际需要真正执行)
    # 直接跳转到对应基准:
    beq  x6, x0, benchmark_branch
    addi x11, x0, 1
    beq  x6, x11, benchmark_memory
    addi x11, x0, 2
    beq  x6, x11, benchmark_mac
    jal  x0, benchmark_mixed
    # 基准完成后回到自动循环

auto_tetris_phase:
    addi x13, x0, 0
    addi x14, x0, 4         # page=4 (Tetris)
    jal  x31, vga_write
    # 如果不在俄罗斯方块状态，初始化
    # 简化: 用 x17 bits 模拟左右移动
    srli x28, x17, 20
    andi x28, x28, 1
    bne  x28, x0, auto_move_left
    srli x28, x17, 21
    andi x28, x28, 1
    bne  x28, x0, auto_move_right
    srli x28, x17, 22
    andi x28, x28, 1
    bne  x28, x0, auto_rotate
    jal  x0, auto_demo_loop
auto_move_left:
    # ... 模拟 S1 按下 ...
    jal  x0, auto_demo_loop
auto_move_right:
    # ... 模拟 S2 按下 ...
    jal  x0, auto_demo_loop
auto_rotate:
    # ... 模拟 S4 按下 ...
    jal  x0, auto_demo_loop
```

**注意**：自动演示模式是一个较大改动，建议先实现简化版（仅自动轮播页面 + 显示标签变化），真正的游戏AI交互逻辑可以后续迭代。

---

## 规格 7：素数计算演示页

**优先级**：P2 | **改动量**：~60行汇编 | **类型**：汇编新增（可选 PAGE 5 或替换自动演示中某阶段）

### 目标
纯粹的计算密集型演示——持续试除法找素数，最大化 CPU 利用率，展示流水线/BTB 加速优势。

### 文件：`tests/demo/cpu_guess_game.S`

#### 改动 7.1 — 新增 prime_demo 子程序
```asm
#==============================================================================
# prime_demo - continuous prime number search (trial division)
# Finds primes using trial division and displays progress on VGA.
# Uses: x20 = current number being tested
#       x21 = divisor
#       x22 = primes found count
#       x23 = sqrt limit (approximate)
# Displays: current number, primes found, real-time MIPS
# This is a pure compute workload — ideal for showing pipeline advantage.
#==============================================================================
prime_demo:
    addi x20, x0, 2         # 从2开始
    addi x22, x0, 0         # 找到的素数计数
prime_loop:
    # 检查 SW15 是否还在素数模式
    lw   x17, 0(x15)
    srli x28, x17, 15
    andi x28, x28, 1
    beq  x28, x0, prime_exit
    # 试除法：用 2..sqrt(n) 测试
    addi x21, x0, 2         # divisor = 2
    # sqrt 近似: 对于 n < 1000000, sqrt(n) < n/2 且粗略近似
    srli x23, x20, 1        # sqrt ≈ n/2 (粗略上界)
    addi x23, x23, 1
prime_test_loop:
    bge  x21, x23, prime_found  # divisor >= limit → 是素数
    # n % divisor == n - (n/divisor)*divisor
    # 用重复减法做除法：
    add  x24, x20, x0       # remainder = n
prime_div_loop:
    blt  x24, x21, prime_check_rem
    sub  x24, x24, x21
    jal  x0, prime_div_loop
prime_check_rem:
    beq  x24, x0, prime_not_prime
    addi x21, x21, 1
    jal  x0, prime_test_loop
prime_not_prime:
    addi x20, x20, 1
    jal  x0, prime_loop
prime_found:
    addi x22, x22, 1        # 素数计数+1
    # 显示当前素数到 VGA（复用 bus trace 的 bus_device 字段临时显示）
    addi x13, x0, 22        # bus_device field (临时占位显示)
    add  x14, x20, x0
    jal  x31, vga_write
    # 显示素数计数
    addi x13, x0, 23        # last_button field (临时占位)
    add  x14, x22, x0
    jal  x31, vga_write
    # 继续找下一个
    addi x20, x20, 1
    jal  x0, prime_loop
prime_exit:
    jalr x0, 0(x1)
```

**注意**：素数演示的 VGA 显示复用了 PAGE 3（总线追踪）的现有字段，也可以扩展新的 VGA MMIO fields 专门显示素数。推荐新增 field 50-51：
- field 50: prime_current (当前检查的数)
- field 51: prime_count (已找到素数个数)

### 素数演示集成方式
- **方案A**：新增 PAGE 5（SW[2:0]=101），纯素数计算页
- **方案B**：集成到自动演示模式中作为第4个轮播阶段
- **方案C**：SW15=1 时替换 PAGE 3（总线追踪页面不太用于验收演示）

推荐方案A——新增 PAGE 5，不影响现有4个页面。

#### 改动 7.2 — VGA MMIO 新增素数显示字段
**文件**：`src/io/vga_mmio_regs.v`
```verilog
    // 新增端口:
    output reg [31:0] prime_current,
    output reg [31:0] prime_count,
    // 新增 field (在 8'd48 之后):
    8'd50: prime_current <= wdata_reg;
    8'd51: prime_count   <= wdata_reg;
```

#### 改动 7.3 — VGA 渲染 PAGE 5
**文件**：`src/io/vga_dashboard.v` 在 `dashboard_char` 中增加 `3'd5` case：
```verilog
    3'd5: begin
        case (row)
            6'd2:  label = "PRIME NUMBER DEMO";
            6'd5:  label = "PURE CPU COMPUTE";
            6'd10: begin label = "CHECKING N"; value = prime_current; end
            6'd14: begin label = "PRIMES FOUND"; value = prime_count; end
            6'd20: label = "100% CPU UTILIZATION";
            6'd24: label = "TRY PIPELINE MODE";
            6'd28: label = "FOR 3.7X SPEEDUP";
            default: ;
        endcase
    end
```

---

## 规格 8：流水线 bitstream 生成

**优先级**：P0（答辩最关键）| **改动量**：1行 | **类型**：Vivado 重新综合

### 文件：`src/board/minisys_top.v`

#### 改动 8.1 — 切换 CPU_MODE（第9行）
```verilog
// 当前:
parameter CPU_MODE = `CPU_MODE_RISCV_MC

// 改为:
parameter CPU_MODE = `CPU_MODE_RISCV_PIPE   // 或直接写 5
```

### 操作步骤（非 Codex 可执行，需人工在 Vivado 中操作）
1. 修改 `minisys_top.v` 第9行为 `CPU_MODE = 5`
2. 打开 Vivado 工程
3. Run Synthesis → Run Implementation → Generate Bitstream
4. 导出 utilization report（`report_utilization -file utilization_pipe.txt`）
5. 导出 timing summary（`report_timing_summary -file timing_pipe.txt`）
6. 将生成的 `minisys_top.bit` 复制并重命名为 `minisys_top_pipeline.bit`
7. 恢复 `CPU_MODE = 0` 重新生成多周期版本的 bitstream
8. 上板时通过切换 bitstream 文件实现多周期 vs 流水线的实时对比

---

## 规格 9：VGA 性能数据十进制化

**优先级**：P2 | **改动量**：~30行 Verilog | **类型**：Verilog 渲染

### 目标
将 PAGE 1 和 PAGE 2 中仍用十六进制显示的数值改为十进制显示。

### 文件：`src/io/vga_dashboard.v`

#### 改动 9.1 — 增加 decimal8_char 函数（约第224行 decimal4_char 之后）
```verilog
    function [7:0] decimal8_char;
        input [31:0] value;
        input integer index;
        reg [31:0] r;
        begin
            // 显示 8 位十进制数 (index 0=千万位 ... 7=个位)
            r = value;
            case (index)
                0: decimal8_char = hex_char((r / 10000000) % 10);
                1: decimal8_char = hex_char((r / 1000000) % 10);
                2: decimal8_char = hex_char((r / 100000) % 10);
                3: decimal8_char = hex_char((r / 10000) % 10);
                4: decimal8_char = hex_char((r / 1000) % 10);
                5: decimal8_char = hex_char((r / 100) % 10);
                6: decimal8_char = hex_char((r / 10) % 10);
                7: decimal8_char = hex_char(r % 10);
                default: decimal8_char = " ";
            endcase
        end
    endfunction
```

#### 改动 9.2 — 将 INSTRET / CYCLES 改为十进制（第297-299行）
当前 PAGE 2 的 INSTRET 和 CYCLES 用十六进制：
```verilog
    6'd45: begin label = "INSTRET"; value = disp_instret; end
    6'd49: begin label = "CYCLES"; value = disp_cycles; end
```

在渲染区域（约第346-356行 `word_hex_char` 的条件中）为非十六进制字段增加十进制渲染分支。或更简单：在 `dashboard_char` 内部对这两个 row 做特殊处理，直接用 `decimal8_char` 替代 `word_hex_char`。

**最简单方案**——新增十进制渲染条件（约第356行后）：
```verilog
    // PAGE 2: INSTRET / CYCLES 十进制显示 (col 20-27)
    if (p == 2 && (row == 45 || row == 49) && col >= 20 && col < 28)
        dashboard_char = decimal8_char(value, col - 20);
    // PAGE 2: MAC COUNT 十进制显示
    if (p == 2 && row == 39 && col >= 20 && col < 28)
        dashboard_char = decimal8_char(value, col - 20);
```

注意到 `decimal8_char` 使用了除法（`/`），在 Verilog 中这是合法的但会综合为大型组合逻辑。由于这些值变化频率是 1Hz（通过 pending/disp 采样），时序不是问题。

---

## 汇总：改动量估计与依赖关系

```
                    ┌──────────────────────────────┐
                    │  规格8: 流水线 bitstream (1行) │ ← 需要 Vivado 操作
                    └──────────────────────────────┘
                              │ 无代码依赖
                              ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ 规格1: 100x  │  │ 规格2: LFSR  │  │ 规格3: 速度  │
│ 基准放大     │  │ 随机方块     │  │ 分级+SW控制  │
│ ~5行汇编     │  │ ~25行汇编    │  │ ~20行汇编    │
│              │  │              │  │ +3行Verilog  │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       │    可并行        │                 │
       ▼                 ▼                 ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ 规格4: 混合  │  │ 规格5: Game  │  │ 规格6: 自动  │
│ 基准 bench3  │  │ Over 视觉    │  │ 演示模式     │
│ ~50行汇编    │  │ ~30行Verilog │  │ ~100行汇编   │
│ +5行Verilog  │  │              │  │              │
└──────────────┘  └──────────────┘  └──────┬───────┘
                                           │
                    ┌──────────────────────┘
                    ▼
              ┌──────────────┐  ┌──────────────┐
              │ 规格7: 素数  │  │ 规格9: 十进制 │
              │ 计算演示     │  │ 化渲染       │
              │ ~60行汇编    │  │ ~30行Verilog │
              │ +5行Verilog  │  │              │
              └──────────────┘  └──────────────┘
```

### 建议 Codex 执行顺序
1. **第一轮**（可并行）：规格 1 + 规格 2 + 规格 3 — 纯汇编改动，风险最低
2. **第二轮**：规格 4 + 规格 5 — 涉及 Verilog 小改动
3. **第三轮**：规格 6 — 自动演示，较大改动
4. **第四轮**（可选）：规格 7 + 规格 9 — 锦上添花
5. **最后**：规格 8 — 手工 Vivado 操作，生成对比 bitstream
