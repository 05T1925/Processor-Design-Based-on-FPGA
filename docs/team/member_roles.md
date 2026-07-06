# 小组成员分工方案

用途：明确四人小组的角色边界、负责路径、测试责任、报告责任、交付标准和协作关系。

最后更新时间：2026-07-06

## 1. 小组基本信息

| 成员 | 姓名 | 学号 | 角色 |
|---|---|---|---|
| A | 刘文涛 | 2024212936 | 组长 / 总体架构与集成 / 报告总负责人 |
| B | 张淇 | 2024212998 | CPU 数据通路与控制器负责人 |
| C | 胡文龙 | 2024212582 | SoC / Memory / I/O / 上板验证负责人 |
| D | 王博生 | 2024212590 | MAC / 性能计数 / 点积测试 / 冲刺负责人 |

组长已确认：姓名和学号全部正确，成员已邀请加入 GitHub 仓库。最终贡献度比例按四人均分，每人 25%。

## 2. 项目方向概述

项目方向为：基于 Minisys FPGA 的 RV32I 子集多周期 CPU 与 MAC 指令加速设计。

主线内容：

```text
RV32I 子集多周期 CPU
+ BRAM 指令/数据存储器
+ memory-mapped I/O
+ LED / 拨码开关 / 七段数码管上板演示
+ 性能计数器
+ MAC 自定义指令
+ 普通点积程序与 MAC 点积程序对比
+ 周期数 / CPI / PPA 分析
```

优先级：

- P0：CPU 能用 Vivado xsim 仿真跑通。
- P1：SoC 能上板，MAC 能进行点积对比。
- P2：流水线、forwarding、stall、flush、UART 等冲刺目标。

五级流水线不是第一版必须完成内容。DDR3、Cache、VGA、WiFi、蓝牙、电机、触摸屏不作为当前主线。

## 3. 四人角色总览表

| 成员 | 角色 | 主要职责 | 负责路径 | 测试职责 | 报告职责 | 完成标准 |
|---|---|---|---|---|---|---|
| A 刘文涛 | 组长 / 架构 / 集成 / 报告 | ISA、memory map、interfaces、任务看板、代码合并、性能复检、报告整合 | `README.md`, `docs/`, `reports/` | 复核性能/PPA 数据，检查 AI 日志和验收证据 | 项目背景、总体目标、ISA、memory map、贡献度、最终整合 | 文档口径统一，`main` 可运行，数据可信，报告可答辩 |
| B 张淇 | CPU 数据通路与控制器 | ALU、regfile、control、imm、branch、`cpu_top`、多周期 FSM、EBREAK/HALT | `src/core/`, `tests/basic/`, `tests/load_store/`, `tests/branch/`, `sim/tb/tb_cpu_basic.v` | CPU basic/load_store/branch xsim 仿真 | CPU 数据通路、多周期 FSM、基础指令波形 | 基础 CPU 能跑到 EBREAK/HALT |
| C 胡文龙 | SoC / Memory / I/O / 上板验证 | BRAM、mem_bus、MMIO、LED、switch、seg7、`soc_top`、`minisys_top`、Vivado | `src/memory/`, `src/io/`, `src/soc/`, `src/board/`, `constraints/`, `reports/vivado/` | BRAM/MMIO/LED/数码管/上板测试，导出 utilization/timing | 存储系统、MMIO、上板验证、Vivado 数据 | CPU + memory + I/O 能集成，上板能显示结果 |
| D 王博生 | MAC / 性能 / 冲刺 | `mac_unit`、`csr_perf_counter`、点积测试、周期/CPI/PPA 初稿、流水线冲刺 | `src/core/mac_unit.v`, `src/core/csr_perf_counter.v`, `tests/mac/`, `tests/perf/`, `reports/tables/` | MAC 单测、MAC 集成、普通/MAC 点积、性能计数测试 | MAC 指令、性能计数、点积对比、PPA 初稿 | 普通点积和 MAC 点积结果一致，周期和资源可比较 |

## 4. A 刘文涛详细职责

### 4.1 职责清单

- 维护 `README.md` 和总体设计文档。
- 冻结 ISA、memory map、interfaces。
- 审核公共接口变更。
- 管理 Git 分支和合并。
- 维护任务看板和项目进度。
- 检查每位成员 AI 日志。
- 复核性能数据、周期数、CPI 和 PPA 表。
- 统一最终报告和答辩材料。
- 协调上板节奏和降级方案。
- 不直接替其他成员重写全部模块，除非集成阻塞且已与对应成员确认。

### 4.2 负责路径

- `README.md`
- `docs/design/architecture.md`
- `docs/design/interfaces.md`
- `docs/design/isa.md`
- `docs/design/memory_map.md`
- `docs/design/task_board.md`
- `docs/design/development_rules.md`
- `docs/team/`
- `docs/planning/`
- `reports/`

### 4.3 测试职责

- 复核 B/C/D 的 xsim 或 Vivado 结果是否有截图、日志或数据来源。
- 复核 `cycle_count`、`instret_count`、`mac_count` 的统计口径。
- 复核 PPA 表中的 LUT、FF、BRAM、DSP、timing slack。
- 检查 AI 日志是否覆盖实际使用 AI 的过程。

