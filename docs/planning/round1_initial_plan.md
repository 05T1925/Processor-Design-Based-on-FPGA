# 第一轮初步规划日志

## 1. 记录信息

- 日期：2026-07-06
- 阶段：开发前规划与仓库初始化
- 项目：题目 B，基于 FPGA 开发板的处理器设计
- 平台：Minisys FPGA 实验板
- 开发环境：Vivado 2018.3
- 记录目的：统一项目目标、技术路线、目录结构、风险边界和第一轮开发顺序。

## 2. 已确认决策

### 2.1 ISA

最终 ISA 选择 RV32I 子集，不做完整 RV32I。

第一轮建议只保留与课程验收和测试程序直接相关的指令：

- 算术：ADD、SUB、ADDI。
- 逻辑：AND、OR、XOR。
- 访存：LW、SW。
- 分支：BEQ、BNE。
- 跳转：JAL 可选。
- 系统/停止：HALT 或自定义 EBREAK。
- 拓展：MAC 自定义指令。

### 2.2 拓展层次策略

五级流水线完整冒险处理不作为硬性必做项。项目拓展主线调整为：

```text
MAC 自定义指令 + 性能计数器 + 点积对比 + PPA 分析
```

五级流水线、forwarding、load-use stall、branch flush 作为冲刺目标分级实现。

### 2.3 演示策略

第一阶段演示使用：

- 数码管显示计算结果。
- 数码管显示 cycle_count 低位。
- LED 显示 running、done、error、mac_mode。
- 拨码开关选择显示模式或运行模式。

后期进阶演示可增加 UART 输出性能统计，但不能让 UART 阻塞主线。

### 2.4 约束文件

Minisys 官方 `.xdc` 已确认存在，等待组长后续提供老师给的详细资料。本轮先初始化 `constraints/` 目录，不手写管脚约束，避免误配。

### 2.5 报告与过程记录

最终报告需要包含：

- GitHub 提交历史。
- AI 使用日志。
- 调试日志。
- 仿真截图。
- Vivado 资源利用和时序报告。
- 上板演示照片或视频。

## 3. 指南可行性判断

现有开发指南总体可用，尤其适合作为后续 Codex 协作的总纲。但原指南对“完整五级流水线 + 完整冒险处理”的要求偏高。考虑一周周期，第一轮执行时应采用分层目标：

| 层级 | 目标 | 状态 |
|---|---|---|
| 保底 | RV32I 子集 CPU + BRAM + 数码管/LED 上板 | 必做 |
| 主线 | MAC 指令 + 性能计数 + 点积加速演示 | 必做 |
| 进阶 | 小型 SoC + memory-mapped I/O | 必做 |
| 冲刺 | 五级流水线基础版本 | 视进度 |
| 冲刺 | forwarding / stall / flush | 视进度 |
| 后置 | UART 输出统计 | 视进度 |
| 暂缓 | DDR3 / Cache / VGA / LCD / WiFi / 蓝牙 / 电机 | 不做主线 |

## 4. 第一轮仓库初始化

本轮初始化的目录分为：

- `docs/`：课程资料索引、设计文档、AI 日志、规划日志。
- `src/`：后续 RTL 源码目录，本轮只建目录。
- `sim/`：仿真 testbench、测试程序、波形输出。
- `tests/`：按功能分类的测试用例。
- `constraints/`：Minisys `.xdc`。
- `scripts/`：Vivado 和仿真脚本。
- `reports/`：波形、图片、表格、Vivado 报告、最终报告。
- `archive/`：无关资料归档。

## 5. 推荐第一轮开发顺序

### Step 1：文档冻结接口

先补齐以下设计文档：

- `docs/design/isa.md`
- `docs/design/memory_map.md`
- `docs/design/architecture.md`
- `docs/design/mac_extension.md`

目标是先把接口、指令编码、地址映射说清楚，再写代码。

### Step 2：最小 CPU

实现最小可运行 CPU：

- `src/core/alu.v`
- `src/core/regfile.v`
- `src/core/control_unit.v`
- `src/core/imm_gen.v`
- `src/core/cpu_top.v`

