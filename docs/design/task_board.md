# 任务看板与分工（四仓库深度合并后更新版）

用途：拆分合并后的开发任务，定义优先级、负责人、路径、依赖、完成标准和当前状态。

最后更新时间：2026-07-09（组长A更新：反映 B 完成综合/实现/bitstream + A 完成 RTL 修复后的真实进度）

## 1. 优先级定义

- P0：保底必做，决定能否验收。
- P1：主线进阶，决定项目亮点。
- P2：冲刺项，时间允许再做。

状态使用：

```text
TODO          →  待开始
IN_PROGRESS   →  进行中
BLOCKED       →  被阻塞
DONE          →  已完成
```

## 2. P0 任务（保底必做 —— 当前阶段重点）

| 优先级 | 任务 | 负责人 | 路径 | 依赖 | 完成标准 | 状态 |
|---|---|---|---|---|---|---|
| P0 | ISA 冻结 | A | `docs/design/isa.md` | 课程要求 | RV32I+MAC编码明确 | **DONE** |
| P0 | memory map 冻结（统一总线版） | A | `docs/design/memory_map.md` | 统一总线架构 | 统一总线地址映射明确 | **DONE** |
| P0 | 公共接口规范 | A | `docs/design/interfaces.md` | ISA、memory map、模块划分 | 接口可执行 | **DONE** |
| P0 | 四仓库分析选型 | A | `docs/planning/four_repo_deep_merge_plan.md` | 6参考仓库 | 组件来源决策明确 | **DONE** |
| P0 | 统一总线架构实现 | A | `src/bus/`、`src/memory/`、`src/io/`、`src/common/`、`src/soc/soc_top.v` | 参考SEU-Class2+minisys_unified | ibus/dbus+仲裁器+统一外设接口就位 | **DONE** |
| P0 | RV32I多周期FSM CPU+MAC | A | `src/core/`（全部14个文件，含riscv_sc_wrapper占位） | ISA、参考riscv-minisys+NCUT+SEU | 31条RV32I+MAC+6状态FSM代码就位 | **DONE** |
| P0 | 全局宏定义头文件 | A | `src/core/public.vh` | RV32I+MIPS+总线+ALU | 280行宏定义完整 | **DONE** |
| P0 | CPU_MODE 参数化框架 | A | `src/core/cpu_top.v`、`src/core/riscv_mc_wrapper.v` | 参考minisys_unified | generate块多核切换就位 | **DONE** |
| P0 | 整合报告与文档同步 | A | `docs/planning/integration_report.md`、`docs/team/member_roles.md`、本文件 | 合并完成 | 文档与RTL一致 | **DONE** |
| P0 | 开发规范和协作流程 | A | `docs/design/development_rules.md`、`docs/team/` | 成员分工 | 成员能按文档开始协作 | **DONE** |
| P0 | Vivado 2018.3 代码兼容性检查 | A | `docs/planning/compliance_check_report.md` | 全部RTL | 零不适配语法，约束100%一致 | **DONE** |
| P0 | RTL bug 修复（综合阻断项） | A | `pc_reg.v`/`data_ram.v`/`inst_ram.v`/`soc_top.v`/`minisys_top.v`/`riscv_sc_wrapper.v` | C组诊断+预判分析 | 7处修复，双版本兼容 | **DONE** |
| P0 | ALU 单元测试 | B | `sim/tb/tb_alu.v` | ALU代码 | xsim单测通过，7类运算全覆盖 | **DONE** |
| P0 | regfile 单元测试 | B | `sim/tb/tb_regfile.v` | regfile代码 | x0=0、3读1写、内部前推通过 | **DONE** |
| P0 | control_unit 译码验证 | B | `sim/tb/tb_control_unit.v` | control_unit代码 | 32条指令译码正确 | **DONE** |
| P0 | CPU basic xsim 仿真 | B | `sim/tb/tb_cpu_basic.v`、`sim/programs/basic_test.hex` | ALU/regfile/control | basic program到EBREAK，debug_pc=0x20, x3/x6/data_ram[0]=0x1e | **DONE** |
| P0 | Vivado 工程建立 | B/C | Vivado 2018.3/2017.4 | RTL代码 | 工程可打开，全部源文件已添加 | **DONE** |
| P0 | Vivado synthesis | B | Vivado 2018.3 | 全部RTL | **WNS=7.212ns, TNS=0, DRC=0** ✅ | **DONE** |
| P0 | Vivado implementation | B | Vivado 2018.3 | synthesis通过 | **WHS=0.241ns, THS=0** ✅ | **DONE** |
| P0 | bitstream 生成 | B | Vivado 2018.3 | impl通过 | **minisys_top.bit 已产出** ✅ | **DONE** |
| P0 | 约束配置电压修复 | B | `constraints/minisys.xdc` | impl DRC | CFGBVS VCCO + CONFIG_VOLTAGE 3.3 已添加 | **DONE** |
| P0 | 上板 LED/数码管 演示 | C | Minisys板 | bitstream | 有可展示结果 | **TODO** |

