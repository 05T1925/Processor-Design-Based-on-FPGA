# 审查清单

用途：提交 RTL、文档和合并前的统一检查清单。

最后更新时间：2026-07-06

## 1. RTL 模块提交前检查

| 检查项 | 结果 |
|---|---|
| 文件名和模块名是否一致 | TODO |
| 端口是否符合 `docs/design/interfaces.md` | TODO |
| 是否使用统一 `clk` / `rst` | TODO |
| 时序逻辑是否使用非阻塞赋值 | TODO |
| 组合逻辑是否给默认值 | TODO |
| `case` 是否有 `default` | TODO |
| 是否避免 latch | TODO |
| x0 是否恒为 0 | TODO |
| 位宽是否明确 | TODO |
| 是否避免未解释的 magic number | TODO |
| 是否有 testbench 或测试程序 | TODO |
| 是否通过 Vivado xsim 仿真 | TODO |
| 是否记录测试结果或截图路径 | TODO |

## 2. 文档提交前检查

| 检查项 | 结果 |
|---|---|
| 是否说明修改原因 | TODO |
| 是否更新接口文档 | TODO |
| 是否更新 `task_board.md` | TODO |
| 是否同步 README | TODO |
| 是否记录 AI 使用 | TODO |
| 是否有截图或数据来源 | TODO |
| 是否避免与已冻结 ISA / memory map 冲突 | TODO |
| 是否标注待人工确认事项 | TODO |

## 3. 合并前检查

| 检查项 | 结果 |
|---|---|
| 是否会破坏 `main` | TODO |
| 是否影响其他成员接口 | TODO |
| 是否需要组长确认 | TODO |
| 是否有仿真结果 | TODO |
| 是否有测试通过记录 | TODO |
| 是否有未提交的 Vivado 临时文件 | TODO |
| 是否同步 AI 日志 | TODO |
| 是否同步调试日志或报告材料 | TODO |

## 4. 成员专项检查

| 成员 | 必查项 |
|---|---|
| A | 接口文档、任务看板、报告口径、PPA 复检、AI 日志 |
| B | CPU 基础指令、regfile x0、EBREAK/HALT、basic/load_store/branch xsim |
| C | BRAM 初始化、MMIO 地址译码、LED/seg7 显示、Vivado utilization/timing |
| D | MAC 写回、perf counter、点积结果一致性、周期/CPI/PPA 初稿 |

## 5. 不允许合并的情况

- 未更新接口文档就修改公共端口。
- 未通过 xsim 或无人工检查记录就合并核心模块。
- 直接在 `main` 上提交未验证代码。
- 提交 Vivado 临时文件。
- 使用 AI 生成内容但未记录日志。
- 擅自扩大范围到 DDR3、Cache、VGA、WiFi、蓝牙、电机、触摸屏。
