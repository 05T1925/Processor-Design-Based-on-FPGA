# 四人小组正式分工文档

用途：明确项目阶段二四位成员的职责边界、交付物、测试归属、性能数据归属和报告撰写分工。

最后更新时间：2026-07-07

## 1. 已确认约束

- 已在老师资料中确认 Minisys 主约束来源：`安装包资料/minisys_MIPS_FPGA1/MIPS_FPGA/workspace/project_linux/project_linux.srcs/constrs_1/new/Minisys_Master.xdc`。
- 项目主线约束统一为 `constraints/minisys.xdc`，端口固定为 `clk/rst_n/sw[15:0]/led[15:0]/seg[7:0]/an[7:0]`。
- 原始 `.xdc` 的 MIPS 工程端口名不直接扩散到内部模块，由 `minisys_top` 和项目约束完成映射。
- 数码管为共阳极，`seg` 和 `an` 低电平有效；LED 高电平点亮；拨码开关高电平表示 1。
- 项目验收仿真工具统一为 Vivado xsim。其他工具输出只能作为辅助参考，不作为最终验收仿真依据。
- 组员姓名和学号已由组长确认正确，成员已邀请加入 GitHub 仓库。
- 最终贡献度比例按四人均分，每人 25%。

## 2. 分工总原则

- 不单独设置占满一人的“测试/性能负责人”。
- 谁负责模块，谁负责该模块的单元测试、集成测试和波形解释。
- D 负责 MAC、性能计数、点积对比和 PPA 初稿。
- A 负责性能数据复检、最终报告统一口径和答辩材料整合。
- 第一版以多周期 RV32I 子集 CPU、BRAM、memory-mapped I/O、性能计数器、MAC 自定义指令和点积对比为主线。
- 流水线、forwarding、stall、flush、UART 输出统计作为冲刺目标，不作为第一版阻塞项。

## 3. 成员总表

| 成员 | 姓名 | 学号 | 角色 | 核心职责 | 测试/性能职责 | 主要交付标准 |
|---|---|---|---|---|---|---|
| A | 刘文涛 | 2024212936 | 组长 / 架构 / 集成 / 报告 | ISA、接口规范、memory map、任务管理、代码集成、报告总控 | PPA 复检、AI 日志检查、最终性能表整理 | 项目方向统一，`main` 可运行，报告完整，数据可信 |
| B | 张淇 | 2024212998 | CPU 数据通路与控制器 | ALU、regfile、control、imm、branch、`cpu_top` | 基础指令、LW/SW、BEQ/BNE、EBREAK、CPU 周期初测 | 基础 CPU 能通过 xsim 仿真并跑到 HALT/EBREAK |
| C | 胡文龙 | 2024212582 | SoC / I/O / 上板验证 | BRAM、mem_bus、MMIO、LED、seg7、`soc_top`、`minisys_top`、`.xdc` | BRAM 初始化、MMIO、LED/数码管、Vivado utilization/timing 导出 | bitstream 可生成，上板能显示结果或给出明确降级方案 |
| D | 王博生 | 2024212590 | MAC / 性能 / 冲刺 | `mac_unit`、`perf_counter`、点积测试、PPA 初稿、流水线冲刺 | MAC 单测、MAC 集成、普通点积/MAC 点积、周期/CPI/PPA 初稿 | 普通点积与 MAC 点积结果一致，性能数据可比较 |

## 4. A 刘文涛职责

### 4.1 定位

A 负责把项目从分散模块组织成可验收工程，重点是统一方向、冻结公共接口、控制集成节奏、复检性能数据和完成最终报告。

### 4.2 具体职责

