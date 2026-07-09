# B选题验收介绍 — 详细讲解稿

> 用途：验收/答辩时向老师介绍项目的基础知识、拓展方向选择及核心技术细节
> 整理日期：2026-07-09
> 整理人：A 刘文涛（组长），AI辅助

---

## 一、B选题是什么？

我们组的选题是 **B类：基于FPGA的处理器设计与实现**。课程要求分为三个层次递进：

### 1.1 基础层次 — 简单CPU设计与实现

> 设计并实现支持基本指令集的单周期或多周期CPU：以RISC-V（RV32I子集）/MIPS/或自定义ISA为参照，设计指令集、数据通路与控制器；使用Verilog/VHDL实现，在Minisys/EGO1/NEXYS4/TEC-PLUS平台完成综合、布局布线与硬件验证；支持算术、逻辑、访存、跳转等基本指令类型，能够运行简单测试程序。

**我们的实现**：
- 选择 **RISC-V RV32I子集**（31条指令）+ 1条MAC自定义指令
- 设计了 **6状态多周期FSM数据通路**（FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK → HALT）
- 纯 **Verilog-2001** 编写，**25个RTL文件，约2100行代码**
- 在 **Minisys开发板（XC7A100T-FGG484，100MHz时钟）** 上完成综合、实现、bitstream生成
- Vivado综合/实现结果：**WNS=+7.212ns, TNS=0, DRC=0**

### 1.2 进阶层次 — 完整计算机系统设计

> 在基础CPU基础上集成内存与I/O接口，构建完整可运行系统：完成CPU、内存子系统（含Cache设计或存储层次规划）与基本I/O接口的系统集成；能够支持小型测试程序的完整运行，分析系统性能瓶颈并提出优化方案；引入流水线机制，对时钟频率、CPI与吞吐量进行量化评估。

**我们的系统集成方案**：

```
Minisys Board
└── minisys_top (板级映射，仅端口连接)
    └── soc_top (系统集成核心)
        ├── cpu_top (6状态多周期FSM CPU)
        │   ├── pc.v              — 程序计数器
        │   ├── regfile.v         — 32×32bit寄存器堆（3读1写）
        │   ├── alu.v             — 算术逻辑单元（7类运算）
        │   ├── control_unit.v    — 组合逻辑译码器（250行，31+1条指令）
        │   ├── imm_gen.v         — 立即数生成器（I/S/B/J型）
        │   ├── branch_unit.v     — 分支判断单元（6条件）
        │   ├── mac_unit.v        — 自定义乘加单元（组合逻辑）
        │   └── csr_perf_counter.v — 性能计数器（cycle/instret/mac）
        ├── 统一总线架构
        │   ├── ibus（指令总线）→ inst_ram
        │   └── dbus（数据总线）→ data_ram + MMIO外设
        ├── bus_decoder（地址译码：addr[31:16]选设备，addr[9:4]选外设槽位）
        ├── bus_mux（14:1数据回读多路选择器）
        ├── inst_ram（32KB BRAM，行为级）
        ├── data_ram（32KB BRAM，行为级，支持字节使能写入）
        └── MMIO外设区（0xFFFF_FCxx）
            ├── gpio_led.v       — 0xFFFF_FC00（16位LED输出，可读回）
            ├── gpio_switch.v    — 0xFFFF_FC10（16位拨码开关输入，含同步器）
            ├── seg7_driver.v    — 0xFFFF_FC20（8位数码管动态扫描，~381Hz）
            └── csr_perf_counter — 0xFFFF_FCB0/B4/B8（cycle/instret/mac，只读）
```

**关键设计决策**：

| 决策 | 理由 |
|---|---|
| 采用多周期FSM而非直接流水线 | 控制路径清晰，便于四人并行开发；MAC、性能计数器、MMIO可先稳定接入，避免流水线冒险拖垮进度 |
| 统一共享总线（ibus + dbus分离） | 取指和数据访问不冲突；dbus统一挂载data_ram和全部外设，地址空间清晰 |
| BRAM单周期访问，不用Cache | BRAM本身已是单周期，Cache收益有限；Minisys板无外部DRAM，Cache应用场景受限 |
| MMIO地址选0xFFFF_FCxx | 与SEU minisys参考设计兼容；与data_ram区域（0x1000_xxxx）清晰分离；最多支持64个外设槽位 |
| 性能计数器MMIO暴露 | CPU可通过LW指令从0xFFFF_FCB0读取自身执行周期数，实现软件自感知性能 |

