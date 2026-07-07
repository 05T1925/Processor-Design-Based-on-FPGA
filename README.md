# Processor-Design-Based-on-FPGA

基于 Minisys FPGA 的 RV32I 子集多周期 CPU 与 MAC 指令加速设计。

## 项目概况

- 课程题目：题目 B，基于 FPGA 开发板的处理器设计
- 硬件平台：Minisys FPGA 实验板，Xilinx Artix-7 XC7A100T
- 开发环境：Vivado 2018.3，组内主仿真工具为 Vivado xsim
- 当前阶段：小组协作准备、MVP 协作文档与接口规范冻结；Minisys 主线 `.xdc` 已确认并落到 `constraints/minisys.xdc`

## 当前主线

```text
RV32I 子集多周期 CPU
+ BRAM 指令/数据存储器
+ memory-mapped I/O
+ LED / 拨码开关 / 七段数码管上板演示
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
docs/team/         成员分工、每日流程、审查清单
docs/ai_logs/      AI 使用日志
docs/planning/     阶段规划记录
src/               后续 RTL 源码
sim/               后续 testbench、程序、波形
tests/             测试程序分类
constraints/       Minisys 约束文件
reports/           报告图表与 Vivado 数据
scripts/           后续 xsim/Vivado/Python 辅助脚本
```

## 四人角色概览

| 成员 | 姓名 | 角色 | 主责 |
|---|---|---|---|
| A | 刘文涛 | 组长 / 架构 / 集成 / 报告 | ISA、memory map、interfaces、集成、性能复检、报告 |
| B | 张淇 | CPU 数据通路与控制器 | ALU、regfile、control、imm、branch、cpu_top、基础仿真 |
| C | 胡文龙 | SoC / Memory / I/O / 上板验证 | BRAM、MMIO、LED、seg7、soc_top、minisys_top、Vivado |
| D | 王博生 | MAC / 性能 / 冲刺 | mac_unit、perf_counter、点积测试、CPI/PPA、流水线冲刺 |

测试/性能任务拆分到模块负责人：B 负责 CPU 基础测试，C 负责 BRAM/MMIO/上板测试，D 负责 MAC/性能/PPA 初稿，A 负责复检和报告整合。

## 组员进入项目后先读

1. `README.md`
2. `docs/team/member_roles.md`
3. `docs/design/task_board.md`
4. `docs/design/interfaces.md`
5. `docs/design/isa.md`
6. `docs/design/memory_map.md`
7. `docs/design/development_rules.md`
8. `docs/ai_logs/ai_usage_log.md`

## 协作入口

- 成员分工：`docs/team/member_roles.md`
- 每日流程：`docs/team/daily_workflow.md`
- 审查清单：`docs/team/review_checklist.md`
- 任务看板：`docs/design/task_board.md`
- 开发规范：`docs/design/development_rules.md`
- AI 日志：`docs/ai_logs/ai_usage_log.md`

## 环境准备

- 组员先按老师提供的安装包安装 Vivado 2018.3。
- 组内主仿真工具统一使用 Vivado xsim。
- ModelSim 可个人使用，但不是组内强制流程。
- 安装路径尽量不要包含中文或空格。
- 安装完成后截图或在群里说明环境已就绪。
- 不要把安装包、破解文件、license 文件、大型软件包上传到 GitHub。
- 不要把 Vivado 自动生成的临时工程文件提交到仓库。
- 环境装好后先阅读 README 和分工文档，再领取任务。

## 当前约束状态

- 已从老师资料中确认 Minisys 主约束来源，并整理为 `constraints/minisys.xdc`。
- 板级端口统一为 `clk/rst_n/sw[15:0]/led[15:0]/seg[7:0]/an[7:0]`。
- 约束审计见 `docs/design/board_constraints_audit.md` 和 `docs/hardware/minisys_pinout.md`。
- 当前尚未在 Vivado 2018.3 中综合/实现验证，bitstream 通过后才能把上板任务标为 DONE。

## 下一步顺序

1. C 先在 Vivado 2018.3 中建立最小工程，加载 `src/board/minisys_top.v` 与 `constraints/minisys.xdc`。
2. 实测 P20 复位按钮极性，必要时只修改 `minisys_top` 的复位转换。
3. 实现 `seg7_driver` 的低有效十六进制扫描显示并单测。
4. 接入 `soc_top`、BRAM、MMIO 和 display mux。
5. 跑 xsim 后再生成 bitstream，并保存 utilization/timing 截图。

## 开发前规则

- 不要直接做 DDR3 / Cache / VGA / WiFi / 蓝牙 / 电机 / 触摸屏。
- 不要直接生成完整 CPU。
- 不要在未更新文档的情况下修改公共接口。
- 不要直接在 `main` 上提交未验证代码。
- 不要复制开源 CPU 作为最终代码。
- 不要没有 testbench 或测试结果就合并核心模块。
- 不要提交 Vivado 临时文件。
- 每次 AI 生成或修改代码必须记录到 `docs/ai_logs/ai_usage_log.md`。
