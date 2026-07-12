# 队友 C 汇报 PPT / 网页界面生成材料包

> 用途：给队友 C 及其 AI agent 直接生成课程汇报 PPT、答辩网页或可视化展示界面。
> 日期：2026-07-12
> 适用场景：课程设计任务 B《基于 FPGA 开发板的处理器设计》汇报、答辩、演示网页、数据看板。
> 核心目标：围绕“CPU 完整性 + 完整 SoC 系统 + 性能优化与效率提升 + 上板演示证据”组织材料。

---

## 1. 汇报定位

### 1.1 一句话项目介绍

本项目在 Minisys FPGA 开发板上实现了一套基于 RISC-V RV32I 子集的处理器系统：以 6 状态多周期 FSM CPU 作为稳定基线，集成统一总线、BRAM 存储、LED/Switch/SEG7 外设、MAC 自定义乘加指令、性能计数器，并进一步实现五级流水线、forwarding/stall/flush 冒险处理、BTB 动态分支预测和 VGA + 普通按键小游戏骨架演示。

### 1.2 建议主标题

- 基于 FPGA 开发板的 RISC-V 处理器系统设计与优化
- RV32I 多周期 CPU、MAC 自定义指令与流水线优化实现
- 从完整 CPU 到高性能优化：Minisys 平台处理器系统设计

### 1.3 汇报主线

按照课程任务图片中的三层要求组织：

1. 基础层次：完成支持基本指令集的 CPU，能综合、实现、生成 bitstream 并运行测试程序。
2. 进阶层次：集成内存与 I/O，构建完整可运行 SoC，量化 CPI、吞吐量和系统瓶颈。
3. 拓展层次：实现性能优化与创新探索，包括 MAC 自定义指令、流水线冒险处理、BTB 分支预测和 PPA 对比框架。

建议 C 的 PPT 不要只讲“做了哪些文件”，而要讲清楚下面这条逻辑：

```text
课程要求
  -> 我们选择 RV32I + 多周期 CPU 作为可靠基线
  -> 接入统一总线、BRAM、MMIO 外设，形成完整计算机系统
  -> 通过 MAC 自定义指令和性能计数器量化加速效果
  -> 通过五级流水线 + 冒险处理 + BTB 进一步提升吞吐量
  -> 用仿真、Vivado 和上板演示证明完整性
```

---

## 2. PPT 推荐结构

建议做 12-15 页。下面每页都给出“标题、核心内容、可视化建议、讲解要点”，AI agent 可以按这个结构直接生成。

### 第 1 页：标题页

标题：基于 FPGA 开发板的 RISC-V 处理器系统设计与优化

内容：

- 课程题目：题目 B，基于 FPGA 开发板的处理器设计
- 平台：Minisys FPGA，Xilinx Artix-7 XC7A100T
- 指令集：RV32I 子集 + MAC 自定义指令
- 设计关键词：多周期 FSM、统一总线、MAC、性能计数器、五级流水线、BTB、VGA 演示
- 小组成员：A/B/C/D，可按实际姓名补全

可视化建议：

- 左侧放项目关键词卡片，右侧放 Minisys / FPGA / RISC-V / pipeline 的抽象结构图。
- 风格建议：蓝白色为主，少量橙色或红色强调性能提升数据。

### 第 2 页：课程任务与我们的完成路线

核心表格：

| 课程层次 | 任务要求 | 我们的实现 | 状态 |
|---|---|---|---|
| 基础层次 | 简单 CPU、基本指令、综合实现、硬件验证 | RV32I 多周期 FSM CPU，31 条基础指令 + MAC，Vivado 通过 | 完成 |
| 进阶层次 | 内存与 I/O 集成，完整系统，性能量化 | 统一总线 SoC，32KB 指令/数据 BRAM，LED/Switch/SEG7，性能计数器 | 完成 |
| 拓展层次 | 流水线、分支预测、自定义 ISA、PPA 分析 | 五级流水线、forwarding/stall/flush、BTB、MAC 点积加速、PPA 框架 | 完成主体，PPA 实测待补 |

讲解要点：