| 类别 | 任务 |
|---|---|
| 总体架构 | 冻结 ISA、memory map、模块接口和顶层数据流 |
| 项目管理 | 制定 P0/P1/P2 优先级，跟进每日进度 |
| 接口规范 | 维护 `docs/design/interfaces.md`，所有公共接口变更需先确认 |
| 代码集成 | 审核分支合并，解决 CPU、memory、MMIO、MAC 的接口冲突 |
| 上板节奏 | 协调 C 的 Vivado 综合、实现、上板验证和降级方案 |
| 性能复检 | 复核 `cycle_count`、`instret_count`、`mac_count`、PPA 表格和截图来源 |
| 报告总控 | 整理最终报告、答辩 PPT、贡献度说明、图表和截图 |
| AI 日志 | 检查每位成员是否记录 AI 使用过程 |

### 4.3 负责文件

| 文件/目录 | 说明 |
|---|---|
| `README.md` | 项目入口和主线说明 |
| `docs/design/architecture.md` | 总体架构 |
| `docs/design/interfaces.md` | 公共接口规范 |
| `docs/design/task_board.md` | 任务看板 |
| `docs/design/development_rules.md` | 开发规范 |
| `docs/design/risk_plan.md` | 风险与降级方案 |
| `docs/planning/` | 阶段计划和分工文档 |
| `reports/final_report/` | 最终报告材料 |
| `reports/tables/` | 性能和 PPA 表格 |

### 4.4 完成标准

1. 所有成员知道自己负责的文件、接口和测试范围。
2. 公共接口有文档记录，端口变更可追溯。
3. `main` 分支始终保留一个可运行版本。
4. 最终报告结构完整，能够解释设计目标、实现路径、测试结果和性能对比。
5. 性能表格经过复检，不出现无来源或互相矛盾的数据。
6. 每位成员贡献能在 Git 记录、AI 日志和报告中体现。

## 5. B 张淇职责

### 5.1 定位

B 负责基础 CPU 能否跑起来，是整个项目的功能地基。

### 5.2 具体职责

| 模块 | 任务 |
|---|---|
| `alu` | 实现 ADD、SUB、AND、OR、XOR 等基础运算 |
| `regfile` | 实现 32 x 32 寄存器堆，保证 x0 恒为 0，配合 D 预留 MAC 第三读口 |
| `control_unit` | 根据 opcode、funct3、funct7 生成控制信号 |
| `imm_gen` | 生成 I/S/B/J 等立即数 |
| `branch_unit` | 判断 BEQ、BNE 等分支是否跳转 |
| `cpu_top` | 实现多周期 FSM CPU 主体 |
| HALT/EBREAK | 检测 `0x00100073`，进入 HALT 或 done 状态 |
| 基础仿真 | 负责 basic、load_store、branch 的第一轮 xsim 仿真 |

### 5.3 负责文件

| 文件/目录 | 说明 |
|---|---|
| `src/core/alu.v` | ALU |
| `src/core/regfile.v` | 寄存器堆 |
| `src/core/control_unit.v` | 控制器 |
| `src/core/imm_gen.v` | 立即数生成 |
| `src/core/branch_unit.v` | 分支判断 |
| `src/core/cpu_top.v` | 多周期 CPU 顶层 |
| `sim/tb/tb_alu.v` | ALU testbench |
| `sim/tb/tb_regfile.v` | regfile testbench |
| `sim/tb/tb_cpu_basic.v` | CPU 基础 testbench |
| `tests/basic/` | 基础指令测试程序 |
| `tests/load_store/` | load/store 测试程序 |
| `tests/branch/` | 分支测试程序 |

### 5.4 拆分到 B 的测试/性能任务

1. ALU 单元测试。
2. regfile 单元测试。
3. control、imm、branch 控制路径测试。
4. basic program xsim 仿真。
5. LW/SW xsim 仿真，并与 C 协同定位 memory 接口问题。
6. BEQ/BNE xsim 仿真。
7. basic program 是否能跑到 EBREAK/HALT。
8. 初步记录基础 CPU 每类指令的周期数。
9. 为报告提供 FETCH、DECODE、EXECUTE、MEMORY、WRITEBACK 波形截图和解释。

### 5.5 完成标准

