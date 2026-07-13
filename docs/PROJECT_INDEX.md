# 项目文件索引

> 最后同步：2026-07-13。项目已完成验收。本索引描述当前真实仓库内容；早期计划文档中“目录为空、RTL 待实现”等描述仅为开发历史。
>
> **本机修改归属**：本电脑当前源码、测试、文档、构建归档和 Git 提交均由 **A 刘文涛** 完成和维护。历史文档中的成员姓名只用于保留当时的任务分工与过程追溯。

## 建议阅读顺序

1. `README.md`：项目概况、板级操作、测试/bitstream 对应关系。
2. `docs/design/architecture.md`：CPU 与 SoC 架构。
3. `docs/design/isa.md`、`docs/design/mac_extension.md`：指令集与 MAC 扩展。
4. `docs/design/memory_map.md`、`docs/design/interfaces.md`：MMIO 地址和模块端口。
5. `docs/design/test_plan.md`、`reports/tables/test_results.md`：验证方案与记录。
6. `build_cpu_vga/`、`reports/vivado/`、`reports/tables/ppa_comparison.md`：实现和 PPA 证据。

## 源码文件索引

| 路径 | 内容与用途 |
|---|---|
| `README.md` | 中文最终项目入口：操作、测试、bitstream、性能与交付说明 |
| `constraints/minisys.xdc` | Minisys 引脚、I/O 标准和 100 MHz 时钟约束 |
| `src/board/minisys_top.v` | FPGA 板级顶层，连接按键、开关、LED、数码管、VGA；参数选择 CPU 模式 |
| `src/soc/soc_top.v` | 集成 CPU、RAM、总线、MMIO、性能计数和 VGA 的 SoC 顶层 |
| `src/core/alu.v` | 算术与逻辑运算 |
| `src/core/control_unit.v` | RV32I 与 MAC 的指令译码、控制信号生成 |
| `src/core/regfile.v` | 32 个通用寄存器，x0 固定为 0，三读一写支持 MAC 累加旧值 |
| `src/core/riscv_mc_cpu.v` | 六状态多周期 RV32I CPU，是主游戏 bitstream 的 CPU |
| `src/core/riscv_pipeline_cpu.v` | 五级流水线 RV32I CPU，含前递、停顿和冲刷 |
| `src/core/csr_perf_counter.v` | 周期数、退休指令数、MAC 次数硬件计数器 |
| `src/core/mac_unit.v` | 自定义乘加数据通路 |
| `src/core/pipeline/` | BTB 和分支预测辅助模块 |
| `src/bus/` | 数据 RAM/MMIO 地址译码和读数据复用 |
| `src/memory/` | 指令 RAM、数据 RAM |
| `src/io/button_mmio.v` | 5 按键去抖、边沿锁存和 CPU MMIO 接口 |
| `src/io/vga_mmio_regs.v` | CPU 写入的 VGA 字段寄存器组 |
| `src/io/vga_dashboard.v` | VGA 仪表板、猜数字、性能页、追踪页和 Tetris 图形渲染 |
| `src/io/font_rom.v` | VGA 字符字库 |
| `src/io/gpio_*.v`、`seg7_driver.v` | LED、拨码开关、数码管 MMIO 外设 |
| `src/io/kbd4x4_scanner.v`、`vga_test_pattern.v`、`vga_button_demo.v` | 输入/显示探索原型；正式交互使用 S1-S5 |
| `processor_fpga/boot_rom.mem` | Vivado 板级工程读入的当前程序镜像 |

## 测试程序与 testbench 索引

| 程序路径 | 配套 testbench | 验证目标 |
|---|---|---|
| `tests/basic/basic_test.S` | `tb_cpu_basic.v` | 基础算术、RAM、停机检查点 |
| `tests/basic/memory_sequence_game.S` | CPU 仿真 | 数据 RAM 顺序处理 |
| `tests/basic/switch_seg_game.S` | 板级/MMIO 演示 | 拨码读取、数码管写入 |
| `tests/load_store/lw_sw_test.S/.hex` | `tb_load_store.v` | `mem[0]=42`、`mem[1]=99`、`x5=141` |
| `tests/branch/beq_bne_test.S/.hex` | `tb_branch.v` | BEQ/BNE 的跳转与不跳转，`x10=12` |
| `tests/mac/dot_normal.S/.hex` | `tb_dot_product.v` | 普通指令点积，结果 70 |
| `tests/mac/dot_mac.S/.hex` | `tb_dot_product.v` | MAC 点积，结果 70 和 MAC 计数 |
| `tests/perf/perf_mmio.S/.hex` | `tb_perf_mmio.v` | CPU 读取 cycle/instret/mac MMIO |
| `tests/perf/retirement_test.S/.hex` | `tb_perf_integration.v` | ALU、访存、分支、MAC 的退休计数 |
| `tests/pipeline/hazard_test.hex` | `tb_pipeline_hazard.v` | RAW 前递、load-use 停顿、分支/JAL 冲刷 |
| `tests/pipeline/branch_loop_test.S` | `tb_pipeline_btb.v` | 循环分支与 BTB 行为 |
| `tests/demo/cpu_guess_game.S/.hex` | 见下方游戏测试 | VGA 四页面、猜数字、基准、Tetris 的主部署程序 |

