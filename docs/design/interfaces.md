# 模块接口统一约束

用途：作为四人小组后续分模块开发的接口标准。公共接口变更必须先更新本文档。

最后更新时间：2026-07-07

## 1. 全局信号规范

- 所有时序模块使用 `clk`。
- 第一版内部同步复位统一使用 `rst`，高有效。
- 板级 `rst_n` 在 `minisys_top` 内部转换为 `rst`。
- 数据宽度统一 32 bit。
- 地址宽度顶层统一 32 bit。
- 寄存器编号宽度统一 5 bit。
- 写使能统一使用 `we` 或 `reg_write`。
- 模块名小写加下划线。
- Verilog 文件名与模块名保持一致。

## 2. `regfile` 接口

第一版 3 读 1 写。

| 端口 | 方向 | 宽度 | 说明 |
|---|---|---:|---|
| `clk` | input | 1 | 时钟 |
| `rst` | input | 1 | 高有效同步复位 |
| `rs1_addr` | input | 5 | 读口 1 |
| `rs2_addr` | input | 5 | 读口 2 |
| `rd_old_addr` | input | 5 | MAC 第三读口 |
| `rd_addr` | input | 5 | 写地址 |
| `rd_wdata` | input | 32 | 写数据 |
| `reg_write` | input | 1 | 写使能 |
| `rs1_data` | output | 32 | 读口 1 数据 |
| `rs2_data` | output | 32 | 读口 2 数据 |
| `rd_old_data` | output | 32 | rd 原值 |

约束：x0 恒为 0，不允许写入。

## 3. `alu` 接口

| 端口 | 方向 | 宽度 | 说明 |
|---|---|---:|---|
| `a` | input | 32 | 操作数 A |
| `b` | input | 32 | 操作数 B |
| `alu_op` | input | 待定 | 操作选择 |
| `result` | output | 32 | 结果 |
| `zero` | output | 1 | result 是否为 0 |

## 4. `control_unit` 接口

| 端口 | 方向 | 宽度 | 说明 |
|---|---|---:|---|
| `instr` | input | 32 | 指令 |
| `alu_op` | output | 待定 | ALU 操作 |
| `alu_src_imm` | output | 1 | ALU B 端选择立即数 |
| `reg_write` | output | 1 | 写回使能 |
| `mem_read` | output | 1 | 读存储器 |
| `mem_write` | output | 1 | 写存储器 |
| `wb_sel` | output | 待定 | 写回选择 |
| `branch_op` | output | 待定 | 分支类型 |
| `is_mac` | output | 1 | MAC 指令 |
| `halt` | output | 1 | EBREAK/HALT |
| `illegal_instr` | output | 1 | 非法指令 |

## 5. `imm_gen` 接口

| 端口 | 方向 | 宽度 | 说明 |
|---|---|---:|---|
| `instr` | input | 32 | 指令 |
| `imm` | output | 32 | 符号扩展立即数 |

## 6. `branch_unit` 接口

| 端口 | 方向 | 宽度 | 说明 |
|---|---|---:|---|
| `rs1_data` | input | 32 | 操作数 1 |
| `rs2_data` | input | 32 | 操作数 2 |
| `branch_op` | input | 待定 | BEQ/BNE |
| `branch_taken` | output | 1 | 是否跳转 |

## 7. `mac_unit` 接口

| 端口 | 方向 | 宽度 | 说明 |
|---|---|---:|---|
| `rs1_data` | input | 32 | 乘数 A |
| `rs2_data` | input | 32 | 乘数 B |
| `rd_old_data` | input | 32 | 累加输入 |
| `mac_result` | output | 32 | MAC 结果 |

## 8. `csr_perf_counter` 接口

| 端口 | 方向 | 宽度 | 说明 |
|---|---|---:|---|
| `clk` | input | 1 | 时钟 |
| `rst` | input | 1 | 复位 |
| `halted` | input | 1 | CPU 停机 |
| `instret_pulse` | input | 1 | 指令退休 |
| `mac_pulse` | input | 1 | MAC 完成 |
| `cycle_count` | output | 32 | 周期计数 |
| `instret_count` | output | 32 | 指令计数 |
| `mac_count` | output | 32 | MAC 计数 |