## 3. P1 任务（主线进阶）

| 优先级 | 任务 | 负责人 | 路径 | 依赖 | 完成标准 | 状态 |
|---|---|---|---|---|---|---|
| P1 | mac_unit 单元测试 | D | `sim/tb/tb_mac.v` | mac_unit代码 | 单测覆盖正数/0/溢出/累加 | TODO |
| P1 | perf_counter 单元测试 | D | `sim/tb/tb_perf_counter.v` | csr_perf_counter代码 | cycle/instret/mac计数正确 | TODO |
| P1 | 普通点积测试程序 | D | `tests/mac/` | CPU xsim通过 | 手写RV32I点积程序 | TODO |
| P1 | MAC 点积测试程序 | D | `tests/mac/` | CPU xsim通过+MAC | 使用MAC指令的点积程序 | TODO |
| P1 | 点积对比：result+cycle+CPI | D | `reports/tables/` | 点积测试完成 | result一致，周期可比较 | TODO |
| P1 | Vivado utilization/timing 导出 | B/C | `reports/vivado/` | bitstream生成 | 有截图或报告 | **IN_PROGRESS** |
| P1 | PPA 表格初稿 | D | `reports/tables/` | Vivado数据 | LUT/FF/BRAM/DSP/Timing字段完整 | TODO |
| P1 | RV32I单周期wrapper接入 | A | `src/core/riscv_sc_wrapper.v` | 参考riscv-minisys-cpu | 占位已创建，P1填入真实逻辑 | **IN_PROGRESS** |
| P1 | 性能计数器MMIO暴露 | D | `src/soc/soc_top.v`修改 | perf_counter验证通过 | MMIO可读性能计数器值 | TODO |
| P1 | LW/SW xsim 仿真 | B | `sim/tb/`、`tests/load_store/` | CPU basic通过 | 访存指令正确 | TODO |
| P1 | BEQ/BNE xsim 仿真 | B | `sim/tb/`、`tests/branch/` | CPU basic通过 | 6种分支条件正确 | TODO |

## 4. P2 任务（冲刺项，不阻塞主线）

| 优先级 | 任务 | 负责人 | 路径 | 依赖 | 完成标准 | 状态 |
|---|---|---|---|---|---|---|
| P2 | 五级流水线冲刺 | D | `src/core/pipeline/` | 多周期CPU稳定 | 有设计说明或可运行原型 | TODO |
| P2 | forwarding/stall/flush | D | `src/core/pipeline/` | 流水线原型 | hazard测试可解释 | TODO |
| P2 | BTB 分支预测 | D | `src/core/pipeline/btb.v` | 流水线原型 | 分支预测正确率可统计 | TODO |
| P2 | UART 外设实现 | C | `src/io/uart.v` | SoC稳定 | 可收发字符 | TODO |
| P2 | 更多性能分析图表 | A + D | `reports/tables/` | PPA数据 | 图表可用于答辩 | TODO |
| P2 | MIPS 模式接入 | A | `src/core/` | 参考minisys_unified各wrapper | CPU_MODE 2-4可用 | TODO |

## 5. 成员职责索引（截至 2026-07-09）

