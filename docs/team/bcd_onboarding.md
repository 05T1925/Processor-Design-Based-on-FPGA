# B/C/D 队友开发入口与 AI Agent 上下文

最后更新时间：2026-07-07

## 1. 项目一句话说明

本项目是在 Minisys FPGA 上实现 RV32I 子集多周期 CPU，并通过 BRAM、MMIO、LED/拨码/七段数码管、性能计数器和 MAC 自定义指令完成点积加速对比与 PPA 分析。

## 2. 当前已完成项

- 项目主线、ISA 子集、memory map、接口规范和上板演示口径已冻结。
- Minisys 主线约束已整理为 `constraints/minisys.xdc`。
- 板级端口统一为 `clk/rst_n/sw[15:0]/led[15:0]/seg[7:0]/an[7:0]`。
- `docs/design/board_constraints_audit.md` 和 `docs/hardware/minisys_pinout.md` 已记录约束来源和端口映射。

## 3. 当前未完成项

- 完整 `cpu_top`、`soc_top`、`mem_bus`、GPIO、seg7、MAC 集成尚未实现。
- Vivado synthesis、implementation、bitstream 尚未验证。
- 上板演示、utilization、timing、PPA 数据尚未产出。

## 4. 三人共同禁止事项

- 不要私自修改 ISA。
- 不要私自修改 memory map。
- 不要私自修改板级端口最终命名。
- 不要直接重构别人的模块。
- 不要一次让 AI 生成完整 CPU。
- 不要把流水线改成第一版必做。
- 不要提交安装包、license、Vivado cache、bitstream 临时文件。
- 不要把 Nexys4DDR/EGO1/TEC-PLUS 约束用于 Minisys。

## 5. B 张淇开发边界

### 5.1 定位

B 负责基础 CPU 数据通路与控制器，是整个项目的功能地基。第一版采用多周期 FSM，不做完整五级流水线。

### 5.2 负责文件

- `src/core/alu.v`
- `src/core/regfile.v`
- `src/core/control_unit.v`
- `src/core/imm_gen.v`
- `src/core/branch_unit.v`
- `src/core/cpu_top.v`
- `sim/tb/tb_alu.v`
- `sim/tb/tb_regfile.v`
- `sim/tb/tb_cpu_basic.v`
- `tests/basic/`
- `tests/load_store/`
- `tests/branch/`

### 5.3 第一轮任务

1. 检查 `docs/design/interfaces.md` 中 regfile、alu、control_unit、imm_gen、branch_unit、cpu_top 的接口。
2. 实现 `alu.v` 和 `tb_alu.v`。
3. 实现 `regfile.v` 和 `tb_regfile.v`，x0 恒为 0，保留 MAC 第三读口 `rd_old_data`。
4. 实现 `imm_gen.v`、`branch_unit.v`、`control_unit.v`。
5. 实现最小多周期 `cpu_top.v`，FSM 包含 FETCH→DECODE→EXECUTE→MEMORY→WRITEBACK→FETCH，HALT 单独停机状态。
6. 写 `tb_cpu_basic.v`，能跑简单程序到 EBREAK/HALT。
7. 更新 `docs/ai_logs/ai_usage_log.md` 中自己的记录。

### 5.4 验收标准

- ALU 单测通过：ADD、SUB、ADDI、AND、OR、XOR 正确。
- regfile 单测通过：x0 恒为 0，第三读口可读 `rd_old`。
- control/imm/branch 基础译码正确。
- `cpu_top` 能跑 basic program 到 EBREAK/HALT。
- ADD/SUB/ADDI/AND/OR/XOR/LW/SW/BEQ/BNE 基础路径可解释。

### 5.5 禁止修改项

