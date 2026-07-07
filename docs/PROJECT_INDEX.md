# 项目文件清单与内容索引

> 用途：给 B/C/D 队友及其 AI agent 提供项目全貌，方便快速定位文件、理解内容和避免越界修改。
> 最后更新：2026-07-07

---

## 目录树总览

```text
.
├── README.md                          ← 项目入口，先读这个
├── .gitignore                         ← 禁止提交 Vivado 临时文件、安装包
├── constraints/
│   └── minisys.xdc                    ← Minisys 主线约束（已冻结）
├── src/
│   ├── board/minisys_top.v            ← 板级顶层（已实现外壳，SOC_TOP 分支未激活）
│   ├── soc/                           ← SoC 顶层（空目录，待 C 实现）
│   ├── core/                          ← CPU 核心模块（空目录，待 B 实现）
│   ├── memory/                        ← BRAM/mem_bus（空目录，待 C 实现）
│   └── io/                            ← GPIO/seg7（空目录，待 C 实现）
├── sim/
│   ├── tb/                            ← testbench（空目录）
│   ├── programs/                      ← 汇编/机器码（空目录）
│   └── wave/                          ← 波形输出（不提交）
├── tests/
│   ├── basic/                         ← 基础指令测试（空目录，B 负责）
│   ├── load_store/                    ← 访存测试（空目录，B 负责）
│   ├── branch/                        ← 分支测试（空目录，B 负责）
│   ├── mac/                           ← MAC 点积测试（空目录，D 负责）
│   ├── perf/                          ← 性能计数测试（空目录，D 负责）
│   ├── mmio/                          ← MMIO 测试（空目录，C 负责）
│   └── hazard/                        ← 流水线冲刺测试（空目录，D 负责）
├── reports/
│   ├── vivado/                        ← Vivado 报告截图（C 负责）
│   ├── tables/                        ← PPA 表格（D 负责）
│   ├── figures/                       ← 架构图/波形图
│   └── final_report/                  ← 最终报告
├── scripts/                           ← 辅助脚本（空目录）
├── docs/
│   ├── PROJECT_INDEX.md               ← 【本文件】项目文件索引
│   ├── design/                        ← 设计文档（冻结的接口/ISA/memory map 在这里）
│   ├── team/                          ← 分工/流程/检查清单
│   ├── ai_logs/                       ← AI 使用日志
│   ├── planning/                      ← 阶段规划记录
│   ├── hardware/                      ← Minisys 硬件手册和管脚核对
│   └── course/                        ← 课程任务书
└── 安装包资料/                         ← 老师原始资料（不提交 Git，不用于主线编码）
```

---

## 一、根目录文件

### `README.md`
**项目入口，所有成员先读。**

内容：项目概况、主线定义、仓库目录、四人角色表、组员阅读顺序、协作入口、环境准备、当前约束状态、项目状态、B/C/D 队友快速开始（每人先读哪些文件、第一轮做什么）、资料与安装口径、下一步顺序、开发前规则。

### `.gitignore`
禁止提交：Vivado 工程文件（`.runs/`、`.sim/`、`.xpr` 等）、仿真波形、安装包资料目录、IDE 配置、Python 缓存。

---

## 二、`docs/design/` — 设计文档

> **标注**：🔒 = 已冻结不可私自改；✏️ = 可补充但需 A 确认；📝 = 参考/规划用

### 🔒 `isa.md`
**RV32I 子集指令编码与 MAC 自定义指令定义。**

内容：第一版支持的指令列表（ADD/SUB/ADDI/AND/OR/XOR/LW/SW/BEQ/BNE/JAL/EBREAK）、指令格式编码表、MAC 指令编码（opcode=0001011, funct7=0000001）、EBREAK/HALT 编码 `0x00100073`、非法指令处理策略。

### 🔒 `memory_map.md`
**地址空间与 MMIO 寄存器定义，所有地址译码必须据此实现。**

