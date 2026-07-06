# 第二阶段 MVP 规划记录

用途：记录最小可行实现方案、组长确认决策、文件生成清单和组员阅读顺序。

最后更新时间：2026-07-06

## 1. 本轮目标

将第二阶段“最小可行实现方案”拆分为可协作开发的 Markdown 文档，作为后续多人 vibecoding / Codex 分模块开发标准。

## 2. 组长确认的 6 项决策

1. 第一版 CPU 采用多周期 FSM，状态至少包括 FETCH、DECODE、EXECUTE、MEMORY、WRITEBACK、HALT。
2. MAC 接受 `rd_old` 第三读口方案，语义为 `rd_new = rd_old + rs1 * rs2`。
3. HALT 统一使用 `EBREAK = 0x00100073`。
4. `.xdc` 到位后，LED、数码管、拨码等命名按官方约束统一；临时端口由 `minisys_top` 映射。
5. 第一阶段手写少量机器码，第二阶段用 Python 脚本生成 `.mem`，暂不写完整 assembler。
6. 统一使用 Vivado xsim；ModelSim 只作为个人可选。

## 3. 最小可行系统定义

```text
RV32I 子集多周期 CPU
+ BRAM 指令/数据存储器
+ memory-mapped I/O
+ 性能计数器
+ MAC 自定义指令
+ 点积程序对比
+ PPA 分析
```

## 4. 保底目标

- CPU 支持基础指令。
- BRAM 程序和数据可运行。
- LED/数码管上板演示。
- xsim 仿真通过。
- Vivado bitstream 生成。

## 5. 主线目标

- MAC 自定义指令。
- cycle_count、instret_count、mac_count。
- 普通点积与 MAC 点积对比。
- Vivado utilization/timing 数据。
- PPA 分析。

## 6. 冲刺目标

- 五级流水线基础版本。
- forwarding。
- load-use stall。
- branch flush。
- UART 输出统计。

## 7. 文件生成清单

- `docs/design/architecture.md`
- `docs/design/isa.md`
- `docs/design/memory_map.md`
- `docs/design/mac_extension.md`
- `docs/design/performance.md`
- `docs/design/interfaces.md`
- `docs/design/test_plan.md`
- `docs/design/board_demo.md`
- `docs/design/development_rules.md`
- `docs/design/task_board.md`
- `docs/design/risk_plan.md`
- `docs/ai_logs/ai_usage_log.md`
- `docs/planning/round2_mvp_plan.md`
- `README.md`
- `.gitignore`

## 8. 下一步开发入口

下一步先冻结文档：

1. `docs/design/interfaces.md`
2. `docs/design/isa.md`
3. `docs/design/memory_map.md`

再开始 P0 模块开发：

1. `alu`
2. `regfile`
3. `control_unit`
4. `imm_gen`
5. `branch_unit`
6. `instr_mem/data_mem`
7. `cpu_top`

## 9. 给组员的阅读顺序

1. `README.md`
2. `docs/design/architecture.md`
3. `docs/design/interfaces.md`
4. `docs/design/isa.md`
5. `docs/design/memory_map.md`
6. `docs/design/task_board.md`
7. `docs/design/development_rules.md`
