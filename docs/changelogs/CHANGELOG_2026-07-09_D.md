# 修改日志 —— 成员 D（王博生）MAC 加速与性能计量验证

提交日期：2026-07-09

提交：`94c963d` → 合并 PR #2 (`a288fca`)：`feature/d-mac-performance` → `main`

## 1. 提交概述

本次提交完成成员 D 的全部 P1 任务：MAC/Perf 单元测试、SoC 级集成测试、MMIO 暴露、
普通点积与 MAC 点积对比、性能报告与 PPA 模板。同时修复了 4 个影响测量可靠性的
控制通路缺陷。

全部 6 个 testbench 在 Icarus Verilog 下通过；`soc_top` 经 Verilator lint 无
error 且无组合环警告。Vivado 2018.3 xsim 截图和完整 SoC PPA 需在 Windows 上补测。

## 2. 新增文件（18 个）

### 2.1 Testbench（5 个）

| 文件 | 说明 |
|---|---|
| `sim/tb/tb_mac.v` | MAC 单元自检查 testbench（7 条测试：正数乘加、0 乘数、有符号负数、低 32 位乘积、累加回绕、连续累加 2 步） |
| `sim/tb/tb_perf_counter.v` | 性能计数器单元测试（7 条测试：reset 清零、cycle 递增、单次 instret 脉冲、连续 instret 脉冲、instret+mac 同时脉冲、halt 冻结 cycle、halt 后 reset） |
| `sim/tb/tb_perf_integration.v` | SoC 级退休计数集成测试（验证 instret=8、mac=1、STORE/BEQ/MAC 写回正确） |
| `sim/tb/tb_dot_product.v` | 双 SoC 实例点积对比测试（同时运行普通和 MAC 两个 soc_top，验证 result=70、normal=62/15/0、MAC=54/13/4、MAC cycle < normal cycle） |
| `sim/tb/tb_perf_mmio.v` | 性能计数器 MMIO 测试（验证 0xFFFF_FCB0/FCB4/FCB8 三个只读寄存器） |

### 2.2 测试程序（6 个）

| 文件 | 说明 |
|---|---|
| `tests/mac/dot_normal.S` | 普通 RV32I 点积汇编（1+1*2+2*3+3*4+4*5+5*6+6*7+7*8=70，7 次加法） |
| `tests/mac/dot_normal.hex` | 普通点积 hex（15 条指令） |
| `tests/mac/dot_mac.S` | MAC 点积汇编（4 条 MAC 指令替代 4 次 ADD） |
| `tests/mac/dot_mac.hex` | MAC 点积 hex（13 条指令） |
| `tests/perf/retirement_test.S` | 退休计数测试汇编（ALU+STORE+BEQ+MAC，各退休一次） |
| `tests/perf/retirement_test.hex` | 退休计数测试 hex（9 条指令） |
| `tests/perf/perf_mmio.S` | MMIO 读回测试汇编（通过 LW 从 0xFFFF_FCB0/FCB4/FCB8 读计数器） |
| `tests/perf/perf_mmio.hex` | MMIO 测试 hex（8 条指令） |

### 2.3 报告与文档（4 个）

| 文件 | 说明 |
|---|---|
| `reports/tables/perf_comparison.md` | 普通点积与 MAC 点积性能对比表（speedup=1.1481，cycle↓12.90%，instruction↓13.33%，含 CPI 计算与停机开销分析） |
| `reports/tables/ppa_comparison.md` | PPA 对比表模板（含完整 SoC / SoC+MAC 双版本字段定义 + 验收条件 + heartbeat 数据无效申明） |
| `reports/tables/test_results.md` | D 成员仿真结果汇总（6 个 testbench 通过记录 + 关键控制台输出 + 4 个缺陷修复说明 + 待补证据清单） |
| `reports/vivado/README.md` | Vivado 结果归档要求（列出需 B/C 补传的 6 类文件 + 重新运行前的 5 项确认） |

### 2.4 目录占位