内容：BRAM 指令区 `0x0000_0000-0x0FFF`、数据区 `0x0000_1000-0x1FFF`、MMIO 区：LED(`0x1000_0000`)、SWITCH(`0x1000_0004`)、SEG7(`0x1000_0008`)、cycle_count(`0x1000_000C`)、instret_count(`0x1000_0010`)、mac_count(`0x1000_0014`)、result_reg(`0x1000_0018`)、status_reg(`0x1000_001C`)、UART reserved(`0x1000_0020`)；地址译码建议 `addr[31:28]==0x1` 为 MMIO；非法地址读返回 0、写忽略。

### 🔒 `interfaces.md`
**所有模块的端口规范，变更必须先改此文件并由 A 确认。**

内容：全局信号规范（clk/rst 高有效/32-bit 数据/5-bit 寄存器号）、regfile(3读1写含 rd_old 第三读口)、alu、control_unit、imm_gen、branch_unit、mac_unit、csr_perf_counter、instr_mem、data_mem、mem_bus、gpio_led、gpio_switch、seg7_driver、soc_top、minisys_top 的端口表。**板级端口映射表**（clk/rst_n/sw/led/seg/an 与 .xdc 和 soc_top 内部端口的对应关系）。接口变更七步流程。

### 🔒 `board_constraints_audit.md`
**从老师原始资料到项目主线 `.xdc` 的核对过程记录。**

内容：扫描范围、8 个候选约束文件的来源和判断、最终采用 `constraints/minisys.xdc` 的依据、端口清单、被排除项（Nexys4/Basys3 约束）、未确认项（P20 复位极性需上板复核）。

### 🔒 `board_demo.md`
**上板演示方案：LED/拨码/数码管的约定和演示流程。**

内容：演示目标、拨码功能分配（SW1:0 选显示、SW2 选模式）、LED 约定（LED0=running, LED1=done, LED2=error, LED3=mac_mode, LED7=heartbeat）、数码管十六进制显示、普通点积/MAC 点积演示流程、周期数对比方法、异常降级方案、留存材料清单。

### 📝 `architecture.md`
**系统总体架构说明。**

内容：P0/P1/P2 三级目标定义、选多周期 FSM 的原因、系统框图（minisys_top→soc_top→cpu_top+mems+mmio）、CPU 核心结构、SoC 结构、6 状态 FSM（FETCH/DECODE/EXECUTE/MEMORY/WRITEBACK/HALT）、取指/访存/MMIO 流程、MAC 接入 EXECUTE 阶段、性能计数器位置、迁移到流水线的路径。

### 📝 `mac_extension.md`
**MAC 自定义指令的完整设计文档。D 必读。**

内容：设计动机、指令语义 `rd_new = rd_old + rs1 * rs2`、R-type custom-0 编码、regfile 第三读口方案、数据通路修改点、控制信号（is_mac/mac_enable/wb_sel/mac_count_en）、FSM 中 MAC 执行流程、性能计数器关系、点积测试规划、风险与降级（第三读口→x31 累加、组合乘加→多周期）。

### 📝 `performance.md`
**性能计数器与 PPA 数据规划。D 必读。**

内容：cycle_count/instret_count/mac_count 的定义和加 1 条件、CPI=speedup 公式、点积对比方法、Vivado utilization 记录字段（LUT/FF/BRAM/DSP/IO）、timing 记录字段（WNS/TNS/Fmax）、PPA 表格模板（基础 CPU / 基础 CPU+MAC / 流水线冲刺版三行）、报告截图清单。

### ✏️ `risk_plan.md`
**风险识别与降级方案。**

内容：风险等级定义、12 项风险表（MAC 第三读口/100MHz timing/数码管/BRAM 初始化/流水线/.xdc/误用其他板卡约束/电平搞反/端口不一致/机器码手工错/AI 接口不一致/Git 冲突）、降级口径、触发降级时间点。

### ✏️ `task_board.md`
**任务看板：所有任务的优先级、负责人、路径、依赖、完成标准、当前状态。**