1. ADD、SUB、ADDI、AND、OR、XOR 正确。
2. LW/SW 正确。
3. BEQ/BNE 正确。
4. EBREAK 后 done 或 halted 状态正确。
5. basic program 通过 Vivado xsim。
6. 波形截图能说明多周期 FSM 流程。

## 6. C 胡文龙职责

### 6.1 定位

C 负责把 CPU 接入 BRAM、MMIO、LED、拨码开关、数码管和 Minisys 板级顶层，使系统具备上板展示能力。

### 6.2 具体职责

| 模块 | 任务 |
|---|---|
| `instr_mem` | 指令 BRAM，支持 `$readmemh` 初始化 |
| `data_mem` | 数据 BRAM，支持 LW/SW |
| `mem_bus` | 区分 data memory 和 MMIO 地址空间 |
| MMIO | 实现 LED、switch、seg7、status、result 等寄存器映射 |
| `gpio_led` | LED 状态输出 |
| `gpio_switch` | 拨码开关输入 |
| `seg7_driver` | 七段数码管扫描显示 |
| `soc_top` | 集成 CPU、memory 和 I/O |
| `minisys_top` | 板级顶层，已按确认的 Minisys 约束统一端口映射 |
| Vivado | 综合、实现、bitstream、上板显示验证 |

### 6.3 负责文件

| 文件/目录 | 说明 |
|---|---|
| `src/memory/instr_mem.v` | 指令存储器 |
| `src/memory/data_mem.v` | 数据存储器 |
| `src/memory/mem_bus.v` | 存储器和 MMIO 总线 |
| `src/io/gpio_led.v` | LED 输出 |
| `src/io/gpio_switch.v` | 拨码输入 |
| `src/io/seg7_driver.v` | 数码管显示 |
| `src/soc/soc_top.v` | SoC 顶层 |
| `src/board/minisys_top.v` | Minisys 板级顶层 |
| `constraints/minisys.xdc` | Minisys 项目主线约束，已按老师资料核对 |
| `scripts/` | Vivado/xsim 辅助脚本 |
| `reports/vivado/` | utilization、timing、bitstream 截图 |

### 6.4 拆分到 C 的测试/性能任务

1. BRAM 初始化是否正确。
2. CPU 访问 data memory 是否正确。
3. MMIO 地址译码是否正确。
4. LED 是否能显示 running、done、error、mac_mode 等状态。
5. 数码管是否能显示 result、cycle_count 或 mac_count 低位。
6. Vivado synthesis、implementation、bitstream 是否通过。
7. 导出 utilization report。
8. 导出 timing summary。
9. 提供上板照片或视频材料。

### 6.5 完成标准

1. 仿真中 CPU 能访问 data_mem 和 MMIO。
2. LED 能显示 running、done、error、mac_mode 中的核心状态。
3. 数码管至少能显示 result 或 cycle_count 低 32 位。
4. bitstream 能生成。
5. 上板有可拍照或录像的演示结果。
6. `reports/vivado/` 下有 utilization 和 timing 数据。

## 7. D 王博生职责

### 7.1 定位

D 负责项目的拓展亮点，重点是 MAC 自定义指令、性能计数器、普通点积与 MAC 点积对比、PPA 初稿和流水线冲刺。

### 7.2 具体职责

| 模块 | 任务 |
|---|---|
| `mac_unit` | 实现 `rd_new = rd_old + rs1 * rs2` |
| regfile 第三读口 | 与 B 协调 `rd_old_data` 接口 |
| MAC 控制信号 | 与 B 配合增加 `is_mac`、`mac_enable`、`wb_sel` 等控制路径 |
| `csr_perf_counter` | 统计 `cycle_count`、`instret_count`、`mac_count` |
| 点积测试 | 准备普通点积和 MAC 点积测试程序 |
| 性能初测 | 对比周期数、指令数、CPI 和 speedup |
| PPA 初稿 | 整理 MAC 前后 LUT、FF、BRAM、DSP、Timing 差异 |
| 流水线冲刺 | 时间允许再做 IF/ID/EX/MEM/WB、forwarding、stall、flush |

