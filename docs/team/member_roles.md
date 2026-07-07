# 小组成员分工方案（四仓库深度合并后更新版）

用途：明确四人小组的角色边界、负责路径、测试责任、报告责任、交付标准和协作关系。

最后更新时间：2026-07-08（组长A更新：重新规划ABCD分工，反映统一整合后的新阶段）

## 1. 小组基本信息

| 成员 | 姓名 | 学号 | 角色 |
|---|---|---|---|
| A | 刘文涛 | 2024212936 | 组长 / 架构 / 集成 / 代码整合 / 报告 |
| B | 张淇 | 2024212998 | CPU 数据通路与控制器 / 基础仿真验证 |
| C | 胡文龙 | 2024212582 | SoC / Memory / I/O / 上板验证 / Vivado |
| D | 王博生 | 2024212590 | MAC / 性能计数 / 点积测试 / PPA初稿 / 流水线冲刺 |

组长已确认：姓名和学号全部正确，成员已邀请加入 GitHub 仓库。最终贡献度比例按四人均分，每人 25%。

## 2. 项目方向概述（四仓库深度合并后）

项目方向：基于 Minisys FPGA + EES-329B-V1.1 的 RV32I 子集多周期 CPU + 统一总线 SoC + MAC 指令加速设计。

**已完成的基础铺垫（A 完成）**：
- 6 个开源参考仓库的深度分析与设计模式提取
- 统一总线架构（ibus/dbus + 仲裁器 + 二级地址译码）
- RV32I 多周期 FSM CPU 核心（31条指令 + MAC）
- 标准化外设（LED/Switch/SEG7）的 6 端口 bus slave 接口
- 性能计数器 + MAC 乘加单元
- CPU_MODE 参数化多核切换框架
- 全局宏定义头文件（`public.vh`：RV32I+MIPS+总线+ALU）
- memory_map 更新为统一总线地址映射
- 合并方案文档 + 整合报告

**当前 RTL 状态**：24 个 Verilog 文件，约 2100 行代码已就位，待 xsim 仿真验证。

优先级：

- P0：xsim 仿真验证、Vivado 综合/实现/bitstream、上板演示。
- P1：MAC 点积对比、性能计数器 MMIO 暴露、PPA 初稿。
- P2：流水线、forwarding、stall、flush、UART 等冲刺目标。

## 3. 四人角色总览表（整合后更新）

| 成员 | 角色 | 主要职责 | 负责路径 | 测试职责 | 报告职责 | 完成标准 |
|---|---|---|---|---|---|---|
| A 刘文涛 | 组长 / 架构 / 集成 / 代码整合 / 报告 | 统一总线架构设计、6仓库分析选型、代码级深度合并、文档同步、接口冻结、任务管理、PPA复检、报告整合 | `docs/`、`src/core/public.vh`、`src/bus/`、`src/core/cpu_top.v`、`src/core/riscv_mc_wrapper.v`、`src/soc/`、`src/board/`、`reports/` | 集成测试、PPA数据复检、AI日志检查 | 项目背景、架构选型依据、整合报告、接口规范、贡献度 | 整合质量验证通过，文档与RTL一致，main可运行 |
| B 张淇 | CPU 数据通路与控制器 / 仿真 | xsim 仿真验证、单元 testbench 编写、basic program 调试、CPU 周期数记录 | `src/core/alu.v`、`src/core/regfile.v`、`src/core/control_unit.v`、`src/core/imm_gen.v`、`src/core/branch_unit.v`、`src/core/pc_reg.v`、`src/core/riscv_mc_cpu.v`、`sim/tb/`、`tests/basic/` | ALU单测、regfile单测、control译码验证、cpu_basic xsim仿真、load_store/branch仿真 | CPU数据通路、多周期FSM、基础指令波形 | 基础CPU能在xsim下跑通basic program到EBREAK |
| C 胡文龙 | SoC / Memory / I/O / 上板验证 | Vivado工程建立、综合/实现/bitstream、上板LED/数码管验证、utilization/timing 导出 | `src/memory/`、`src/io/`、`src/soc/soc_top.v`、`src/board/minisys_top.v`、`constraints/minisys.xdc`、`scripts/`、`reports/vivado/` | inst_ram/data_ram测试、MMIO地址译码测试、LED/SEG7上板测试、Vivado综合实现 | 存储系统、MMIO、上板验证、Vivado数据 | bitstream可生成，上板LED/数码管有可展示结果 |
| D 王博生 | MAC / 性能 / 点积测试 / PPA / 冲刺 | mac_unit+perf_counter验证、点积测试程序、性能数据统计、PPA初稿、流水线冲刺 | `src/core/mac_unit.v`、`src/core/csr_perf_counter.v`、`tests/mac/`、`tests/perf/`、`reports/tables/`、`src/core/pipeline/` | MAC单测、MAC集成测试、普通点积/MAC点积对比、周期/CPI统计 | MAC指令、性能计数、点积对比、PPA初稿 | 普通点积和MAC点积result一致，性能数据可比较 |