内容：P0（保底）9 项、P1（主线）13 项、P2（冲刺）4 项；每项含负责人/路径/依赖/完成标准/状态；成员职责索引；Git 提交节点建议。**当前所有 RTL 均为 TODO，文档类为 DONE。**

### ✏️ `development_rules.md`
**小组统一开发规范。**

内容：协作总原则、按成员分工的修改约束（谁可以改什么、禁止改什么）、RTL 编码规范（命名/位宽/x0/no latch）、复位规范、always 块规范、接口变更八步流程、Git 分支规范、AI 使用规范、调试日志规范、Code Review 规则、禁止事项 7 条。

### ✏️ `test_plan.md`
**测试程序与仿真计划。**

内容：测试总原则（xsim 主流程）、测试路径、6 类测试程序（basic/load_store/branch/mmio/perf/mac）、pass/fail 标准、xsim 仿真命令参考、波形检查方法、测试记录要求。

### 📝 `guide_feasibility_review.md`
**项目 B 开发指南可行性检查结果。**

内容：组长确认的 10 项口径（RV32I 子集/多周期 FSM/MAC 第三读口/EBREAK/约束已确认等）、三级目标分级、不推荐的路线、需进一步明确的开放项。

### 📝 `project_paths.md`
**项目目录与文件路径规划。**

内容：资料保留路径、设计文档路径、AI 日志路径、RTL 源码路径、仿真与测试路径、约束/脚本/报告路径、归档路径。

### 📝 `项目B_vibecoding开发指南.md`
**原始项目开发指南（较长，约 200 行）。**

内容：项目定位（基础/进阶/拓展三层）、硬件平台、RV32I 子集定义、SoC 结构、MAC 方案、流水线规划、PPA 方案、分工建议、开发节奏、验收标准。**以 `architecture.md` + `isa.md` + `memory_map.md` + `interfaces.md` 的拆分版本为准。**

---

## 三、`docs/team/` — 团队协作文档

### `member_roles.md`
**四人角色总表、每人详细职责清单、接口协作关系、每日同步机制、报告分工表。**

A/B/C/D 各有：职责清单、负责文件路径表、测试职责、报告职责、完成标准、禁止越界事项。末尾有接口协作关系矩阵和报告章节分工表。

### `bcd_onboarding.md`
**B/C/D 队友开发入口与 AI Agent 上下文。每人先读这个。**

内容：项目一句话说明、已完成/未完成项、三人共同禁止事项、B/C/D 各自的开发边界（负责文件 + 第一轮任务 + 验收标准 + 禁止修改项 + 完成后输出）、**完整的 AI agent 提示语**（可直接复制给 Codex/ChatGPT，包含项目背景、只能修改的路径、必须遵守的规则、第一轮任务、完成后输出要求）。

### `setup_checklist.md`
**组员环境与资料准备清单。**

内容：全员必装（Vivado 2018.3/Git/VS Code）、全员必读、B/C/D 各自的必看/可选/不需要研究的资料清单（含具体文件名如 `Minisys资源信息.docx`、`Minisys基础开发.zip`、`EES329b功能测试20170817.pdf`）、不用于主线的资料、安装完成后自检。

### `daily_workflow.md`
**每日协作流程。**

内容：每天开始前同步模板（昨日完成/今日目标/接口变更/阻塞问题+每人写清修改文件/接口变更/协作/测试方式）、开发中任务状态更新规则、每天结束前必须补充（完成文件/仿真/截图/日志/影响模块/阻塞）、AI 日志记录规则、调试日志记录、PR 合并流程、**互不干扰规则**（B 改 src/core、C 改 src/memory+io+soc+board+constraints、D 改 mac+perf+tests+reports/tables、公共文档由 A 确认）、进度延误与降级、每日最小完成标准。

### `review_checklist.md`
**RTL/文档/合并前检查清单。**

内容：RTL 模块提交前检查 13 项（模块名/端口/clk_rst/阻塞非阻塞/default/x0/位宽/magic number/testbench/xsim）、文档提交前检查 8 项、合并前检查 8 项、成员专项检查（每人必查项不同）、不允许合并的 7 种情况。