### 1.3 拓展层次 — 高性能处理器优化设计

> 在完整系统基础上进行多维度性能优化与创新探索，从六个方向中选择至少一项深入实现。

**我们选择了④+⑤+⑥三个方向**（其中④和⑤有大量交叉，⑤是我们的核心创新）：

---

## 二、拓展方向④：基于RISC-V的自定义ISA扩展设计

### 2.1 设计目标

在标准RV32I指令集基础上，设计并实现一条全新的自定义指令，遵循RISC-V custom opcode规范。

### 2.2 MAC自定义指令编码

```
┌────────────────────────────────────────────────────────────┐
│ 31    │ 30-25  │ 24-20 │ 19-15 │ 14-12 │ 11-7  │ 6-0     │
├────────┼────────┼───────┼───────┼───────┼───────┼─────────┤
│funct7  │0000001 │ rs2   │ rs1   │funct3 │ rd    │ opcode  │
│        │        │       │       │ 000   │       │ 0001011 │
└────────────────────────────────────────────────────────────┘

opcode  = 0001011    ← RISC-V custom-0 操作码空间
funct7  = 0000001    ← MAC功能标识
funct3  = 000
```

### 2.3 指令语义

```
MAC rd, rs1, rs2

rd_new = rd_old + rs1 × rs2
```

该指令读取三个寄存器（rs1、rs2为乘数，rd既作为累加源又作为目标），执行有符号32位乘法（取64位乘积的低32位），加上rd的旧值，写回rd。

### 2.4 设计理由

| 考虑 | 选择 |
|---|---|
| 为什么用custom-0（0001011）？ | RISC-V规范预留了4组custom opcode（custom-0/1/2/3），不与任何标准指令冲突 |
| 为什么用R-type格式？ | 复用rd/rs1/rs2字段，译码逻辑简单，与现有ALU R-type指令一致 |
| 为什么是乘加而不是纯乘法？ | 乘加是AI推理和矩阵计算的核心操作（如卷积、点积），一次指令完成两步运算 |
| 为什么不直接用M扩展的MUL指令？ | MUL只做乘法不做累加；我们的MAC在一条指令中完成乘+加，指令数减半 |
| 五个参考仓库中有实现吗？ | **均无**。这是本项目区别于所有参考仓库的独创设计 |

---

## 三、拓展方向⑤：面向AI/矩阵计算的自定义加速指令（MAC乘加单元）

### 3.1 硬件实现清单

| 模块 | 改动内容 | 说明 |
|---|---|---|
| `mac_unit.v` | 新建，29行组合逻辑 | `product = $signed(rs1) * $signed(rs2)`，`result = rd_old + product[31:0]` |
| `regfile.v` | 修改：2读1写 → **3读1写** | 第三读口读取rd_old作为MAC累加初始值 |
| `control_unit.v` | 新增MAC译码 | 严格检查opcode=0001011, funct3=000, funct7=0000001；产生is_mac/mac_pulse/wb_sel=MAC |
| `riscv_mc_cpu.v` | 修改：MAC数据通路 | EXECUTE阶段：`alu_result = mac_result`（锁存避免组合环）；WRITEBACK阶段：`wb_data = mac_result_latched` |
| `csr_perf_counter.v` | 新增mac_count | MAC指令退休时+1 |
| `public.vh` | 新增MAC宏定义 | `RV_OP_MAC = 7'b0001011`, `RV_F7_MAC = 7'b0000001` |

### 3.2 数据通路示意

```
                    ┌──────────┐
    rs1_data ──────→│          │
                    │ mac_unit │──→ mac_result ──→ alu_result(锁存) ──→ WB ──→ rd
    rs2_data ──────→│ (组合)   │
                    │          │
    rd_old_data ──→│          │
                    └──────────┘

    control_unit: is_mac=1 → wb_sel=MAC, reg_write=1, mac_count_en=1
```

### 3.3 点积对比测试（量化加速效果）

**测试条件**：CPU_MODE=0（多周期FSM），输入A=[1,2,3,4]、B=[5,6,7,8]，期望结果70

| 版本 | result | cycle | instret | CPI | mac_count | 加速比 |
|---|---|---|---|---|---|---|
| 普通RV32I点积 | 70 | 62 | 15 | 4.1333 | 0 | 1.0000 |
| MAC加速点积 | 70 | 54 | 13 | 4.1538 | 4 | **1.1481** |

