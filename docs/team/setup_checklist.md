# 组员环境与资料准备清单

最后更新时间：2026-07-07

## 1. 全员必装

- Vivado 2018.3。
- Git。
- VS Code 或其他编辑器。
- 拉取 GitHub 仓库并确认能 `git pull`。

全员必读：

- `README.md`
- `docs/team/member_roles.md`
- `docs/design/task_board.md`
- `docs/design/interfaces.md`
- `docs/design/isa.md`
- `docs/design/memory_map.md`
- `docs/design/development_rules.md`
- `docs/team/daily_workflow.md`

## 2. B 张淇必看/可选资料

### 必须下载安装

- Vivado 2018.3。
- Git。
- 项目 GitHub 仓库。

### 必须阅读

- `README.md`
- `docs/team/member_roles.md`
- `docs/team/bcd_onboarding.md`
- `docs/design/task_board.md`
- `docs/design/interfaces.md`
- `docs/design/isa.md`
- `docs/design/memory_map.md`
- `docs/design/development_rules.md`
- `docs/team/daily_workflow.md`
- `docs/course/2026项目式课程阶段二-修订完成版.pdf`：理解题目 B 和验收要求。
- `docs/design/项目B_vibecoding开发指南.md`：理解 CPU 主线。

### 可选参考

- `安装包资料/Minisys硬件手册1.1.pdf`：只需了解板卡、时钟、BRAM/资源背景。

### 不需要深入研究

- 功能测试包。
- EES329B 外设功能测试。
- Nexys4DDR、TEC-PLUS、EGO1 约束和资料。
- WiFi、蓝牙、电机、触摸屏相关功能测试资料。

## 3. C 胡文龙必看/可选资料

### 必须下载安装

- Vivado 2018.3 安装包和安装说明。
- Git。
- 项目 GitHub 仓库。
- `安装包资料/Minisys硬件手册1.1.pdf`。
- `安装包资料/Minisys资源信息.docx`（如果资料目录中存在）。
- `安装包资料/Minisys基础开发.zip`（或 `安装包资料/Minisys基础开发包/`）。
- `安装包资料/minisys功能测试.zip`（或 `安装包资料/Minisys功能测试/`）。
- `安装包资料/minisys_MIPS_FPGA.zip`（或 `安装包资料/minisys_MIPS_FPGA1/`）。

### 必须阅读

- `README.md`
- `docs/team/member_roles.md`
- `docs/team/bcd_onboarding.md`
- `docs/design/task_board.md`
- `docs/design/interfaces.md`
- `docs/design/memory_map.md`
- `docs/design/board_demo.md`
- `docs/design/risk_plan.md`
- `docs/design/development_rules.md`
- `docs/team/daily_workflow.md`
- `docs/hardware/minisys_pinout.md`
- `docs/design/board_constraints_audit.md`
- `constraints/minisys.xdc`

### 可选参考

- `安装包资料/minisys_MIPS_FPGA1/`：只作为 Vivado 工程、约束、上板流程参考，不照搬 CPU。
- `安装包资料/EES329b功能测试20170817.pdf`：只作为扩展板/上板测试参考，不作为主线。

### 不需要深入研究

- 不照搬 MIPS CPU 实现。
- 不碰 CPU 控制逻辑。
- 不研究 Nexys4DDR、TEC-PLUS、EGO1 等其他板卡约束。
- 不研究 WiFi、蓝牙、电机、触摸屏功能测试。

## 4. D 王博生必看/可选资料

### 必须下载安装

- Vivado 2018.3。
- Git。
- 项目 GitHub 仓库。

### 必须阅读

- `README.md`
- `docs/team/member_roles.md`
- `docs/team/bcd_onboarding.md`
- `docs/design/task_board.md`
- `docs/design/interfaces.md`
- `docs/design/memory_map.md`
- `docs/design/development_rules.md`
- `docs/team/daily_workflow.md`
- `docs/design/mac_extension.md`
- `docs/design/performance.md`
- `docs/design/项目B_vibecoding开发指南.md`

### 可选参考

- `安装包资料/Minisys硬件手册1.1.pdf`：了解 Artix-7、DSP48E1、BRAM、时钟资源。
- `安装包资料/MIPSfpga_Fundamentals/`：处理器系统思路参考，但不要移植为主线。
- `安装包资料/MIPSfpga_Getting-Started/`：处理器系统思路参考，但不要移植为主线。
- `安装包资料/MIPSfpga_SOC/`：处理器系统思路参考，但不要移植为主线。

### 不需要深入研究

- EES329B 外设功能测试。
- Nexys4DDR、TEC-PLUS、EGO1 约束和资料。
- WiFi、蓝牙、电机、触摸屏相关功能测试资料。
- 不需要提前主攻流水线。

## 5. 不要下载或不要用于主线的资料

- Nexys4DDR 资料。
- TEC-PLUS 资料。
- EGO1 资料。
- ISE14.7 资料，除非个人想了解旧工具。
- WiFi、蓝牙、电机、触摸屏相关功能测试资料。

## 6. 安装完成后自检

- Vivado 能打开。
- 能创建或打开工程。
- 能看到并运行 xsim。
- Git 能 `pull` / `push`。
- 不把安装包、license、破解文件、Vivado cache、临时 bitstream 提交到 GitHub。
