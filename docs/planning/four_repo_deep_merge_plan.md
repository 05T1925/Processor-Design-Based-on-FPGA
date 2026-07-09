# 五仓库深度合并方案

> 基于 Minisys FPGA + EES-329B-V1.1 子板，将四个开源 MIPS 仓库的设计精华深度合并到本项目 RV32I 多周期/流水线 CPU + SoC 体系中。
>
> 最后更新：2026-07-07

---

## 〇、合并总纲

### 0.1 核心原则

1. **ISA 不可动摇**：坚持 RV32I 子集 + MAC 自定义指令，不退回 MIPS
2. **渐进式架构演进**：以多周期 FSM 为保底基线 → 五级流水线为 P1/P2 冲刺
3. **组件级借鉴**：从四个 MIPS 仓库提取可复用的硬件设计模式，改造为 RV32I 语义
4. **总线统一**：采用 SEU minisys 的共享总线 + 仲裁器模式，统一本项目 MMIO
5. **外设标准化**：采用统一的 6 端口外设接口规范
6. **保底优先**：任何时候 `main` 分支保留可综合、可仿真版本

### 0.2 五仓库角色定位

```text
┌─────────────────────────────────────────────────────────────────┐
│  ① NCUT_MiniSys        →  流水线寄存器模板 + regfile前推模式    │
│  ② SUSTech CS202       →  Minisys约束验证 + MMIO地址译码模式   │
│  ③ SEU minisys          →  ★ 共享总线+仲裁器 + 统一外设接口     │
│  ④ SEU minisys         →  BTB分支预测 + CP0异常框架 + ALU分类   │
│  本项目现有             →  RV32I ISA + MAC + 多周期FSM + Perf   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 一、总体架构选型

### 1.1 三级架构路线

```text
           P0（保底，第一版）        P1（主线）           P2（冲刺）
          ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
CPU架构   │ 多周期FSM         │→│ 5级流水线         │→│ +BTB分支预测     │
ISA       │ RV32I子集 11条    │  │ +乘除硬件/异常    │  │ +完整RV32I       │
总线      │ 直连+mem_bus     │→│ 共享总线+仲裁     │  │ +多主设备        │
外设      │ LED/SW/SEG       │→│ +Timer/PWM/Buzzer │→│ +UART/VGA/Key    │
MAC       │ 单周期乘加        │  │ 流水线MAC        │  │ +DSP48E1优化     │
Perf      │ cycle/inst/mac   │  │ +stall/flush     │  │ +branch_miss     │
异常      │ EBREAK/HALT      │→│ CSR基础异常       │→│ 完整中断体系      │
─────────────────────────────────────────────────────────────────────
```

### 1.2 P0 保底架构（当前阶段目标）

```text
Minisys Board (XC7A100T) + EES-329B-V1.1
└── minisys_top                          ← 板级顶层，复位转换
    └── soc_top                          ← SoC 集成层
        ├── cpu_top (多周期FSM)           ← 借鉴 NCUT 的 FSM 组织
        │   ├── pc_reg                   ← 借鉴 NCUT pc_reg
        │   ├── regfile (3读1写)          ← 借鉴 NCUT regfile + 本项目rd_old
        │   ├── alu                      ← 借鉴 SEU minisys ALU六分类
        │   ├── control_unit (RV32I译码)  ← 改造自 SEU minisys 译码框架
        │   ├── imm_gen                  ← RV32I立即数生成
        │   ├── branch_unit              ← RV32I分支判断
        │   ├── mac_unit                 ← 本项目独创
        │   └── csr_perf_counter         ← 本项目独创
        ├── mem_bus (总线仲裁器)          ← ★ 借鉴 SEU minisys arbitration
        │   ├── instr_mem (BRAM)         ← 借鉴 SUSTech inst_rom
        │   ├── data_mem (BRAM)          ← 借鉴 SUSTech data_ram
        │   └── mmio_decoder             ← 借鉴 SEU minisys IO地址译码
        └── io_devices                   ← 统一6端口外设接口
            ├── gpio_led                 ← 借鉴 SEU minisys/SUSTech
            ├── gpio_switch              ← 借鉴 SEU minisys/SUSTech
            └── seg7_driver              ← 借鉴 SEU minisys nixieTube
