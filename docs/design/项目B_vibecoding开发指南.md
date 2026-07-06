# 项目 B：基于 Minisys FPGA 的五级流水线 CPU 与 MAC 指令加速开发指南

> 用途：本文件供小组后续在 GitHub / Codex / AI 辅助开发中统一目标、接口、分工、验收标准和开发节奏。  
> 推荐题目包装：**面向矩阵计算加速的五级流水线 CPU 设计与性能优化**  
> 推荐主线：**基础 CPU → 完整系统 → 五级流水线 → 冒险处理 → MAC 自定义指令 → 性能量化评估**

---

## 0. 项目定位

本项目对应课程设计题目 B：**基于 FPGA 开发板的处理器设计**。

课程要求分为三层：

| 层次 | 课程要求 | 本组实现目标 |
|---|---|---|
| 基础层次 | 简单 CPU 设计与实现，支持基本指令集，完成综合、布局布线和硬件验证 | 实现一个 RV32I 子集 / MIPS 子集 / 自定义 ISA 的 CPU，支持算术、逻辑、访存、跳转等基本指令 |
| 进阶层次 | 集成内存与 I/O，构建完整可运行系统，引入流水线并评估 CPI、吞吐量、时钟频率 | 集成指令存储器、数据存储器、GPIO、数码管、性能计数器，形成简化 SoC |
| 拓展层次 | 至少选择一项性能优化或创新探索，如流水线冒险、Cache、乘除法、MAC、自定义 ISA、PPA 对比 | 主攻 **流水线冒险完整处理 + MAC 自定义指令加速 + PPA 对比分析** |

一句话目标：

> 在 Minisys FPGA 上实现一个可运行测试程序的五级流水线 CPU，并通过数据前推、暂停、分支冲刷和 MAC 自定义指令，对性能进行可量化优化。

---

## 1. 硬件平台与约束

### 1.1 已有实验板

本组现有硬件主线为：

```text
Minisys 主板 + EES-329B 扩展板
```

核心开发平台应以 **Minisys** 为准。不要把 TEC-PLUS、Nexys4DDR、EGO1 的资料和约束文件混用到本项目主线中。

### 1.2 Minisys 资源优势

Minisys 板卡适合本项目的原因：

| 板上资源 | 对本项目的价值 |
|---|---|
| Xilinx Artix-7 XC7A100T | 逻辑资源充足，适合实现 CPU、流水线和外设总线 |
| 100MHz 主时钟 | 适合做时钟频率、CPI、吞吐量分析 |
| Block RAM | 可实现指令存储器、数据存储器、寄存器/缓冲区 |
| DSP48E1 | 适合实现乘法、乘加 MAC、矩阵/点积加速 |
| 拨码开关 | 可作为模式选择、输入参数、测试控制 |
| LED | 可显示运行状态、done、error、stall、branch flush 等状态 |
| 8 位七段数码管 | 可显示结果、周期数、CPI 简化值、加速比 |
| USB-UART | 可选，用于输出调试信息和性能统计 |
| VGA / 键盘 / EES-329B 外设 | 可作为展示点缀，不建议作为处理器优化主线 |

### 1.3 不建议主攻的板上资源

以下资源可以作为演示点缀，但不建议作为本项目核心目标：

```text
WiFi
蓝牙
直流电机
步进电机
触摸屏
完整 DDR3 控制器
复杂 VGA 图形系统
```

原因：这些外设与“处理器性能优化”的主线关联不强，容易耗费大量联调时间，且答辩时不如流水线、CPI、MAC、PPA 说服力强。

---

## 2. 最终推荐实现组合

本项目建议采用如下组合：

```text
五级流水线 CPU
+ 数据前推 Forwarding
+ load-use 冒险暂停 Stall
+ 分支冲刷 Flush
+ 性能计数器
+ MAC 自定义指令
+ 点积 / 矩阵计算性能对比
```

### 2.1 推荐程度