## 9. `instr_mem` / `data_mem` 接口

`instr_mem`：

| 端口 | 方向 | 宽度 | 说明 |
|---|---|---:|---|
| `clk` | input | 1 | 时钟 |
| `addr` | input | 32 | 指令地址 |
| `instr` | output | 32 | 指令 |

`data_mem`：

| 端口 | 方向 | 宽度 | 说明 |
|---|---|---:|---|
| `clk` | input | 1 | 时钟 |
| `we` | input | 1 | 写使能 |
| `addr` | input | 32 | 数据地址 |
| `wdata` | input | 32 | 写数据 |
| `rdata` | output | 32 | 读数据 |

## 10. `mem_bus` 接口

`mem_bus` 连接 CPU、data_mem 和 MMIO。具体端口可在实现前进一步冻结，但必须包含：

- CPU 地址、写数据、读写使能。
- data_mem 地址、写数据、写使能、读数据。
- MMIO 地址、写数据、读写使能、读数据。
- `mem_access` 和 `illegal_addr` 状态输出。

## 11. I/O 模块接口

`gpio_led`：

- `clk,rst,we,wdata`
- `led_value`

`gpio_switch`：

- `sw[15:0]`
- `rdata[31:0]`

`seg7_driver`：

- `clk,rst,value[31:0]`
- `seg[7:0], an[7:0]`
- Minisys 数码管为共阳极，`seg` 和 `an` 均低电平有效。

## 12. `soc_top` 接口

RTL 尚未完成时先冻结语义接口，后续实现应尽量采用：

```text
input         clk
input         rst
input  [15:0] sw_i
output [15:0] led_o
output [7:0]  seg_data_o
output [7:0]  seg_sel_o
```

## 13. `minisys_top` 板级接口

老师资料中的 Minisys 约束已确认，项目统一采用 `constraints/minisys.xdc` 和以下板级端口。`Minisys_Master.xdc` 原始端口名带有 MIPS 工程痕迹，项目不把这些名字扩散到内部模块。

```text
input        clk
input        rst_n
input [15:0] sw
output [15:0] led
output [7:0] seg
output [7:0] an
```

`minisys_top` 内部把板级 `rst_n` 转为内部高有效 `rst`。`seg[7:0]` 和 `an[7:0]` 均按 Minisys 共阳极数码管低电平有效方式驱动。

板级端口映射表：

| 功能 | 官方/主线 `.xdc` 端口名 | `minisys_top` 端口 | `soc_top` 内部端口 | 位宽 | 有效电平 | 备注 |
|---|---|---|---|---:|---|---|
| 100MHz 主时钟 | `clk` | `clk` | `clk` | 1 | 上升沿 | Y18 |
| 板级复位按钮 | `rst_n` | `rst_n` | `rst` | 1 | 内部高有效 | P20；实际按钮极性需上板复核 |
| 拨码开关 | `sw[15:0]` | `sw[15:0]` | `sw_i[15:0]` | 16 | 高电平为 1 | 第一版 SW0-SW15 |
| 用户 LED | `led[15:0]` | `led[15:0]` | `led_o[15:0]` | 16 | 高电平点亮 | 第一版低 8 位显示核心状态 |
| 七段段选 | `seg[7:0]` | `seg[7:0]` | `seg_data_o[7:0]` | 8 | 低电平点亮 | `seg[0]=CA`，`seg[7]=DP` |
| 七段位选 | `an[7:0]` | `an[7:0]` | `seg_sel_o[7:0]` | 8 | 低电平选中 | `an[0]=A0`，`an[7]=A7` |

## 14. 接口变更流程

1. 提出接口变更原因。
2. 更新本文档。
3. 组长确认。
4. 修改 RTL。
5. 同步修改 testbench。
6. 运行相关仿真。
7. 提交 Git。
