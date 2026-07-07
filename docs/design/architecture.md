# 系统总体架构

用途：说明项目第一版最小可行系统的整体结构、数据流、FSM 执行流程，以及后续迁移到流水线的路径。

最后更新时间：2026-07-07

## 1. 目标分级

### P0 保底目标

- RV32I 子集多周期 CPU。
- BRAM 指令存储器和数据存储器。
- Memory-mapped I/O。
- LED 显示运行状态。
- 七段数码管显示结果或计数器低位。
- Vivado xsim 仿真通过。
- Vivado 综合、实现、bitstream 生成。
- Minisys 上板演示成功。

### P1 主线目标

- 小型 SoC：CPU + BRAM memory + GPIO + seg7 + performance counter。
- MAC 自定义指令。
- 普通点积程序与 MAC 点积程序周期对比。
- cycle_count、instret_count、mac_count。
- Vivado utilization/timing 数据与 PPA 分析。

### P2 冲刺目标

- 五级流水线基础版本。
- Forwarding、load-use stall、branch flush。
- UART 输出性能统计。
- stall_count、flush_count、branch_count、branch_miss_count。

## 2. 第一版采用多周期 FSM CPU 的原因

第一版最终采用多周期 FSM，而不是直接做五级流水线。

原因：

- 一周周期内优先保证可仿真、可综合、可上板。
- 多周期结构更容易和同步 BRAM 配合。
- 控制路径清晰，便于四人分模块开发和答辩解释。
- MAC、性能计数、MMIO 可以先稳定接入，避免流水线冒险拖垮进度。
- 后续仍可复用 ALU、regfile、imm_gen、branch_unit、mac_unit、mem_bus 等模块迁移到流水线。

## 3. 系统总体框图

```text
Minisys Board
└── minisys_top
    └── soc_top
        ├── cpu_top
        │   ├── multi-cycle FSM
        │   ├── pc
        │   ├── regfile
        │   ├── alu
        │   ├── control_unit
        │   ├── imm_gen
        │   ├── branch_unit
        │   ├── mac_unit
        │   └── csr_perf_counter
        ├── instr_mem
        ├── data_mem
        ├── mem_bus
        └── mmio
            ├── gpio_led
            ├── gpio_switch
            └── seg7_driver
```

## 4. CPU 核心结构

`cpu_top` 负责组织多周期执行流程：

- `pc`：保存当前指令地址。
- `regfile`：32 个 32 bit 通用寄存器，x0 恒为 0；第一版采用 3 读 1 写。
- `alu`：执行算术逻辑、地址计算。
- `control_unit`：译码并产生控制信号。
- `imm_gen`：生成 I/S/B/J 型立即数。
- `branch_unit`：判断 BEQ/BNE。
- `mac_unit`：执行 `rd_old + rs1 * rs2`。
- `csr_perf_counter`：统计 cycle、instret、mac。

## 5. SoC 结构

`soc_top` 连接 CPU、存储器和 MMIO：

- `instr_mem`：程序 ROM/BRAM。
- `data_mem`：数据 RAM/BRAM。
- `mem_bus`：根据地址选择 data memory 或 MMIO。
- `gpio_led`：LED 输出寄存器。
- `gpio_switch`：拨码开关输入。
- `seg7_driver`：七段数码管扫描显示。

`minisys_top` 只负责板级映射，不承载 CPU 或 MMIO 业务逻辑：

- 接入 `constraints/minisys.xdc` 中的板级端口。
- 将板级复位转换为内部高有效 `rst`。
- 将 `sw/led/seg/an` 映射到 `soc_top` 的语义化端口。

`soc_top` 才负责 CPU、BRAM、MMIO、LED、switch、seg7 的系统集成。`mac_unit` 和 `csr_perf_counter` 属于 CPU/核心扩展路径，通过 MMIO 或 display mux 暴露给板级显示。

## 6. FSM 状态

第一版至少包含：

```text
FETCH -> DECODE -> EXECUTE -> MEMORY -> WRITEBACK -> FETCH
HALT 单独停机状态
```

状态说明：

| 状态 | 作用 |
|---|---|
| FETCH | 用 PC 从 instr_mem 取指 |
| DECODE | 译码，读寄存器，生成立即数 |
| EXECUTE | ALU、branch、MAC 执行 |
| MEMORY | LW/SW 或 MMIO 访问 |
| WRITEBACK | 写回寄存器，更新 instret |
| HALT | 停止取指，`done=1` |

## 7. 取指流程

1. `pc` 输出给 `instr_mem`。
2. `instr_mem` 返回 `instr`。
3. `cpu_top` 在 FETCH/DECODE 边界锁存指令。
4. 默认下一条 PC 为 `pc + 4`。
5. 分支或跳转指令在 EXECUTE 阶段决定是否改写 PC。

## 8. 访存流程

1. LW/SW 在 EXECUTE 阶段由 ALU 计算地址。
2. MEMORY 阶段向 `mem_bus` 发起访问。
3. `mem_bus` 判断目标是 `data_mem` 还是 MMIO。
4. LW 的返回数据在 WRITEBACK 阶段写回寄存器。
5. SW 不写回寄存器，但计入已退休指令。

## 9. MMIO 访问流程

MMIO 第一版设计为单周期读写：

- 写 LED/SEG7/result_reg：CPU 执行 SW 到对应地址。
- 读 SWITCH/counter/status：CPU 执行 LW 到对应地址。
- `mem_bus` 对非法 MMIO 地址返回 0，并置 error 或 status 标志。

## 10. MAC 接入位置

MAC 单元接在 EXECUTE 阶段：

```text
rs1_data ----\
              mac_unit -> mac_result -> WRITEBACK -> rd
rs2_data ----/
rd_old_data -/
```

`regfile` 第三读口读取 `rd_old_data`。`control_unit` 识别 `is_mac` 后设置 `wb_sel=MAC`、`reg_write=1`、`mac_count_en=1`。

## 11. 性能计数器位置

`csr_perf_counter` 放在 CPU 核心中，由执行状态产生 pulse：

- `cycle_count`：CPU 未 HALT 时每周期加 1。
- `instret_count`：指令完成时加 1。
- `mac_count`：MAC 指令完成时加 1。

计数器通过 MMIO 暴露给 CPU，也可由 `display_mux` 直接送数码管显示。

## 12. 迁移到流水线的路径

第一版多周期模块应保持边界清晰，便于迁移：

1. 保留 ALU、regfile、imm_gen、branch_unit、mac_unit。
2. 增加 IF/ID、ID/EX、EX/MEM、MEM/WB 流水寄存器。
3. 先运行手插 NOP 程序。
4. 再加入 forwarding。
5. 再加入 load-use stall。
6. 最后加入 branch flush。

流水线是 P2 冲刺目标，不作为第一版阻塞项。