| 拓展方向 | 是否推荐 | 本项目处理方式 |
|---|---|---|
| 流水线冒险完整解决 | 强烈推荐 | 必做：Forwarding + Stall + Flush |
| MAC 自定义指令 | 强烈推荐 | 必做：面向点积/矩阵计算加速 |
| MUL 乘法扩展 | 推荐 | 可作为 MAC 的基础模块 |
| 静态分支预测 | 可选 | 时间允许时加入，默认 not taken 或后向跳转预测 taken |
| 简化 Cache | 可选 | 只做 BRAM 主存上的直接映射 Cache，不碰复杂 DDR3 |
| 除法扩展 | 不推荐主攻 | 展示效果不如 MAC |
| 浮点运算 | 不推荐 | 难度高、调试重、容易变成调用 IP |
| 完整 DDR3 Cache | 不推荐 | 调试复杂，容易拖垮进度 |

---

## 3. 系统总体架构

### 3.1 总体框图

```text
                 +-------------------------+
                 |       Test Program      |
                 |  dot product / matrix   |
                 +-----------+-------------+
                             |
                             v
+--------------------------------------------------------------+
|                         CPU Core                             |
|                                                              |
|  +------+   +------+   +------+   +------+   +------+        |
|  |  IF  |-->|  ID  |-->|  EX  |-->| MEM  |-->|  WB  |        |
|  +------+   +------+   +------+   +------+   +------+        |
|      |          |          |          |          |            |
|      |          |          |          |          |            |
|      |     Hazard Unit  Forwarding Unit  Branch Flush         |
|      |                    MAC Unit                            |
+------+-------------------------------------------------------+
       |
       v
+--------------------------------------------------------------+
|                       Memory / I/O Bus                       |
+-------------------+-------------------+----------------------+
                    |                   |
                    v                   v
        +---------------------+   +-----------------------------+
        | Instruction / Data  |   | Memory-mapped I/O           |
        | BRAM Memory         |   | LED / Switch / 7seg / UART  |
        +---------------------+   +-----------------------------+
```

### 3.2 五级流水线

| 阶段 | 名称 | 功能 |
|---|---|---|
| IF | Instruction Fetch | 根据 PC 读取指令，计算 PC+4 |
| ID | Instruction Decode | 指令译码，读寄存器，生成控制信号 |
| EX | Execute | ALU 运算、分支判断、地址计算、MAC 运算 |
| MEM | Memory Access | 数据存储器读写、I/O 访问 |
| WB | Write Back | 将 ALU/MEM/MAC 结果写回寄存器堆 |

---

## 4. 指令集设计建议

### 4.1 指令集选择

建议优先选：

```text
RV32I 子集 + 自定义 MAC 指令
```

如果 RISC-V 编码压力较大，也可以选：

```text
MIPS 子集 + 自定义 MAC 指令
```

课程允许参考 RISC-V、MIPS 或自定义 ISA。为了答辩更容易体现先进性，建议报告中使用“RISC-V 子集”进行包装。

### 4.2 基础指令集 MVP

第一阶段只实现这些指令即可：

| 类型 | 指令 | 作用 |
|---|---|---|
| 算术 | ADD | 寄存器加法 |
| 算术 | SUB | 寄存器减法 |
| 算术 | ADDI | 立即数加法 |
| 逻辑 | AND | 按位与 |
| 逻辑 | OR | 按位或 |
| 逻辑 | XOR | 按位异或 |
| 访存 | LW | 从数据存储器读 word |
| 访存 | SW | 向数据存储器写 word |
| 分支 | BEQ | 相等跳转 |
| 分支 | BNE | 不相等跳转 |
| 跳转 | JAL | 无条件跳转并保存返回地址，可选 |
| 系统 | HALT / EBREAK | 程序停止，用于仿真和硬件演示 |

### 4.3 拓展指令

推荐添加：

```text
MUL rd, rs1, rs2
功能：rd = rs1 * rs2
```

```text
MAC rd, rs1, rs2
功能：rd = rd + rs1 * rs2
```

其中 MAC 是核心创新点。

### 4.4 MAC 指令设计说明

