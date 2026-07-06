# 任务看板与分工建议

用途：拆分第一版开发任务，定义优先级、负责人建议、完成标准和 Git 提交节点。

最后更新时间：2026-07-06

## 1. 优先级定义

- P0：保底必做，决定能否验收。
- P1：主线进阶，决定项目亮点。
- P2：冲刺项，时间允许再做。

## 2. P0 任务表

| 任务 | 文件/目录 | 负责人建议 | 完成标准 |
|---|---|---|---|
| ISA 文档 | `docs/design/isa.md` | 组长/CPU | 指令编码冻结 |
| Memory map | `docs/design/memory_map.md` | SoC/I/O | 地址冻结 |
| 架构文档 | `docs/design/architecture.md` | 组长 | 接口清晰 |
| ALU/regfile | `src/core/` | CPU 数据通路负责人 | 单测通过 |
| control/imm/branch | `src/core/` | CPU 控制负责人 | basic 仿真通过 |
| instr/data memory | `src/memory/` | SoC 负责人 | LW/SW 通过 |
| cpu_top | `src/core/` | 组长 + CPU | basic program 通过 |

## 3. P1 任务表

| 任务 | 文件/目录 | 负责人建议 | 完成标准 |
|---|---|---|---|
| MMIO/LED/seg7 | `src/io/` | 硬件验证负责人 | 上板显示 |
| soc/minisys top | `src/soc/`, `src/board/` | SoC 负责人 | bitstream 生成 |
| perf counter | `src/core/` | 性能/报告负责人 | 计数正确 |
| MAC | `src/core/mac_unit.v` | MAC 负责人 | 点积正确 |
| 点积测试 | `tests/mac/` | 测试负责人 | 周期可比 |

## 4. P2 任务表

| 任务 | 文件/目录 | 负责人建议 | 完成标准 |
|---|---|---|---|
| Vivado 数据 | `reports/vivado/` | 报告负责人 | 表格完整 |
| 流水线冲刺 | `src/core/` | 流水线负责人 | 可选通过 |
| UART 输出 | `src/io/` | SoC/I/O | 可选展示 |
| hazard 测试 | `tests/hazard/` | 测试负责人 | 可选通过 |

## 5. 成员职责建议

| 角色 | 职责 |
|---|---|
| 组长/架构集成 | 架构、接口冻结、合并、答辩主线 |
| CPU 负责人 | ALU、regfile、control、imm、branch、cpu_top |
| SoC/I/O 负责人 | memory、mem_bus、gpio、seg7、minisys_top、xdc |
| 测试/性能/MAC 负责人 | MAC、testbench、点积程序、PPA、报告图表 |

## 6. Git 提交节点建议

```text
docs: define mvp architecture and interfaces
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
