# 项目仿真结果记录

日期：2026-07-12

平台：macOS（Icarus/Verilator）+ Windows（Vivado 2018.3 XSim）

工具：Icarus Verilog + Verilator lint + Vivado 2018.3 XSim

负责归属：原 MAC/性能计数器 Icarus 测试由 D 王博生完成；2026-07-12 流水线 basic/hazard XSim 仿真、调试与结果整理由 B 张淇完成（AI 辅助）。

## 测试汇总

| 测试 | 结果 | 关键数据 |
|---|---|---|
| `tb_mac.v` | PASS | 正数、0、负数、低32位、回绕、连续累加 |
| `tb_perf_counter.v` | PASS | reset、cycle、halt冻结、instret、mac、同时脉冲 |
| `tb_control_unit.v` | PASS | 合法 MAC；非法 funct3/funct7 被拒绝 |
| `tb_perf_integration.v` | PASS | cycle=33，instret=8，mac=1 |
| `tb_dot_product.v` | PASS | normal=70/62/15/0，MAC=70/54/13/4 |
| `tb_perf_mmio.v` | PASS | MMIO snapshots：cycle=23，instret=6，mac=1 |
| Verilator `soc_top` lint | PASS | 无 error；无组合环警告 |
| `tb_pipeline_basic.v` (Vivado XSim) | PASS | cycle=10，instret=6，CPI=1.67，x3/x6/RAM=30 |
| `tb_pipeline_hazard.v` (Vivado XSim) | PASS | cycle=28，instret=17，CPI=1.65；FWD=6+4，stall=1，branch flush=1，JAL flush=2 |

## 关键控制台输出

```text
PERF: cycle=33 instret=8 mac=1
ALL PERFORMANCE INTEGRATION TESTS PASSED

NORMAL: result=70 cycle=62 instret=15 mac=0
MAC:    result=70 cycle=54 instret=13 mac=4
ALL DOT-PRODUCT TESTS PASSED

MMIO snapshots: cycle=23 instret=6 mac=1
ALL PERFORMANCE MMIO TESTS PASSED
```

## 修复过程中暴露的问题

流水线 XSim 实测输出：

```text
Pipeline Basic: cycle=10 instret=6 CPI=1.67 PASS
Pipeline Hazard: cycle=28 instret=17
EX/MEM forwards=6 MEM/WB forwards=4 load-use stalls=1
branch flushes=1 JAL flushes=2
RAM checkpoints=5,8,9,15,0,42,0,88
PASS: Pipeline hazard handling passed
```

1. MAC 写回原先直接组合引用 `mac_result`，与 regfile 的写回前递形成组合环。
   修复为 EXECUTE 锁存到 `alu_result`，WRITEBACK 写回锁存值。
2. taken branch 原先使用上一周期的 `branch_taken`，导致实际不跳转。
   修复为 EXECUTE 直接使用当前 `br_taken` 选择 PC。
3. instret 原先只在 WRITEBACK 计数，遗漏 STORE 和 BRANCH。
   修复后 STORE 在 MEMORY、BRANCH 在 EXECUTE、寄存器写回指令在 WRITEBACK
   各退休一次。
4. custom-0 原先只检查 opcode，错误 funct3/funct7 也会执行 MAC。
   现在严格检查文档规定的 `funct3=000`、`funct7=0000001`。

## 待补证据

- BTB 循环预测与 JALR 专项 XSim 证据。
- 完整 SoC 重新综合后的 utilization/timing 报告。
- MAC 是否推断 DSP 的层次利用率截图。
