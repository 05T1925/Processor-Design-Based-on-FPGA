# Vivado 结果归档要求

当前仓库 `processor_fpga/processor_fpga.runs/` 中的 2 LUT / 24 FF 历史报告对应
heartbeat 占位电路，不是完整 SoC，不能作为 CPU/MAC PPA 数据。

最终归档（2026-07-13）：项目验收、流水线测试、上板和 PPA 工作均已完成。仓库中可直接复核的当前 VGA SoC 报告为 `cpu_vga_*.rpt`；流水线的最终数字应以负责队友交付的同一 `CPU_MODE=5` 实现报告为准。历史 heartbeat 报告仍不得引用。

请在 Windows + Vivado 2018.3 中重新运行完整 SoC，并将以下文件复制到本目录：

- baseline utilization report
- baseline timing summary
- MAC utilization report
- MAC timing summary
- xsim MAC/perf/dot-product 截图
- DSP inference 层次截图

重新运行前确认：

- 顶层为 `minisys_top`
- 未定义 `MINISYS_USE_HEARTBEAT`
- compile order 包含全部主线 RTL
- 目标器件、XDC、100 MHz 时钟和实现策略保持一致
