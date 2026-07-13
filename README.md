# 基于 FPGA 的 RISC-V CPU、VGA 游戏与性能可视化系统

## 一、项目最终状态

本项目已完成课程验收。系统以 Minisys FPGA 开发板为平台，实现了 RV32I
子集多周期 CPU、自定义 MAC 指令、MMIO 外设、CPU 驱动的 VGA 猜数字与
俄罗斯方块游戏、硬件性能计数器，以及具有前递、停顿、冲刷和 BTB 的 RV32I
五级流水线版本。

主上板演示使用 `CPU_MODE=0` 的多周期 RV32I CPU。该版本的 CPU 执行流程、
MMIO 数据通路、VGA 游戏与性能计数均能在板上直观展示。`CPU_MODE=5` 的
五级流水线、其测试、上板和 PPA 工作也已由负责队友完成。

| 项目 | 最终状态 |
|---|---|
| RV32I 多周期 CPU | 已完成：31 条 RV32I 子集指令 + 1 条自定义 MAC；`EBREAK` 为测试/停机辅助指令 |
| RV32I 五级流水线 | 已完成：前递、load-use 停顿、控制冲刷、BTB 分支预测 |
| VGA 页面 | 已完成：寄存器/猜数字、性能基准、总线追踪、俄罗斯方块 |
| 性能计数器 | 已完成：硬件周期数、退休指令数、MAC 次数经 MMIO 供 CPU 软件读取 |
| 板级演示 | 已完成：拨码开关和 S1-S5 按键通过 MMIO 驱动 CPU 程序 |
| 仿真、流水线与 PPA | 已完成；引用具体 PPA 数值时应使用对应实现报告，不能把早期估算写成实测 |

## 二、快速开始

### 直接进行板级演示

1. 连接 Minisys 开发板和 VGA 显示器，启动 Vivado Hardware Manager。
2. 下载 `build_cpu_vga/minisys_top_cpu_vga.bit`。
3. 复位后使用 `SW[2:0]` 选择页面，使用 S1-S5 完成交互；各页面的操作见第六节。

该 bitstream 固化的是 `tests/demo/cpu_guess_game.hex` 对应程序，包含猜数字、
性能基准、总线追踪和 Tetris；无需在板上另行装载四份程序。

### 从源码重新生成主 VGA 镜像

在项目根目录的 PowerShell 中执行：

```powershell
.\scripts\build_cpu_guess_game.ps1 -InstallBootRom
```

随后在 Vivado 2018.3 Tcl Console 运行：

```tcl
source scripts/build_cpu_vga_bitstream.tcl
```

该流程会以 `CPU_MODE=0` 构建多周期主演示版本，并输出时序、资源、DRC 与功耗
报告到 `reports/vivado/`。流水线版本使用
`scripts/build_cpu_vga_pipeline.tcl`，必须将其 PPA 数据与该次 `CPU_MODE=5` 的
implementation 报告对应保存。

### 快速定位

| 需求 | 首选文件 |
|---|---|
| 查看 CPU/SoC 总体结构 | `docs/design/architecture.md`、`src/soc/soc_top.v` |
| 查询 32 条主功能指令和 MAC 编码 | `docs/design/isa.md`、`docs/design/mac_extension.md` |
| 查询 MMIO 地址与字段 | `docs/design/memory_map.md`、`src/io/vga_mmio_regs.v` |
| 修改 VGA 页面外观 | `src/io/vga_dashboard.v`、`src/io/font_rom.v` |
| 修改游戏/基准 CPU 软件 | `tests/demo/cpu_guess_game.S` |
| 运行对应仿真 | `sim/tb/` 与第七节测试映射 |
| 查看最终上板实现证据 | `build_cpu_vga/` |

## 三、硬件平台与系统结构

