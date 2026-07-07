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

## 12. `soc_top` 接口（四仓库深度合并后实现）

基于 SEU-Class2 + minisys_unified 的统一总线架构，`soc_top.v` 已实现以下接口：

```verilog
module soc_top #(
    parameter CPU_MODE         = 0,     // CPU核心选择 (0=RV32I多周期FSM)
    parameter INST_RAM_SIZE    = 32768,
    parameter DATA_RAM_SIZE    = 32768
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire [15:0] led,
    input  wire [15:0] sw,
    output wire [7:0]  seg_an,         // 数码管位选（低有效）
    output wire [7:0]  seg_cat,        // 数码管段选（低有效）
    input  wire        uart_rx,
    output wire        uart_tx,
    output wire [31:0] debug_pc,
    output wire [7:0]  debug_state
);
```

内部集成：CPU（通过cpu_top选择器） + inst_ram + bus_decoder + data_ram + 外设 + bus_mux。

## 13. `minisys_top` 板级接口（四仓库深度合并后实现）

`minisys_top.v` 通过 `ifdef MINISYS_USE_SOC_TOP` 切换统一 SoC 模式和心跳占位模式。

```verilog
module minisys_top #(
    parameter CPU_MODE = `CPU_MODE_RISCV_MC  // 默认RV32I多周期FSM
) (
    input        clk,
    input        rst_n,
    input [15:0] sw,
    output [15:0] led,
    output [7:0] seg,
    output [7:0] an
);
```

板级复位极性转换：`wire rst = ~rst_n;`（在 `minisys_top` 内部完成，SoC 模块使用 `rst_n`）。

板级端口映射表（✅ 与 `constraints/minisys.xdc` 交叉验证通过）：

| 功能 | `.xdc` 端口名 | `minisys_top` 端口 | `soc_top` 内部端口 | 位宽 | 有效电平 | FPGA引脚 | 验证 |
|---|---|---|---|---|---|---|---|
| 100MHz 时钟 | `clk` | `clk` | `clk` | 1 | 上升沿 | Y18 | ✅ 三仓库一致 |
| 板级复位 | `rst_n` | `rst_n` | `rst_n` | 1 | 外部低有效，SoC内高有效 | P20 | ✅ 待上板复核极性 |
| 拨码开关 | `sw[15:0]` | `sw[15:0]` | `sw[15:0]` | 16 | 高为1 | W4..AB6 | ✅ 三仓库一致 |
| 用户LED | `led[15:0]` | `led[15:0]` | `led[15:0]` | 16 | 高点亮 | A21..M17 | ✅ 三仓库一致 |
| 七段段选 | `seg[7:0]` | `seg[7:0]` | `seg_cat[7:0]` | 8 | 低点亮 | F15..E13 | ✅ |
| 七段位选 | `an[7:0]` | `an[7:0]` | `seg_an[7:0]` | 8 | 低选中 | C19..A18 | ✅ |

> **验证来源**：① SUSTech CS202 `minisys_cons.xdc`、② SEU-Class2 `minisys-1a-cpu.srcs/constrs_1/`、③ SEU-Group16 `cpu_1.srcs/constrs_1/`、④ 本项目 `constraints/minisys.xdc` 四个约束文件交叉比对，引脚分配100%一致。

## 14. 接口变更流程

1. 提出接口变更原因。
2. 更新本文档。
3. 组长确认。
4. 修改 RTL。
5. 同步修改 testbench。
6. 运行相关仿真。
7. 提交 Git。