- 我们不是只写了 CPU 核心，而是从 CPU、存储器、总线、外设、性能统计到上板演示构成完整系统。
- 流水线和 BTB 的 PPA 数字目前是估计/模型数据，正式 utilization/timing 仍待完整 SoC 重综合。

### 第 3 页：系统总体架构

建议图示：

```text
Minisys Board
  clk/rst/sw/led/seg/an/vga/btn
       |
       v
minisys_top
       |
       v
soc_top
  |-- cpu_top (CPU_MODE=0/5)
  |     |-- RV32I multi-cycle CPU
  |     |-- RV32I pipeline CPU
  |
  |-- inst_ram 32KB
  |-- data_ram 32KB
  |-- bus_decoder + bus_mux
  |-- MMIO peripherals
        |-- LED
        |-- Switch
        |-- SEG7
        |-- performance counters
```

讲解要点：

- `cpu_top` 用 `CPU_MODE` 参数切换不同 CPU 实现，方便 PPA 对比。
- 指令总线 `ibus` 和数据总线 `dbus` 分离，避免取指和访存结构冲突。
- 外设通过统一 MMIO 地址空间连接，便于扩展。

### 第 4 页：CPU 完整性证明

核心表格：

| 模块 | 功能 | 证据 |
|---|---|---|
| `control_unit.v` | RV32I 31 条指令 + MAC 译码 | 32 条指令译码验证通过 |
| `riscv_mc_cpu.v` | 6 状态多周期 CPU | basic / load-store / branch 测试通过 |
| `regfile.v` | 32 x 32 寄存器堆，3 读 1 写 | 支持 MAC 读取 `rd_old` |
| `alu.v` | 算术、逻辑、移位、比较等运算 | ALU 单元测试通过 |
| `branch_unit.v` | BEQ/BNE/BLT/BGE/BLTU/BGEU | BEQ/BNE 扩展测试通过 |
| `inst_ram.v` / `data_ram.v` | 指令/数据存储 | LW/SW 测试通过 |
| `csr_perf_counter.v` | cycle/instret/mac 计数 | perf/MMIO 测试通过 |

建议醒目数字：

| 指标 | 数值 |
|---|---:|
| 支持指令 | 31 条 RV32I + 1 条 MAC |
| CPU 状态 | 6 状态 FSM |
| 核心 RTL 规模 | 25 个 RTL 文件，约 2100 行 Verilog |
| 目标频率 | 100 MHz |
| Vivado 时序 | WNS=+7.212ns, TNS=0 |
| DRC | 0 violations |

### 第 5 页：多周期 FSM 数据通路

建议图示：

```text
FETCH -> DECODE -> EXECUTE -> MEMORY -> WRITEBACK -> FETCH
                         \                         /
                          -------- EBREAK -> HALT -
```

各类指令周期数：

| 指令类型 | 周期数 | 路径 |
|---|---:|---|
| ALU R/I | 4 | F -> D -> E -> WB |
| LW | 5 | F -> D -> E -> M -> WB |
| SW | 4 | F -> D -> E -> M |
| BEQ/BNE | 3 | F -> D -> E |
| JAL/JALR | 3 | F -> D -> E |
| MAC | 4 | F -> D -> E -> WB |
| EBREAK | 2 | F -> D -> HALT |

讲解要点：

- 多周期 FSM 是可靠基线，逻辑清晰、便于验证。
- 程序主体 CPI 接近 4.0，后续流水线优化以它为对比基准。

### 第 6 页：完整 SoC 与内存/I/O 集成

核心表格：

| 地址区域 | 模块 | 作用 |
|---|---|---|
| `0x0000_0000 - 0x0000_7FFF` | `inst_ram` | 32KB 指令存储 |
| `0x1000_0000 - 0x1000_7FFF` | `data_ram` | 32KB 数据存储 |
| `0xFFFF_FC00` | LED | 16 位 LED 输出 |
| `0xFFFF_FC10` | Switch | 16 位拨码输入 |
| `0xFFFF_FC20` | SEG7 | 8 位数码管动态扫描 |
| `0xFFFF_FCB0` | cycle_count | 周期计数 |
| `0xFFFF_FCB4` | instret_count | 退休指令数 |
| `0xFFFF_FCB8` | mac_count | MAC 指令数 |
| `0xFFFF_FCC0/C4/C8` | BTB 统计 | 分支总数、误预测数、BTB 命中数 |