- 开发板：Minisys FPGA + EES-329B-V1.1 子板
- FPGA：Xilinx Artix-7 XC7A100T-FGG484
- 工具：Vivado 2018.3、Vivado XSim
- 时钟：100 MHz
- CPU 模式：`CPU_MODE=0` 为多周期，`CPU_MODE=5` 为五级流水线
- 存储器：默认 32 KiB 指令 RAM、32 KiB 数据 RAM
- 板级接口：16 位拨码开关、5 个普通按键、LED、八位数码管、VGA、4x4 键盘引脚

```text
按键 / 拨码开关 -> 按键 MMIO / GPIO -> CPU 的 LW 指令
                                           |
CPU 的 SW 指令 -> VGA MMIO 字段寄存器 -> VGA 仪表板 -> 显示器
                  性能计数器 <- CPU 执行事件
```

性能数据来自真实硬件逻辑：`csr_perf_counter.v` 产生 `cycle_count`、
`instret_count` 和 `mac_count`，CPU 程序通过 MMIO 读取后再写入 VGA 字段。
因此屏幕上显示的是 CPU 对自身执行过程采集的硬件值，而不是 PC 软件伪造的数据。

### 可验收的核心亮点

| 亮点 | 可验证证据 |
|---|---|
| CPU 驱动而非纯硬件状态机 | `tb_cpu_game_mmio.v` 检查按键 MMIO 读、RV32I 分支、VGA MMIO 写和按键确认的完整路径 |
| 自定义 MAC 指令 | `dot_normal`/`dot_mac` 对比同一 4 元素点积，结果均为 70；MAC 版本统计 `mac_count=4` |
| 硬件性能数据上屏 | `perf_mmio`、`vga_perf_snapshot` 与 PAGE 2 的 cycle/instret/mac、CPI/IPC/MIPS 字段 |
| 流水线冒险处理 | `tb_pipeline_hazard.v` 覆盖前递、load-use stall、分支和 JAL 冲刷 |
| 完整板级展示 | `build_cpu_vga/` 的 bitstream、DCP、时序、资源、功耗和 DRC 报告 |

## 四、目录与文件作用

| 路径 | 内容与作用 |
|---|---|
| `src/core/` | ALU、译码器、立即数/分支单元、寄存器堆、多周期 CPU、流水线 CPU、MAC、性能计数器 |
| `src/core/pipeline/` | 16 项 BTB 与分支预测辅助逻辑 |
| `src/bus/` | 数据总线地址译码和读数据选择 |
| `src/memory/` | 指令 RAM、数据 RAM |
| `src/io/` | LED、拨码、数码管、按键 MMIO、VGA 字段寄存器、VGA 仪表板与字库 |
| `src/soc/soc_top.v` | 集成 CPU、存储器、MMIO、性能计数器、VGA 的 SoC 顶层 |
| `src/board/minisys_top.v` | 开发板顶层端口，`CPU_MODE` 参数在此选择 CPU |
| `constraints/minisys.xdc` | Minisys 引脚、I/O 标准、100 MHz 时钟约束 |
| `tests/` | 汇编测试程序与生成的 `.hex` 机器码镜像 |
| `sim/tb/` | XSim 测试平台：模块、CPU、流水线、MMIO、游戏、基准和 Tetris |
| `scripts/` | 检查 RTL、生成游戏镜像、构建多周期/流水线 bitstream 的 Tcl/PowerShell 脚本 |
| `processor_fpga/boot_rom.mem` | Vivado 板级工程读取的程序镜像 |
| `build_cpu_vga/` | 主 VGA 演示 bitstream，以及综合、实现、DRC、时序、资源和功耗报告 |
| `reports/` | Vivado 文本报告、PPA/CPI/冒险分析表、答辩网页 |
| `docs/` | ISA、接口、地址映射、测试方案、设计过程、任务记录与 AI 使用记录 |

所有文件的详细索引见 [docs/PROJECT_INDEX.md](docs/PROJECT_INDEX.md)。

## 五、CPU 与 MMIO 重点

指令集定义见 `docs/design/isa.md`。验收口径为：**32 条主功能指令 =
31 条 RV32I 子集指令 + 1 条自定义 MAC 指令**。RTL 支持 `EBREAK`，但它只用于
测试结束/CPU 停机，不计入 32 条主功能指令。

