# 性能计数器与 PPA 数据规划

用途：定义性能计数器、点积对比方法、Vivado 报告字段和最终报告表格。

最后更新时间：2026-07-09（D：完成计数链路、MMIO与点积辅助仿真）

## 1. 为什么需要性能计数

本项目不是只做“能运行的 CPU”，还需要证明优化有效。性能计数器用于量化：

- 普通点积和 MAC 点积的周期差异。
- CPI 变化。
- MAC 指令是否减少指令数或周期数。
- 性能提升是否值得额外资源开销。

## 2. 第一版必须统计

| 计数器 | 加 1 条件 |
|---|---|
| `cycle_count` | CPU 未 HALT 时每个时钟周期 |
| `instret_count` | 一条指令完成/退休 |
| `mac_count` | MAC 指令完成 |

退休状态约定：

- ALU、LOAD、JUMP、MAC：WRITEBACK 退休。
- STORE：MEMORY 退休。
- BRANCH：EXECUTE 退休。
- EBREAK 和非法指令不计入 `instret_count`。

第一版建议 HALT 后停止 `cycle_count`，方便上板显示稳定结果。

## 3. 冲刺版可统计

| 计数器 | 用途 |
|---|---|
| `stall_count` | 统计流水线暂停 |
| `flush_count` | 统计分支冲刷 |
| `branch_count` | 统计分支指令 |
| `branch_miss_count` | 统计分支预测失败，若实现预测 |

## 4. CPI 计算

```text
CPI = cycle_count / instret_count
```

硬件不做除法，CPI 在报告中用记录值计算。

## 5. 点积对比方法

同一组输入数据运行两版程序：

- 普通软件点积。
- MAC 点积。

比较：

```text
speedup = normal_cycle_count / mac_cycle_count
```

要求：

- 两版 result 一致。
- MAC 版 `mac_count > 0`。
- MAC 版周期数更少或报告中解释差异。

## 6. Vivado utilization 记录字段

至少记录：

- LUT。
- FF。
- BRAM。
- DSP。
- IO。

重点观察 MAC 是否推断出 DSP。

## 7. Vivado timing 记录字段

至少记录：

- Worst Negative Slack。
- Total Negative Slack。
- 是否满足 100 MHz 目标时钟。
- 可选记录估算 Fmax。

## 8. PPA 表格模板

| 版本 | 周期数 | 指令数 | CPI | LUT | FF | BRAM | DSP | Timing Slack | 说明 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 普通 RV32I 点积 | 62 | 15 | 4.1333 | 待填 | 待填 | 待填 | 待填 | 待填 | result=70 |
| MAC 点积 | 54 | 13 | 4.1538 | 待填 | 待填 | 待填 | 待填 | 待填 | result=70, mac=4 |
| 流水线冲刺版 | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 待填 | 可选 |

当前仓库已有的 2 LUT、24 FF、0 BRAM、0 DSP 报告对应 heartbeat 占位电路，
不能作为完整 SoC/MAC 的 PPA 数据。正式表见
`reports/tables/ppa_comparison.md`，等待完整 SoC 重新综合。

## 9. 报告截图清单

- xsim 仿真 pass 截图。
- 普通点积 result/cycle 截图。
- MAC 点积 result/cycle 截图。
- Vivado utilization 截图。
- Vivado timing summary 截图。
- 上板数码管显示照片或视频。
- Git 提交历史截图。
- AI 使用日志截图或附录。
