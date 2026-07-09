# Processor-Design-Based-on-FPGA

基于 Minisys FPGA 的 RV32I 子集多周期 CPU 与 MAC 指令加速设计。

## 项目概况

- 课程题目：题目 B，基于 FPGA 开发板的处理器设计
- 硬件平台：Minisys FPGA 实验板 + EES-329B-V1.1 子板，Xilinx Artix-7 XC7A100T
- 开发环境：Vivado 2018.3，组内主仿真工具为 Vivado xsim
- **当前阶段**：✅ 五仓库深度合并已完成 | RTL 基础设施 + RV32I 多周期 FSM CPU + 五级流水线 CPU + 统一总线 SoC 已就位
- 项目状态：多周期+流水线双模式可切换，待 Vivado 综合流水线模式获取 PPA 数据

## 当前主线（统一架构版）

```text
┌─────────────────────────────────────────────────────────┐
│ RV32I 多周期 FSM CPU (P0基线) + MAC 自定义指令            │
│ + 统一共享总线 (ibus+dbus) + 仲裁器 + 总线解码器          │
│ + BRAM 指令/数据存储器 (行为级, $readmemh初始化)          │
│ + 标准化外设 (LED/Switch/SEG7/UART预留)                   │
│ + 性能计数器 (cycle/instret/mac)                          │
│ + 6种CPU模式可切换 (参数CPU_MODE)                         │
│   ├─ MODE 0: RV32I 多周期FSM ★ 主线                      │
│   ├─ MODE 1: RV32I 单周期 (参考)                          │
│   ├─ MODE 2: MIPS 单周期 (参考)                           │
│   ├─ MODE 3: MIPS 5级流水线 (参考)                        │
│   ├─ MODE 4: MIPS 5级流水线+CP0 (参考)                    │
│   └─ MODE 5: RV32I 五级流水线 (P2冲刺) 🆕                 │
│ + PPA 分析与点积程序对比                                   │
└─────────────────────────────────────────────────────────┘
```

五级流水线、forwarding、load-use stall、branch flush 已完成 🆕。**BTB 动态分支预测（16条目 2-bit）已完成 🆕**。UART 输出统计为后续冲刺目标。

## 仓库目录

```text
参考仓库/              已下载的4个开源MIPS仓库+riscv-minisys-cpu+minisys_unified
docs/course/       课程任务与环境资料
docs/hardware/     Minisys 与 EES-329B 资料
docs/design/       架构、接口、ISA、测试、规范文档
docs/team/         成员分工、每日流程、审查清单
docs/ai_logs/      AI 使用日志
docs/planning/     阶段规划记录
src/
├── core/          RV32I CPU 核心 (alu/regfile/control_unit/imm_gen/branch_unit/pc_reg/mac_unit/csr_perf_counter/cpu_top/riscv_mc_cpu/riscv_pipeline_cpu)
│   ├── public.vh  全局宏定义 (RV32I+MIPS+总线+ALU+CPU_MODE)
│   ├── riscv_pipe_wrapper.v 流水线CPU封装 🆕
│   └── pipeline/  BTB 分支预测器 🆕 (btb.v + br_predictor.v)
├── bus/           统一总线系统 (bus_decoder/bus_mux)
├── memory/        存储器 (inst_ram/data_ram)
├── io/            外设控制器 (gpio_led/gpio_switch/seg7_driver)
├── common/        通用模块 (sync/debounce/edge_det)
├── soc/           SoC集成顶层 (soc_top)
└── board/         板级顶层 (minisys_top)
sim/               后续 testbench、程序、波形
tests/             测试程序分类
constraints/       Minisys 约束文件
reports/           报告图表与 Vivado 数据
scripts/           后续 xsim/Vivado/Python 辅助脚本
```

## 四人角色概览

| 成员 | 姓名 | 角色 | 主责 |
|---|---|---|---|
| A | 刘文涛 | 组长 / 架构 / 集成 / 报告 | ISA、memory map、interfaces、集成、性能复检、报告 |
| B | 张淇 | CPU 数据通路与控制器 | ALU、regfile、control、imm、branch、cpu_top、基础仿真 |
| C | 胡文龙 | SoC / Memory / I/O / 上板验证 | BRAM、MMIO、LED、seg7、soc_top、minisys_top、Vivado |
| D | 王博生 | MAC / 性能 / 冲刺 | mac_unit、perf_counter、点积测试、CPI/PPA、流水线冲刺 |

测试/性能任务拆分到模块负责人：B 负责 CPU 基础测试，C 负责 BRAM/MMIO/上板测试，D 负责 MAC/性能/PPA 初稿，A 负责复检和报告整合。

## 组员进入项目后先读