- 不要私自改 MAC 语义（`rd_new = rd_old + rs1 * rs2` 已由 A 和 D 冻结）。
- 不要私自修改 memory map。
- 不要私自修改 `constraints/`、`src/io/`、`src/board/`。
- 不要修改 C 的 memory/io/soc 代码。
- 不要修改 D 的 mac_unit/perf_counter 代码。
- 可以和 D 协调 MAC 第三读口，但不要私自改 MAC 语义。
- 可以和 C 协调 CPU-memory 接口，但不要私自改 memory map。

### 5.6 完成后输出

- 修改文件列表。
- 每个模块功能说明。
- 测试方式。
- 是否通过 xsim。
- 尚未完成项。
- 是否影响 C/D 接口。

## 6. C 胡文龙开发边界

### 6.1 定位

C 负责把 CPU 接入 BRAM、MMIO、LED、拨码开关、数码管和 Minisys 板级顶层，使系统具备上板展示能力。

### 6.2 负责文件

- `src/memory/instr_mem.v`
- `src/memory/data_mem.v`
- `src/memory/mem_bus.v`
- `src/io/gpio_led.v`
- `src/io/gpio_switch.v`
- `src/io/seg7_driver.v`
- `src/soc/soc_top.v`
- `src/board/minisys_top.v`
- `constraints/minisys.xdc`（只能复核，不要乱改管脚号）
- `reports/vivado/`
- `scripts/vivado*`
- `docs/design/board_demo.md`
- `docs/design/interfaces.md` 中与 C 相关的接口
- `docs/ai_logs/ai_usage_log.md` 中自己的记录

### 6.3 第一轮任务

1. 复核 `constraints/minisys.xdc` 和 `minisys_top.v` 端口一致。
2. 实现 `instr_mem.v`，支持 `$readmemh`。
3. 实现 `data_mem.v`，支持 32-bit word LW/SW。
4. 实现 `gpio_led.v`，能寄存 LED 状态。
5. 实现 `gpio_switch.v`，能读 `sw[15:0]`。
6. 实现 `seg7_driver.v`，支持 8 位十六进制扫描显示，低有效。
7. 实现 `mem_bus.v`，根据 `memory_map.md` 区分 data memory 和 MMIO。
8. 等 B 的 `cpu_top` 接口稳定后，集成 `soc_top.v`。
9. 跑 Vivado synthesis/implementation/bitstream，保存截图到 `reports/vivado/`。
10. 更新 `docs/ai_logs/ai_usage_log.md` 中自己的记录。

### 6.4 验收标准

- `instr_mem` 支持 `$readmemh` 初始化。
- `data_mem` 支持 LW/SW。
- `mem_bus` 能区分 data memory 和 MMIO 地址空间。
- `gpio_led` 能寄存 LED 状态。
- `gpio_switch` 能读 `sw[15:0]`。
- `seg7_driver` 能低有效显示 0-F。
- `minisys_top` 端口和 `constraints/minisys.xdc` 完全一致。
- Vivado synthesis/implementation/bitstream 结果有截图。

### 6.5 memory map 必须按

```
0x0000_0000 - 0x0000_0FFF：Instruction Memory
0x0000_1000 - 0x0000_1FFF：Data Memory
0x1000_0000：LED
0x1000_0004：SWITCH
0x1000_0008：SEG7
0x1000_000C：cycle_count
0x1000_0010：instret_count
0x1000_0014：mac_count
0x1000_0018：result_reg
0x1000_001C：status_reg
0x1000_0020：UART reserved
```

### 6.6 禁止修改项

- 不要修改 ISA。
- 不要修改 CPU 内部控制逻辑。
- 不要修改 regfile/MAC 语义。
- 不要使用 Nexys4DDR/EGO1/TEC-PLUS 约束。
- `minisys_top` 只做板级映射和复位转换，不写 CPU 业务逻辑。
- `soc_top` 才负责 CPU + memory + MMIO 集成。
- seg/an 均按低有效处理。
- 未跑 Vivado 综合/实现前，不能写"bitstream 已通过"。

### 6.7 完成后输出

- 修改文件列表。
- 端口/约束复核结果。
- MMIO 地址译码说明。
- seg7 低有效编码表。
- xsim/Vivado 验证状态。
- 尚未完成项。
- 是否影响 B/D 接口。