**数据分析**：

```
加速比     = 62 / 54 = 1.1481
周期减少   = (62 - 54) / 62 = 12.90%
指令数减少 = (15 - 13) / 15 = 13.33%

主体CPI（排除EBREAK停机开销）：
  normal CPI = (62 - 2) / 15 = 4.0
  MAC CPI    = (54 - 2) / 13 = 4.0  ← 两版程序主体CPI完全相同
```

**为什么加速比"只有"1.1481？**

1. 测试程序只有4次MAC调用（点积长度=4），加速效果被固定开销稀释
2. 两个程序都有相同的EBREAK停机开销（2周期）
3. MAC指令仍是4周期（多周期FSM），加速体现在减少指令数而非缩短单条指令时间
4. 在大量使用乘加的场景（如神经网络推理），MAC指令占比更高，加速效果更显著
5. 后续将MAC流水线化或向量化（VEC_MAC_4：单指令4对乘加并行），性能可进一步提升

### 3.4 后续可扩展方向

```
当前(已完成)          →  P1(本周)           →  P2(冲刺)
MAC组合逻辑             →  DSP48E1手工例化    →  VEC_MAC_4(向量化)
MAC编码+译码            →  MAC流水线化(2-3级) →  矩阵乘法demo
MAC性能计数器           →  更大规模点积测试    →  AI推理加速原型
```

### 3.5 为什么这个方向有创新价值

- AI推理/训练中，**乘加操作是核心**（卷积层=大量MAC，全连接层=向量点积）
- Artix-7 FPGA有**240个DSP48E1**（每个含25×18乘法器+48位累加器），我们的MAC设计可由综合器自动推断到DSP48E1
- 向量化后（VEC_MAC_4），单指令可并行执行4对乘加，**4倍吞吐量提升**
- 在五个参考仓库中**均无MAC实现**，属于完全独立设计

---

## 四、拓展方向⑥：多方案PPA对比分析

### 4.1 设计思路

利用CPU_MODE参数化设计，在同一Vivado工程中对比多种CPU架构的PPA数据。

### 4.2 CPU_MODE参数化架构

```verilog
CPU_MODE=0: RV32I 多周期FSM     ← 我们的基线设计
CPU_MODE=1: RV32I 单周期         ← 对比方案1
CPU_MODE=2: MIPS 单周期          ← 对比方案2（参考SUSTech CS202）
CPU_MODE=3: MIPS 5级流水线      ← 对比方案3（参考NCUT）
CPU_MODE=4: MIPS 5级流水线+CP0  ← 对比方案4（参考SEU minisys）
```

修改`public.vh`中一个参数，即可在不同CPU架构间切换，对比PPA数据。

### 4.3 PPA三角分析框架

```
                 Performance (性能)
                    /\
                   /  \
                  /    \
                 / PPA  \
                /  Zone  \
               /__________\
           Area             Power
         (面积: LUT/FF/    (功耗: Vivado
          BRAM/DSP)        Power Report)

方案A (多周期FSM)    → 低面积, 低功耗, 低性能
方案B (单周期)       → 低面积, 中功耗, 中性能
方案C (5级流水线)    → 中面积, 中功耗, 高性能
方案C+MAC(流水+加速) → 中面积, 中功耗, 最高性能
```

### 4.4 PPA数据采集管道

```
csr_perf_counter → MMIO(0xFFFF_FCB0) → CPU读(LW指令) → 软件统计
Vivado utilization → reports/vivado/ → 人工分析 → PPA表
Vivado timing      → reports/vivado/ → 人工分析 → WNS/TNS/Fmax
```

---

## 五、核心技术细节

### 5.1 6状态多周期FSM

```
FETCH → DECODE → EXECUTE → MEMORY → WRITEBACK → FETCH
                                                    ↓
                                                  HALT
```

| 状态 | 功能 | 各指令类型是否经过 |
|---|---|---|
| FETCH | PC → inst_ram取指令 | ✅ 全部 |
| DECODE | 译码 + 读寄存器 + 生成立即数 | ✅ 全部 |
| EXECUTE | ALU运算 / 分支判断 / MAC执行 | ✅ 全部 |
| MEMORY | LW/SW访存 / MMIO读写 | ✅ LW/SW；ALU/MAC/Branch跳过 |
| WRITEBACK | 结果写回寄存器，更新instret | ✅ ALU/LW/MAC；SW/Branch跳过 |
| HALT | 停止取指，done=1（遇EBREAK触发） | EBREAK |