先不追求流水线，先保证基础程序能正确运行。

### Step 3：BRAM 与 I/O

实现：

- `src/memory/instr_mem.v`
- `src/memory/data_mem.v`
- `src/memory/mem_bus.v`
- `src/io/gpio_led.v`
- `src/io/gpio_switch.v`
- `src/io/seg7_driver.v`
- `src/soc/soc_top.v`
- `src/board/minisys_top.v`

目标是在 Minisys 上用数码管/LED 展示结果。

### Step 4：性能计数器

实现：

- `src/core/csr_perf_counter.v`

至少统计：

- cycle_count
- instret_count
- mac_count

视进度增加：

- stall_count
- flush_count
- branch_count

### Step 5：MAC 指令

实现：

- `src/core/mac_unit.v`

并准备两套程序：

- 普通软件点积。
- MAC 指令点积。

验收目标是结果一致、MAC 版本周期更少，并能给出资源和 PPA 对比。

### Step 6：流水线冲刺

如果保底和 MAC 主线稳定，再推进：

- 五级流水线基础结构。
- 手插 NOP 测试。
- forwarding。
- load-use stall。
- branch flush。

## 6. 第一轮测试计划

| 测试类别 | 路径 | 目标 |
|---|---|---|
| 基础指令 | `tests/basic/` | 验证 ADD/SUB/ADDI/AND/OR/XOR |
| 访存 | `tests/load_store/` | 验证 LW/SW 与 data memory |
| 分支 | `tests/branch/` | 验证 BEQ/BNE |
| SoC I/O | `sim/tb/` | 验证 memory-mapped I/O |
| MAC | `tests/mac/` | 验证普通点积与 MAC 点积结果一致 |
| 冒险 | `tests/hazard/` | 后续用于流水线冲刺 |

## 7. 性能与 PPA 数据需求

第一轮报告至少准备以下表格字段：

| 版本 | 周期数 | 指令数 | CPI | LUT | FF | BRAM | DSP | Timing slack | 说明 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 基础 CPU | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 保底版本 |
| 基础 CPU + MAC | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | MAC 加速 |
| 流水线版本 | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 视进度 |

关键结论应围绕：

- MAC 是否减少周期数。
- MAC 是否使用 DSP 资源。
- MAC 是否降低 Fmax 或增加 LUT/FF。
- 性能提升是否值得面积/功耗代价。

## 8. AI 使用与 Git 提交规范

### 8.1 AI 使用记录

每次使用 Codex 或其他 AI 生成/修改代码时，必须记录：

- 日期。
- 使用者。
- 使用环节。
- 提示词摘要。
- 输出内容摘要。
- 人工审阅和修改。
- 仿真/综合验证结果。

统一记录到：

```text
docs/ai_logs/ai_usage_log.md
```

### 8.2 Git 提交建议

建议每个可验证节点提交一次：

- `docs: initialize project planning`
- `docs: define rv32i subset and memory map`
- `rtl: add basic alu and regfile`
- `sim: add basic cpu testbench`
- `rtl: integrate bram and gpio`
- `rtl: add mac extension`
- `report: add performance comparison data`

提交历史本身是报告材料的一部分，不要把大量无关二进制临时文件混入提交。

## 9. 当前阻塞项

- 等待老师提供 Minisys 官方 `.xdc` 和更详细资料。
- 需要确认小组成员姓名、学号、具体分工。
- 需要确认最终是否使用 ModelSim，还是主要使用 Vivado xsim。
- 需要确认测试程序采用手写机器码、简易汇编脚本，还是后续写小型 assembler。

## 10. 下一轮建议任务

下一轮建议先做文档，不急着写 RTL：

1. 编写 `docs/design/isa.md`。
2. 编写 `docs/design/memory_map.md`。
3. 编写 `docs/design/architecture.md`。
4. 初始化 `docs/ai_logs/ai_usage_log.md`。
5. 等 `.xdc` 到位后建立 `constraints/minisys.xdc`。

完成这些后，再进入第一批模块实现。