### 7.3 负责文件

| 文件/目录 | 说明 |
|---|---|
| `src/core/mac_unit.v` | MAC 单元 |
| `src/core/csr_perf_counter.v` | 性能计数器 |
| `tests/mac/` | MAC 点积测试 |
| `tests/perf/` | 性能测试 |
| `tests/hazard/` | 流水线冲刺测试 |
| `sim/tb/tb_mac.v` | MAC testbench |
| `sim/tb/tb_perf_counter.v` | 性能计数器 testbench |
| `sim/tb/tb_pipeline_hazard.v` | 流水线冲刺 testbench |
| `docs/design/mac_extension.md` | MAC 指令设计 |
| `docs/design/performance.md` | 性能计数和 PPA 规划 |
| `reports/tables/` | PPA 和性能表格初稿 |

### 7.4 拆分到 D 的测试/性能任务

1. MAC 单元测试。
2. MAC 指令集成测试。
3. 普通点积程序测试。
4. MAC 点积程序测试。
5. `cycle_count` 是否正确。
6. `instret_count` 是否正确。
7. `mac_count` 是否正确。
8. 普通点积和 MAC 点积结果是否一致。
9. MAC 版本是否降低周期数，若未降低需解释原因。
10. 初步填写周期数、指令数、CPI、speedup 和 PPA 对比表。

### 7.5 完成标准

1. MAC 单元仿真通过。
2. MAC 指令能写回 rd。
3. 普通点积和 MAC 点积 result 一致。
4. MAC 版本周期数更少，或报告中能说明性能和时序权衡。
5. `cycle_count`、`instret_count`、`mac_count` 可读且来源明确。
6. PPA 表格有初步数据。
7. 流水线若未完成，不影响主线验收。

## 8. 测试与性能拆分总表

| 测试/性能内容 | 负责人 | 协作人 | 说明 |
|---|---|---|---|
| ALU 单测 | B | A 复核接口 | 谁写 ALU，谁测 ALU |
| regfile 单测 | B | D 协调第三读口 | MAC 需要 rd 原值 |
| control/imm/branch 测试 | B | A 复核 ISA 口径 | 属于 CPU 控制核心 |
| basic 指令测试 | B | A 复核验收口径 | 验证基础 CPU |
| LW/SW 测试 | B | C | B 验 CPU，C 验 memory |
| BRAM 初始化测试 | C | B | 属于 memory/SoC |
| MMIO 测试 | C | A 复核地址表 | 属于 I/O 地址映射 |
| LED/数码管上板测试 | C | A 协调展示流程 | 属于硬件验证 |
| MAC 单元测试 | D | B 协调 regfile/control | 属于拓展模块 |
| MAC 指令集成测试 | D | B | B 负责译码写回，D 负责 MAC 功能 |
| perf counter 测试 | D | A 复核计数口径 | 属于性能统计 |
| 普通点积/MAC 点积 | D | B/C | B 确认 CPU 执行，C 确认显示通路 |
| Vivado utilization | C | D 分析，A 复检 | C 导出，D 分析，A 复检 |
| timing summary | C | D 分析，A 复检 | C 导出，D 分析，A 复检 |
| PPA 表格初稿 | D | C 提供 Vivado 数据 | D 初填 |
| PPA 表格复检 | A | D | 防止数据错误 |
| AI 日志 | 每位成员 | A 检查 | 谁使用 AI，谁记录 |
| 最终报告整理 | A | B/C/D 写各自小节 | 统一格式和口径 |

## 9. 一周开发节奏建议