1. `README.md`
2. `docs/PROJECT_INDEX.md`（项目文件全貌索引，给 AI agent 快速定位用）
3. `docs/team/member_roles.md`
4. `docs/design/task_board.md`
5. `docs/design/interfaces.md`
6. `docs/design/isa.md`
7. `docs/design/memory_map.md`
8. `docs/design/development_rules.md`
9. `docs/ai_logs/ai_usage_log.md`

## 协作入口

- 文件索引：`docs/PROJECT_INDEX.md`（所有文件内容摘要 + AI agent 推荐读取顺序）
- 成员分工：`docs/team/member_roles.md`
- B/C/D 开发入口：`docs/team/bcd_onboarding.md`
- 环境准备：`docs/team/setup_checklist.md`
- 每日流程：`docs/team/daily_workflow.md`
- 审查清单：`docs/team/review_checklist.md`
- 任务看板：`docs/design/task_board.md`
- 开发规范：`docs/design/development_rules.md`
- AI 日志：`docs/ai_logs/ai_usage_log.md`

## 环境准备

- 组员先按老师提供的安装包安装 Vivado 2018.3。
- 组内主仿真工具统一使用 Vivado xsim。
- ModelSim 可个人使用，但不是组内强制流程。
- 安装路径尽量不要包含中文或空格。
- 安装完成后截图或在群里说明环境已就绪。
- 不要把安装包、破解文件、license 文件、大型软件包上传到 GitHub。
- 不要把 Vivado 自动生成的临时工程文件提交到仓库。
- 环境装好后先阅读 README 和分工文档，再领取任务。

## Vivado 工程重建

- 本仓库不提交 Vivado 自动生成的工程产物，例如 `.xpr`、`.runs/`、`.sim/`、`.cache/`、bitstream 和中间报告。
- 克隆仓库后，请在 Vivado 2018.3 中手动新建工程，并添加 `src/` 下全部 RTL 源文件、`sim/tb/` 下需要的 testbench，以及 `constraints/minisys.xdc`。
- 顶层上板入口使用 `src/board/minisys_top.v`；仿真时按需要选择对应 testbench。
- 工程重建后再执行 `Synthesis -> Implementation -> Generate Bitstream`。

## 当前约束状态

- 已从老师资料中确认 Minisys 主约束来源，并整理为 `constraints/minisys.xdc`。
- 板级端口统一为 `clk/rst_n/sw[15:0]/led[15:0]/seg[7:0]/an[7:0]`。
- 四个参考仓库 `.xdc` 交叉验证 50 引脚 100% 一致。
- 约束审计见 `docs/design/board_constraints_audit.md` 和 `docs/hardware/minisys_pinout.md`。
- ✅ **Vivado 2018.3 综合/实现/bitstream 全部通过**（2026-07-09，B 执行）：WNS=+7.212ns, TNS=0, WHS=+0.241ns, THS=0, DRC=0。
- ✅ 配置电压约束已补充：`CFGBVS VCCO` + `CONFIG_VOLTAGE 3.3`。
- 🔄 待上板实测：P20 复位按钮极性。

## 当前项目状态

- ✅ 文档已冻结：`docs/design/isa.md`、`docs/design/memory_map.md`、`docs/design/interfaces.md`、`docs/design/board_demo.md`。
- ✅ Minisys 主线约束已整理到 `constraints/minisys.xdc`，配置电压约束已补充。
- ✅ 板级端口已统一，`minisys_top` 对外端口与 `.xdc` 保持一致。
- ✅ **四仓库深度合并已完成**：总线系统 / 存储器 / 外设 / RV32I多周期CPU / MAC / 性能计数器 RTL 已就位（25 个文件）。
- ✅ 合并方案文档：`docs/planning/four_repo_deep_merge_plan.md`。
- ✅ **xsim 仿真全部通过**（B+C）：4 个 testbench（ALU/regfile/control/CPU basic）全部 PASS。
- ✅ **Vivado 2018.3 综合/实现/bitstream 全部通过**（B）：100MHz 时序充裕，DRC=0。
- ✅ **RTL 综合阻断 bug 已修复**（A+C）：`pc_reg.v` wire→reg、`$clog2` 双版本兼容、include 路径、缺失模块补齐、ifdef 默认值修正。
- ✅ Vivado 2017.4 / 2018.3 双版本兼容性验证通过。
- ✅ **五级流水线 RTL 已完成**（2026-07-09，A）：CPU_MODE=5，forwarding + load-use stall + branch flush + JAL/JALR 冲刷，含冒险测试程序和仿真testbench。
- ✅ **BTB 动态分支预测已完成**（2026-07-09，A+AI）：16条目直接映射 2-bit 饱和计数器，IF阶段查找+EX阶段更新，流水线CPU集成，分支预测正确率可统计（MMIO 0xFCC0-C8），含测试平台和性能分析文档。
- 🔄 待完成：上板 LED/数码管演示（C）、流水线 Vivado 综合 PPA 导出（B/C）、LW/SW/Branch 扩展仿真（B）。

