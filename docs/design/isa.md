# RV32I 子集与自定义指令编码

用途：冻结第一版 CPU 的指令范围、编码方案、控制信号和最小测试程序口径。

最后更新时间：2026-07-06

## 1. ISA 总体说明

第一版采用 RV32I 子集，不实现完整 RV32I。目标是支持课程验收所需的算术、逻辑、访存、分支和停止类指令，并加入 MAC 自定义指令作为主线拓展。

## 2. 指令格式

| 格式 | 用途 |
|---|---|
| R-type | ADD/SUB/AND/OR/XOR/MAC |
| I-type | ADDI/LW/EBREAK |
| S-type | SW |
| B-type | BEQ/BNE |
| J-type | JAL，可选 |
| custom | MAC 使用 RISC-V custom opcode |

## 3. 第一版必做指令表

| 指令 | 格式 | opcode | funct3 | funct7/imm | 写寄存器 | 访存 | 改 PC | 特殊控制 |
|---|---|---|---|---|---|---|---|---|
| ADD | R | `0110011` | `000` | `0000000` | 是 | 否 | 否 | `alu_op=ADD` |
| SUB | R | `0110011` | `000` | `0100000` | 是 | 否 | 否 | `alu_op=SUB` |
| AND | R | `0110011` | `111` | `0000000` | 是 | 否 | 否 | `alu_op=AND` |
| OR | R | `0110011` | `110` | `0000000` | 是 | 否 | 否 | `alu_op=OR` |
| XOR | R | `0110011` | `100` | `0000000` | 是 | 否 | 否 | `alu_op=XOR` |
| ADDI | I | `0010011` | `000` | - | 是 | 否 | 否 | `alu_src_imm=1` |
| LW | I | `0000011` | `010` | - | 是 | 读 | 否 | `mem_read=1` |
| SW | S | `0100011` | `010` | - | 否 | 写 | 否 | `mem_write=1` |
| BEQ | B | `1100011` | `000` | - | 否 | 否 | 条件 | `branch_eq=1` |
| BNE | B | `1100011` | `001` | - | 否 | 否 | 条件 | `branch_ne=1` |
| EBREAK | I/SYSTEM | `1110011` | `000` | `0x001` | 否 | 否 | 停止 | `halt=1` |
| MAC | R/custom | `0001011` | `000` | `0000001` | 是 | 否 | 否 | `is_mac=1` |

## 4. 可选指令表

| 指令 | 格式 | opcode | 用途 | 是否第一版必做 |
|---|---|---|---|---|
| JAL | J | `1101111` | 无条件跳转，可支持简单循环/函数 | 可选 |

## 5. EBREAK/HALT

HALT 统一使用 RISC-V EBREAK 编码：

```text
EBREAK = 0x00100073
```

CPU 检测到该指令后进入 `HALT` 状态：

- `done=1`。
- 停止继续取指。
- `cycle_count` 是否继续计数由 `csr_perf_counter` 文档定义；第一版建议 HALT 后停止计数。

## 6. MAC 自定义指令编码

推荐使用 RISC-V `custom-0` opcode：

```text
funct7 = 0000001
rs2    = instr[24:20]
rs1    = instr[19:15]
funct3 = 000
rd     = instr[11:7]
opcode = 0001011
```

语义：

```text
MAC rd, rs1, rs2
rd_new = rd_old + rs1 * rs2
```

理由：

- `0001011` 属于 custom opcode，不与标准 RV32I 基础指令冲突。
- R-type 字段复用 `rd/rs1/rs2`，译码简单。
- 便于答辩解释“自定义 ISA 扩展”。

## 7. 控制信号表

| 控制信号 | 含义 |
|---|---|
| `alu_op` | ALU 操作选择 |
| `alu_src_imm` | ALU B 端是否来自立即数 |
| `reg_write` | 是否写回 rd |
| `mem_read` | 是否读存储器/MMIO |
| `mem_write` | 是否写存储器/MMIO |
| `wb_sel` | 写回来源：ALU/MEM/PC4/MAC |
| `branch_op` | 分支类型 |
| `is_mac` | 当前指令为 MAC |
| `mac_enable` | 启用 MAC 数据通路 |
| `mac_count_en` | MAC 计数脉冲 |
| `halt` | 进入 HALT 状态 |

## 8. 指令与 FSM 阶段对应

| 指令类型 | FETCH | DECODE | EXECUTE | MEMORY | WRITEBACK |
|---|---|---|---|---|---|
| ALU R/I | 取指 | 译码/读寄存器 | ALU | 跳过 | 写 rd |
| LW | 取指 | 译码/读 rs1 | 地址计算 | 读内存 | 写 rd |
| SW | 取指 | 译码/读 rs1/rs2 | 地址计算 | 写内存 | 跳过 |
| BEQ/BNE | 取指 | 译码/读寄存器 | 分支判断/改 PC | 跳过 | 跳过 |
| MAC | 取指 | 读 rs1/rs2/rd_old | MAC | 跳过 | 写 rd |
| EBREAK | 取指 | 识别 halt | 进入 HALT | - | - |

## 9. 最小测试程序示例

```text
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2
sw   x3, 0(x0)
lw   x4, 0(x0)
beq  x3, x4, pass
addi x5, x0, 0
ebreak
pass:
addi x5, x0, 1
ebreak
```

通过标准：仿真结束时 `x5=1`、`done=1`、`error=0`。