自定义 MAC 使用 RISC-V `custom-0` 空间：`opcode=0001011`、`funct3=000`、
`funct7=0000001`，语义是：

```text
rd = old(rd) + rs1 * rs2
```

寄存器堆因此从普通的两读一写扩展为三读一写，第三读口读取 `old(rd)`；MAC
执行次数由性能计数器统计。

关键性能 MMIO 地址：

| 地址 | 含义 |
|---|---|
| `0xFFFF_FCB0` | 非 HALT 状态累计的 CPU 周期数 |
| `0xFFFF_FCB4` | 已退休指令总数 |
| `0xFFFF_FCB8` | 已完成 MAC 指令总数 |

PAGE 2 采用定点显示：`CPI X100=(cycles*100)/instret`，`IPC
X100=(instret*100)/cycles`，`MIPS X10=(instret*1000)/cycles`。`MAC CYC`
只在 MAC 基准中有直接比较意义；在其他基准为 0 是正常现象。

## 六、板上操作与页面内容

`SW[2:0]` 选择 VGA 页面/模式，主程序为 `tests/demo/cpu_guess_game.hex`。
该机器码在构建前复制到 `processor_fpga/boot_rom.mem`，随后固化进 bitstream。
按键经 `button_mmio.v` 进入 CPU，因此每次游戏操作真实经过
`CPU LW -> 分支判断 -> VGA MMIO SW` 的执行链路。

| 页面/模式 | 屏幕呈现 | S1-S5 操作 |
|---|---|---|
| `SW[2:0]=000` 猜数字页 | 三位猜测值、次数、过低/过高/正确提示；目标每 30 秒刷新 | S1 前一位，S2 后一位，S3 增加选中位，S4 减少选中位，S5 提交 |
| `SW[2:0]=010` 性能基准页 | CPI、IPC、MIPS、周期/指令/MAC 统计，以及 NORMAL CYC、MAC CYC、SPEEDUP | S1/S2 在 BRANCH/MEMORY/MAC/MIXED 间切换，S5 运行 |
| 总线追踪页 | CPU 阶段、PC、总线读写和追踪字段 | 正常运行时观察 CPU 执行过程 |
| `SW[2:0]=100` Tetris | 10x20 方块棋盘、当前方块、下一个方块、得分、性能字段 | S1 左移，S2 右移，S3 软降/暂停时重开，S4 旋转，S5 暂停/继续 |

正式展示使用已验证的 S1-S5 普通按键。4x4 键盘的引脚仍保留，但并非最终交互路径。

## 七、测试程序与对应 bitstream

| 程序/测试 | 验证内容 | 使用位置 |
|---|---|---|
| `tests/demo/cpu_guess_game.S/.hex` | VGA 四页面、猜数字、性能基准、总线追踪、Tetris、按键与 MMIO | 主 VGA/Tetris bitstream 的 ROM 程序 |
| `tests/basic/basic_test.S` | 基础算术、存储器、停机检查点 | `tb_cpu_basic.v` |
| `tests/basic/memory_sequence_game.S` | 确定性数据 RAM 序列处理 | 基础访存演示 |
| `tests/basic/switch_seg_game.S` | 拨码输入与数码管 MMIO | LED/SEG7 板级演示 |
| `tests/load_store/lw_sw_test.S/.hex` | 两次 store、两次 load、结果 `42+99=141` | `tb_load_store.v` |
| `tests/branch/beq_bne_test.S/.hex` | BEQ/BNE 跳转与不跳转，最终 `x10=12` | `tb_branch.v` |
| `tests/mac/dot_normal.S/.hex` | 普通 RV32I 点积，结果 70 | `tb_dot_product.v` 基线 |
| `tests/mac/dot_mac.S/.hex` | 四次 MAC 点积，结果 70 | `tb_dot_product.v` MAC 对比 |
| `tests/perf/perf_mmio.S/.hex` | CPU 读取三项性能计数器 MMIO | `tb_perf_mmio.v` |
| `tests/perf/retirement_test.S/.hex` | ALU、访存、分支、MAC 的退休计数 | `tb_perf_integration.v` |
| `tests/pipeline/hazard_test.hex` | RAW 前递、load-use 停顿、分支/JAL 冲刷 | `tb_pipeline_hazard.v` |
| `tests/pipeline/branch_loop_test.S` | 循环分支和 BTB 行为 | `tb_pipeline_btb.v` |