MAC 指令可解释为：

```text
rd_new = rd_old + rs1 * rs2
```

适用场景：

```c
sum = sum + a[i] * b[i];
```

它可以把原本多条指令完成的乘法和加法合并为一条自定义指令，适合点积、矩阵乘法、卷积等 AI/矩阵计算场景。

---

## 5. 存储系统与 I/O 映射

### 5.1 建议先用 BRAM，不要先碰 DDR3

MVP 阶段使用：

```text
Instruction Memory：BRAM ROM
Data Memory：BRAM RAM
```

优点：

```text
实现简单
仿真稳定
综合方便
适合性能计数和测试程序
不会被 DDR3 控制器拖慢进度
```

### 5.2 地址映射建议

```text
0x0000_0000 - 0x0000_0FFF：Instruction Memory / Program ROM
0x0000_1000 - 0x0000_1FFF：Data Memory
0x1000_0000：LED 输出寄存器
0x1000_0004：拨码开关输入寄存器
0x1000_0008：七段数码管输出寄存器
0x1000_000C：cycle_count
0x1000_0010：instret_count
0x1000_0014：stall_count
0x1000_0018：flush_count
0x1000_001C：branch_count
0x1000_0020：branch_miss_count
0x1000_0024：mac_count
0x1000_0028：result_reg
```

### 5.3 I/O 展示建议

| 输出设备 | 显示内容 |
|---|---|
| LED0 | CPU running |
| LED1 | program done |
| LED2 | error flag |
| LED3 | MAC mode enabled |
| LED4 | stall happened |
| LED5 | branch flush happened |
| LED6 | memory access |
| LED7 | heartbeat |
| 七段数码管 | result / cycle_count / CPI 简化值 / speedup |
| 拨码开关 | 选择显示内容或运行模式 |

---

## 6. 核心模块划分

建议按 4 人小组分工。

### 6.1 模块清单

```text
src/
├── core/
│   ├── cpu_top.v
│   ├── pipeline_if.v
│   ├── pipeline_id.v
│   ├── pipeline_ex.v
│   ├── pipeline_mem.v
│   ├── pipeline_wb.v
│   ├── regfile.v
│   ├── alu.v
│   ├── control_unit.v
│   ├── imm_gen.v
│   ├── branch_unit.v
│   ├── hazard_unit.v
│   ├── forwarding_unit.v
│   ├── mac_unit.v
│   └── csr_perf_counter.v
│
├── memory/
│   ├── instr_mem.v
│   ├── data_mem.v
│   └── mem_bus.v
│
├── io/
│   ├── gpio_led.v
│   ├── gpio_switch.v
│   ├── seg7_driver.v
│   └── uart_debug.v      # 可选
│
├── soc/
│   └── soc_top.v
│
└── board/
    └── minisys_top.v
```

### 6.2 分工建议

| 成员 | 主要职责 | 交付物 |
|---|---|---|
| 成员 A | CPU 数据通路、寄存器堆、ALU、指令译码 | `regfile.v`, `alu.v`, `control_unit.v`, `imm_gen.v` |
| 成员 B | 流水线寄存器、冒险处理、前递、分支冲刷 | `pipeline_*.v`, `hazard_unit.v`, `forwarding_unit.v`, `branch_unit.v` |
| 成员 C | 存储系统、I/O、性能计数器、SoC 集成 | `instr_mem.v`, `data_mem.v`, `mem_bus.v`, `csr_perf_counter.v`, `soc_top.v` |
| 成员 D | MAC 指令、测试程序、仿真、上板演示、报告图表 | `mac_unit.v`, tests, tb, performance table, report figures |

---

## 7. 开发阶段规划

### 阶段 1：单周期 / 多周期 CPU 跑通

目标：先得到一个正确的 CPU。

完成标准：

```text
能运行 add/sub/addi/and/or/xor/lw/sw/beq/bne 测试程序
寄存器写回正确
数据存储器读写正确
仿真可自动判断 pass/fail
```

建议测试：