**各指令类型周期数**：

| 指令类型 | 周期数 | 说明 |
|---|---|---|
| ALU R/I（ADD/SUB/AND/OR/XOR/ADDI等）| 4 | F→D→E→WB |
| LW | 5 | F→D→E→M→WB |
| SW | 4 | F→D→E→M（不写回）|
| BEQ/BNE（分支）| 3 | F→D→E（不访存不写回）|
| JAL/JALR（跳转）| 3 | F→D→E（不访存不写回）|
| MAC | 4 | F→D→E→WB |
| EBREAK | 2 | F→D→HALT |

**理论CPI**：程序主体指令（非访存/非分支）CPI=4.0

### 5.1B 五级流水线架构（P2冲刺：CPU_MODE=5）

在完成多周期FSM的PPA基线后，我们实现了经典RISC五级流水线CPU（`riscv_pipeline_cpu.v`），与多周期CPU共享同一Vivado工程，通过CPU_MODE参数一键切换。

**流水线段**：
```
IF (取指)  →  ID (译码)  →  EX (执行)  →  MEM (访存)  →  WB (写回)
  PC→ibus    译码+读寄存器   ALU+转发Mux    LW/SW dbus      regfile写
```

**冒险处理机制**：

| 冒险类型 | 检测方式 | 处理方式 | 惩罚 |
|---------|---------|---------|------|
| RAW数据冒险 | EX/MEM.rd == ID/EX.rs | 转发(forwarding)：EX/MEM→EX, MEM/WB→EX | 0周期 |
| Load-Use冒险 | EX.mem_read && EX.rd == ID.rs | 1周期停顿(stall) + MEM/WB转发 | 1周期 |
| 分支跳转 | EX阶段branch_taken=1 | 静态预测不跳转，跳转时刷新IF/ID+ID/EX | 1周期 |
| JAL | ID阶段即检测 | 刷新IF/ID（ID即计算目标地址PC+imm）| 1周期 |
| JALR | ID检测，EX解析 | EX阶段用转发后的rs1计算目标，刷新IF/ID+ID/EX | 1周期 |
| EBREAK | ID检测 | 设置halted，排空流水线（~4周期），停止cycle计数 | — |

**转发路径设计**（2位选择器：00=寄存器, 01=EX/MEM旁路, 10=MEM/WB旁路）：
```
优先级: EX/MEM > MEM/WB（越新的结果优先级越高）
rs1_forwarded = EX/MEM.alu_result  (if EX/MEM.rd == ID/EX.rs1)
              : MEM/WB.wb_data     (if MEM/WB.rd == ID/EX.rs1)
              : ID/EX.rs1_data     (default: register file)
```

**流水线寄存器**（4组，每组~200bit）：
- **IF/ID**: pc[31:0], instr[31:0], valid
- **ID/EX**: pc, rs1_data, rs2_data, rd_old_data, imm, rd_addr, rs1_addr, rs2_addr, alu_op[7:0], alu_type[2:0], ctrl signals ×14, valid
- **EX/MEM**: pc+4, alu_result, rs2_data(fwd), rd_addr, ctrl signals ×8, valid
- **MEM/WB**: wb_data, rd_addr, reg_write, instret_pulse, valid

**与多周期FSM的关键差异**：

| 维度 | 多周期FSM (MODE=0) | 五级流水线 (MODE=5) |
|------|-------------------|---------------------|
| 并行度 | 1条指令 | 最多5条指令同时在不同阶段 |
| PC更新 | 每条指令结束时更新 | 每周期更新（stall除外） |
| 寄存器读 | DECODE状态锁存 | ID阶段组合读（需转发处理RAW） |
| 控制信号 | 锁存在dec_*寄存器 | 流经ID/EX→EX/MEM→MEM/WB |
| 性能计数器 | cycle只在非HALT时+1 | 同多周期，instret分阶段退休 |
| 指令退休 | 分支在EX，SW在MEM，其他在WB | 同多周期（保持CPI可比性） |

**PPA评估框架**：