| 测试分类 | 文件 | 覆盖内容 |
|---|---|---|
| 核心单元 | `tb_alu`、`tb_regfile`、`tb_control_unit`、`tb_mac`、`tb_perf_counter` | ALU、寄存器、译码、MAC 和计数器功能 |
| 多周期 CPU | `tb_cpu_basic`、`tb_load_store`、`tb_branch`、`tb_dot_product`、`tb_perf_integration`、`tb_perf_mmio` | 指令、存储器、分支、MAC 和性能 MMIO |
| 五级流水线 | `tb_pipeline_basic`、`tb_pipeline_hazard`、`tb_pipeline_btb` | 基础流动、冒险处理和 BTB |
| VGA/MMIO | `tb_button_mmio`、`tb_vga_mmio`、`tb_vga_perf_snapshot`、`tb_perf_dashboard` | 按键事件、VGA 字段、稳定性能快照 |
| CPU 游戏 | `tb_cpu_game_mmio`、`tb_benchmark`、`tb_cpu_benchmark_select`、`tb_cpu_tetris_mmio`、`tb_tetris_geometry` | CPU 驱动猜数字、四类基准、Tetris 输入/状态/几何 |

游戏测试验证 `按键 MMIO 读取 -> RV32I 分支 -> VGA MMIO 写入 -> 按键确认` 的真实数据路径，不只是检查显示模块输出。

## 构建脚本与 bitstream 索引

| 文件 | 内容与作用 |
|---|---|
| `scripts/build_cpu_guess_game.ps1` | 生成 VGA 游戏 `.hex` ROM 镜像 |
| `scripts/check_cpu_vga_rtl.tcl` | 读取 RTL 并执行 CPU/VGA 检查 |
| `scripts/build_cpu_vga_bitstream.tcl` | 构建多周期 `CPU_MODE=0` 主 VGA 游戏镜像 |
| `scripts/build_cpu_vga_pipeline.tcl` | 构建 `CPU_MODE=5` 五级流水线配置并导出 PPA 证据 |
| `scripts/build_cpu_vga_standalone.tcl` | 独立 CPU/VGA 实现流程 |
| `build_cpu_vga/minisys_top_cpu_vga.bit` | 主交付 bitstream：猜数字、性能页、追踪页、Tetris、按键/LED/数码管 MMIO |
| `processor_fpga/minisys_top_cpu_tetris.bit` | Tetris/VGA 归档副本；经 SHA-256 核对与主 VGA bitstream 相同，`SW[2:0]=100` 进入俄罗斯方块 |
| `processor_fpga/processor_fpga.runs/impl_1/minisys_top.bit` | Vivado 自动输出；当前 SHA-256 与主 VGA bitstream 相同，后续构建会覆盖 |
| `build_cpu_vga/post_synth.dcp` | 综合后的设计检查点 |
| `build_cpu_vga/post_route.dcp` | 布局布线后的设计检查点 |
| `build_cpu_vga/timing_summary.rpt` | 主 VGA SoC 时序报告 |
| `build_cpu_vga/utilization_*.rpt` | 综合后/实现后资源利用率报告 |
| `build_cpu_vga/power.rpt`、`drc.rpt` | 功耗估计与设计规则检查 |

## 文档索引

| 目录 | 内容 |
|---|---|
| `docs/design/` | 架构、ISA、接口、地址映射、游戏计划、测试计划、板级设计 |
| `docs/planning/` | 项目过程、完成清单、流水线指南、答辩准备 |
| `docs/team/` | 角色分工、审查与协作历史 |
| `docs/hardware/` | Minisys 引脚与硬件说明 |
| `docs/changelogs/` | 早期变更记录 |
| `docs/ai_logs/` | AI 使用声明和工作记录 |
| `reports/tables/` | CPI、性能、PPA、冒险和测试结果表 |
| `reports/figures/` | 答辩网页和性能可视化网页 |

## 证据使用原则

`build_cpu_vga/` 是本次最终提交的主 VGA 实现证据。`.runs`、`.cache`、`.Xil`、
`.wdb` 和普通日志是会随工具环境变化的工作目录，通常不作为交付证据。引用 PPA
数据时要写清 CPU_MODE、程序镜像、约束和报告来源；早期模型估算不能替代最终实现报告。