### `team_division.md`
**小组分工入口索引**（指向 `docs/planning/team_division.md`，仅作路径索引）。

---

## 四、`docs/ai_logs/` — AI 使用日志

### `ai_usage_log.md`
**所有 AI 使用记录总表。**

内容：记录模板、记录要求、5 条已记录的使用（AI-20260706-01/02/03：项目资料整理+MVP文档+分工协作；AI-20260707-01：Minisys 约束核对和顶层端口统一；AI-20260707-02：提交前协作文档完善）。每条含日期/成员/模块/工具/提示词摘要/输出摘要/验证方式/是否合并。**每次 AI 使用必须追加。**

---

## 五、`docs/planning/` — 阶段规划记录

### `round1_initial_plan.md`
**第一轮初步规划日志**（2026-07-06）。ISA 决策、拓展策略、目标分级、仓库初始化。

### `round2_mvp_plan.md`
**第二阶段 MVP 规划记录**（2026-07-06）。组长确认的 6 项决策、最小可行系统定义、文件生成清单、组员阅读顺序。

### `team_division.md`
**四人小组正式分工文档**（最详细版，约 300 行）。已确认约束、分工总原则、A/B/C/D 各自定位+具体职责表+负责文件表+测试任务+完成标准、测试与性能拆分总表（27 行）、一周开发节奏建议（7 天每天每人做什么）、报告撰写分工（12 个章节）。

### `four_repo_deep_merge_plan.md` 🆕
**四仓库深度合并方案**（约 400 行）。基于六个开源仓库（NCUT_MiniSys / SUSTech CS202 / SEU-Class2 / SEU-Group16 / riscv-minisys-cpu / minisys_unified）的深度分析，制定的完整合并蓝图。包含：架构选型（P0多周期FSM→P1流水线→P2 BTB）、组件来源决策表（CPU/总线/外设从哪个仓库借鉴）、MIPS→RV32I 改造路径（编码/控制信号/ALU映射）、合并后完整目录结构、6阶段实施计划、统一接口规范、风险控制与降级方案、关键技术决策记录、参考仓库文件对照速查表。

### `integration_report.md` 🆕
**四仓库深度合并整合报告**（约 500 行，组长A撰写）。记录组长A完成的代码整合工作全过程。包含：六仓库选型分析（每个仓库的可取之处和不可用原因）、合并过程中的4个关键设计决策（总线地址空间选择/ALU操作码扩展/多周期FSM状态设计/CPU_MODE参数化）、一致性验证报告（板级约束100%一致/ISA编码完全一致/接口满足规范/内存映射一致）、24个RTL文件的生成追溯与改造程度分类、当前项目功能清单。**本报告是本项目"深度整合"而非"简单复制"的核心证据**，体现组长A的架构选型思考过程。

---

## 六、`docs/hardware/` — 硬件资料

### `minisys_pinout.md`
**Minisys 约束核对结论与完整引脚表。C 必读。**

内容：确认 `Minisys_Master.xdc` 为主约束来源、4 个辅助核对来源、项目 6 个端口定义、完整引脚表（clk=Y18, rst_n=P20, sw[0]-sw[15] 16 个引脚, led[0]-led[15] 16 个引脚, an[0]-an[7] 8 个引脚, seg[0]-seg[7] 8 个引脚）、暂不进入主线的资源。

### `Minisys硬件手册1.1.pdf`
Minisys 主板完整硬件手册 PDF。了解 Artix-7 XC7A100T、BRAM、DSP48E1、时钟资源、板上外设。

### `EES329b功能测试20170817.pdf`
EES-329B 扩展板功能测试说明 PDF。只作为扩展板/上板流程参考，**不作为主线**。

---

## 七、`docs/course/` — 课程资料