讲解要点：

- 进阶层次要求“内存与 I/O 接口”，我们已经用统一总线和 MMIO 完成。
- 性能计数器也通过 MMIO 暴露，CPU 软件可以读自己的执行数据。

### 第 7 页：功能验证矩阵

核心表格：

| 验证项 | 工具/平台 | 结果 | 关键输出 |
|---|---|---|---|
| ALU 单元测试 | Vivado xsim | PASS | 7 类运算覆盖 |
| regfile 单元测试 | Vivado xsim | PASS | x0=0、3R1W、前推 |
| control_unit 译码 | Vivado xsim | PASS | 32 条指令译码 |
| CPU basic | Vivado xsim | PASS | `debug_pc=0x20` |
| LW/SW | Vivado xsim | PASS | `mem0=42 mem1=99 x5=141` |
| BEQ/BNE | Vivado xsim | PASS | `x10=12 debug_pc=0x30` |
| MAC/perf/MMIO | Icarus + Verilator | PASS | 点积和计数器正确 |
| Vivado Synthesis/Implementation | Vivado 2018.3 | PASS | WNS=+7.212ns, DRC=0 |
| VGA + `S1~S5` | Minisys 实物板 | PASS | 可交互小游戏骨架 |

建议做法：

- PPT 上可以把这一页做成“绿灯矩阵”。
- 每行右侧用 “PASS” 徽标，提高直观性。

### 第 8 页：MAC 自定义指令创新

MAC 指令编码：

```text
opcode = 0001011  (RISC-V custom-0)
funct7 = 0000001
funct3 = 000
语义：rd_new = rd_old + rs1 * rs2
```

硬件改动：

| 模块 | 改动 |
|---|---|
| `mac_unit.v` | 有符号乘法 + 累加 |
| `regfile.v` | 从 2 读 1 写扩展为 3 读 1 写 |
| `control_unit.v` | 增加 MAC 严格译码 |
| `riscv_mc_cpu.v` | EXECUTE 锁存 MAC 结果，WRITEBACK 写回 |
| `csr_perf_counter.v` | 增加 `mac_count` |

讲解要点：

- MAC 是面向 AI / 矩阵计算的核心乘加操作。
- 参考仓库中没有现成 MAC，这是本项目独立创新点。
- 3 读口寄存器堆是为了支持 `rd_old` 作为累加初始值。

### 第 9 页：MAC 点积加速数据

核心表格：

| 版本 | result | cycle | instret | CPI | mac_count | 加速比 |
|---|---:|---:|---:|---:|---:|---:|
| 普通 RV32I 点积 | 70 | 62 | 15 | 4.1333 | 0 | 1.0000 |
| MAC 加速点积 | 70 | 54 | 13 | 4.1538 | 4 | 1.1481 |

关键结论：

```text
speedup = 62 / 54 = 1.1481
cycle reduction = (62 - 54) / 62 = 12.90%
instruction reduction = (15 - 13) / 15 = 13.33%
```

可视化建议：

- 用双柱状图展示 cycle：62 -> 54。
- 用双柱状图展示 instret：15 -> 13。
- 标注“结果一致 result=70”，说明优化没有破坏正确性。

讲解要点：

- 当前点积长度只有 4，固定开销会稀释加速比。
- 加速来自指令数减少，而不是单条指令周期变短。
- 在神经网络、矩阵乘、卷积等乘加密集场景，MAC 占比越高，加速空间越大。

### 第 10 页：五级流水线优化

流水线结构：

```text
IF -> ID -> EX -> MEM -> WB
```

冒险处理机制：

| 冒险类型 | 处理方式 | 惩罚 |
|---|---|---:|
| RAW 数据冒险 | EX/MEM、MEM/WB 转发 | 0 周期 |
| Load-Use | 1 周期 stall + MEM/WB 转发 | 1 周期 |
| Branch taken | EX 阶段 flush | 1 周期 |
| JAL/JALR | flush 控制 | 1 周期 |
| 结构冒险 | ibus/dbus 分离 | 0 周期 |

讲解要点：