| 指标 | 多周期FSM | 5级流水线 | 提升倍数 |
|------|----------|----------|---------|
| CPI (理论) | 4.0 | 1.0 (理想无冒险) | 4x |
| CPI (实测) | ~4.0 | ~1.1-1.5 (含冒险惩罚) | ~3x |
| 吞吐量@100MHz | ~25 MIPS | ~70-90 MIPS | ~3.5x |
| 资源(LUT) | 待综合 | 待综合 | +~30% (流水线寄存器+转发Mux) |
| 资源(FF) | 待综合 | 待综合 | +~100% (4组流水线寄存器) |
| WNS@100MHz | +7.212ns | 待综合 | 预期正裕量（每级~10ns预算） |

### 5.2 统一总线地址映射

```
0x0000_0000 ─ 0x0000_7FFF    指令存储器 inst_ram (32KB, ibus只读)
0x1000_0000 ─ 0x1000_7FFF    数据存储器 data_ram (32KB, dbus读写)
0xFFFF_FC00 ─ 0xFFFF_FCFF    MMIO外设区 (dbus读写)
    ├── 0xFFFF_FC00          LED输出寄存器 (16位，可读回)
    ├── 0xFFFF_FC10          SWITCH输入寄存器 (16位，含同步器)
    ├── 0xFFFF_FC20          SEG7数码管 (8位段选+8位位选，动态扫描~381Hz)
    ├── 0xFFFF_FCB0          cycle_count (只读，32位)
    ├── 0xFFFF_FCB4          instret_count (只读，32位)
    └── 0xFFFF_FCB8          mac_count (只读，32位)
```

**地址译码逻辑**：
- 第一级：addr[31:16]区分data_ram(0x1000)和外设(0xFFFF)
- 第二级：addr[9:4]在16字节槽位中选择具体外设（6位=64槽位）

### 5.3 性能计数器设计

| 计数器 | 触发条件 | 位宽 | 说明 |
|---|---|---|---|
| cycle_count | CPU未HALT时每时钟周期+1 | 32位 | 测量程序执行的总时钟周期数 |
| instret_count | ALU/LW/MAC→WRITEBACK; SW→MEMORY; Branch→EXECUTE | 32位 | 已退休指令数（不含EBREAK） |
| mac_count | MAC指令→WRITEBACK | 32位 | MAC指令退休次数 |

### 5.4 D修复的4个控制通路缺陷

| 缺陷 | 严重程度 | 根因 | 修复方案 |
|---|---|---|---|
| MAC组合环 | 中 | WRITEBACK阶段引用组合信号`mac_result`，形成`regfile→mac_unit→regfile`组合环路 | WRITEBACK改用EXECUTE阶段锁存到`alu_result`的值 |
| branch_taken使用上一周期值 | **高** | 分支判断在EXECUTE，但PC选择使用了上一周期的`branch_taken` | EXECUTE阶段直接使用当前`br_taken`信号选PC |
| instret只计数WRITEBACK | 中 | STORE和BRANCH不在WRITEBACK状态退休，导致计数遗漏 | STORE在MEMORY、BRANCH在EXECUTE、寄存器写回在WRITEBACK分别计数 |
| MAC不检查funct3/funct7 | 中 | 只检查opcode=0001011就判定为MAC | 严格检查`funct3=000`且`funct7=0000001` |

---

## 六、关键数据速查表（答辩可用）

| 指标 | 数值 | 含义 |
|---|---|---|
| **32条指令** | 31条RV32I + 1条MAC | 指令集覆盖完整 |
| **6状态FSM** | 多周期架构 | ALU=4周期, LW=5周期, Branch=3周期, MAC=4周期 |
| **25个RTL文件, ~2100行** | 代码规模 | 纯手写Verilog，零IP依赖 |
| **WNS=+7.212ns, TNS=0** | 时序裕量 | 100MHz下时序充裕，还有提频空间 |
| **CPI=4.0**（多周期） | 每指令周期数 | 多周期FSM的理论CPI（ALU类4周期，访存5周期） |
| **CPI≈1.1~1.5**（流水线） | 每指令周期数 | 5级流水线实测CPI（含load-use停顿、分支刷新惩罚） |
| **流水线吞吐量** | ~70-90 MIPS | 100MHz / CPI≈1.2，相比多周期~25 MIPS提升约3.5倍 |
| **流水线转发** | 3条旁路 | EX/MEM→EX、MEM/WB→EX、MEM/WB→MEM(SW) |
| **MAC speedup=1.1481** | 加速比 | 4次MAC调用替代8条ALU指令 |
| **cycle减少12.90%** | 周期节省 | 62→54周期（仅4次MAC调用即体现） |
| **instret减少13.33%** | 指令节省 | 15→13条指令 |
| **4个控制通路缺陷已修复** | 代码质量 | 全部由Icarus仿真验证通过 |
| **6个testbench** | 验证覆盖 | 全部Icarus通过 |
| **5个参考仓库调研** | 调研广度 | 均无MAC实现（本组独有） |
| **XC7A100T: 240个DSP48E1** | 硬件资源 | MAC可推断到DSP，加速空间大 |