## 4. A 刘文涛详细职责（整合后更新）

### 4.1 职责清单

**代码整合工作（已完成）**：
- 分析 6 个参考仓库，提取设计模式，制定合并方案
- 编写统一全局头文件 `public.vh`（280行，RV32I+MIPS+总线+ALU六分类+外设地址）
- 设计并实现统一总线架构（`bus_decoder.v` + `bus_mux.v`）
- 集成 CPU_MODE 参数化选择框架（`cpu_top.v`）
- 编写 SoC 集成顶层（`soc_top.v`）和板级顶层更新（`minisys_top.v`）
- 创建 RV32I 多周期 CPU 的统一总线 wrapper（`riscv_mc_wrapper.v`）
- 更新 `memory_map.md` 为统一总线地址映射
- 撰写合并方案文档（`four_repo_deep_merge_plan.md`）
- 撰写整合报告（`integration_report.md`）

**持续职责**：
- 维护 `README.md` 和总体设计文档
- 冻结 ISA、memory map、interfaces
- 审核公共接口变更（7步流程）
- 管理 Git 分支和合并
- 维护任务看板和项目进度
- 检查每位成员 AI 日志
- 复核性能数据、周期数、CPI 和 PPA 表
- 统一最终报告和答辩材料
- 协调上板节奏和降级方案
- 需要时协助 B/C/D 调试集成问题

### 4.2 负责路径

- `README.md`
- `docs/`（全部设计文档、团队文档、规划文档、AI日志）
- `src/core/public.vh`
- `src/core/cpu_top.v`
- `src/core/riscv_mc_wrapper.v`
- `src/bus/bus_decoder.v`
- `src/bus/bus_mux.v`
- `src/common/`
- `src/soc/soc_top.v`
- `src/board/minisys_top.v`
- `constraints/minisys.xdc`（与C协同维护）
- `reports/`

### 4.3 测试职责

- 集成测试：验证 CPU + bus + memory + 外设 全链路连通
- 复核 B/C/D 的 xsim 或 Vivado 结果是否有截图、日志或数据来源
- 复核 `cycle_count`、`instret_count`、`mac_count` 的统计口径
- 复核 PPA 表中的 LUT、FF、BRAM、DSP、timing slack
- 检查 AI 日志是否覆盖实际使用 AI 的过程

### 4.4 报告职责

- 项目背景与总体目标
- 架构选型依据与整合报告（整合过程、设计决策、一致性验证）
- ISA 与 memory map
- 总体架构与协作流程
- PPA 数据复检说明
- 调试问题汇总
- AI 使用说明汇总（含代码整合阶段的AI使用）
- 贡献度说明，全员确认后写入报告

### 4.5 禁止越界事项

