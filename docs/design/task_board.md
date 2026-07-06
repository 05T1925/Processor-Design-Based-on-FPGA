# 任务看板与分工

用途：拆分第一版开发任务，定义优先级、负责人、路径、依赖、完成标准和当前状态。

最后更新时间：2026-07-06

## 1. 优先级定义

- P0：保底必做，决定能否验收。
- P1：主线进阶，决定项目亮点。
- P2：冲刺项，时间允许再做。

状态使用：

```text
TODO
IN_PROGRESS
BLOCKED
DONE
```

测试和性能任务拆分到对应模块负责人：CPU 基础测试归 B，BRAM/MMIO/上板测试归 C，MAC/性能/PPA 初稿归 D，性能复检和报告整合归 A。

## 2. P0 任务

| 优先级 | 任务 | 负责人 | 路径 | 依赖 | 完成标准 | 状态 |
|---|---|---|---|---|---|---|
| P0 | ISA 冻结 | A 刘文涛 | `docs/design/isa.md` | 课程要求、CPU 指令范围 | RV32I 子集和 MAC 扩展编码明确 | DONE |
| P0 | memory map 冻结 | A 刘文涛 + C 胡文龙 | `docs/design/memory_map.md` | SoC/MMIO 需求 | RAM、MMIO、status/result 地址明确 | DONE |
| P0 | 公共接口规范 | A 刘文涛 | `docs/design/interfaces.md` | ISA、memory map、模块划分 | clk/rst、CPU、memory、I/O、MAC 接口可执行；板级端口待官方 `.xdc` 后核对 | DONE |
| P0 | ALU | B 张淇 | `src/core/alu.v`, `sim/tb/tb_alu.v` | ISA | 单测通过，基础运算正确 | TODO |
| P0 | regfile | B 张淇 | `src/core/regfile.v`, `sim/tb/tb_regfile.v` | interfaces、MAC 第三读口需求 | x0 恒为 0，读写和第三读口正确 | TODO |
| P0 | control/imm/branch | B 张淇 | `src/core/control_unit.v`, `src/core/imm_gen.v`, `src/core/branch_unit.v` | ISA | 基础指令控制信号和分支判断正确 | TODO |
| P0 | 多周期 `cpu_top` | B 张淇 | `src/core/cpu_top.v`, `sim/tb/tb_cpu_basic.v` | ALU、regfile、control、memory 接口 | basic program 用 xsim 跑到 EBREAK/HALT | TODO |
| P0 | 基础指令测试 | B 张淇 | `tests/basic/`, `tests/load_store/`, `tests/branch/` | CPU 基础模块 | basic、LW/SW、BEQ/BNE 仿真通过 | TODO |
| P0 | 指令/数据存储器 | C 胡文龙 | `src/memory/instr_mem.v`, `src/memory/data_mem.v` | memory map、CPU memory 接口 | `$readmemh` 初始化、LW/SW 访问正确 | TODO |
| P0 | 开发规范和协作流程 | A 刘文涛 | `docs/design/development_rules.md`, `docs/team/` | 成员分工 | 成员能按文档开始协作 | DONE |

## 3. P1 任务

| 优先级 | 任务 | 负责人 | 路径 | 依赖 | 完成标准 | 状态 |
|---|---|---|---|---|---|---|
| P1 | mem_bus 与 MMIO | C 胡文龙 | `src/memory/mem_bus.v`, `src/io/` | memory map、CPU memory 接口 | data memory 与 MMIO 地址译码正确 | TODO |
| P1 | LED/拨码/数码管 | C 胡文龙 | `src/io/gpio_led.v`, `src/io/gpio_switch.v`, `src/io/seg7_driver.v` | MMIO、board_demo | LED 显示状态，seg7 显示 result/cycle | TODO |
| P1 | `soc_top` 集成 | C 胡文龙 + A 刘文涛 | `src/soc/soc_top.v` | CPU、memory、MMIO | CPU + memory + I/O 仿真连通 | TODO |
| P1 | `minisys_top` 和约束 | C 胡文龙 | `src/board/minisys_top.v`, `constraints/minisys.xdc` | 组长安装环境后确认官方 `.xdc` | 端口与官方约束一致，bitstream 可生成 | BLOCKED |
| P1 | `mac_unit` | D 王博生 | `src/core/mac_unit.v`, `sim/tb/tb_mac.v` | regfile 第三读口 | MAC 单测通过，结果可写回 | TODO |
| P1 | MAC 控制与写回集成 | D 王博生 + B 张淇 | `src/core/control_unit.v`, `src/core/cpu_top.v` | `mac_unit`、control、regfile | MAC 指令能译码、执行、写回 rd | TODO |
| P1 | 性能计数器 | D 王博生 | `src/core/csr_perf_counter.v`, `sim/tb/tb_perf_counter.v` | CPU halted/retire/mac pulse | cycle、instret、mac_count 统计正确 | TODO |
| P1 | 点积对比测试 | D 王博生 | `tests/mac/`, `tests/perf/` | MAC 集成、perf counter | 普通点积与 MAC 点积结果一致，周期可比较 | TODO |
| P1 | Vivado utilization/timing 导出 | C 胡文龙 | `reports/vivado/` | 可综合工程 | utilization 和 timing summary 有截图或报告 | TODO |
| P1 | PPA 表格初稿 | D 王博生 | `reports/tables/` | Vivado 数据、性能计数 | 周期、CPI、LUT、FF、BRAM、DSP、timing 字段完整 | TODO |
| P1 | 性能复检和报告整合 | A 刘文涛 | `reports/`, `docs/ai_logs/ai_usage_log.md` | B/C/D 测试结果 | 数据来源可信，报告口径统一 | TODO |

## 4. P2 任务

| 优先级 | 任务 | 负责人 | 路径 | 依赖 | 完成标准 | 状态 |
|---|---|---|---|---|---|---|
| P2 | 五级流水线冲刺 | D 王博生 | `src/core/`, `docs/design/performance.md` | 多周期 CPU 已稳定 | 有设计说明或可运行原型，不影响主线 | TODO |
| P2 | forwarding/stall/flush | D 王博生 | `tests/hazard/`, `sim/tb/tb_pipeline_hazard.v` | 流水线原型 | hazard 测试可解释 | TODO |
| P2 | UART 输出统计 | C 胡文龙 | `src/io/` | SoC 已稳定 | 可选输出性能数据 | TODO |
| P2 | 更多性能分析图表 | A 刘文涛 + D 王博生 | `reports/tables/` | PPA 数据 | 图表可用于答辩 | TODO |

## 5. 成员职责索引

详细职责、测试拆分、报告分工见：

- `docs/team/member_roles.md`
- `docs/team/daily_workflow.md`
- `docs/team/review_checklist.md`

## 6. Git 提交节点建议

```text
docs: add team roles and collaboration rules
docs: define rv32i subset and memory map
rtl: add alu and regfile
sim: add alu and regfile tests
rtl: add multi-cycle cpu basic path
sim: add cpu basic program
rtl: integrate bram and mmio
rtl: add mac extension
test: add dot product comparison
report: add vivado performance data
```
