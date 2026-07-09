# PPA 对比表

日期：2026-07-09

负责人：D 王博生

## 正式 PPA 表

| 版本 | LUT | FF | BRAM | DSP | IO | WNS | TNS | 目标频率 | 状态 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 完整 SoC 基线（不执行 MAC） | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 100 MHz | BLOCKED |
| 完整 SoC + MAC 点积 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 100 MHz | BLOCKED |

## 为什么没有填写仓库中现有的 Vivado 数值

仓库中的原始报告：

- `processor_fpga/processor_fpga.runs/impl_1/minisys_top_utilization_placed.rpt`
- `processor_fpga/processor_fpga.runs/impl_1/minisys_top_timing_summary_routed.rpt`

记录的是：

| LUT | FF | BRAM | DSP | WNS | TNS |
|---:|---:|---:|---:|---:|---:|
| 2 | 24 | 0 | 0 | +7.212 ns | 0 ns |

对应 synthesis Tcl 只读取了 `src/core/public.vh` 和
`src/board/minisys_top.v`，cell usage 只有 heartbeat 计数器相关的
24 个触发器。该结果不是完整 CPU/SoC，更不是 CPU+MAC 的 PPA 数据，因此不得
填入正式对比表。

## B/C 重新导出数据时的验收条件

1. Vivado compile order 包含 `src/core/`、`src/bus/`、`src/memory/`、
   `src/io/`、`src/soc/` 和 `src/board/` 的完整主线 RTL。
2. 顶层为 `minisys_top`，且没有定义 `MINISYS_USE_HEARTBEAT`。
3. 层次利用率中能看到 `u_soc_top`、CPU、regfile、RAM 和 MAC。
4. MAC 版本应检查 DSP48 是否被推断；若 DSP=0，先确认 MAC 逻辑没有被优化掉。
5. 两个版本使用相同器件、XDC、100 MHz 时钟和实现策略。
6. 报告复制到 `reports/vivado/`，并在本表中记录具体来源路径。

当前 PPA 状态是“模板完成、真实数据待完整 SoC 重新综合”，不能用 heartbeat
数据冒充完成。