### 测试平台分类与通过标准

- 核心单元：`tb_alu`、`tb_regfile`、`tb_control_unit`、`tb_mac`、`tb_perf_counter`。
- 多周期 CPU：`tb_cpu_basic`、`tb_load_store`、`tb_branch`、`tb_dot_product`、`tb_perf_integration`、`tb_perf_mmio`。
- 五级流水线：`tb_pipeline_basic`、`tb_pipeline_hazard`、`tb_pipeline_btb`。
- VGA/MMIO/游戏：`tb_button_mmio`、`tb_vga_mmio`、`tb_vga_perf_snapshot`、`tb_perf_dashboard`、`tb_cpu_game_mmio`、`tb_benchmark`、`tb_cpu_benchmark_select`、`tb_cpu_tetris_mmio`、`tb_tetris_geometry`。

游戏类 testbench 不只验证画面颜色：它们检查按键事件确认、CPU 从按键 MMIO 读数据、
CPU 向 VGA MMIO 写字段、基准结果提交，以及 Tetris 的边界移动、旋转、下落、锁定与重开。

| 验证项 | 关键通过条件 |
|---|---|
| 多周期基础 CPU | 程序执行到 `EBREAK`，寄存器/RAM 检查点符合预期 |
| LW/SW 与分支 | `x5=141`；`x10=12` |
| MAC 点积 | 普通与 MAC 程序的点积结果均为 70，MAC 计数正确 |
| 流水线基础/冒险 | basic：10 cycle / 6 instret；hazard：28 cycle / 17 instret，前递、停顿、冲刷计数符合 testbench 断言 |
| 猜数字 CPU-MMIO | 覆盖低、高、猜中三条路径，并验证按钮读取后发生 VGA 字段写入 |
| Tetris CPU-MMIO | 覆盖左边界、旋转、软降、暂停/继续、锁定得分和暂停后重开 |

## 八、bitstream 文件、固化程序与画面

| 文件 | 固化程序 | CPU/用途 | 烧录后呈现 |
|---|---|---|---|
| `build_cpu_vga/minisys_top_cpu_vga.bit` | `processor_fpga/boot_rom.mem`，对应 `tests/demo/cpu_guess_game.hex` | `CPU_MODE=0` 多周期 RV32I 主验收版本 | VGA 的猜数字、性能基准、总线追踪、`SW=100` Tetris；LED/数码管和 S1-S5 MMIO 同时可用 |
| `processor_fpga/minisys_top_cpu_tetris.bit` | 同一 CPU 游戏程序镜像 | Tetris/VGA 归档副本 | 已核对 SHA-256 与主 VGA bitstream 一致；`SW[2:0]=100` 后进入俄罗斯方块 |
| `processor_fpga/processor_fpga.runs/impl_1/minisys_top.bit` | 同一 CPU 游戏程序镜像 | Vivado 自动输出 | 当前 SHA-256 也与主 VGA bitstream 一致；后续综合会覆盖，使用前须核对当前 ROM/CPU_MODE |
| 流水线交付 bitstream | 队友流水线交付的 ROM/配置 | `CPU_MODE=5` 五级流水线 | 用于流水线板测、性能与 PPA 验证；应与其同次 implementation 报告配套保存 |

`build_cpu_vga/` 已作为本次仓库最终交付的一部分提交，其中：