- 多周期 CPU 串行执行，CPI 约 4.0。
- 五级流水线最多同时处理 5 条指令，理想 CPI 接近 1.0。
- forwarding 和 stall/flush 是保证流水线正确性的关键。

### 第 11 页：BTB 动态分支预测

BTB 设计参数：

| 参数 | 数值 |
|---|---|
| 类型 | BTB + 2-bit 饱和计数器 |
| 条目数 | 16 |
| 索引 | `PC[5:2]` |
| 预测规则 | counter[1] = 1 预测跳转 |
| 更新阶段 | EX 阶段 |
| 估计开销 | ~200 LUT + ~130 FF |

2-bit 状态机：

```text
SNT(00) -> WNT(01) -> WT(10) -> ST(11)
预测跳转条件：最高位为 1
```

分支预测预期：

| 程序类型 | 静态预测正确率 | BTB 正确率 |
|---|---:|---:|
| 简单算术 | ~55% | ~90% |
| 点积运算 | ~50% | ~85% |
| 猜数字游戏 | ~45% | ~88% |
| 循环密集程序 | ~30% | ~92% |

讲解要点：

- 静态预测“不跳转”遇到循环时表现差。
- BTB 通过历史学习分支行为，可以降低控制冒险带来的 CPI 损失。
- 当前正确率为模型/预期数据，待后续 xsim 统计进一步确认。

### 第 12 页：性能提升总览

核心表格：

| 指标 | 多周期 FSM | 五级流水线静态预测 | 五级流水线 + BTB | 相对多周期 |
|---|---:|---:|---:|---:|
| CPI | 4.0 | ~1.16 | ~1.08 | -73% |
| 吞吐量 @100MHz | ~25 MIPS | ~86 MIPS | ~92 MIPS | +268% |
| IPC | 0.25 | ~0.86 | ~0.93 | +272% |
| 分支延迟 | 3 周期 | 1 周期 | ~0.12 周期 | -96% |

说明：

- 多周期 FSM 的 CPI 与 MAC 点积数据为实测。
- 流水线和 BTB 的 CPI/吞吐量为估计值，来源于冒险分解模型。
- 正式 PPA 仍需要完整 SoC / 流水线 Vivado 重综合。

可视化建议：

- 折线或阶梯图：CPI 4.0 -> 1.16 -> 1.08。
- 柱状图：吞吐量 25 -> 86 -> 92 MIPS。
- 在图上明确标注“实测/估计”。

### 第 13 页：PPA 与资源效率

核心表格：

| 资源 | 多周期 FSM | 流水线 + BTB | 芯片总量 | 占比 |
|---|---:|---:|---:|---:|
| LUT | ~800 | ~1,200 | 63,400 | ~1.9% |
| FF | ~350 | ~1,880 | 126,800 | ~1.5% |
| BRAM | 0 | 0 | 135 | 0% |
| DSP48E1 | 1 | 1 | 240 | 0.4% |

效率指标：

| 架构 | 吞吐量 | LUT | 面积效率 |
|---|---:|---:|---:|
| 多周期 FSM | ~25 MIPS | ~800 | 31 MIPS/KLUT |
| 五级流水线静态 | ~86 MIPS | ~950 | 91 MIPS/KLUT |
| 五级流水线 + BTB | ~92 MIPS | ~1,200 | 77 MIPS/KLUT |

讲解要点：

- 资源占用远低于 XC7A100T 总量，优化空间充足。
- BTB 会增加 LUT/FF，但能降低分支密集场景的 CPI。
- 不要把仓库中 heartbeat 的 2 LUT / 24 FF 当成完整 SoC 数据。

### 第 14 页：上板演示与用户可见成果

核心表格：

| 演示项 | 状态 | 说明 |
|---|---|---|
| Vivado bitstream | 已生成 | WNS=+7.212ns, DRC=0 |
| LED/数码管最小链路 | 已有基础 | 可作为基础上板演示 |
| VGA 显示链路 | 已打通 | 可显示彩条、黑底白边界面 |
| `S1~S5` 普通按键 | 已打通 | 方向移动、功能键交互正常 |
| 猜数字游戏骨架 | 已完成 | 开始页、输入页、结果页，蓝/红/绿边框反馈 |
| 4x4 矩阵键盘 | 未作为正式路线 | 多轮尝试未稳定响应，已切换到 `S1~S5` |