| 文件 | 说明 |
|---|---|
| `2026项目式课程阶段二-修订完成版.pdf` | 课程任务书与验收规则 |
| `2024版课程教学大纲-项目式课程阶段2.doc` | 课程目标与考核支撑 |
| `vivado.docx` | Vivado 2018.3 和 ModelSim 环境说明 |

---

## 八、`constraints/` — 约束文件

### `minisys.xdc`
**Minisys 项目主线约束（已冻结，不可乱改管脚号）。**

内容：clk(Y18, 100MHz, 10ns 周期)、rst_n(P20)、sw[15:0] 16 个引脚（LVCMOS15）、led[15:0] 16 个引脚（LVCMOS33/LVCMOS15）、an[7:0] 8 个位选引脚（LVCMOS33）、seg[7:0] 8 个段选引脚（LVCMOS33, seg[0]=CA ... seg[7]=DP）。来源注释完整。

---

## 九、`src/` — RTL 源码（✅ 四仓库深度合并完成）

### `src/core/` — CPU 核心（24个文件中最核心的部分）

| 文件 | 状态 | 负责人 | 说明 |
|---|---|---|---|
| `public.vh` | ✅ 已生成 | A | 全局宏定义：RV32I+MIPS opcode、ALUOP六分类、总线宽度、内存映射、外设地址 |
| `alu.v` | ✅ 已生成 | B | ALU：支持6类运算（NOP/ARITH/LOGIC/MOVE/SHIFT/JUMP/MAC），组合逻辑 |
| `regfile.v` | ✅ 已生成 | B | 寄存器堆：3读1写，x0硬连线=0，内置写后读前推 |
| `imm_gen.v` | ✅ 已生成 | B | 立即数生成器：I/S/B/U/J 五种RV32I格式 |
| `branch_unit.v` | ✅ 已生成 | B | 分支判断：BEQ/BNE/BLT/BGE/BLTU/BGEU 六种条件 |
| `pc_reg.v` | ✅ 已生成 | B | 程序计数器：pc+4/分支/跳转/JALR，含stall输入 |
| `control_unit.v` | ✅ 已生成 | B | 控制单元：RV32I 31条指令 + MAC自定义指令译码 |
| `mac_unit.v` | ✅ 已生成 | D | MAC乘加单元：rd_new=rd_old+rs1*rs2，组合逻辑 |
| `csr_perf_counter.v` | ✅ 已生成 | D | 性能计数器：cycle_count/instret_count/mac_count |
| `riscv_mc_cpu.v` | ✅ 已生成 | B+A | **★ RV32I多周期FSM CPU**：6状态（FETCH→DECODE→EXECUTE→MEMORY→WRITEBACK→HALT） |
| `riscv_mc_wrapper.v` | ✅ 已生成 | A | MC CPU→统一总线适配wrapper |
| `cpu_top.v` | ✅ 已生成 | A | CPU模式选择器：generate块按CPU_MODE参数实例化不同CPU |
| `pipeline/` | 📝 预留 | D(P2) | P2流水线冲刺：if_id/id_ex/ex_mem/mem_wb/forwarding/hazard/btb |

### `src/bus/` — 总线系统（借鉴SEU-Class2）

| 文件 | 状态 | 说明 |
|---|---|---|
| `bus_decoder.v` | ✅ 已生成 | 地址解码器：addr[31:0]→DataRAM/12个外设片选，addr[9:4]二级译码 |
| `bus_mux.v` | ✅ 已生成 | 读数据多路选择器：14选1优先级MUX |

### `src/memory/` — 存储器（行为级BRAM）

| 文件 | 状态 | 说明 |
|---|---|---|
| `inst_ram.v` | ✅ 已生成 | 指令BRAM：组合读，支持UART编程写入端口 |
| `data_ram.v` | ✅ 已生成 | 数据BRAM：同步写/组合读，字节使能，小端序 |

### `src/io/` — 外设控制器（统一6端口接口）