- 禁止未经 B/C/D 确认大规模重写其负责模块
- 禁止绕过接口文档直接要求组员改端口
- 禁止为赶进度把未经验证代码合入 `main`

## 5. B 张淇详细职责（整合后更新）

### 5.1 职责清单

**第一阶段：xsim 仿真验证（当前最紧急）**：
- 编写 `tb_alu.v`：验证 ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU
- 编写 `tb_regfile.v`：验证 x0=0、3读1写、内部前推
- 编写 `tb_control_unit.v`：验证所有31条指令的控制信号译码
- 编写 `tb_cpu_basic.v`：加载 `basic_test.hex`，验证多周期FSM到EBREAK
- 分析现有 RTL 代码的 CPU 数据通路和控制路径
- 发现并修复 CPU 相关的 bug

**第二阶段：CPU 测试完善**：
- LW/SW xsim 仿真，与 C 协同定位 memory 接口问题
- BEQ/BNE/BLT/BGE/BLTU/BGEU xsim 仿真
- basic program 能否正确到达 EBREAK/HALT
- 记录基础 CPU 每类指令的周期数

### 5.2 负责路径

- `src/core/alu.v`（A已完成代码，B负责验证和调试）
- `src/core/regfile.v`（A已完成代码，B负责验证和调试）
- `src/core/control_unit.v`（A已完成代码，B负责验证和调试）
- `src/core/imm_gen.v`（A已完成代码，B负责验证和调试）
- `src/core/branch_unit.v`（A已完成代码，B负责验证和调试）
- `src/core/pc_reg.v`（A已完成代码，B负责验证和调试）
- `src/core/riscv_mc_cpu.v`（A已完成代码，B负责验证和调试）
- `sim/tb/tb_alu.v`
- `sim/tb/tb_regfile.v`
- `sim/tb/tb_control_unit.v`
- `sim/tb/tb_cpu_basic.v`
- `tests/basic/`
- `tests/load_store/`
- `tests/branch/`

### 5.3 测试职责

- ALU 单元测试（7类运算全覆盖）
- regfile 单元测试（x0=0，内部前推，3读1写）
- control/imm/branch 控制路径测试
- basic program xsim 仿真（`basic_test.hex`）
- LW/SW xsim 仿真
- BEQ/BNE/BLT/BGE/BLTU/BGEU xsim 仿真
- EBREAK/HALT 到达测试
- 初步记录基础 CPU 周期数

### 5.4 完成标准

- ALU xsim 仿真全部 pass
- regfile xsim 仿真全部 pass
- control_unit 译码覆盖所有 32 条指令（31 RV32I + MAC）
- basic program 通过 Vivado xsim，`x5=1, done=1, error=0`
- 关键波形能解释 FETCH→DECODE→EXECUTE→MEMORY→WRITEBACK

### 5.5 禁止越界事项

- 禁止私自修改 memory map（已更新为统一总线地址）
- 禁止私自改变 SoC/MMIO 接口
- 禁止私自移除 MAC 第三读口需求
- 禁止未经沟通修改 C 的 memory/SoC 代码或 D 的 MAC/perf 代码

## 6. C 胡文龙详细职责（整合后更新）

### 6.1 职责清单

**第一阶段：Vivado 工程与上板准备（当前优先）**：
- 在 Vivado 2018.3 中建立最小工程
- 添加所有 24 个 RTL 源文件 + `constraints/minisys.xdc`
- 复用或创建 Vivado IP（clock divider，参考 minisys_unified 的 `clk_gen.v`）
- 验证 `minisys_top` 端口与 `.xdc` 完全一致
- 实测 P20 复位按钮极性

**第二阶段：SoC 集成验证**：
- `inst_ram.v` + `data_ram.v` 功能验证
- `bus_decoder.v` 地址译码正确性验证
- `gpio_led.v` / `gpio_switch.v` / `seg7_driver.v` 功能验证
- `soc_top.v` 全系统集成仿真