讲解要点：

- 上板演示不是核心 CPU 性能数据，但能证明工程落地能力。
- VGA + 按键小游戏比单纯 LED 更直观，适合答辩展示。

### 第 15 页：总结与后续工作

总结三句话：

1. CPU 完整性：RV32I 多周期 CPU 支持算术、逻辑、访存、跳转和 MAC 自定义指令，并通过多组仿真与 Vivado 验证。
2. 系统完整性：CPU、BRAM、统一总线、MMIO 外设、性能计数器和板级顶层形成完整 SoC。
3. 性能优化：MAC 指令带来 1.1481x 点积加速，流水线 + BTB 预计将 CPI 从 4.0 降至约 1.08，吞吐量提升到约 92 MIPS。

后续工作：

- 完整 SoC / 流水线 Vivado utilization + timing 实测。
- BTB 正确率 xsim 统计。
- 上板演示截图/视频归档。
- VGA 猜数字游戏补字符显示和伪随机数。

---

## 3. 可直接用于图表的数据

### 3.1 CPU 完整性数据

| 项目 | 数据 |
|---|---|
| ISA | RV32I 子集 |
| 标准指令 | 31 条 |
| 自定义指令 | 1 条 MAC |
| CPU 基线 | 6 状态多周期 FSM |
| 优化 CPU | 五级流水线 |
| 冒险处理 | forwarding + load-use stall + branch/JAL/JALR flush |
| 分支预测 | 16 条目 BTB + 2-bit 饱和计数器 |
| 存储器 | 32KB 指令 BRAM + 32KB 数据 BRAM |
| 外设 | LED、Switch、SEG7、性能计数器、VGA/按键演示 |
| RTL 规模 | 约 25 个 RTL 文件，约 2100 行 Verilog |

### 3.2 验证数据

| 验证 | 结果 | 数据 |
|---|---|---|
| Vivado Synthesis | PASS | 100 MHz |
| Vivado Implementation | PASS | WNS=+7.212ns, TNS=0 |
| Hold Timing | PASS | WHS=+0.241ns, THS=0 |
| DRC | PASS | 0 violations |
| CPU basic | PASS | `debug_pc=0x20` |
| LW/SW | PASS | `mem0=42 mem1=99 x5=141` |
| BEQ/BNE | PASS | `x10=12 debug_pc=0x30` |
| MAC dot product | PASS | result=70 |
| Perf MMIO | PASS | cycle/instret/mac 可读 |
| VGA + S1~S5 | PASS | 可交互小游戏骨架 |

### 3.3 性能优化数据

| 优化点 | 指标 | 优化前 | 优化后 | 提升 |
|---|---|---:|---:|---:|
| MAC 点积 | cycle | 62 | 54 | -12.90% |
| MAC 点积 | instret | 15 | 13 | -13.33% |
| MAC 点积 | speedup | 1.0000 | 1.1481 | +14.81% |
| 流水线 | CPI | 4.0 | ~1.16 | ~3.45x |
| 流水线 + BTB | CPI | 4.0 | ~1.08 | ~3.70x |
| 流水线 + BTB | 吞吐量 | ~25 MIPS | ~92 MIPS | +268% |
| BTB | 分支正确率 | ~50% 静态 | ~85-92% | 大幅提升 |

### 3.4 资源/PPA 数据

| 架构 | LUT | FF | DSP | CPI | 吞吐量 | 说明 |
|---|---:|---:|---:|---:|---:|---|
| 多周期 FSM | ~800 | ~350 | 1 | 4.0 | ~25 MIPS | 基线 |
| 五级流水线静态 | ~950 | ~1650 | 1 | ~1.16 | ~86 MIPS | 估计 |
| 五级流水线 + BTB | ~1200 | ~1880 | 1 | ~1.08 | ~92 MIPS | 估计 |

注意：

- 以上流水线资源与 CPI 是估计值，不要在 PPT 中写成最终 Vivado 实测。
- 完整 SoC 的正式 utilization/timing 需要 B/C 重新导出。

---

## 4. AI 生成 PPT 的完整提示词

队友 C 可以把下面这一段直接交给 AI agent：