```asm
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2
sw   x3, 0(x0)
lw   x4, 0(x0)
beq  x3, x4, pass
halt
pass:
addi x5, x0, 1
halt
```

### 阶段 2：SoC 集成

目标：CPU 不只是仿真跑，而是能通过 I/O 和板子交互。

完成标准：

```text
程序运行结果能显示到 LED 或七段数码管
拨码开关能控制显示模式
cycle_count 能读出或显示
Vivado 综合通过
可以生成 bitstream
```

### 阶段 3：五级流水线

目标：把 CPU 改造成五级流水线。

完成标准：

```text
IF/ID, ID/EX, EX/MEM, MEM/WB 流水寄存器完整
无冒险程序能正确运行
有冒险程序在插入 nop 后能正确运行
能统计 retired instruction
```

### 阶段 4：冒险处理

目标：不用依赖软件手动插入大量 nop。

完成标准：

```text
EX/MEM -> EX 前递正确
MEM/WB -> EX 前递正确
load-use 冒险能暂停一个周期
分支跳转能冲刷错误路径指令
连续相关测试程序正确运行
stall_count、flush_count 可统计
```

测试程序：

```asm
addi x1, x0, 1
addi x2, x0, 2
add  x3, x1, x2
add  x4, x3, x2
add  x5, x4, x3
halt
```

load-use 测试：

```asm
addi x1, x0, 0
lw   x2, 0(x1)
add  x3, x2, x2
halt
```

分支冲刷测试：

```asm
addi x1, x0, 1
addi x2, x0, 1
beq  x1, x2, target
addi x3, x0, 99
addi x4, x0, 99
target:
addi x5, x0, 7
halt
```

### 阶段 5：MAC 自定义指令

目标：实现面向点积/矩阵计算的加速指令。

完成标准：

```text
MAC 指令译码正确
MAC 单元接入 EX 阶段
MAC 结果可写回 rd
MAC 与流水线前递、暂停机制兼容
点积程序结果正确
mac_count 可统计
```

点积测试：

```c
sum = a0*b0 + a1*b1 + a2*b2 + a3*b3;
```

普通版本：

```asm
mul t0, a0, b0
add sum, sum, t0
mul t1, a1, b1
add sum, sum, t1
mul t2, a2, b2
add sum, sum, t2
mul t3, a3, b3
add sum, sum, t3
```

MAC 版本：

```asm
mac sum, a0, b0
mac sum, a1, b1
mac sum, a2, b2
mac sum, a3, b3
```

如果基础 CPU 没有 MUL，可以用“软件移位加法乘法”作为普通版本，这样 MAC 加速效果更明显。

### 阶段 6：性能评估与 PPA 分析

目标：把项目从“能跑”提升为“能证明优化有效”。

必须统计：

```text
cycle_count
instret_count
CPI = cycle_count / instret_count
stall_count
flush_count
branch_count
mac_count
LUT / FF / BRAM / DSP 使用量
Fmax 或 timing slack
```

报告中建议放表：

| 版本 | 指令数 | 周期数 | CPI | Fmax | LUT | FF | BRAM | DSP | 说明 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 单周期 CPU | | | | | | | | | 基础版本 |
| 五级流水线，无前递 | | | | | | | | | 需要 nop |
| 五级流水线，带冒险处理 | | | | | | | | | 正确处理相关 |
| 五级流水线 + MAC | | | | | | | | | 面向点积加速 |

建议计算：

```text
加速比 = 普通版本周期数 / MAC 版本周期数
吞吐量 ≈ Fmax / CPI
```

---

## 8. GitHub 仓库结构建议