| 日期 | A 刘文涛 | B 张淇 | C 胡文龙 | D 王博生 | 当日完成标准 |
|---|---|---|---|---|---|
| 第 1 天 | 冻结 ISA、memory map、interfaces、task_board | 根据 ISA 设计 ALU/regfile/control 接口 | 根据 memory map 设计 mem_bus/MMIO/seg7 接口 | 根据 MAC 方案设计 mac_unit/perf_counter 接口 | 公共接口冻结，成员明确文件路径 |
| 第 2 天 | 审核接口，建立集成分支策略 | 完成 ALU、regfile、imm_gen、branch_unit 初版 | 完成 instr_mem、data_mem 初版 | 完成 mac_unit、perf_counter 初版 | 小模块单测基本通过 |
| 第 3 天 | 协调 B/C 接口，准备 basic program | 完成多周期 `cpu_top` FSM | 配合接入 instr_mem/data_mem | 准备点积测试和性能计数接口 | basic program 能跑到 EBREAK |
| 第 4 天 | 合并 CPU + memory + I/O，检查文档同步 | 修 CPU bug | 完成 soc_top、gpio、seg7、minisys_top | 接入 perf_counter，统计 cycle/instret | result/cycle_count 可通过仿真或 MMIO 通路读出 |
| 第 5 天 | 管控 MAC 集成，不让接口失控 | 配合 D 增加 MAC 译码和写回 | 准备 result/cycle/mac_count 上板显示 | 完成 MAC 指令集成、点积测试、周期对比 | 普通点积与 MAC 点积结果一致 |
| 第 6 天 | 复检性能表，整理报告结构 | 修 CPU 最后 bug，补 CPU 设计说明 | Vivado 综合、实现、上板、导出 utilization/timing | 整理 MAC/PPA 数据，补性能分析 | bitstream 生成，性能表初稿完成 |
| 第 7 天 | 最终报告整合、答辩稿、贡献度说明 | 写 CPU 数据通路与控制器部分 | 写 SoC/I/O/上板验证部分 | 写 MAC/性能/PPA/流水线冲刺部分 | 报告、截图、Git 记录、AI 日志完整 |

## 10. 报告撰写分工

| 报告部分 | 负责人 | 说明 |
|---|---|---|
| 项目背景、总体设计目标 | A | 统一项目主线 |
| 硬件平台与开发环境 | A + C | 包含 Vivado 2018.3、Minisys、xsim |
| ISA 与 memory map | A | 与设计文档保持一致 |
| CPU 数据通路与控制器 | B | 包含 FSM、控制信号、关键波形 |
| 多周期 CPU 设计 | B | 说明 FETCH/DECODE/EXECUTE/MEMORY/WRITEBACK |
| 存储系统与 MMIO | C | 包含 BRAM、地址译码、I/O 映射 |
| LED/数码管上板演示 | C | 包含照片、视频截图、Vivado 结果 |
| MAC 指令设计 | D | 包含指令语义、数据路径、写回 |
| 性能计数器与点积对比 | D | 包含 cycle、instret、mac_count |
| PPA 分析 | D 初稿，A 复检 | 资源和时序数据需有截图来源 |
| 调试问题与解决方案 | 各成员写各自部分，A 汇总 | 按模块归档 |
| AI 使用记录 | 各成员记录，A 汇总 | 对应 `docs/ai_logs/ai_usage_log.md` |
| 小组分工与贡献度 | A | 根据本文件、Git 记录和报告内容整理 |

## 11. 组内统一要求

1. 每个人优先修改自己负责目录下的文件。
2. 涉及公共接口必须先同步 `docs/design/interfaces.md`，并由 A 确认。
3. 每次使用 AI 生成或修改代码必须记录到 `docs/ai_logs/ai_usage_log.md`。
4. 每个模块必须配 testbench 或最小测试程序。
5. `main` 分支不能长期保留不可运行版本。
6. Vivado 临时文件不要提交。
7. 所有最终验收仿真结论以 Vivado xsim 结果为准。

## 12. 一句话分工总结

B 让 CPU 跑起来，C 让系统能上板，D 让项目有 MAC 和性能亮点，A 让所有模块能集成、数据可信、报告能交付。