```text
你是一个擅长课程设计答辩 PPT 和技术可视化网页设计的 AI agent。请根据我提供的 Markdown 材料，为《题目B：基于 FPGA 开发板的处理器设计》生成一份 12-15 页中文汇报 PPT 或单页技术展示网页。

目标受众：课程老师和助教。
汇报重点：
1. 体现 CPU 的完整性：RV32I 31 条指令 + MAC 自定义指令、6 状态多周期 FSM、控制器、ALU、regfile、branch、BRAM、统一总线、MMIO 外设、性能计数器。
2. 体现完整计算机系统：Minisys 板级顶层、soc_top、inst_ram、data_ram、LED/Switch/SEG7、VGA + S1~S5 按键演示。
3. 体现性能优化：MAC 点积加速、五级流水线、forwarding/stall/flush、BTB 动态分支预测。
4. 体现数据支撑：使用明确表格和图表展示 CPI、cycle、instret、speedup、MIPS、资源估计、Vivado 时序结果和验证矩阵。

必须使用的关键数据：
- 指令集：31 条 RV32I + 1 条 MAC。
- CPU 基线：6 状态多周期 FSM。
- RTL 规模：约 25 个 RTL 文件，约 2100 行 Verilog。
- Vivado：WNS=+7.212ns, TNS=0, WHS=+0.241ns, THS=0, DRC=0。
- 点积测试：普通 RV32I result=70, cycle=62, instret=15, CPI=4.1333；MAC result=70, cycle=54, instret=13, CPI=4.1538, mac_count=4；speedup=1.1481, cycle 减少 12.90%, 指令数减少 13.33%。
- 流水线估计：CPI 4.0 -> 1.16 -> 1.08；吞吐量约 25 MIPS -> 86 MIPS -> 92 MIPS；相对多周期约 3.70x。
- BTB：16 条目，2-bit 饱和计数器，预测正确率预期 85-92%，开销约 200 LUT + 130 FF。
- 资源估计：多周期约 800 LUT / 350 FF / 1 DSP；流水线+BTB 约 1200 LUT / 1880 FF / 1 DSP；XC7A100T 总资源为 63,400 LUT、126,800 FF、240 DSP48E1。
- 功能验证：ALU/regfile/control/basic/LW-SW/BEQ-BNE/MAC/perf/MMIO/Vivado/VGA+S1~S5 均有 PASS 或上板验证。

重要边界：
- 流水线 CPI、MIPS、LUT/FF 是估计/模型数据，不能写成完整 Vivado 实测。
- 仓库中 heartbeat 的 2 LUT / 24 FF 不是完整 SoC PPA，不能放进正式 PPA 表。
- 4x4 矩阵键盘不是正式演示路线，正式路线是 S1~S5 普通按键 + VGA。

设计风格：
- 中文技术答辩风格，清晰、克制、数据驱动。
- 使用蓝白主色，少量橙/红强调性能提升。
- 每页放一个明确结论，不堆长段文字。
- 多用表格、流程图、柱状图、CPI 演进图、PPA 三角图、验证矩阵。
- 如果生成网页，要做成工程技术仪表盘风格，包含顶部 KPI 卡片、架构图、性能对比图、验证矩阵和时间线。

请输出：
1. 每一页/每一区块的标题。
2. 每页应放的文字内容。
3. 每页的图表建议。
4. 每页的讲解备注。
5. 最终 3 分钟汇报话术。
```

---

## 5. AI 生成网页界面的提示词补充

如果 C 想生成网页而不是 PPT，可以追加：

```text
请把内容做成一个单页交互式技术展示网页，不要做营销落地页。首屏必须直接展示项目 KPI 和 CPU 架构，不要大幅 hero 空文案。页面结构：
1. 顶部 KPI 卡：32条指令、WNS=+7.212ns、MAC speedup=1.1481x、CPI 4.0->1.08、吞吐量 25->92 MIPS。
2. 三层课程要求对照区：基础/进阶/拓展。
3. 系统架构区：minisys_top -> soc_top -> cpu_top/memory/bus/io。
4. 性能优化区：MAC、流水线、BTB 三张并列卡片。
5. 数据图表区：cycle 对比柱状图、CPI 演进折线图、资源占比图、验证矩阵。
6. 上板演示区：VGA + S1~S5 小游戏骨架说明。
7. 风险与待补区：PPA 实测待导出、BTB 正确率待统计、截图/视频待归档。

界面风格：面向工程答辩，信息密度高但整洁；不要使用过度装饰；卡片圆角不超过 8px；表格要清晰；图表颜色统一。
```