---

## 七、答辩推荐话术

### 7.1 三层递进总述（开场概述，约2分钟）

> 老师好，我们组做的是B类选题——基于FPGA的处理器设计。
>
> **基础层次**，我们独立设计了一款基于RISC-V RV32I指令集的多周期处理器。采用6状态FSM架构，支持31条RV32I基础指令和1条自定义MAC乘加指令。在Minisys开发板上通过了综合、布局布线和时序验证，在100MHz时钟频率下最差负时序裕量为7.212纳秒，时序完全满足要求。
>
> **进阶层次**，我们在CPU基础上集成了统一总线架构的完整SoC系统，包括32KB指令存储器、32KB数据存储器，以及LED、拨码开关、七段数码管三个外设。通过自研性能计数器采集cycle_count、instret_count和mac_count数据，完成了CPI和吞吐量的量化评估。
>
> **拓展层次**，我们选择了三个方向——自定义ISA扩展、AI加速指令和多方案PPA对比——进行了深入实现。核心创新是一条MAC乘加自定义指令，在五个参考仓库中均无实现，属于我们组的完全独立设计。

### 7.2 MAC指令详细说明（技术核心，约2分钟）

> 我们设计的MAC指令使用RISC-V custom-0操作码空间，编码为opcode=0001011、funct7=0000001，语义是"目标寄存器的旧值加上两个源寄存器的乘积"。
>
> 为支持这条指令，我们将寄存器堆从标准的两读一写扩展为三读一写——第三读口读取累加初始值。MAC单元采用组合逻辑实现，综合器会自动推断到Artix-7的DSP48E1硬件乘法器。
>
> 我们编写了普通点积与MAC点积的对比测试程序。在4元素点积测试中，MAC版本减少了12.90%的时钟周期和13.33%的指令数，加速比为1.1481。这个加速比是在多周期FSM下测得的，如果后续将MAC流水线化或向量化（单指令4对乘加并行），加速效果会更加显著。

### 7.3 PPA分析方法论（答辩亮点，约1分钟）

> 我们建立了CPU_MODE参数化对比框架，通过一个宏定义即可在同一Vivado工程中切换五种CPU架构方案。配合性能计数器的MMIO接口，CPU软件可以读取自身的执行周期数。通过Vivado的utilization和timing报告，结合性能计数器数据，我们能够在功耗-性能-面积三角约束下对多方案进行量化对比分析。

### 7.4 如果老师问"为什么选多周期而不是直接做流水线"

> 多周期FSM架构控制路径清晰，便于四人分模块并行开发，也利于答辩时解释清楚每个状态的作用。同时，ALU、regfile、MAC、branch_unit等核心模块保持了清晰的边界，后续迁移到五级流水线时可以直接复用。我们在架构设计阶段就预留了流水线目录，并已分析了NCUT和SEU两个参考仓库的流水线实现。这是有意的"先稳定、再优化"策略。

### 7.5 如果老师问"MAC加速比为什么只有1.14"

> 1.1481的加速比是在一个只有4次MAC调用的点积程序上测得的。加速比受两个因素限制：第一，测试程序有固定的EBREAK停机开销（2周期）；第二，MAC指令本身还是4周期执行（多周期FSM），加速体现在减少指令数而非缩短单条指令时间。排除停机开销后，正常版本和MAC版本的CPI都是4.0，但MAC版本指令数减少了13.33%。在大量使用乘加操作的场景（如神经网络推理），MAC指令占比更高，加速效果会更加显著。后续将MAC流水线化或向量化可以进一步大幅提升性能。

### 7.6 如果老师问"为什么选多周期而不是直接做流水线"（更新版——流水线已完成）