## B/C/D 队友快速开始（四仓库深度合并后更新 ⭐）

> **重要**：组长A已完成统一总线架构、RV32I多周期FSM CPU、MAC单元、性能计数器和全部外设的 RTL 代码（24个文件）。
> B/C/D 当前职责从"从零开发"转变为"**验证 + 调试 + 扩展**"。

### B 张淇：CPU xsim 仿真验证 ✅ 已完成 → 扩展测试 + Vivado 数据导出

先读：

1. `docs/planning/integration_report.md`（了解组长A已完成的整合工作）
2. `docs/design/isa.md`（RV32I编码）
3. `docs/design/interfaces.md`（公共接口）
4. `src/core/control_unit.v`（已写好的译码逻辑）
5. `src/core/riscv_mc_cpu.v`（已写好的6状态FSM CPU）
6. `docs/team/member_roles.md` §5（B的更新后的职责）

当前任务：

1. ~~**tb_alu.v**~~ ✅ 已完成（12个测试向量全部通过）
2. ~~**tb_regfile.v**~~ ✅ 已完成（x0=0、3读1写、内部前推全部通过）
3. ~~**tb_control_unit.v**~~ ✅ 已完成（32条指令译码全部通过）
4. ~~**tb_cpu_basic.v**~~ ✅ 已完成（CPU HALTED, debug_pc=0x20, 结果正确）
5. ~~Vivado synthesis/implementation/bitstream~~ ✅ 已完成（WNS=7.212ns, TNS=0, DRC=0）
6. **当前任务**：扩展 `tests/load_store/` 和 `tests/branch/` 的 LW/SW/BEQ/BNE 测试
7. **当前任务**：导出 Vivado utilization/timing 截图到 `reports/vivado/`

**禁止**：不要改 memory map、不要改 MAC 语义、不要改 C/D 的模块。

### C 胡文龙：上板验证 🔴 当前重点

先读：

1. `docs/planning/integration_report.md`（了解整合架构）
2. `docs/design/board_constraints_audit.md`
3. `docs/hardware/minisys_pinout.md`
4. `docs/design/board_demo.md`
5. `docs/design/memory_map.md`（统一总线版）
6. `docs/team/member_roles.md` §6（C的更新后的职责）

当前任务：

1. ~~Vivado 工程建立 + RTL 源文件添加~~ ✅ B 已完成（Vivado 2018.3）
2. ~~验证 `soc_top` 全系统集成仿真~~ ✅ xsim 通过（B+C 均确认）
3. ~~Synthesis → Implementation → Bitstream~~ ✅ B 已完成（WNS=7.212ns, DRC=0）
4. **当前任务 🔴**：实测 P20 复位按钮极性
5. **当前任务 🔴**：上板：LED 状态显示 + 数码管 result/cycle_count 显示
6. Vivado 2017.4 用户注意：batch 模式综合在 Win11 上有 IPC 兼容性 bug（`TclStackFree` 崩溃），建议使用 **GUI 模式**或对 `vivado.exe` 设置 **Windows 7 兼容模式**

**禁止**：不要改 CPU 译码、不要改 MAC 接口、不要改 regfile 第三读口。

### D 王博生：MAC / 性能 / 点积验证

先读：

1. `docs/design/mac_extension.md`
2. `docs/design/performance.md`
3. `docs/planning/integration_report.md`
4. `docs/team/member_roles.md` §7（D的更新后的职责）

当前任务：

1. ~~**tb_mac.v**：验证 `mac_unit`~~ ✅ 已完成
2. ~~**tb_perf_counter.v**：验证 cycle/instret/mac 计数~~ ✅ 已完成
3. ~~编写普通点积程序~~ ✅ 已完成（normal=70, 62cycle, 15instret）
4. ~~编写 MAC 点积程序~~ ✅ 已完成（MAC=70, 54cycle, 13instret, speedup=1.15×）
5. ~~xsim 对比~~ ✅ 已完成
6. PPA 表格初稿（需等C提供Vivado数据）

**禁止**：不要改基础CPU控制逻辑、不要改EBREAK/HALT、不要把流水线变P0。

## 资料与安装口径