| 文件 | 说明 |
|---|---|
| `tests/mac/.gitkeep` | MAC 测试目录占位 |
| `tests/perf/.gitkeep` | Perf 测试目录占位 |
| `reports/tables/.gitkeep` | 表格目录占位 |
| `reports/vivado/.gitkeep` | Vivado 报告目录占位 |

## 3. 修改文件（12 个）

### 3.1 RTL 修复（5 个）

| 文件 | 变更 | 原因 |
|---|---|---|
| `src/core/riscv_mc_cpu.v` | ① MAC 写回改为 EXECUTE 锁存到 `alu_result`、WRITEBACK 写回锁存值（25 行变更） ② taken branch 改为 EXECUTE 直接使用当前 `br_taken` 选择 PC ③ 退休脉冲重构：STORE 在 MEMORY、BRANCH 在 EXECUTE、寄存器写回指令在 WRITEBACK 各退休一次 | ① 原先 `mac_result` 组合引用与 regfile 写回前递形成组合环 ② 原先使用上一周期 `branch_taken` 导致实际不跳转 ③ 原先只在 WRITEBACK 计数，遗漏 STORE 和 BRANCH |
| `src/core/control_unit.v` | MAC 译码严格检查 `funct3=000` 且 `funct7=0000001`；错误 funct3/funct7 产生 `illegal_instr`（7 行变更） | 原先只检查 opcode，非法编码也会执行 MAC |
| `src/core/cpu_top.v` | 性能计数器从 `riscv_mc_wrapper` 逐层导出，占位模式补充 0 赋值 | 接通 perf 信号从 CPU → SoC 的完整路径 |
| `src/core/riscv_mc_wrapper.v` | 补充 `perf_cycle_count/instret_count/mac_count` 端口连接 | 性能计数器信号从 CPU 透传到 wrapper |
| `src/soc/soc_top.v` | ① 添加性能计数器 MMIO 读回（地址 0xFFFF_FCB0/FCB4/FCB8） ② 写请求被忽略（只读语义） | P1 任务：性能计数器 MMIO 暴露 |

### 3.2 Testbench 修改（2 个）

| 文件 | 变更 | 原因 |
|---|---|---|
| `sim/tb/tb_control_unit.v` | 新增 MAC 合法/非法 funct3/funct7 测试向量（9 行变更） | 验证严格译码修复 |
| `sim/tb/tb_cpu_basic.v` | 更新 CPU 内部层次路径以匹配修复后的信号名 | 适配 RTL 变更 |

### 3.3 文档更新（5 个）

| 文件 | 变更 |
|---|---|
| `docs/design/interfaces.md` | 补充 `perf_cycle_count/instret_count/mac_count` 三个只读性能信号接口 + MMIO 地址表 |
| `docs/design/mac_extension.md` | 新增第 12 节"验证结果"（6 项验证 + 性能数据 + 来源追溯） |
| `docs/design/performance.md` | 更新第 8-9 节：PPA 模板填入仿真数据、补充待补截图清单 |
| `docs/design/task_board.md` | D 的 P1 任务标记 IN_PROGRESS、阻塞项更新、成员职责索引更新 |
| `docs/ai_logs/ai_usage_log.md` | 新增 AI-20260709-D01（D 成员 AI 使用记录） |

### 3.4 仓库配置

| 文件 | 变更 |
|---|---|
| `.gitignore` | 追加 `reports/vivado/*.rpt`、`reports/vivado/*.png` 忽略项 |

## 4. 修复的 4 个控制通路缺陷

| # | 缺陷 | 影响 | 修复方式 |
|---|---|---|---|
| 1 | MAC 写回直接组合引用 `mac_result` | 与 regfile 写回前递形成组合环 | EXECUTE 锁存到 `alu_result`，WRITEBACK 写回锁存值 |
| 2 | taken branch 使用上一周期 `branch_taken` | BEQ/BNE 实际不跳转 | EXECUTE 直接使用当前 `br_taken` 选择 PC |
| 3 | instret 只在 WRITEBACK 计数 | 遗漏 STORE 和 BRANCH 退休 | STORE→MEMORY、BRANCH→EXECUTE、寄存器写回→WRITEBACK 分别退休 |
| 4 | MAC 只检查 opcode | 错误 funct3/funct7 也会执行 MAC | 严格检查 `funct3=000` 且 `funct7=0000001` |