| 文件 | 状态 | 说明 |
|---|---|---|
| `gpio_led.v` | ✅ 已生成 | LED输出：16位寄存器，地址0xFFFF_FC00 |
| `gpio_switch.v` | ✅ 已生成 | 拨码开关输入：2级同步器防亚稳态，地址0xFFFF_FC10 |
| `seg7_driver.v` | ✅ 已生成 | 七段数码管：共阳极动态扫描~381Hz，地址0xFFFF_FC20 |

### `src/common/` — 通用模块

| 文件 | 状态 | 说明 |
|---|---|---|
| `sync.v` | ✅ 已生成 | 参数化N级同步器（默认2级） |
| `debounce.v` | ✅ 已生成 | 按键消抖（20ms@50MHz） |
| `edge_det.v` | ✅ 已生成 | 边沿检测器（上升沿/下降沿/任意沿） |

### `src/soc/` / `src/board/` — 系统集成

| 文件 | 状态 | 说明 |
|---|---|---|
| `soc_top.v` | ✅ 已生成 | SoC集成：CPU+inst_ram+总线解码+data_ram+12外设+总线MUX |
| `minisys_top.v` | ✅ 已更新 | 板级顶层：`ifdef MINISYS_USE_SOC_TOP` 切换统一SoC/心跳占位 |

---

## 十、`sim/` `tests/` `reports/` `scripts/` — 仿真/测试/报告/脚本

所有目录已初始化（含 `.gitkeep`），当前为空，等待 RTL 实现后填充。

| 目录 | 负责人 | 用途 |
|---|---|---|
| `sim/tb/` | B/D | testbench（tb_alu, tb_regfile, tb_cpu_basic, tb_mac, tb_perf_counter） |
| `sim/programs/` | B/D | 汇编/机器码/`.mem` 初始化文件 |
| `tests/basic/` | B | 基础指令测试 |
| `tests/load_store/` | B | LW/SW 测试 |
| `tests/branch/` | B | BEQ/BNE 测试 |
| `tests/mac/` | D | MAC 点积测试 |
| `tests/perf/` | D | 性能计数器测试 |
| `tests/mmio/` | C | MMIO 测试 |
| `tests/hazard/` | D(P2) | 流水线冒险测试 |
| `reports/vivado/` | C | utilization/timing 截图 |
| `reports/tables/` | D | PPA 表格 |
| `reports/figures/` | 全员 | 架构图/波形图/上板照片 |
| `scripts/` | C | Vivado/xsim 辅助脚本 |

---

## 十一、给 AI Agent 的推荐读取顺序

### 所有人的 Agent 先读（5 个文件）
1. `docs/PROJECT_INDEX.md`（本文件）
2. `README.md`
3. `docs/design/isa.md`
4. `docs/design/memory_map.md`
5. `docs/design/interfaces.md`

### B 的 Agent 追加
`docs/design/architecture.md` → `docs/team/bcd_onboarding.md`（第 5、8 节）→ `docs/team/member_roles.md`（第 5 节）

### C 的 Agent 追加
`docs/design/board_demo.md` → `docs/design/board_constraints_audit.md` → `docs/hardware/minisys_pinout.md` → `docs/team/bcd_onboarding.md`（第 6、9 节）

### D 的 Agent 追加
`docs/design/mac_extension.md` → `docs/design/performance.md` → `docs/team/bcd_onboarding.md`（第 7、10 节）

---

## 十二、文件权威性速查

| 类别 | 最权威文件 | 不可私自改 |
|---|---|---|
| ISA 指令编码 | `docs/design/isa.md` | ✅ |
| 地址映射 | `docs/design/memory_map.md` | ✅ |
| 模块端口 | `docs/design/interfaces.md` | ✅ |
| 板级引脚 | `constraints/minisys.xdc` | ✅ |
| 任务状态 | `docs/design/task_board.md` | A 维护 |
| 开发规范 | `docs/design/development_rules.md` | A 维护 |
| 成员分工 | `docs/planning/team_division.md` | A 维护 |
| AI 日志 | `docs/ai_logs/ai_usage_log.md` | 各自追加 |