```text
project-b-pipelined-cpu/
├── README.md
├── docs/
│   ├── course/
│   │   └── 2026项目式课程阶段二-修订完成版.pdf
│   ├── hardware/
│   │   ├── Minisys硬件手册1.1.pdf
│   │   └── EES329b功能测试20170817.pdf
│   ├── design/
│   │   ├── architecture.md
│   │   ├── isa.md
│   │   ├── memory_map.md
│   │   ├── pipeline_hazard.md
│   │   ├── mac_extension.md
│   │   └── performance.md
│   └── ai_logs/
│       └── ai_usage_log.md
│
├── src/
│   ├── core/
│   ├── memory/
│   ├── io/
│   ├── soc/
│   └── board/
│
├── sim/
│   ├── tb/
│   ├── programs/
│   └── wave/
│
├── constraints/
│   └── minisys.xdc
│
├── scripts/
│   ├── build.tcl
│   ├── run_sim.tcl
│   ├── gen_mem.py
│   └── collect_perf.py
│
├── tests/
│   ├── basic/
│   ├── hazard/
│   ├── branch/
│   ├── load_store/
│   └── mac/
│
├── reports/
│   ├── figures/
│   ├── tables/
│   └── final_report/
│
└── archive/
    └── unrelated_boards/
```

---

## 9. Codex / AI 辅助开发规范

### 9.1 总原则

```text
AI 可以辅助生成代码，但必须人工审阅、仿真验证、记录使用过程。
每次 AI 修改模块接口，必须同步更新对应文档和 testbench。
禁止直接复制大段开源 CPU 项目作为最终提交。
禁止没有解释的黑盒代码。
```

### 9.2 每次使用 Codex 的建议流程

```text
1. 先写清楚模块功能和接口
2. 让 Codex 只生成单个模块，不要一次生成整个 CPU
3. 人工审阅代码，包括时序逻辑、复位、阻塞/非阻塞赋值、位宽
4. 编写或补全 testbench
5. 运行仿真
6. 记录 AI 使用日志
7. 再合并到主分支
```

### 9.3 AI 使用日志模板

```markdown
## AI 使用记录

- 日期：YYYY-MM-DD
- 成员：XXX
- 工具：Codex / ChatGPT / 其他
- 使用环节：例如 forwarding_unit.v 初稿生成
- 输入提示词摘要：
  > 请根据已有流水线寄存器接口，生成 forwarding_unit 模块……
- AI 输出内容摘要：
  - 生成了 forwarding_unit.v
  - 生成了基础 testbench
- 人工审阅与修改：
  - 修正了 MEM/WB 优先级
  - 修正了 x0 寄存器不应前递的问题
  - 补充了 load-use 情况测试
- 验证结果：
  - 仿真通过 / 未通过
  - 波形文件：xxx.vcd
- 是否合并：是 / 否
```

---

## 10. 推荐给 Codex 的模块级提示词

### 10.1 生成 ALU

```text
请为一个 32 位简化 RISC-V CPU 生成 Verilog ALU 模块。
要求：
1. 输入 a、b、alu_op。
2. 输出 result、zero。
3. 支持 ADD、SUB、AND、OR、XOR、SLT、SLL、SRL。
4. 使用组合逻辑 always @(*)。
5. 不要生成 testbench。
6. 代码风格清晰，所有 case 给 default。
```

### 10.2 生成寄存器堆

```text
请生成一个 32x32 位 RISC-V 风格寄存器堆 Verilog 模块。
要求：
1. 两个异步读端口 rs1、rs2。
2. 一个同步写端口 rd。
3. x0 恒为 0，不能被写入。
4. posedge clk 写入，reset 时清零所有寄存器。
5. 模块接口为 clk, rst, we, rs1_addr, rs2_addr, rd_addr, rd_data, rs1_data, rs2_data。
```

### 10.3 生成 Forwarding Unit

```text
请生成一个五级流水线 CPU 的 forwarding_unit Verilog 模块。
流水线阶段为 IF/ID/EX/MEM/WB。
要求：
1. 输入 ID_EX_rs1、ID_EX_rs2。
2. 输入 EX_MEM_rd、EX_MEM_regwrite。
3. 输入 MEM_WB_rd、MEM_WB_regwrite。
4. 输出 forward_a、forward_b。
5. 编码：00 表示来自寄存器堆，10 表示来自 EX/MEM，01 表示来自 MEM/WB。
6. x0 不参与前递。
7. EX/MEM 优先级高于 MEM/WB。
8. 只生成模块，不生成完整 CPU。
```