| 文件 | 作用 |
|---|---|
| `minisys_top_cpu_vga.bit` | 可直接在 Hardware Manager 下载的主 VGA 演示镜像 |
| `post_synth.dcp` / `post_route.dcp` | 综合后/布局布线后的设计检查点，用于复查或继续实现 |
| `timing_summary.rpt` | 时序结果；当前 VGA SoC 为 WNS `+0.182 ns`、TNS `0`、WHS `+0.049 ns`、THS `0` |
| `utilization_synth.rpt` / `utilization_route.rpt` | 综合/实现资源利用率 |
| `power.rpt` | 功耗估算 |
| `drc.rpt` | 设计规则检查结果 |

当前 VGA SoC 实现报告为 25,728 LUT、4,482 个寄存器、3 个 DSP48E1；这包含
VGA/dashboard 逻辑，不能当成孤立 CPU 核面积。流水线 PPA 的具体数值必须引用
对应 `CPU_MODE=5` 的最终实现报告。

`drc.rpt` 对已布线设计给出 28 条 **Warning**，分别为 DSP 输入/输出流水寄存
优化与异步加载检查建议（`DPIP-1`、`DPOP-1`、`DPOR-1`），不是阻止生成
bitstream 的错误；报告中的设计状态为 `Fully Routed`。

## 九、报告解读、复现与文档入口

### 实现报告的正确引用方式

`build_cpu_vga` 的报告对应的是 **含 VGA/dashboard/按键 MMIO 的多周期完整 SoC**，
不是只有 CPU 核的面积数据。该版本的 100 MHz 时序结果为 WNS `+0.182 ns`、
TNS `0`、WHS `+0.049 ns`、THS `0`，资源为 25,728 LUT、4,482 个寄存器、
3 个 DSP48E1。DRC 的 28 条均为 DSP 流水寄存和异步加载优化建议，已完成布线并
成功生成 bitstream。

答辩或复盘时请按以下边界表述：多周期 VGA 报告是本仓库可直接复核的实测实现
证据；流水线具体 PPA 必须引用队友交付的同次 `CPU_MODE=5` implementation 报告；
报告表中的早期模型估算仅用于设计分析，不能替代实测数据。

1. 在 Vivado 中运行 `scripts/check_cpu_vga_rtl.tcl` 检查 CPU/VGA RTL。
2. 在 XSim 中选择与测试程序对应的 `sim/tb/tb_*.v`，按第七节映射运行。
3. 主 VGA 镜像：生成 `tests/demo/cpu_guess_game.hex`，复制到
   `processor_fpga/boot_rom.mem`，运行 `scripts/build_cpu_vga_bitstream.tcl`。
4. 流水线镜像：在相同约束下运行 `scripts/build_cpu_vga_pipeline.tcl`，并归档该次
   `CPU_MODE=5` 的 utilization/timing 报告。

### 已知边界

- 正式交互链路是 S1-S5 普通按键；4x4 键盘端口保留但不是验收操作路径。
- `processor_fpga/processor_fpga.runs/` 是 Vivado 工作目录，下一次综合可能覆盖其
  `minisys_top.bit`；交付时优先使用 `build_cpu_vga/minisys_top_cpu_vga.bit`。
- bitstream、DCP 和报告均依赖特定 ROM 镜像、CPU_MODE 与 XDC；复现/引用时必须
  同时说明这三项。

- 架构：`docs/design/architecture.md`
- ISA 与 MAC：`docs/design/isa.md`、`docs/design/mac_extension.md`
- 地址映射与接口：`docs/design/memory_map.md`、`docs/design/interfaces.md`
- 测试与板级操作：`docs/design/test_plan.md`、`docs/design/board_demo.md`
- 最终任务/进度：`docs/design/task_board.md`、`docs/planning/progress_checklist.md`
- Vivado/PPA：`build_cpu_vga/`、`reports/vivado/`、`reports/tables/ppa_comparison.md`
- 答辩页面：`reports/figures/defense_presentation.html`
- AI 使用日志：`docs/ai_logs/ai_usage_log.md`
