# 普通点积与 MAC 点积性能对比

日期：2026-07-09

执行人：D 王博生

本地辅助仿真：Icarus Verilog

正式验收：Vivado 2018.3 xsim 待复验

## 测试条件

- CPU：RV32I 多周期 FSM，`CPU_MODE=0`
- 输入：`A=[1,2,3,4]`，`B=[5,6,7,8]`
- 期望结果：`70`
- 普通版本：RV32I 重复加法，不使用未实现的 MUL 指令
- MAC 版本：`rd = rd_old + rs1 * rs2`
- `cycle_count` 包含最后 EBREAK 的 FETCH/DECODE 两个停机周期
- EBREAK 不计入 `instret_count`

## 仿真结果

| 版本 | result | cycle | instret | CPI | mac_count | 相对加速比 |
|---|---:|---:|---:|---:|---:|---:|
| 普通 RV32I 点积 | 70 | 62 | 15 | 4.1333 | 0 | 1.0000 |
| 自定义 MAC 点积 | 70 | 54 | 13 | 4.1538 | 4 | 1.1481 |

计算：

```text
normal CPI = 62 / 15 = 4.1333
MAC CPI    = 54 / 13 = 4.1538
speedup    = 62 / 54 = 1.1481
cycle reduction = (62 - 54) / 62 = 12.90%
instruction reduction = (15 - 13) / 15 = 13.33%
```

## 结论

两版程序结果一致。MAC 版本减少 2 条退休指令和 8 个周期，周期数下降
12.90%，相对加速比为 1.1481。

CPI 略高不是性能退化，而是两个程序都包含固定的 2 个 EBREAK 停机周期；
程序主体中的所有普通写回指令和 MAC 指令都采用 4 周期路径。若排除停机开销，
两版程序主体 CPI 均为 4.0。

## 可复现来源

- `tests/mac/dot_normal.S`
- `tests/mac/dot_normal.hex`
- `tests/mac/dot_mac.S`
- `tests/mac/dot_mac.hex`
- `sim/tb/tb_dot_product.v`
- `reports/tables/test_results.md`