### 4.4 报告职责

- 项目背景与总体目标。
- ISA 与 memory map。
- 总体架构与协作流程。
- PPA 数据复检说明。
- 调试问题汇总。
- AI 使用说明汇总。
- 贡献度说明，全员确认后写入报告。

### 4.5 完成标准

- 所有公共接口有文档记录。
- `main` 分支保留可运行版本。
- 性能表格有来源，截图和数据一致。
- 最终报告结构完整，答辩材料口径统一。

### 4.6 禁止越界事项

- 禁止未经 B/C/D 确认大规模重写其负责模块。
- 禁止绕过接口文档直接要求组员改端口。
- 禁止为赶进度把未经验证代码合入 `main`。

## 5. B 张淇详细职责

### 5.1 职责清单

- 实现 CPU 核心数据通路。
- 实现多周期 FSM。
- 支持基础 RV32I 子集。
- 实现 EBREAK/HALT 停机。
- 实现 ALU、regfile、control_unit、imm_gen、branch_unit、cpu_top。
- 与 D 协调 regfile 第三读口和 MAC 写回。
- 与 C 协调 instruction/data memory 接口。
- 负责 CPU basic/load_store/branch 仿真。

### 5.2 负责路径

- `src/core/alu.v`
- `src/core/regfile.v`
- `src/core/control_unit.v`
- `src/core/imm_gen.v`
- `src/core/branch_unit.v`
- `src/core/cpu_top.v`
- `tests/basic/`
- `tests/load_store/`
- `tests/branch/`
- `sim/tb/tb_alu.v`
- `sim/tb/tb_regfile.v`
- `sim/tb/tb_cpu_basic.v`

### 5.3 测试职责

- ALU 单元测试。
- regfile 单元测试，包含 x0 恒为 0。
- control/imm/branch 控制路径测试。
- basic program xsim 仿真。
- LW/SW xsim 仿真。
- BEQ/BNE xsim 仿真。
- EBREAK/HALT 到达测试。
- 初步记录基础 CPU 周期数。

### 5.4 报告职责

- CPU 数据通路。
- 多周期 FSM。
- 基础指令支持范围。
- EBREAK/HALT 设计。
- CPU 关键波形与测试结果。

### 5.5 完成标准

- basic program 能跑到 EBREAK/HALT。
- ADD、SUB、ADDI、AND、OR、XOR、LW、SW、BEQ、BNE 等基础功能正确。
- 关键波形能解释 FETCH、DECODE、EXECUTE、MEMORY、WRITEBACK。

### 5.6 禁止越界事项

- 禁止私自修改 memory map。
- 禁止私自改变 SoC/MMIO 接口。
- 禁止私自移除 MAC 第三读口需求。
- 禁止未经沟通修改 C 的 memory/SoC 代码或 D 的 MAC/perf 代码。

## 6. C 胡文龙详细职责

### 6.1 职责清单

- 实现 BRAM 指令/数据存储器。
- 实现 memory-mapped I/O。
- 实现 LED、拨码开关、七段数码管显示。
- 实现 `soc_top` 和 `minisys_top`。
- 维护约束文件。
- 等官方 `.xdc` 到位后核对板级端口命名。
- 负责 Vivado 综合、实现、bitstream、上板。
- 导出 utilization 和 timing 报告。

### 6.2 负责路径

- `src/memory/`
- `src/io/`
- `src/soc/`
- `src/board/`
- `constraints/`
- `scripts/vivado*`
- `reports/vivado/`

### 6.3 测试职责

- BRAM 初始化测试。
- data memory LW/SW 通路测试。
- MMIO 地址译码测试。
- LED 状态显示测试。
- 数码管 result/cycle/mac_count 显示测试。
- Vivado synthesis、implementation、bitstream 检查。
- 上板照片、视频和 Vivado 报告留存。

### 6.4 报告职责

- 存储系统设计。
- MMIO 地址映射和 I/O 设计。
- LED/数码管上板验证。
- Vivado utilization 和 timing summary。
- 官方 `.xdc` 到位后的端口核对结论。

### 6.5 完成标准

- CPU 能通过 bus 访问 data memory 和 MMIO。
- LED 能显示 running、done、error、mac_mode 等状态。
- 数码管至少能显示 result 或 cycle_count 低位。
- bitstream 可生成，上板有可展示材料。

### 6.6 禁止越界事项

- 禁止私自修改 ISA。
- 禁止私自修改 CPU 内部控制信号。
- 禁止私自改变 regfile/MAC 接口。
- 禁止未经 A 确认改变板级端口最终口径。

## 7. D 王博生详细职责

### 7.1 职责清单

- 实现 MAC 单元。
- 实现或配合接入性能计数器。
- 配合 B 接入 MAC 控制信号和写回路径。
- 编写普通点积和 MAC 点积测试。
- 统计 `cycle_count`、`instret_count`、`mac_count`。
- 整理周期数、CPI、speedup 和 PPA 初稿。
- 时间允许时负责流水线冲刺文档或实现。