### 10.4 生成 Hazard Detection Unit

```text
请生成一个五级流水线 CPU 的 hazard_detection_unit 模块。
要求检测 load-use 冒险：
当 ID_EX_memread 为 1，并且 ID_EX_rd 等于 IF_ID_rs1 或 IF_ID_rs2，且 rd 不为 0 时，需要暂停流水线。
输出：pc_write、if_id_write、id_ex_flush。
无冒险时 pc_write=1, if_id_write=1, id_ex_flush=0。
有冒险时 pc_write=0, if_id_write=0, id_ex_flush=1。
```

### 10.5 生成 MAC Unit

```text
请生成一个 32 位 CPU 使用的 MAC 单元 Verilog 模块。
功能：rd_new = acc_in + rs1 * rs2。
要求：
1. 输入 rs1_data、rs2_data、acc_in。
2. 输出 mac_result。
3. 先实现为组合逻辑版本。
4. 乘法结果取低 32 位。
5. 后续需要能接入 EX 阶段。
6. 不要使用厂商专用原语，先让综合器自动推断 DSP。
```

### 10.6 生成性能计数器

```text
请生成一个 CPU 性能计数器模块 csr_perf_counter。
输入 clk、rst、instret_pulse、stall_pulse、flush_pulse、branch_pulse、branch_miss_pulse、mac_pulse。
输出 cycle_count、instret_count、stall_count、flush_count、branch_count、branch_miss_count、mac_count。
要求：
1. cycle_count 每个时钟周期加 1。
2. 其他计数器在对应 pulse 为 1 时加 1。
3. reset 时所有计数器清零。
4. 计数器宽度为 32 位。
```

---

## 11. 验收演示设计

### 11.1 演示模式

用拨码开关选择模式：

```text
SW0 = 0：普通软件点积程序
SW0 = 1：MAC 加速点积程序

SW2:SW1 = 00：七段数码管显示计算结果
SW2:SW1 = 01：显示 cycle_count 低位
SW2:SW1 = 10：显示 stall_count / flush_count
SW2:SW1 = 11：显示 speedup 简化值
```

### 11.2 演示流程

```text
1. 上电复位
2. 选择普通模式
3. 运行普通点积程序
4. 数码管显示结果和周期数
5. 复位
6. 选择 MAC 模式
7. 运行 MAC 加速程序
8. 数码管显示相同结果和更少周期数
9. 说明加速比、资源占用、CPI 差异
```

### 11.3 必备答辩材料

```text
系统总体框图
五级流水线图
数据前推路径图
load-use stall 时序图
branch flush 时序图
MAC 数据通路图
Memory map 表
指令集表
仿真波形截图
上板运行照片/视频
Vivado resource utilization 截图
Timing summary 截图
性能对比表
AI 使用日志
小组分工贡献表
```

---

## 12. Definition of Done

### 12.1 基础层次完成标准

```text
CPU 支持基础指令集
能运行简单测试程序
功能仿真通过
寄存器和内存结果正确
```

### 12.2 进阶层次完成标准

```text
CPU 集成指令存储器和数据存储器
实现 memory-mapped I/O
能在 Minisys 上显示运行结果
引入五级流水线
能统计 cycle_count 和 instret_count
能进行 CPI 分析
```

### 12.3 拓展层次完成标准

```text
实现 forwarding_unit
实现 load-use stall
实现 branch flush
实现 MAC 自定义指令
点积 / 矩阵计算程序运行正确
普通版本和 MAC 版本结果一致
MAC 版本周期数更少
完成 LUT/FF/BRAM/DSP/Fmax/PPA 对比
```

---

## 13. 风险与应对