**第三阶段：上板验证**：
- Vivado synthesis → implementation → bitstream
- 上板：LED 显示 running/done/error 状态
- 上板：数码管显示 result 或 cycle_count
- 导出 utilization 和 timing 报告到 `reports/vivado/`

### 6.2 负责路径

- `src/memory/inst_ram.v`（A已完成代码，C负责验证和上板）
- `src/memory/data_ram.v`（A已完成代码，C负责验证和上板）
- `src/io/gpio_led.v`（A已完成代码，C负责验证和上板）
- `src/io/gpio_switch.v`（A已完成代码，C负责验证和上板）
- `src/io/seg7_driver.v`（A已完成代码，C负责验证和上板）
- `src/common/`
- `src/soc/soc_top.v`（A已完成代码，C负责Vivado集成）
- `src/board/minisys_top.v`（A已完成代码，C负责Vivado集成）
- `constraints/minisys.xdc`
- `scripts/`
- `reports/vivado/`

### 6.3 测试职责

- BRAM 初始化测试（`$readmemh` 或 Vivado coe）
- data_mem LW/SW 通路测试
- bus_decoder 地址译码测试
- LED 状态显示测试
- 数码管 result/cycle 显示测试
- Vivado synthesis → implementation → bitstream
- 导出 utilization/timing 报告
- 上板照片、视频留存

### 6.4 完成标准

- Vivado 工程可综合，无 critical warning
- bitstream 可生成
- LED 能显示基本状态
- 数码管能显示 0-F 或 result/cycle_count
- `reports/vivado/` 下有 utilization 和 timing 数据
- 约束验证：`minisys_top` 端口与 `.xdc` 100%一致

### 6.5 禁止越界事项

- 禁止私自修改 ISA
- 禁止私自修改 CPU 内部控制信号
- 禁止私自改变 regfile/MAC 接口
- 禁止未经 A 确认改变板级端口最终口径

## 7. D 王博生详细职责（整合后更新）

### 7.1 职责清单

**第一阶段：MAC 和性能计数器验证**：
- 编写 `tb_mac.v`：覆盖正数、0、溢出低32位、rd_old 累加
- 编写 `tb_perf_counter.v`：验证 cycle/instret/mac 计数

**第二阶段：点积对比测试**：
- 准备普通点积程序（RV32I 手写汇编 → hex）
- 准备 MAC 点积程序（使用 MAC 自定义指令）
- xsim 仿真：两版 result 一致性验证
- 周期数/指令数/mac_count 统计
- 计算 speedup = normal_cycle / mac_cycle

**第三阶段：PPA 初稿与冲刺**：
- 从 C 获取 Vivado utilization/timing 数据
- 整理 PPA 表格（LUT/FF/BRAM/DSP/Timing）
- 时间允许：流水线冲刺（参考 NCUT 的五级流水线寄存器）

### 7.2 负责路径

- `src/core/mac_unit.v`（A已完成代码，D负责验证和点积测试）
- `src/core/csr_perf_counter.v`（A已完成代码，D负责验证）
- `tests/mac/`
- `tests/perf/`
- `tests/hazard/`（P2 冲刺）
- `sim/tb/tb_mac.v`
- `sim/tb/tb_perf_counter.v`
- `sim/tb/tb_pipeline_hazard.v`（P2）
- `docs/design/mac_extension.md`
- `docs/design/performance.md`
- `reports/tables/`

### 7.3 测试职责

- MAC 单元测试（正数、0、溢出、累加）
- MAC 指令集成测试（与 B 协同，确认控制信号和写回路径）
- 普通点积程序测试
- MAC 点积程序测试
- cycle_count/instret_count/mac_count 正确性
- 普通点积与 MAC 点积 result 一致性
- CPI/speedup 初步计算

### 7.4 完成标准

