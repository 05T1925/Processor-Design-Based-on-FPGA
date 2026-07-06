# Processor-Design-Based-on-FPGA

基于 FPGA 开发板的处理器设计课程项目。

## 项目概况

- 课程题目：题目 B，基于 FPGA 开发板的处理器设计
- 硬件平台：Minisys FPGA 实验板，Xilinx Artix-7 XC7A100T
- 开发环境：Vivado 2018.3，组内主仿真工具为 Vivado xsim
- 当前阶段：MVP 协作文档与接口规范冻结

## 当前主线

```text
RV32I 子集多周期 CPU
+ BRAM 指令/数据存储器
+ memory-mapped I/O
+ 性能计数器
+ MAC 自定义指令
+ 点积程序对比
+ PPA 分析
```

五级流水线、forwarding、load-use stall、branch flush、UART 输出统计均为冲刺目标，不作为第一版阻塞项。

## 仓库目录

```text
docs/course/       课程任务与环境资料
docs/hardware/     Minisys 与 EES-329B 资料
docs/design/       架构、接口、ISA、测试、规范文档
docs/ai_logs/      AI 使用日志
docs/planning/     阶段规划记录
src/               后续 RTL 源码
sim/               后续 testbench、程序、波形
tests/             测试程序分类
constraints/       Minisys 约束文件
reports/           报告图表与 Vivado 数据
scripts/           后续 xsim/Vivado/Python 辅助脚本
```

## 组员入门阅读顺序

1. `README.md`
2. `docs/design/architecture.md`
3. `docs/design/interfaces.md`
4. `docs/design/isa.md`
5. `docs/design/memory_map.md`
6. `docs/design/task_board.md`
7. `docs/design/development_rules.md`
8. `docs/ai_logs/ai_usage_log.md`

## 开发前规则

- 不要直接做 DDR3 / Cache / VGA / WiFi / 蓝牙 / 电机 / 触摸屏。
- 不要直接生成完整 CPU。
- 不要在未更新文档的情况下修改公共接口。
- 不要提交 Vivado 临时文件。
- 每次 AI 生成或修改代码必须记录到 `docs/ai_logs/ai_usage_log.md`。