## 7. D 王博生开发边界

### 7.1 定位

D 负责项目的拓展亮点：MAC 自定义指令、性能计数器、普通点积与 MAC 点积对比、PPA 初稿。第一版不把流水线作为阻塞项。

### 7.2 负责文件

- `src/core/mac_unit.v`
- `src/core/csr_perf_counter.v`
- `sim/tb/tb_mac.v`
- `sim/tb/tb_perf_counter.v`
- `tests/mac/`
- `tests/perf/`
- `tests/hazard/`（仅 P2 冲刺时使用）
- `docs/design/mac_extension.md`
- `docs/design/performance.md`
- `reports/tables/`
- `docs/ai_logs/ai_usage_log.md` 中自己的记录

### 7.3 第一轮任务

1. 实现 `mac_unit.v`，组合逻辑版本，语义固定为 `rd_new = rd_old + rs1 * rs2`。
2. 写 `tb_mac.v`，覆盖正数、0、溢出低 32 位、rd_old 累加。
3. 实现 `csr_perf_counter.v`，统计 `cycle_count`、`instret_count`、`mac_count`。
4. 写 `tb_perf_counter.v`。
5. 准备普通点积和 MAC 点积测试程序说明。
6. 等 B 的 `cpu_top` 稳定后，和 B 一起接入 `is_mac`、`mac_result`、`wb_sel`、`mac_pulse`。
7. 整理 `reports/tables/perf_template.md` 或 `.csv`，字段包含 cycle、instret、CPI、mac_count、LUT、FF、BRAM、DSP、timing。
8. 更新 `docs/ai_logs/ai_usage_log.md` 中自己的记录。

### 7.4 验收标准

- `mac_unit` 单测通过：`rd_new = rd_old + rs1 * rs2`。
- `csr_perf_counter` 单测通过。
- MAC 指令能写回 rd。
- 普通点积和 MAC 点积 result 一致。
- MAC 版本周期数可统计。
- PPA 初稿包含 cycle、CPI、LUT、FF、BRAM、DSP、Timing 字段。
- 乘法结果第一版取低 32 位。
- 不使用厂商专用 DSP 原语，先让综合器自动推断 DSP。

### 7.5 禁止修改项

- 不要私自修改基础 CPU 控制逻辑。
- 不要私自改变 EBREAK/HALT 规则。
- 不要把流水线改成第一版必做。
- 不要修改 `constraints/minisys.xdc`。
- 不要修改 `memory_map.md`，除非 A 确认。
- MAC 集成 control/cpu_top 时必须和 B 协作。
- PPA 数据必须有来源，不能编造。

### 7.6 完成后输出

- 修改文件列表。
- MAC 单元说明。
- 性能计数器说明。
- testbench 覆盖情况。
- 是否通过 xsim。
- 点积测试设计。
- PPA 表格模板。
- 尚未完成项。
- 是否影响 B/C 接口。

## 8. 给 B Agent 的提示语（复制给 AI）