| 成员 | 已完成 | 当前任务 | 下一任务 |
|---|---|---|---|
| A 刘文涛 | ✅ 6仓库分析选型 + 24 RTL生成 + 文档同步 + 合规检查报告 + 7处RTL修复（pc_reg/$clog2/include路径/riscv_sc_wrapper/ifdef） | 文档同步更新、AI日志维护 | RV32I单周期wrapper实现、集成测试复核 |
| B 张淇 | ✅ 4个testbench（ALU/regfile/control/CPU basic）全部xsim通过 + Vivado工程搭建 + Synthesis/Implementation/Bitstream全部通过（WNS=7.212ns, TNS=0, DRC=0）+ 约束电压配置修复 | Vivado utilization/timing数据导出 | LW/SW/branch仿真、CPU周期记录 |
| C 胡文龙 | ✅ xsim全系统仿真验证通过 + 3处RTL bug诊断（pc_reg/$clog2/路径）+ Vivado 2017.4兼容性深度诊断 | 🔴 上板LED/数码管验证 | 上板演示录像/照片、UART（P2） |
| D 王博生 | — | 🔴 MAC/perf_counter testbench | 点积测试程序、PPA初稿 |

## 6. Git 提交节点（已完成 → 待完成）

```text
✅ docs: add four-repo deep merge plan
✅ docs: add integration report and updated division of labor
✅ rtl: add unified bus system and peripherals
✅ rtl: add rv32i multi-cycle cpu with mac and performance counters
✅ rtl: add soc integration and board-level top
✅ sim: add alu and regfile testbenches
✅ sim: add cpu basic program simulation
✅ fix: resolve Vivado synthesis blockers and RTL compatibility issues
✅ chore: update Vivado constraints and repo hygiene
⏳ rtl: add vivado project and synthesis results → B已产出数据，待C导出截图
⏳ test: add dot product comparison → D待执行
⏳ report: add vivado performance data → D待执行
```

## 7. 当前阻塞项与风险

| 阻塞/风险 | 影响 | 负责人 | 状态 | 解决方案 |
|---|---|---|---|---|
| ~~Vivado 2018.3 环境未确认~~ | ~~C无法建工程~~ | ~~C~~ | ✅ 已解决 | B已用Vivado 2018.3完成综合/实现/bitstream |
| ~~xsim 仿真未跑通~~ | ~~B无法验证CPU~~ | ~~B~~ | ✅ 已解决 | 4个testbench全部xsim通过 |
| ~~RTL语法错误阻断综合~~ | ~~综合失败~~ | ~~A~~ | ✅ 已解决 | pc_reg.v wire→reg修复；$clog2兼容双版本 |
| Vivado 2017.4 Win11综合崩溃 | C的综合卡住 | C | 🔴 待解决 | 方案A: GUI模式 / 方案C: Win7兼容模式 / 换2018.3 |
| 复位按钮极性待实测 | 上板可能异常 | C | 🟡 | Vivado最小工程实测P20 |
| D的MAC/性能工作未启动 | P1亮点缺失 | D | 🔴 | D需要尽快开始tb_mac和tb_perf_counter |
| LW/SW/Branch测试未覆盖 | 指令验证不完整 | B | 🟡 | basic_test.hex已覆盖LW/SW/BEQ，需扩展 |

## 8. Vivado 综合/实现验证结果（2026-07-09，B执行）

| 指标 | 结果 | 状态 |
|---|---|---|
| 综合 (Synthesis) | 通过 | ✅ |
| 实现 (Implementation) | 通过 | ✅ |
| WNS (最差负时序裕量) | **+7.212 ns** | ✅ 充裕 |
| TNS (总负时序裕量) | **0 ns** | ✅ |
| WHS (最差负保持裕量) | **+0.241 ns** | ✅ |
| THS (总负保持裕量) | **0 ns** | ✅ |
| DRC Violations | **0** | ✅ |
| Bitstream | **成功生成** | ✅ |
| 目标频率 | 100 MHz (10 ns周期) | ✅ 满足 |
| 约束配置电压 | CFGBVS VCCO + CONFIG_VOLTAGE 3.3 | ✅ 已添加 |

## 9. 项目整体完成度

```text
P0 保底任务   ███████████████ 96%  (22/23 DONE，仅缺上板演示)
P1 进阶任务   ████░░░░░░░░░░░ 30%  (3/10 IN_PROGRESS，7 TODO)
P2 冲刺任务   ░░░░░░░░░░░░░░░  0%  (0/6 DONE)

课程基础层次  ███████████████ 100% (含硬件综合验证)
课程进阶层次  ████████░░░░░░░  60% (SoC框架+综合通过，缺性能数据)
课程拓展层次  ████████░░░░░░░  65% (MAC+PPA框架完成，缺点积对比数据)
```
