# Vivado 结果归档要求

当前仓库 `processor_fpga/processor_fpga.runs/` 中的 2 LUT / 24 FF 报告对应
heartbeat 占位电路，不是完整 SoC，不能作为 CPU/MAC PPA 数据。

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
