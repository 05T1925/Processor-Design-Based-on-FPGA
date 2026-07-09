# MAC 自定义指令设计

用途：定义 MAC 指令语义、编码、数据通路接入、控制信号、测试方式和降级方案。

最后更新时间：2026-07-09（D：完成单元与点积验证）

## 1. 设计动机

课程拓展层次鼓励自定义 ISA 和面向 AI/矩阵计算的加速指令。点积和小型矩阵乘法中反复出现乘加模式：

```text
sum = sum + a[i] * b[i]
```

MAC 指令把乘法和累加合并为一条自定义指令，便于展示性能优化、DSP 使用和 PPA 权衡。

## 2. 指令语义

统一语义：

```text
MAC rd, rs1, rs2
rd_new = rd_old + rs1 * rs2
```

其中：

- `rs1`：乘数 A。
- `rs2`：乘数 B。
- `rd_old`：rd 寄存器原值，作为累加器输入。
- `rd_new`：写回 rd。

## 3. 指令编码

采用 R-type custom 编码：

```text
funct7 = 0000001
rs2    = instr[24:20]
rs1    = instr[19:15]
funct3 = 000
rd     = instr[11:7]
opcode = 0001011
```

`opcode=0001011` 是 RISC-V custom-0，不与标准 RV32I 基础指令冲突。

译码器必须同时检查 opcode、funct3 和 funct7。仅 opcode 匹配但 funct3/funct7
错误的指令必须产生 `illegal_instr`，且不得写寄存器或增加性能计数。

## 4. Regfile 第三读口

组长已确认第一版接受 `rd_old` 第三读口方案。

`regfile` 第一版采用 3 读 1 写：

```text
rs1_addr -> rs1_data
rs2_addr -> rs2_data
rd_addr  -> rd_old_data
rd_addr + rd_wdata + reg_write -> write port
```

约束：

- x0 恒为 0。
- 写入 x0 必须忽略。
- 第三读口专门服务 MAC，也可供调试观察使用。

## 5. 数据通路修改点

```text
rs1_data ----\
              mac_unit -> mac_result -> wb_mux -> regfile rd
rs2_data ----/
rd_old_data -/
```

`mac_unit` 输入：

- `rs1_data`
- `rs2_data`
- `rd_old_data`

`mac_unit` 输出：

- `mac_result`

WRITEBACK 阶段：

- `wb_sel=MAC`。
- `reg_write=1`。
- `rd_wdata=mac_result`。

## 6. 控制信号修改点

| 信号 | 作用 |
|---|---|
| `is_mac` | 当前指令为 MAC |
| `mac_enable` | 启用 MAC 单元 |
| `wb_sel` | 选择 MAC 结果写回 |
| `reg_write` | 写回 rd |
| `mac_count_en` | MAC 指令计数 |

## 7. 多周期 FSM 中 MAC 的执行流程

| 状态 | 行为 |
|---|---|
| FETCH | 取 MAC 指令 |
| DECODE | 读 rs1、rs2、rd_old，识别 `is_mac` |
| EXECUTE | 计算 `rd_old + rs1 * rs2` |
| MEMORY | 跳过 |
| WRITEBACK | 写回 rd，`mac_count++`，`instret_count++` |

## 8. 性能计数器关系

MAC 完成时：

- `mac_count` 加 1。
- `instret_count` 加 1。
- `cycle_count` 正常按周期累计。

普通点积和 MAC 点积的对比指标：

- 周期数。
- 指令数。
- CPI。
- DSP 使用量。
- Timing slack。

## 9. MAC 测试程序规划

测试目标：

- 普通点积结果与 MAC 点积结果一致。
- MAC 版本指令数和周期数更少。
- `mac_count` 等于 MAC 指令执行次数。

建议点积：

```text
sum = a0*b0 + a1*b1 + a2*b2 + a3*b3
```

## 10. 风险与降级方案

| 风险 | 降级方案 |
|---|---|
| 第三读口导致 regfile 复杂 | 改为 x31 累加器方案 |
| 组合乘加 timing 不过 | MAC 改为多周期执行 |
| DSP 未被推断 | 检查乘法写法和 Vivado utilization |
| MAC 周期优势不明显 | 普通版本使用多条 MUL/ADD 或软件乘法作对比 |

备选 x31 方案：

```text
MAC rs1, rs2
x31 = x31 + rs1 * rs2
```

但第一版优先实现 `rd = rd_old + rs1 * rs2`，更通用，也更容易解释为 ISA 扩展。

## 11. 报告展示方式

报告中展示：

- MAC 指令编码表。
- MAC 数据通路图。
- 普通点积和 MAC 点积伪汇编。
- 仿真结果一致性截图。
- 周期数和 CPI 对比。
- Vivado DSP 使用截图。
- PPA 权衡说明。

## 12. 2026-07-09 验证结果

- `tb_mac.v` 覆盖正数、0、有符号负数、低 32 位、累加回绕和连续累加。
- CPU 级测试确认 MAC 写回 `rd`，`mac_count` 每条合法 MAC 只加 1。
- 普通点积和 MAC 点积结果均为 70。
- 普通版本：62 cycles、15 instret、0 MAC。
- MAC 版本：54 cycles、13 instret、4 MAC。
- 周期下降 12.90%，speedup=1.1481。

详细数据见 `reports/tables/perf_comparison.md`。当前结果由 Icarus Verilog
复现，仍需在 Vivado 2018.3 xsim 中补正式截图。