```text
你现在负责项目中的 B 成员任务：CPU 数据通路与控制器。

项目背景：
这是一个基于 Minisys FPGA 的 RV32I 子集多周期 CPU 与 MAC 指令加速设计。
第一版采用多周期 FSM，不做完整五级流水线。
目标是先让基础 CPU 用 Vivado xsim 跑通 basic/load_store/branch 程序，并能到达 EBREAK/HALT。

你只能重点修改这些路径：
- src/core/alu.v
- src/core/regfile.v
- src/core/control_unit.v
- src/core/imm_gen.v
- src/core/branch_unit.v
- src/core/cpu_top.v
- sim/tb/tb_alu.v
- sim/tb/tb_regfile.v
- sim/tb/tb_cpu_basic.v
- tests/basic/
- tests/load_store/
- tests/branch/
- docs/ai_logs/ai_usage_log.md 中自己的记录

必须遵守：
1. 不要修改 memory_map.md。
2. 不要修改 constraints/minisys.xdc。
3. 不要修改 minisys_top 板级端口。
4. 不要修改 C 的 memory/io/soc 代码。
5. 不要修改 D 的 mac_unit/perf_counter 代码。
6. regfile 必须保留 MAC 第三读口 rd_old_data。
7. x0 恒为 0。
8. EBREAK/HALT 编码为 0x00100073。
9. 所有时序模块使用 clk 和内部高有效 rst。
10. 每个模块要有 testbench 或至少给出测试说明。

第一轮任务：
1. 检查 interfaces.md 中 regfile、alu、control_unit、imm_gen、branch_unit、cpu_top 的接口。
2. 实现 alu.v 和 tb_alu.v。
3. 实现 regfile.v 和 tb_regfile.v。
4. 实现 imm_gen.v、branch_unit.v、control_unit.v。
5. 实现最小多周期 cpu_top.v。
6. 写 tb_cpu_basic.v，能跑简单程序到 EBREAK/HALT。
7. 更新 docs/ai_logs/ai_usage_log.md。

完成后输出：
- 修改文件列表
- 每个模块功能说明
- 测试方式
- 是否通过 xsim
- 尚未完成项
- 是否影响 C/D 接口
```

## 9. 给 C Agent 的提示语（复制给 AI）

```text
你现在负责项目中的 C 成员任务：SoC / Memory / I/O / 上板验证。

项目背景：
这是一个基于 Minisys FPGA 的 RV32I 子集多周期 CPU 与 MAC 指令加速设计。
第一版使用 BRAM 和 MMIO，不使用 DDR3/Cache。
板级端口已经统一为：
input clk
input rst_n
input [15:0] sw
output [15:0] led
output [7:0] seg
output [7:0] an

你只能重点修改这些路径：
- src/memory/instr_mem.v
- src/memory/data_mem.v
- src/memory/mem_bus.v
- src/io/gpio_led.v
- src/io/gpio_switch.v
- src/io/seg7_driver.v
- src/soc/soc_top.v
- src/board/minisys_top.v
- constraints/minisys.xdc，只能复核，不要乱改管脚号
- reports/vivado/
- scripts/vivado*
- docs/design/board_demo.md
- docs/design/interfaces.md 中与 C 相关的接口
- docs/ai_logs/ai_usage_log.md 中自己的记录

必须遵守：
1. 不要修改 ISA。
2. 不要修改 CPU 内部控制逻辑。
3. 不要修改 regfile/MAC 语义。
4. 不要使用 Nexys4DDR/EGO1/TEC-PLUS 约束。
5. minisys_top 只做板级映射和复位转换，不写 CPU 业务逻辑。
6. soc_top 才负责 CPU + memory + MMIO 集成。
7. seg/an 均按低有效处理。
8. 未跑 Vivado 综合/实现前，不能写"bitstream 已通过"。

第一轮任务：
1. 复核 constraints/minisys.xdc 和 minisys_top.v 端口一致。
2. 实现 instr_mem.v，支持 $readmemh。
3. 实现 data_mem.v，支持 32-bit word LW/SW。
4. 实现 gpio_led.v。
5. 实现 gpio_switch.v。
6. 实现 seg7_driver.v，支持 8 位十六进制扫描显示，低有效。
7. 实现 mem_bus.v，根据 memory_map.md 地址译码。
8. 等 B 的 cpu_top 接口稳定后，集成 soc_top.v。
9. 跑 Vivado synthesis/implementation/bitstream，保存截图和 reports/vivado。
10. 更新 docs/ai_logs/ai_usage_log.md。

memory map 必须按：
0x0000_0000 - 0x0000_0FFF：Instruction Memory
0x0000_1000 - 0x0000_1FFF：Data Memory
0x1000_0000：LED
0x1000_0004：SWITCH
0x1000_0008：SEG7
0x1000_000C：cycle_count
0x1000_0010：instret_count
0x1000_0014：mac_count
0x1000_0018：result_reg
0x1000_001C：status_reg

完成后输出：
- 修改文件列表
- 端口/约束复核结果
- MMIO 地址译码说明
- seg7 低有效编码表
- xsim/Vivado 验证状态
- 尚未完成项
- 是否影响 B/D 接口
```