- 全员必须安装 Vivado 2018.3、Git 和一个代码编辑器，并能拉取本仓库。
- 全员必读 `README.md`、`docs/team/member_roles.md`（整合后新版）、`docs/design/task_board.md`（整合后新版）、`docs/planning/integration_report.md`。
- 全员需要理解统一总线架构（ibus/dbus/仲裁器/二级地址译码）。
- C 重点看 Minisys 硬件手册、Minisys 资源信息、Minisys 基础开发包和 `constraints/minisys.xdc`。
- 参考仓库（`参考仓库/`）已包含6个完整项目代码，可作为实现细节参考。
- Nexys4DDR、TEC-PLUS、EGO1、ISE14.7、WiFi、蓝牙、电机、触摸屏资料不用于当前主线。

## 下一步顺序（当前阶段 ⭐）

1. ~~**B** 编写 `tb_alu.v`、`tb_regfile.v`、`tb_control_unit.v`，在 xsim 下单元验证 CPU 核心模块。~~ ✅ 已完成
2. ~~**C** 在 Vivado 2018.3 中建立最小工程，添加全部 RTL 源文件和 `.xdc`，实测 P20 复位极性。~~ ✅ B 已完成工程搭建
3. ~~**B** 编写 `tb_cpu_basic.v`，加载 `basic_test.hex`，验证多周期 FSM 全流程。~~ ✅ 已完成
4. ~~**B** 跑 Vivado synthesis/implementation/bitstream，保存截图。~~ ✅ 已完成（WNS=7.212ns, TNS=0, DRC=0）
5. ~~**D** 编写 MAC/性能计数器 testbench，准备点积测试程序。~~ ✅ 已完成
6. ~~**D** 对比普通点积和MAC点积的性能数据。~~ ✅ 已完成
7. ~~**A** 实现五级流水线 RTL（CPU_MODE=5）~~ 🆕 ✅ 已完成：forwarding + load-use stall + branch/JAL/JALR flush + hazard_test.hex
8. **C** 上板验证 LED/数码管显示。（当前任务 🔴）
9. **B** 扩展 LW/SW/Branch 仿真覆盖。
10. **B/C** Vivado 综合流水线模式（MODE=5），导出 PPA 数据到 `reports/vivado/`。
11. **A** 复核所有测试结果，整理 PPA 数据，写报告。

## 关键新文档（必读）

| 文档 | 内容 | 读者 |
|---|---|---|
| `docs/planning/four_repo_deep_merge_plan.md` | 六仓库分析选型 + 组件来源决策 + MIPS→RV32I改造 + 统一接口规范 | 全员 |
| `docs/planning/integration_report.md` | 组长A整合报告：设计决策过程 + 一致性验证（约束/ISA/接口/地址）+ 文件追溯 | 全员 |
| `docs/team/member_roles.md` | 整合后重新规划的ABCD分工（代码已由A完成→B/C/D负责验证调试扩展） | 全员 |
| `docs/design/task_board.md` | 整合后更新的任务看板（DONE/TODO状态 + 成员职责索引） | 全员 |
| `docs/design/memory_map.md` | 统一总线版地址映射（`0xFFFF_FCxx`外设区 + `addr[9:4]`二级译码） | B/C/D |
| `docs/planning/optimization_roadmap.md` 🆕 | 拓展方向可行性分析 + PPA资源预算 + 六方向推荐优先级 + 一周优化路线图 + 答辩主线建议 | 全员 |
| `docs/ai_logs/ai_declaration.md` 🆕 | AI辅助工具使用声明表（教师要求）：15个模块改造说明+独立设计占比+学术诚信承诺 | 全员 |
| `docs/planning/compliance_check_report.md` 🆕 | Vivado 2018.3代码兼容性 + 课程三级对齐 + 板级约束终检 + 问题清单与修复建议 | 全员 |

## 开发前规则

- 不要直接做 DDR3 / Cache / VGA / WiFi / 蓝牙 / 电机 / 触摸屏。
- 不要直接生成完整 CPU（组长A已完成代码框架，B/C/D在此基础上验证和扩展）。
- 不要在未更新文档的情况下修改公共接口。
- 不要直接在 `main` 上提交未验证代码。
- 不要复制开源 CPU 作为最终代码（借鉴设计模式而非照搬代码）。
- 不要没有 testbench 或测试结果就合并核心模块。
- 不要提交 Vivado 临时文件。
- 每次 AI 生成或修改代码必须记录到 `docs/ai_logs/ai_usage_log.md`。
- 不要提交安装包、license、破解文件或 bitstream 临时文件。
- 不要把 Nexys4DDR、EGO1、TEC-PLUS 等其他板卡约束混入 Minisys 主线。
- 公共接口变更必须先更新 `docs/design/interfaces.md` 并由 A 确认。
- `参考仓库/` 目录中的代码仅供设计参考，不要直接复制到 `src/`。