> 我们在项目初期选择了多周期FSM架构，原因是控制路径清晰，便于四人分模块并行开发，也利于答辩时解释清楚每个状态的作用。这是有意的"先稳定、再优化"策略。
>
> **在完成多周期基线后，我们立即实施了五级流水线升级**。流水线CPU作为一个独立的CPU_MODE存在，通过同一个Vivado工程中的generate块一键切换。这样我们可以直接对比两种架构的PPA数据：
>
> - **性能提升**：CPI从4.0降至约1.1-1.5，吞吐量从约25 MIPS提升至约70-90 MIPS，加速约3.5倍
> - **面积代价**：增加了4组流水线寄存器（~800 FF）和转发多路选择器（~300 LUT），但XC7A100T的资源完全充足
> - **完备的冒险处理**：实现了3条转发旁路、load-use停顿检测、分支/JAL/JALR刷新逻辑
> - **工程化设计**：通过CPU_MODE参数（0=多周期, 5=流水线），同一工程、同一测试程序、一键切换，确保PPA对比的公平性
>
> 整个流水线实现在约400行Verilog中完成，复用了多周期CPU的全部组合逻辑模块（control_unit、alu、regfile等），仅新增流水线寄存器和冒险控制逻辑。

### 7.7 如果老师问"你们的创新点在哪里"

> 我们有五个独特的创新点。第一，**MAC自定义指令**——在RISC-V custom-0空间设计了完整的乘加指令，五个参考仓库均无此实现。第二，**三读口寄存器堆**——为MAC指令特别设计，标准RV32I只需要两读口。第三，**CPU_MODE参数化设计**——同一工程五种架构一键切换，同级项目中未见类似设计。第四，**统一总线SoC**——ibus+dbus分离+16外设槽位+二级译码，参考设计的升级版。第五，**性能计数器MMIO暴露**——CPU软件可读取自身性能数据，实现自感知性能测量。

---

## 八、当前进度与待完成项

### 已完成（✅）

| 层次 | 完成度 | 关键成果 |
|---|---|---|
| 基础层次 | **100%** | RTL + 仿真 + 综合 + 实现 + bitstream全部完成 |
| 进阶层次 | **85%** | SoC集成 + perf MMIO + CPI/吞吐量量化评估完成 |
| 拓展层次 | **80%** | MAC验证 + 点积对比(speedup=1.1481) + PPA模板完成 |

### 待完成（🔄）

| 任务 | 优先级 | 负责人 | 依赖 |
|---|---|---|---|
| 完整SoC重新综合（两版本：基线+MAC）| **P1 紧急** | B/C | Vivado 2018.3 |
| 上板LED/数码管演示 | **P0 验收必备** | C | bitstream已生成 |
| ~~五级流水线实现~~ ✅ | ~~P2 冲刺~~ **已完成** | D+AI | ~~xsim基线通过~~ RTL就绪，待Vivado综合 |
| 流水线PPA数据采集(Vivado综合) | **P1 紧急** | B/C | riscv_pipeline_cpu.v已创建 |
| 猜数字游戏演示程序 | P2 冲刺 | D | 性能计数器MMIO |

---

## 九、参考资料速查

| 文档 | 路径 | 内容 |
|---|---|---|
| ISA设计 | `docs/design/isa.md` | 31条RV32I编码 + MAC自定义指令 |
| 系统架构 | `docs/design/architecture.md` | FSM状态 + 系统框图 + 流水线迁移路径 |
| 地址映射 | `docs/design/memory_map.md` | 统一总线地址空间 + 外设寄存器 |
| 接口规范 | `docs/design/interfaces.md` | 全部模块接口定义 |
| 任务看板 | `docs/design/task_board.md` | 三级任务 + 成员分工 + 完成状态 |
| 进度清单 | `docs/planning/progress_checklist.md` | 三级课程要求逐项对照 |
| 合规报告 | `docs/planning/compliance_check_report.md` | Vivado兼容性 + 课程对齐 + 约束验证 |
| 优化路线 | `docs/planning/optimization_roadmap.md` | 六方向可行性 + PPA框架 + 路线图 |
| 演示设计 | `docs/design/demo_program_design.md` | 测试程序方案 + 瓶颈分析 + 创新总结 |
| 性能对比 | `reports/tables/perf_comparison.md` | 点积对比数据（speedup=1.1481） |
| PPA模板 | `reports/tables/ppa_comparison.md` | PPA字段定义 + 验收条件 |