| 风险 | 表现 | 应对 |
|---|---|---|
| 指令集太大 | 译码和控制复杂，调试慢 | 只做 RV32I/MIPS 子集，不追求完整 ISA |
| 直接做 DDR3 | MIG/IP/时序复杂 | MVP 使用 BRAM，DDR3 只作为报告中的可扩展方向 |
| 流水线一次性改太多 | 很难定位 bug | 先无冒险程序，再前递，再 stall，再 flush |
| MAC 指令影响时序 | Fmax 降低 | 先组合 MAC，必要时改多周期或 EX 阶段流水 |
| AI 生成代码接口混乱 | 模块难集成 | 每个模块先写接口文档，再让 AI 写代码 |
| 缺少量化数据 | 答辩说服力弱 | 早期就加入性能计数器 |
| 外设调试占用时间 | 主线延期 | 外设只做 LED/数码管/拨码开关，UART 可选 |

---

## 14. 报告写作主线

最终报告建议按这个逻辑写：

```text
1. 项目背景与设计目标
2. 硬件平台与开发环境
3. 指令集设计
4. CPU 总体结构
5. 五级流水线设计
6. 冒险检测与解决机制
7. 存储系统与 I/O 映射
8. MAC 自定义指令设计
9. 仿真与硬件验证
10. 性能测试与 PPA 分析
11. 调试问题与解决方案
12. 小组分工与 AI 使用说明
13. 总结与展望
```

### 14.1 最重要的报告亮点

报告里要反复体现：

```text
不是只做了一个能跑的 CPU，而是完成了从功能实现到性能优化的工程闭环。
```

具体包括：

```text
功能正确性：测试程序结果正确
系统完整性：CPU + Memory + I/O + Counter
工程复杂度：五级流水线 + 冒险处理
创新性：MAC 自定义指令
量化分析：CPI / 周期数 / 吞吐量 / 资源占用 / PPA
```

---

## 15. 建议最终对外表述

答辩时可以这样总结：

> 本项目基于 Minisys FPGA 平台，设计并实现了一个支持基础指令集的五级流水线 CPU。系统集成了指令存储器、数据存储器、memory-mapped I/O 和性能计数器，能够在硬件平台上运行点积测试程序。针对流水线中的数据冒险和控制冒险，我们实现了数据前推、load-use 暂停和分支冲刷机制，并通过 cycle counter、stall counter 和 retired instruction counter 对 CPI 和吞吐量进行量化分析。在此基础上，我们面向矩阵计算场景扩展了 MAC 自定义指令，利用 FPGA 的 DSP 资源完成乘加加速，对比普通软件实现与硬件 MAC 实现的周期数、CPI、资源占用和加速比，并给出 PPA 权衡说明。

---

## 16. 当前推荐下一步

立刻开始时，不要直接让 Codex 写完整 CPU。建议按下面顺序推进：

```text
1. 建立 GitHub 仓库结构
2. 写 README.md、isa.md、memory_map.md、architecture.md
3. 确定指令子集和编码
4. 写 ALU、regfile、control_unit
5. 写单周期 CPU 或多周期 CPU
6. 写基础 testbench
7. 跑通基础测试程序
8. 再改成五级流水线
9. 再加 forwarding / stall / flush
10. 最后加 MAC 和性能对比
```

最先创建的文档：

```text
docs/design/isa.md
docs/design/memory_map.md
docs/design/architecture.md
docs/ai_logs/ai_usage_log.md
```

最先创建的代码：

```text
src/core/alu.v
src/core/regfile.v
src/core/control_unit.v
src/memory/instr_mem.v
src/memory/data_mem.v
sim/tb/tb_cpu_basic.v
```

---

## 17. 结论

本组最优路线是：

```text
基础 CPU
→ 完整 SoC
→ 五级流水线
→ 冒险处理
→ MAC 自定义指令
→ 点积/矩阵计算性能对比
→ PPA 分析
```

这条路线同时满足：

```text
课程要求明确
工程难度足够
实现复杂度可控
适合 Minisys 硬件资源
答辩容易讲清楚
报告数据容易量化
```

不要把项目做散。主线始终围绕：

```text
处理器设计 + 流水线优化 + MAC 加速 + 性能量化
```