### 7.2 负责路径

- `src/core/mac_unit.v`
- `src/core/csr_perf_counter.v`
- `tests/mac/`
- `tests/perf/`
- `tests/hazard/`
- `sim/tb/tb_mac.v`
- `sim/tb/tb_perf_counter.v`
- `sim/tb/tb_pipeline_hazard.v`
- `docs/design/mac_extension.md`
- `docs/design/performance.md`
- `reports/tables/`

### 7.3 测试职责

- MAC 单元测试。
- MAC 指令集成测试。
- 普通点积程序测试。
- MAC 点积程序测试。
- cycle_count、instret_count、mac_count 正确性测试。
- MAC 点积与普通点积结果一致性测试。
- 周期数、CPI、speedup 初步统计。

### 7.4 报告职责

- MAC 指令设计。
- MAC 数据通路和写回说明。
- 性能计数器设计。
- 普通点积与 MAC 点积对比。
- PPA 初稿。
- 流水线冲刺项说明。

### 7.5 完成标准

- MAC 指令能写回 rd。
- 普通点积和 MAC 点积 result 一致。
- MAC 版本周期数可统计，若未提升需解释原因。
- PPA 初稿包含 LUT、FF、BRAM、DSP、Timing 字段。

### 7.6 禁止越界事项

- 禁止私自改变基础指令控制逻辑。
- 禁止私自改变 EBREAK/HALT 规则。
- 禁止私自把流水线改成主线必做。
- 禁止私自扩大项目范围。

## 8. 接口协作关系

| 接口/事项 | 主责 | 必须协作 | 规则 |
|---|---|---|---|
| ISA | A | B/D | 修改前先更新 `docs/design/isa.md`，由 A 确认 |
| memory map | A | C/D | 修改前先更新 `docs/design/memory_map.md`，由 A 确认 |
| regfile 第三读口 | B | D/A | 涉及 MAC rd 原值，变更需同步 `interfaces.md` |
| MAC 控制信号 | B + D | A | 译码、执行、写回口径必须一致 |
| CPU-memory 接口 | B + C | A | 地址、读写使能、数据宽度按 `interfaces.md` |
| MMIO 显示通路 | C | D/A | result/cycle/mac_count 显示选择需服务演示 |
| 板级端口和 `.xdc` | C | A | 等官方 `.xdc` 后核对，最终端口名与官方一致 |
| PPA 数据 | C + D | A | C 导出，D 分析，A 复检 |

## 9. 每日同步机制

- 上午：确认当天目标、接口变更、阻塞问题。
- 下午：各自完成模块开发、单元测试和局部文档更新。
- 晚上：组长集成，成员提交日志、截图、测试结果和 commit。
- 每天至少有一个可说明进度的 commit。
- 每个成员每天更新自己负责的任务状态。
- 有 AI 使用必须当天记录到 `docs/ai_logs/ai_usage_log.md`。
- 有 bug 必须记录现象、原因、解决方案和验证结果。

## 10. 贡献度记录建议

- 以 Git commit、任务看板、测试截图、Vivado 报告、AI 日志和报告小节作为贡献度依据。
- 每位成员记录自己完成的模块、测试、文档和调试问题。
- 组长只汇总贡献度，不替其他成员补写不存在的工作。
- 最终贡献度比例已由组长确认按四人均分，每人 25%；报告中仍需保留各自实际工作记录作为支撑材料。

## 11. 报告分工表

| 报告章节 | 负责人 | 输入材料 | 完成标准 |
|---|---|---|---|
| 项目背景与总体目标 | A | README、课程要求、总体架构 | 说明项目主线和优先级 |
| 硬件平台与开发环境 | A + C | Minisys 手册、Vivado 截图、xsim 流程 | 平台和工具版本清楚 |
| ISA 与 memory map | A | `isa.md`, `memory_map.md` | 编码和地址范围一致 |
| CPU 数据通路与多周期 FSM | B | CPU RTL、波形、测试记录 | 能解释基础 CPU 运行流程 |
| 存储系统与 MMIO | C | memory/MMIO 设计、仿真截图 | 地址译码和 I/O 映射清楚 |
| LED/数码管上板验证 | C | 上板照片、视频、bitstream 截图 | 展示 result/cycle/status |
| MAC 指令设计 | D | `mac_extension.md`、MAC 波形 | 指令语义和写回路径清楚 |
| 性能计数与点积对比 | D | `performance.md`、测试结果 | result 一致，周期可比较 |
| PPA 分析 | D 初稿，A 复检 | utilization、timing、PPA 表 | 数据有来源且计算正确 |
| 调试问题与解决方案 | 各成员写自己部分，A 汇总 | 调试日志、commit、截图 | 问题、原因、修复、验证完整 |
| AI 使用说明 | 各成员记录，A 汇总 | `ai_usage_log.md` | 日志真实、可追溯 |
| 贡献度说明 | A 整理，全员确认 | Git、任务看板、报告小节 | 分工和实际贡献对应 |