## 10. 给 D Agent 的提示语（复制给 AI）

```text
你现在负责项目中的 D 成员任务：MAC / 性能计数 / 点积测试 / PPA 初稿。

项目背景：
这是一个基于 Minisys FPGA 的 RV32I 子集多周期 CPU 与 MAC 指令加速设计。
第一版不把流水线作为阻塞项。你的核心任务是 MAC 自定义指令和性能量化。

你只能重点修改这些路径：
- src/core/mac_unit.v
- src/core/csr_perf_counter.v
- sim/tb/tb_mac.v
- sim/tb/tb_perf_counter.v
- tests/mac/
- tests/perf/
- tests/hazard/，仅 P2 冲刺时使用
- docs/design/mac_extension.md
- docs/design/performance.md
- reports/tables/
- docs/ai_logs/ai_usage_log.md 中自己的记录

必须遵守：
1. 不要私自修改基础 CPU 控制逻辑。
2. 不要私自改变 EBREAK/HALT 规则。
3. 不要把流水线改成第一版必做。
4. 不要修改 constraints/minisys.xdc。
5. 不要修改 memory_map.md，除非 A 确认。
6. MAC 语义固定为 rd_new = rd_old + rs1 * rs2。
7. 乘法结果第一版取低 32 位。
8. 不使用厂商专用 DSP 原语，先让综合器自动推断 DSP。
9. MAC 集成 control/cpu_top 时必须和 B 协作。
10. PPA 数据必须有来源，不能编造。

第一轮任务：
1. 实现 mac_unit.v，组合逻辑版本。
2. 写 tb_mac.v，覆盖正数、0、溢出低 32 位、rd_old 累加。
3. 实现 csr_perf_counter.v，统计 cycle_count、instret_count、mac_count。
4. 写 tb_perf_counter.v。
5. 准备普通点积和 MAC 点积测试程序说明。
6. 等 B 的 cpu_top 稳定后，和 B 一起接入 is_mac、mac_result、wb_sel、mac_pulse。
7. 整理 reports/tables/perf_template.md 或 .csv，字段包含 cycle、instret、CPI、mac_count、LUT、FF、BRAM、DSP、timing。
8. 更新 docs/ai_logs/ai_usage_log.md。

完成后输出：
- 修改文件列表
- MAC 单元说明
- 性能计数器说明
- testbench 覆盖情况
- 是否通过 xsim
- 点积测试设计
- PPA 表格模板
- 尚未完成项
- 是否影响 B/C 接口
```

## 11. 每人每日提交前检查清单

- 今天修改了哪些文件。
- 是否影响 `interfaces.md`、`isa.md`、`memory_map.md`。
- 是否跑了单测、xsim 或人工检查。
- 是否更新了 `docs/ai_logs/ai_usage_log.md`。
- 是否误提交 Vivado cache、安装包、license 或大文件。
- 是否需要通知其他成员接口变化。

## 12. 如何更新 AI 日志

每次使用 AI 生成或修改代码、文档、测试思路，都在 `docs/ai_logs/ai_usage_log.md` 追加记录，写清楚日期、成员、负责模块、提示词摘要、输出摘要、人工审阅点、验证方式和是否合并。

## 13. 如何避免互相干扰

- B 只改 `src/core` 基础 CPU 和 CPU 测试。
- C 只改 `src/memory`、`src/io`、`src/soc`、`src/board`、`constraints`、`reports/vivado`。
- D 只改 MAC、perf、MAC/perf 测试和 PPA 表格。
- 公共文档 `interfaces.md`、`memory_map.md`、`isa.md` 必须由 A 确认后再改。