- MAC 单元仿真通过
- MAC 指令能写回 rd
- 普通点积和 MAC 点积 result 一致
- MAC 版本周期数可统计，若未降低需解释原因
- PPA 初稿包含 LUT、FF、BRAM、DSP、Timing 字段

### 7.5 禁止越界事项

- 禁止私自改变基础指令控制逻辑
- 禁止私自改变 EBREAK/HALT 规则
- 禁止私自把流水线改成主线必做
- 禁止私自扩大项目范围

## 8. 接口协作关系（整合后更新）

| 接口/事项 | 主责 | 必须协作 | 规则 |
|---|---|---|---|
| ISA | A | B/D | RV32I 指令编码以 `isa.md` 和 `public.vh` 为准 |
| memory map | A | C/D | 统一总线地址以新版 `memory_map.md` 为准 |
| regfile 第三读口 | B | D/A | 涉及 MAC rd 原值，B验证时注意第三读口 |
| MAC 控制信号 | B + D | A | `is_mac`/`wb_sel` 在 `control_unit.v` 中已实现 |
| CPU-memory 接口 | B + C | A | 统一总线 ibus/dbus 接口，见 `public.vh` |
| 统一总线 | A + C | B | 总线地址译码以 `bus_decoder.v` 为准 |
| MMIO 外设 | C | D/A | 外设地址以新版 `memory_map.md` 为准 |
| 板级端口和 `.xdc` | C | A | 以 `constraints/minisys.xdc` 为准 |
| PPA 数据 | C + D | A | C 导出 Vivado 数据，D 分析，A 复检 |

## 9. 每日同步机制

- 上午：A 检查 `task_board.md`，确认当天 P0/P1/P2 目标
- 开发中：B/C/D 在各自 feature 分支开发，优先修改自己负责路径
- 晚上：A 做集成检查、接口检查、看板更新
- 每天至少有一个可说明进度的 commit
- 有 AI 使用必须当天记录到 `docs/ai_logs/ai_usage_log.md`
- 有 bug 必须记录现象、原因、解决方案和验证结果

## 10. 报告分工表

| 报告章节 | 负责人 | 输入材料 | 完成标准 |
|---|---|---|---|
| 项目背景与总体目标 | A | README、课程要求、整合报告 | 说明项目主线和优先级 |
| 架构选型与整合过程 | A | 整合报告、merge plan | 6仓库分析、设计决策、一致性验证 |
| 硬件平台与开发环境 | A + C | Minisys 手册、Vivado 截图、xsim 流程 | 平台和工具版本清楚 |
| ISA 与 memory map | A | `isa.md`、`memory_map.md`（统一总线版） | 编码和地址范围一致 |
| CPU 数据通路与多周期 FSM | B | CPU RTL、波形、测试记录 | 能解释6状态FSM运行流程 |
| 存储系统与 MMIO | C | memory/MMIO 设计、仿真截图 | 地址译码和统一总线映射清楚 |
| LED/数码管上板验证 | C | 上板照片、视频、bitstream 截图 | 展示 result/cycle/status |
| MAC 指令设计 | D | `mac_extension.md`、MAC 波形 | 指令语义和写回路径清楚 |
| 性能计数与点积对比 | D | `performance.md`、测试结果 | result 一致，周期可比较 |
| PPA 分析 | D 初稿，A 复检 | utilization、timing、PPA 表 | 数据有来源且计算正确 |
| 调试问题与解决方案 | 各成员写自己部分，A 汇总 | 调试日志、commit、截图 | 问题、原因、修复、验证完整 |
| AI 使用说明 | 各成员记录，A 汇总 | `ai_usage_log.md` | 日志真实、可追溯 |
| 贡献度说明 | A 整理，全员确认 | Git、任务看板、报告小节 | 分工和实际贡献对应 |

## 11. 一句话分工总结

**A 完成代码整合和架构铺垫，B 让 CPU 在 xsim 下跑起来，C 让系统能上板展示，D 让项目有 MAC 和性能亮点。**
