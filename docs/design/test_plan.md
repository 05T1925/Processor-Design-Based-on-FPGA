# 测试程序与仿真计划

用途：规划测试程序、testbench、pass/fail 标准和 xsim 仿真记录方式。

最后更新时间：2026-07-06

## 1. 测试总原则

- 所有 testbench 必须能在 Vivado xsim 下运行。
- ModelSim 仅作为个人可选调试工具，不作为组内主流程。
- 第一阶段少量 hex 机器码允许手写。
- 第二阶段再写 `scripts/gen_mem.py` 生成 `.mem`。
- 暂不开发完整 assembler。
- 每个可验证节点都应适合 Git 提交和报告展示。

## 2. 测试路径

```text
tests/basic/
tests/load_store/
tests/branch/
tests/mmio/
tests/perf/
tests/mac/
tests/hazard/
sim/tb/
sim/programs/
sim/wave/
```

## 3. 测试程序规划

| 测试类别 | 路径 | 目标 | 通过标准 |
|---|---|---|---|
| basic | `tests/basic/` | ADD/SUB/ADDI/AND/OR/XOR | `done=1,error=0,x5=1` |
| load_store | `tests/load_store/` | LW/SW | 读回值等于写入值 |
| branch | `tests/branch/` | BEQ/BNE | 正确路径执行，错误路径不写结果 |
| mmio | `tests/mmio/` | LED/SEG7/SWITCH | MMIO 寄存器读写正确 |
| perf | `tests/perf/` | cycle/instret/mac_count | 计数符合预期 |
| mac | `tests/mac/` | 普通点积与 MAC 点积 | result 一致，MAC 周期可比 |
| hazard | `tests/hazard/` | 流水线冲刺 | forwarding/stall/flush 正确 |

## 4. Testbench 文件规划

| Testbench | 阶段 | 输入激励 | 观察信号 |
|---|---|---|---|
| `tb_alu.v` | P0 | 枚举操作数和 op | `result,zero` |
| `tb_regfile.v` | P0 | 写读寄存器和 x0 | `rs1_data,rs2_data,rd_old_data` |
| `tb_cpu_basic.v` | P0 | basic `.mem` | `done,error,registers` |
| `tb_soc_mmio.v` | P1 | MMIO 程序和 sw | `led,seg_value,rdata` |
| `tb_mac.v` | P1 | 点积程序 | `result,mac_count,cycle_count` |
| `tb_perf_counter.v` | P1 | pulse 序列 | counters |
| `tb_pipeline_hazard.v` | P2 | 冒险程序 | stall/flush/forward |

## 5. Pass/Fail 标准

推荐统一标准：

- 仿真超时前 `done=1`。
- `error=0`。
- 指定寄存器或 `result_reg` 等于期望值。
- 对 MAC 测试，普通版和 MAC 版 result 一致。
- 对 perf 测试，计数器值落在预期范围。

## 6. 波形与日志

- xsim 可生成 WDB 波形。
- 大波形文件不提交 Git。
- 关键波形截图保存到 `reports/figures/`。
- 工具生成日志不提交，必要摘要写入调试日志或报告。

## 7. 后续脚本

第二阶段可创建：

```text
scripts/gen_mem.py
```

用途：

- 把少量手写汇编/结构化测试描述转为 `.mem`。
- 不追求完整 assembler。