## 5. 验证结果汇总

| 测试 | 工具 | 结果 | 关键数据 |
|---|---|---|---|
| `tb_mac.v` | Icarus | ✅ PASS | 7 类测试全通过 |
| `tb_perf_counter.v` | Icarus | ✅ PASS | 7 类测试全通过 |
| `tb_control_unit.v` | Icarus | ✅ PASS | 合法 MAC 通过；非法 funct3/funct7 被拒绝 |
| `tb_perf_integration.v` | Icarus | ✅ PASS | cycle=33, instret=8, mac=1 |
| `tb_dot_product.v` | Icarus | ✅ PASS | normal=70/62/15/0, MAC=70/54/13/4 |
| `tb_perf_mmio.v` | Icarus | ✅ PASS | cycle=23, instret=6, mac=1 |
| `soc_top` lint | Verilator | ✅ PASS | 无 error；无组合环 |

## 6. 点积对比核心结论

| 指标 | 普通 RV32I | MAC 加速 | 变化 |
|---|---|---|---|
| result | 70 | 70 | 一致 |
| cycle | 62 | 54 | **↓12.90%** |
| instret | 15 | 13 | **↓13.33%** |
| CPI | 4.1333 | 4.1538 | 持平（含固定停机开销） |
| mac_count | 0 | 4 | MAC 正确计数 |
| speedup | 1.0000 | **1.1481** | — |

## 7. 已知待补项

| 项目 | 阻塞原因 | 负责人 |
|---|---|---|
| Vivado 2018.3 xsim 全部 testbench 截图 | 当前机器无 Vivado | D（需 Windows 环境） |
| 完整 SoC 重新综合 utilization/timing | 当前机器无 Vivado | B/C |
| MAC DSP48 推断层次截图 | 依赖完整 SoC 综合 | B/C |
| 上板 LED/数码管 演示 | 依赖 bitstream | C |

## 8. 完整文件清单（30 个文件，+987 / −51 行）

```text
新增 (18):
  sim/tb/tb_mac.v
  sim/tb/tb_perf_counter.v
  sim/tb/tb_perf_integration.v
  sim/tb/tb_dot_product.v
  sim/tb/tb_perf_mmio.v
  tests/mac/dot_mac.S
  tests/mac/dot_mac.hex
  tests/mac/dot_normal.S
  tests/mac/dot_normal.hex
  tests/perf/perf_mmio.S
  tests/perf/perf_mmio.hex
  tests/perf/retirement_test.S
  tests/perf/retirement_test.hex
  reports/tables/perf_comparison.md
  reports/tables/ppa_comparison.md
  reports/tables/test_results.md
  reports/vivado/README.md
  (tests/mac/.gitkeep, tests/perf/.gitkeep,
   reports/tables/.gitkeep, reports/vivado/.gitkeep)

修改 (12):
  src/core/riscv_mc_cpu.v       (+33/-18)
  src/core/control_unit.v       (+25/-18)
  src/core/cpu_top.v            (+17/-4)
  src/core/riscv_mc_wrapper.v   (+12/-1)
  src/soc/soc_top.v             (+26/-5)
  sim/tb/tb_control_unit.v      (+22/-1)
  sim/tb/tb_cpu_basic.v         (+11/-3)
  docs/design/interfaces.md     (+16/-1)
  docs/design/mac_extension.md  (+17/-1)
  docs/design/performance.md    (+17/-1)
  docs/design/task_board.md     (+16/-14)
  docs/ai_logs/ai_usage_log.md  (+44/-2)
  .gitignore                    (+1)
```