---

## 6. 3 分钟汇报话术

老师好，我们组完成的是题目 B：基于 FPGA 开发板的处理器设计。

我们首先实现了一套完整的 RV32I 多周期处理器，支持 31 条 RV32I 基础指令，并扩展了一条 MAC 自定义乘加指令。CPU 采用 6 状态 FSM，包括取指、译码、执行、访存、写回和停机，配套实现了 ALU、寄存器堆、控制器、立即数生成、分支判断、BRAM 存储器和性能计数器。功能上，我们已经通过 ALU、regfile、control、basic、LW/SW、BEQ/BNE 等多组仿真验证。

在完整系统方面，我们把 CPU 接入统一总线 SoC，包含 32KB 指令存储、32KB 数据存储，以及 LED、Switch、SEG7 和性能计数器等 MMIO 外设。Vivado 2018.3 下综合、实现和 bitstream 生成均通过，100MHz 时钟下 WNS 为 +7.212ns，TNS 为 0，DRC 为 0，说明基础系统具备上板运行条件。

在拓展优化方面，我们主要做了三件事。第一，设计了 RISC-V custom-0 空间的 MAC 指令，语义是 `rd = rd_old + rs1 * rs2`。在 4 元素点积测试中，普通 RV32I 程序需要 62 个周期、15 条退休指令，MAC 版本减少到 54 个周期、13 条退休指令，加速比为 1.1481，周期减少 12.90%。第二，我们实现了五级流水线 CPU，加入 forwarding、load-use stall 和分支刷新机制，理论上可把 CPI 从多周期的 4.0 降到约 1.16。第三，我们进一步加入 16 条目 BTB 和 2-bit 饱和计数器，预计在分支密集场景中把 CPI 降到约 1.08，吞吐量从约 25 MIPS 提高到约 92 MIPS。

最后，我们还打通了 VGA 显示和 S1 到 S5 普通按键输入，完成了一个猜数字小游戏骨架，包含开始页、输入页和结果页，能通过边框颜色反馈猜测结果。这说明我们的工程不只停留在仿真，也具备上板演示和交互展示能力。

---

## 7. 必须避免的错误表述

1. 不要说流水线 PPA 已经完成 Vivado 实测。当前流水线 LUT/FF/CPI/MIPS 多数是估计或模型数据。
2. 不要把 `processor_fpga.runs` 里 heartbeat 的 `2 LUT / 24 FF` 当成完整 CPU/SoC 数据。
3. 不要说 4x4 矩阵键盘已经作为正式输入验证通过。正式演示输入是 `S1~S5` 普通按键。
4. 不要说 Cache 已实现。当前项目有 Cache 可行性分析，但主线没有实现 Cache。
5. 不要说浮点或除法扩展已实现。当前核心创新是 MAC，不是完整 M 扩展或 F 扩展。
6. 不要把 VGA 小游戏说成 CPU 软件完整运行的游戏程序。当前是板级 VGA 交互骨架，主要用于上板展示。

---

## 8. 参考文件

| 文件 | 用途 |
|---|---|
| `README.md` | 项目入口和当前状态 |
| `docs/planning/defense_preparation.md` | 答辩讲稿和技术细节 |
| `docs/design/task_board.md` | 最新任务状态和成员分工 |
| `docs/planning/progress_checklist.md` | 课程三层要求完成度 |
| `reports/tables/performance_summary.md` | 性能总览和 KPI |
| `reports/tables/before_after_comparison.md` | 前后对比卡片 |
| `reports/tables/resource_utilization.md` | 资源和 PPA 分析 |
| `reports/tables/ppa_comparison.md` | PPA 表格和注意事项 |
| `reports/tables/test_results.md` | 测试和上板验证结果 |
| `reports/figures/pipeline_performance_dashboard.html` | 可视化仪表盘参考 |