```

### 1.3 P1/P2 流水线架构（冲刺阶段）

```text
cpu_top (5级流水线)
├── IF Stage
│   ├── pc_reg + BTB (借鉴 SEU minisys BTB.v)
│   ├── instr_mem_iface
│   └── if_id  (借鉴 NCUT/SEU minisys 流水线寄存器)
├── ID Stage
│   ├── regfile (3读1写)
│   ├── control_unit + 数据前推 (借鉴 NCUT id.v 前推逻辑)
│   ├── imm_gen
│   └── id_ex
├── EX Stage
│   ├── alu (6类运算: NOP/ARITH/LOGIC/MOVE/SHIFT/JUMP)
│   ├── mac_unit (流水线化)
│   ├── mul/div (借鉴 SEU minisys mul.v)
│   ├── branch_unit + forwarding mux
│   └── ex_mem
├── MEM Stage
│   ├── mem_bus_arbiter
│   ├── csr_perf_counter
│   └── mem_wb
└── WB Stage
    └── wb_mux → regfile
```

---

## 二、组件来源决策表

### 2.1 CPU 核心组件

| 组件 | P0 来源 | P1/P2 来源 | 改造说明 |
|---|---|---|---|
| **pc_reg** | ③ SEU minisys `pc.v` | ④ SEU minisys + BTB | 改为 RV32I 的 `pc+4`，去掉延迟槽 |
| **regfile** | ① NCUT `regfile.v` + 本项目 `rd_old` | 同左 | 3读1写，x0=0，内部前推 |
| **alu** | ④ SEU minisys ALU六分类 | 同左，加流水线级 | RV32I 操作码映射到 6 类 ALU 操作 |
| **control_unit** | ③ SEU minisys `id.v` 框架 | 同左 | **关键改造**：MIPS opcode→RV32I opcode/funct3/funct7 |
| **imm_gen** | 本项目 | 同左 | RV32I I/S/B/U/J 五种立即数格式 |
| **branch_unit** | 本项目 | ④ BTB.v 思路 | RV32I BEQ/BNE + 可选的 JALR |
| **mac_unit** | 本项目（独创） | 流水线化版本 | `rd_new = rd_old + rs1*rs2` |
| **csr_perf_counter** | 本项目（独创） | 扩展 | cycle/instret/mac/stall/flush/branch_miss |

### 2.2 总线与存储器

| 组件 | 来源 | 说明 |
|---|---|---|
| **mem_bus** | ★ ③ SEU minisys `arbitration.v` | 改造为 mem_bus，统一 data_mem 与 MMIO 访问 |
| **mmio_decoder** | ③ SEU minisys 地址译码 | `addr[31:10]==0xFFFFF` → IO，`addr[9:4]` → 设备选择 |
| **instr_mem** | ② SUSTech `inst_rom.v` | `$readmemh` 行为级初始化 |
| **data_mem** | ② SUSTech `dm memory32.v` | 32-bit word LW/SW，行为级 BRAM |

### 2.3 外设控制器

| 组件 | P0 来源 | P1/P2 扩展 | 接口规范 |
|---|---|---|---|
| **gpio_led** | ③ SEU minisys `leds.v` | 同左 | 6端口统一接口 |
| **gpio_switch** | ③ SEU minisys `switches.v` | 同左 | 6端口统一接口 |
| **seg7_driver** | ④ SEU minisys `nixieTube.v` | 同左 | 低有效共阳极扫描 |
| **timer** | — | ③ SEU minisys `timer.v` | P1 添加 |
| **pwm** | — | ③/④ `pwm.v` | P1 添加 |
| **uart** | — | ② SUSTech `uart_bmpg_0` | P2 添加，用于程序在线加载 |
| **buzzer** | — | ③ SEU minisys `beep.v` | P2 添加 |

### 2.4 流水线基础设施（P1/P2）

| 组件 | 来源 | 说明 |
|---|---|---|
| **流水线寄存器 (if_id/id_ex/ex_mem/mem_wb)** | ① NCUT / ③ SEU minisys | 统一信号命名风格 |
| **数据前推 (forwarding)** | ① NCUT `id.v` 前推逻辑 | EX/MEM/WB → ID 三路径前推 |
| **冒险检测 (hazard)** | ① NCUT + ③ SEU minisys `ppl_scheduler.v` | load-use stall, branch flush |
| **BTB 分支预测** | ④ SEU minisys `BTB.v` | P2 冲刺，可显著提升 IPC |
| **CP0/CSR 异常** | ④ SEU minisys `CP0.v` → RV32I CSR | P2 冲刺 |

---

## 三、MIPS → RV32I 改造路径

### 3.1 编码差异总览

| 维度 | MIPS (五个仓库) | RV32I (本项目) |
|---|---|---|
| **opcode 位置** | `instr[31:26]` (6-bit) | `instr[6:0]` (7-bit) |
| **源寄存器 rs1** | `instr[25:21]` | `instr[19:15]` |
| **源寄存器 rs2** | `instr[20:16]` | `instr[24:20]` |
| **目的寄存器 rd** | `instr[15:11]` | `instr[11:7]` |
| **funct3** | 嵌入 opcode | `instr[14:12]` |
| **funct7** | `instr[5:0]` | `instr[31:25]` |
| **立即数** | I-type: `instr[15:0]` | I-type: `instr[31:20]` |
| **分支寻址** | `pc+4+offset<<2` (相对) | `pc+offset<<1` (相对) |
| **跳转** | J-type: `pc[31:28]|addr<<2` | JAL: `pc+offset<<1` |
| **$0 硬件零** | ✅ | ✅ x0 |

### 3.2 改造对照表（关键指令）

| MIPS 指令 | MIPS 编码 | → RV32I 指令 | RV32I 编码 |
|---|---|---|---|
| `ADD rd,rs,rt` | `000000_rs_rt_rd_00000_100000` | `ADD rd,rs1,rs2` | `0000000_rs2_rs1_000_rd_0110011` |
| `ADDI rt,rs,imm` | `001000_rs_rt_imm` | `ADDI rd,rs1,imm` | `imm[11:0]_rs1_000_rd_0010011` |
| `LW rt,offset(rs)` | `100011_rs_rt_offset` | `LW rd,offset(rs1)` | `offset[11:0]_rs1_010_rd_0000011` |
| `SW rt,offset(rs)` | `101011_rs_rt_offset` | `SW rs2,offset(rs1)` | `offset[11:5]_rs2_rs1_010_offset[4:0]_0100011` |
| `BEQ rs,rt,offset` | `000100_rs_rt_offset` | `BEQ rs1,rs2,offset` | `offset[12|10:5]_rs2_rs1_000_offset[4:1|11]_1100011` |
| `J addr` | `000010_addr` | `JAL x0,offset` | `offset[20|10:1|11|19:12]_rd_1101111` |
| `JR rs` | `000000_rs_..._001000` | `JALR x0,rs1,0` | `000000000000_rs1_000_rd_1100111` |
| `NOP` | `000000...` (SLL $0,$0,0) | `ADDI x0,x0,0` | `0x00000013` |

### 3.3 控制信号映射

| MIPS 控制信号 (③/④风格) | RV32I 对应 | 本项目命名 |
|---|---|---|
| `RegDst` (rd vs rt) | R-type→rd, I-type→rd | `reg_dst` |
| `RegWrite` | 同 | `reg_write` |
| `ALUSrc` (rt vs imm) | 同 | `alu_src_imm` |
| `MemRead` / `MemWrite` | 同 | `mem_read` / `mem_write` |
| `MemtoReg` | 同 | `wb_sel` (扩展为ALU/MEM/PC4/MAC) |
| `Branch` / `nBranch` | BEQ/BNE | `branch_op` |
| `Jump` / `Jal` / `Jr` | JAL/JALR | 合并到 `branch_op` |
| `I_type` (op[5:3]==001) | I-type 检测 | `is_i_type` |
| `Shfmd` (移位检测) | SLL/SRL/SRA | `is_shift` |

### 3.4 ALU 操作码映射

| RV32I 运算 | ④ SEU minisys alutype | ④ SEU minisys aluop |
|---|---|---|
| ADD/SUB | `ARITH (3'b001)` | 映射到 ADD/SUB op |
| AND/OR/XOR | `LOGIC (3'b010)` | 映射到 AND/OR/XOR op |
| SLL/SRL/SRA | `SHIFT (3'b100)` | 映射到 SLL/SRL/SRA op |
| SLT/SLTU | `ARITH` | 比较运算 |
| LUI | `MOVE (3'b011)` | 直通立即数高位 |
| AUIPC | `ARITH` | PC + imm |
| JAL/JALR | `JUMP (3'b101)` | PC+4 保存 |
| MAC | `ARITH` | 乘加组合 |

---

## 四、合并后代码目录结构

```text
Project-based Curriculum Stage/
├── README.md
├── .gitignore
│
├── constraints/
│   └── minisys.xdc                    # 已冻结的 Minisys 主线约束
│
├── src/
│   ├── board/
│   │   └── minisys_top.v              # 板级顶层（已实现外壳）
│   │
│   ├── soc/
│   │   ├── soc_top.v                  # SoC 集成层
│   │   └── display_mux.v             # 数码管显示多路选择器
│   │
│   ├── core/                          # ★ CPU 核心模块
│   │   ├── public.vh                  # 全局宏定义头文件（RV32I版）
│   │   ├── alu.v                      # ALU（6类运算）
│   │   ├── regfile.v                  # 寄存器堆（3读1写）
│   │   ├── control_unit.v             # 控制单元（RV32I译码）
│   │   ├── imm_gen.v                  # 立即数生成
│   │   ├── branch_unit.v              # 分支判断单元
│   │   ├── pc_reg.v                   # 程序计数器
│   │   ├── cpu_top.v                  # 多周期FSM CPU顶层
│   │   ├── mac_unit.v                 # MAC 乘加单元
│   │   ├── csr_perf_counter.v         # 性能计数器
│   │   │
│   │   └── pipeline/                  # [P2] 流水线冲刺
│   │       ├── if_id.v                # IF→ID 流水寄存器
│   │       ├── id_ex.v                # ID→EX 流水寄存器
│   │       ├── ex_mem.v               # EX→MEM 流水寄存器
│   │       ├── mem_wb.v               # MEM→WB 流水寄存器
│   │       ├── forwarding_unit.v      # 数据前推
│   │       ├── hazard_detection.v     # 冒险检测
│   │       └── btb.v                  # 分支目标缓冲
│   │
│   ├── memory/                        # ★ 存储器与总线
│   │   ├── instr_mem.v                # 指令 BRAM
│   │   ├── data_mem.v                 # 数据 BRAM
│   │   ├── mem_bus.v                  # 总线控制器（地址译码+仲裁）
│   │   └── mmio_decoder.v             # MMIO 地址二级译码
│   │
│   └── io/                            # ★ 外设控制器（统一6端口接口）
│       ├── io_interface.vh            # 外设接口宏定义
│       ├── gpio_led.v                 # LED 输出
│       ├── gpio_switch.v              # 拨码开关输入
│       ├── seg7_driver.v              # 七段数码管扫描显示
│       ├── uart_rx.v                  # [P2] UART 接收
│       ├── uart_tx.v                  # [P2] UART 发送
│       ├── timer.v                    # [P1] 定时器
│       ├── pwm.v                      # [P1] PWM
│       ├── buzzer.v                   # [P2] 蜂鸣器
│       └── watchdog.v                 # [P2] 看门狗
│
├── sim/
│   ├── tb/
│   │   ├── tb_alu.v
│   │   ├── tb_regfile.v
│   │   ├── tb_control_unit.v
│   │   ├── tb_cpu_basic.v
│   │   ├── tb_mac.v
│   │   ├── tb_perf_counter.v
│   │   ├── tb_soc_top.v
│   │   └── tb_pipeline_hazard.v       # [P2]
│   ├── programs/
│   │   ├── basic.hex
│   │   ├── load_store.hex
│   │   ├── branch.hex
│   │   ├── dot_product_normal.hex
│   │   ├── dot_product_mac.hex
│   │   └── gen_mem.py
│   └── wave/                          # 波形输出（不提交）
│
├── tests/
│   ├── basic/                         # B负责
│   ├── load_store/                    # B负责
│   ├── branch/                        # B负责
│   ├── mac/                           # D负责
│   ├── perf/                          # D负责
│   ├── mmio/                          # C负责
│   └── hazard/                        # [P2] D负责
│
├── reports/
│   ├── vivado/                        # C负责
│   ├── tables/                        # D负责
│   ├── figures/                       # 全员
│   └── final_report/                  # A整合
│
├── scripts/
│   ├── gen_mem.py
│   └── vivado_build.tcl
│
├── docs/
│   ├── PROJECT_INDEX.md
│   ├── design/                        # 已冻结的设计文档
│   ├── team/                          # 团队协作文档
│   ├── hardware/                      # 硬件资料
│   ├── course/                        # 课程资料
│   ├── ai_logs/                       # AI使用日志
│   └── planning/                      # 规划文档
│
├── ref_repos/                         # ★ 四个参考仓库（只读参考）
│   ├── NCUT_MiniSys/
│   ├── SUSTech_CS202/
│   ├── SEU_Class2_minisys/
│   └── SEU_Group16_minisys/
│
└── 安装包资料/                         # 老师原始资料（不提交Git）
```

---

## 五、分阶段实施计划

### 阶段一：基础设施统一（当前→第1天）

**目标**：建立统一的代码框架、宏定义和接口规范

| 序号 | 任务 | 借鉴来源 | 负责人 | 输出 |
|---|---|---|---|---|
| 1.1 | 编写 `src/core/public.vh` 全局头文件 | ③+④ define.v | A+B | RV32I 编码宏、ALUOP宏、IO地址宏 |
| 1.2 | 编写 `src/io/io_interface.vh` 外设接口规范 | ③ public.v | A+C | 6端口统一外设接口宏 |
| 1.3 | 重构 `src/board/minisys_top.v` | ②+③ minisys_top | C | 复位转换+SOC_TOP切换保持 |
| 1.4 | 建立 `constraints/minisys.xdc` 与三个约束交叉验证 | ②+③+④ .xdc | C | 验证报告 |
| 1.5 | 建立 `ref_repos/` 目录，放置四个参考仓库 | ①+②+③+④ | A | 只读参考 |

**验收标准**：
- `public.vh` 覆盖本项目所有 RV32I 指令和 ALU 操作编码
- `io_interface.vh` 定义外设地址与6端口模板
- 约束验证通过（Y18=clk, P20=rst, LED/SW/SEG 引脚完全一致）

---

### 阶段二：P0 保底 CPU 模块实现（第1-3天）

**目标**：多周期 FSM CPU 能在 xsim 下跑通 basic program

| 序号 | 任务 | 借鉴来源 | 负责人 | 输出 |
|---|---|---|---|---|
| 2.1 | 实现 `alu.v`（6类ALU操作） | ④ Ex_1.v ALU分类 | B | ALU单测通过 |
| 2.2 | 实现 `regfile.v`（3读1写+内部前推） | ① regfile.v + 本项目rd_old | B | regfile单测通过 |
| 2.3 | 实现 `imm_gen.v`（5种立即数格式） | RV32I 规范 | B | 译码正确 |
| 2.4 | 实现 `control_unit.v`（RV32I译码） | ③ id.v 译码框架改造 | B | 控制信号正确 |
| 2.5 | 实现 `branch_unit.v` + `pc_reg.v` | ③ pc.v 改造 | B | 分支/NPC正确 |
| 2.6 | 实现 `cpu_top.v`（多周期FSM, 6状态） | 本项目FSM设计 | B | basic program 到 EBREAK |
| 2.7 | 实现 `csr_perf_counter.v` | 本项目（独创） | D | cycle/instret/mac 计数正确 |
| 2.8 | 实现 `mac_unit.v`（组合逻辑乘加） | 本项目（独创） | D | MAC单测通过 |

**验收标准**：
- basic program (`tests/basic/`) xsim 仿真通过
- `done=1, error=0, x5=1`
- 波形可解释 FETCH→DECODE→EXECUTE→MEMORY→WRITEBACK 流程

---

### 阶段三：SoC 总线与存储器（第2-4天）

**目标**：CPU 能通过总线访问 data_mem 和 MMIO

| 序号 | 任务 | 借鉴来源 | 负责人 | 输出 |
|---|---|---|---|---|
| 3.1 | 实现 `instr_mem.v`（$readmemh 初始化） | ② inst_rom.v | C | 取指正确 |
| 3.2 | 实现 `data_mem.v`（32-bit LW/SW） | ② dmemory32.v | C | 读写正确 |
| 3.3 | 实现 `mmio_decoder.v`（二级地址译码） | ③ arbitration.v 改造 | C | 地址区分正确 |
| 3.4 | 实现 `mem_bus.v`（总线控制器+仲裁） | ③ arbitration.v | C | data_mem/MMIO 通路正常 |
| 3.5 | 实现 `gpio_led.v`（6端口接口） | ③ leds.v | C | LED 状态寄存 |
| 3.6 | 实现 `gpio_switch.v`（6端口接口） | ③ switches.v | C | 拨码读取正确 |
| 3.7 | 实现 `seg7_driver.v`（低有效扫描） | ④ nixieTube.v | C | 十六进制0-F显示 |
| 3.8 | 实现 `soc_top.v`（CPU+内存+MMIO集成） | ③ minisys.v | C+A | 系统仿真连通 |
| 3.9 | 实现 `display_mux.v`（拨码选择显示） | 本项目 | C | result/cycle可切换 |

**验收标准**：
- CPU 通过 bus 访问 data_mem LW/SW 正确
- MMIO 地址译码正确，LED/SEG7 寄存器可读写
- soc_top xsim 仿真连通

---

### 阶段四：MAC 集成与点积对比（第4-5天）

**目标**：普通点积和 MAC 点积结果一致，性能数据可比较

| 序号 | 任务 | 借鉴来源 | 负责人 | 输出 |
|---|---|---|---|---|
| 4.1 | MAC 控制信号接入 `control_unit` | 本项目 | B+D | `is_mac`/`wb_sel` 正确译码 |
| 4.2 | MAC 写回路径接入 `cpu_top` | 本项目 | B+D | `mac_result → rd` 正确 |
| 4.3 | 准备普通点积测试程序（RV32I 汇编） | 本项目 | D | 手工 hex |
| 4.4 | 准备 MAC 点积测试程序 | 本项目 | D | 手工 hex |
| 4.5 | xsim 仿真对比：结果+周期+CPI | 本项目 | D | result 一致 |
| 4.6 | PPA 表初稿（LUT/FF/BRAM/DSP/Timing） | — | C+D | 有数据来源 |

**验收标准**：
- 普通点积 result == MAC 点积 result
- MAC 版本 `mac_count > 0`
- PPA 初稿包含所有字段

---

### 阶段五：Vivado 综合与上板验证（第5-6天）

**目标**：bitstream 生成，上板演示

| 序号 | 任务 | 借鉴来源 | 负责人 | 输出 |
|---|---|---|---|---|
| 5.1 | Vivado 最小工程建立 | ②+③ EDA_Xilinx 流程 | C | 工程文件 |
| 5.2 | Synthesis → Implementation → Bitstream | — | C | bit 文件 |
| 5.3 | 上板：LED 状态显示 | 本项目 board_demo | C | 照片 |
| 5.4 | 上板：数码管 result/cycle 显示 | 本项目 board_demo | C | 照片 |
| 5.5 | Utilization + Timing 报告 | — | C | 截图留存 |
| 5.6 | PPA 表终稿 | — | D+A | 数据复检 |

**验收标准**：
- bitstream 可生成，无 critical warning
- LED/数码管上板显示正常
- 有完整的 utilization/timing 截图

---

### 阶段六：P1/P2 流水线冲刺（第6-7天，视进度）

**目标**：五级流水线基础可用，或至少完成设计文档

| 序号 | 任务 | 借鉴来源 | 负责人 | 输出 |
|---|---|---|---|---|
| 6.1 | 流水线寄存器 (if_id/id_ex/ex_mem/mem_wb) | ①+③ | D+B | P1 |
| 6.2 | 数据前推 (forwarding_unit) | ① id.v 前推 | D+B | P1 |
| 6.3 | 冒险检测 (hazard_detection) | ③ ppl_scheduler | D+B | P1 |
| 6.4 | BTB 分支预测 (可选) | ④ BTB.v | D | P2 |
| 6.5 | CSR 基础异常 (可选) | ④ CP0.v→RV32I CSR | D | P2 |
| 6.6 | UART 输出统计 (可选) | ②+③ uart_bmpg | C | P2 |

---

## 六、统一接口规范

### 6.1 外设统一 6 端口接口

> 借鉴 ③ SEU minisys 的外设接口设计，所有 `src/io/` 下的外设模块必须遵循此规范。

```verilog
// 外设统一接口模板
module peripheral_template (
    input  wire         clk,          // 时钟
    input  wire         rst,          // 高有效复位
    input  wire [31:0]  addr,         // 32位地址总线
    input  wire         en,           // 使能（高有效）
    input  wire [3:0]   byte_sel,     // 字节选择
    input  wire [31:0]  data_in,      // 写数据
    input  wire         we,           // 写使能（1=写，0=读）
    output wire [31:0]  data_out      // 读数据（→仲裁器）
);
```

### 6.2 MMIO 地址映射（RV32I 统一版）

> 综合借鉴 ② SUSTech 的 `ALU_o[31:10]==22'h3FFFFF` 方案和
> ③ SEU minisys 的 `addr[31:10]=={20'hFFFFF, 2'b11}` + `addr[9:4]` 外设选择方案，
> 统一为本项目的 MMIO 地址映射。

```text
地址空间划分：
  addr[31:28] == 4'h0  →  Instruction Memory / Data Memory
  addr[31:28] == 4'h1  →  MMIO 空间
  addr[31:28] == 4'hF  →  保留（UART/VGA等扩展）

MMIO 二级译码（addr[7:4] 外设选择）：
  0x1000_0000  4'h0  → LED          (W)
  0x1000_0004  4'h0  → SWITCH       (R)
  0x1000_0008  4'h0  → SEG7         (W)
  0x1000_000C  4'h0  → cycle_count  (R)
  0x1000_0010  4'h0  → instret_count(R)
  0x1000_0014  4'h0  → mac_count    (R)
  0x1000_0018  4'h0  → result_reg   (R/W)
  0x1000_001C  4'h0  → status_reg   (R)
  0x1000_0020  4'h0  → UART TXDATA  (W) [P2]
  0x1000_0024  4'h0  → UART STATUS  (R) [P2]
  0x1000_0030  4'h0  → Timer Ctrl   (R/W) [P1]
  0x1000_0034  4'h0  → Timer Data   (R) [P1]

非法地址：读返回 0，写忽略，status_reg.error=1
```

### 6.3 CPU-Memory 总线信号

```verilog
// CPU 侧（主设备，唯一）
output [31:0]  bus_addr;        // 地址总线
output [31:0]  bus_write_data;  // 写数据总线
output         bus_enable;      // 总线使能
output         bus_we;          // 写使能（0=读 1=写）
output [3:0]   bus_byte_sel;    // 字节选择
input  [31:0]  bus_read_data;   // 读数据（来自仲裁器）
```

---

## 七、风险控制与降级

| 风险 | 概率 | 影响 | 降级方案 | 触发时间 |
|---|---|---|---|---|
| MIPS→RV32I 译码改造出错 | 中 | 高 | 从最小的 ALU+regfile 开始验证，逐模块增量 | 第1天发现立即修 |
| 共享总线仲裁时序不收敛 | 中 | 高 | 退回直连方式，data_mem 和 MMIO 用简单地址判断 | 第4天末 |
| MAC 第三读口 timing 不过 | 中 | 中 | 降级为 x31 累加器方案 | 第5天末 |
| 流水线冒险处理不完 | 高 | 低 | 保留为文档+展望，不影响主线验收 | 第6天末 |
| Vivado IP 核不兼容 | 低 | 高 | 全部改用行为级 `$readmemh` 模型 | 第5天初 |
| 板级端口不一致 | 低 | 高 | 三个 .xdc 交叉验证已确认引脚一致 | 已消除 |

---

## 八、关键技术决策记录

| 编号 | 决策 | 理由 | 确认人 | 日期 |
|---|---|---|---|---|
| D-01 | RV32I 不变，不从 MIPS | 课程需求+MAC自定义ISA扩展 | A | 2026-07-06 |
| D-02 | P0=多周期FSM, P1/P2=流水线 | 先保底后冲刺 | A | 2026-07-06 |
| D-03 | 总线采用 ③ SEU minisys 仲裁模式 | 最成熟的共享总线+外设统一接口 | 待确认 | 2026-07-07 |
| D-04 | 外设统一 6 端口接口 | 标准化，易扩展 | 待确认 | 2026-07-07 |
| D-05 | MMIO 地址 `addr[31:28]==4'h1` | 与现有 memory_map.md 一致 | 待确认 | 2026-07-07 |
| D-06 | P0 全行为级 BRAM（不用 Vivado IP） | 便于 xsim 仿真和无 IP 依赖 | 待确认 | 2026-07-07 |
| D-07 | 合并统一采用 Verilog（不用 VHDL） | 团队熟悉度+本课程要求 | 待确认 | 2026-07-07 |

---

## 九、参考仓库文件对照速查表

### 9.1 如何阅读四个参考仓库的代码

| 如果你想实现... | 先看本项目文档 | 再看参考仓库文件 |
|---|---|---|
| ALU | `docs/design/isa.md` §3 | ④ `Ex_1.v` → ALU六分类 + ③ `alu.v` → 运算实现 |
| 寄存器堆 | `docs/design/interfaces.md` §2 | ① `regfile.v` → 双口读+前推 + ③ `gpr.v` → 完整实现 |
| 控制单元 | `docs/design/isa.md` §7 | ③ `id.v` → 译码框架 + ④ `define.v` → 编码定义 |
| 总线/仲裁 | `docs/design/memory_map.md` §4 | ③ `arbitration.v` → 仲裁器 + ③ `minisys.v` → 总线连接 |
| MMIO 地址译码 | `docs/design/memory_map.md` §4 | ② `memio.sv` → IO地址检查 + ③ `arbitration.v` → case译码 |
| LED | `docs/design/board_demo.md` §4 | ③ `leds.v` → 6端口LED + ② `led.sv` → 分时写 |
| 拨码开关 | `docs/design/board_demo.md` §3 | ③ `switches.v` + ② `switch.sv` |
| 数码管 | `docs/design/board_demo.md` §5 | ④ `nixieTube.v` → 低有效共阳极扫描 |
| 流水线寄存器 | `docs/design/architecture.md` §12 | ①/③ `if_id.v` `id_ex.v` `ex_mem.v` `mem_wb.v` |
| 数据前推 | — | ① `id.v` → 源操作数前推逻辑（EX/MEM/WB三级） |
| 分支预测 | — | ④ `BTB.v` → 分支目标缓冲 |
| 异常处理 | — | ④ `CP0.v` → MIPS CP0 框架（可改造为 RV32I CSR） |
| MAC | `docs/design/mac_extension.md` | 本项目独创（无直接参考） |
| 性能计数器 | `docs/design/performance.md` | 本项目独创（无直接参考） |
