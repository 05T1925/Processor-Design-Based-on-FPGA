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

## 二、硬件平台与系统结构

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

## 三、目录与文件作用

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

## 四、CPU 与 MMIO 重点

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

## 五、板上操作与页面内容

`SW[2:0]` 选择 VGA 页面/模式，主程序为 `tests/demo/cpu_guess_game.hex`。
该机器码在构建前复制到 `processor_fpga/boot_rom.mem`，随后固化进 bitstream。
按键经 `button_mmio.v` 进入 CPU，因此每次游戏操作真实经过
`CPU LW -> 分支判断 -> VGA MMIO SW` 的执行链路。

| 页面/模式 | 屏幕呈现 | S1-S5 操作 |
|---|---|---|
| 猜数字页 | 三位猜测值、次数、过低/过高/正确提示、目标定时更新 | S1 选择位，S2/S3 增减，S5 提交 |
| 性能基准页 | CPI、IPC、MIPS、周期/指令/MAC 统计，以及 NORMAL CYC、MAC CYC、SPEEDUP | S1/S2 切换 BRANCH/MEMORY/MAC/MIXED，S5 运行 |
| 总线追踪页 | CPU 阶段、PC、总线读写和追踪字段 | 正常运行时观察 CPU 执行过程 |
| `SW[2:0]=100` Tetris | 10x20 方块棋盘、当前方块、下一个方块、得分、性能字段 | S1 左移，S2 右移，S3 软降/暂停时重开，S4 旋转，S5 暂停/继续 |

正式展示使用已验证的 S1-S5 普通按键。4x4 键盘的引脚仍保留，但并非最终交互路径。

## 六、测试程序与对应 bitstream

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

### 测试平台分类

- 核心单元：`tb_alu`、`tb_regfile`、`tb_control_unit`、`tb_mac`、`tb_perf_counter`。
- 多周期 CPU：`tb_cpu_basic`、`tb_load_store`、`tb_branch`、`tb_dot_product`、`tb_perf_integration`、`tb_perf_mmio`。
- 五级流水线：`tb_pipeline_basic`、`tb_pipeline_hazard`、`tb_pipeline_btb`。
- VGA/MMIO/游戏：`tb_button_mmio`、`tb_vga_mmio`、`tb_vga_perf_snapshot`、`tb_perf_dashboard`、`tb_cpu_game_mmio`、`tb_benchmark`、`tb_cpu_benchmark_select`、`tb_cpu_tetris_mmio`、`tb_tetris_geometry`。

游戏类 testbench 不只验证画面颜色：它们检查按键事件确认、CPU 从按键 MMIO 读数据、
CPU 向 VGA MMIO 写字段、基准结果提交，以及 Tetris 的边界移动、旋转、下落、锁定与重开。

## 七、bitstream 文件、固化程序与画面

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

## 八、复现与文档入口

1. 在 Vivado 中运行 `scripts/check_cpu_vga_rtl.tcl` 检查 CPU/VGA RTL。
2. 在 XSim 中选择与测试程序对应的 `sim/tb/tb_*.v`，按第六节映射运行。
3. 主 VGA 镜像：生成 `tests/demo/cpu_guess_game.hex`，复制到
   `processor_fpga/boot_rom.mem`，运行 `scripts/build_cpu_vga_bitstream.tcl`。
4. 流水线镜像：在相同约束下运行 `scripts/build_cpu_vga_pipeline.tcl`，并归档该次
   `CPU_MODE=5` 的 utilization/timing 报告。

- 架构：`docs/design/architecture.md`
- ISA 与 MAC：`docs/design/isa.md`、`docs/design/mac_extension.md`
- 地址映射与接口：`docs/design/memory_map.md`、`docs/design/interfaces.md`
- 测试与板级操作：`docs/design/test_plan.md`、`docs/design/board_demo.md`
- 最终任务/进度：`docs/design/task_board.md`、`docs/planning/progress_checklist.md`
- Vivado/PPA：`build_cpu_vga/`、`reports/vivado/`、`reports/tables/ppa_comparison.md`
- 答辩页面：`reports/figures/defense_presentation.html`
- AI 使用日志：`docs/ai_logs/ai_usage_log.md`
