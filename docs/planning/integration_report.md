# 四仓库深度合并整合报告

> 文档类型：组长工作报告
> 作者：A 刘文涛（组长/架构/集成/代码整合）
> 日期：2026-07-08
> 关联文档：`docs/planning/four_repo_deep_merge_plan.md`

---

## 一、整合背景与目标

### 1.1 为什么需要深度合并

项目原始状态只有设计文档（ISA、memory map、interfaces）和一个 `minisys_top.v` 外壳。所有 RTL 源码目录（`src/core/`、`src/memory/`、`src/io/`、`src/soc/`）均为空目录。

为了加速开发、借鉴成熟设计模式、避免从零造轮子，组长 A 对五个经过验证的 Minisys 开源 FPGA 项目进行了深度分析（注：此前文档中的 "SEU-Class2" 和 "SEU-Group16" 实际为同一仓库 SEU minisys / minisys-master）：

| 仓库 | 来源 | 架构 | ISA | 验证状态 | 分析文档 |
|---|---|---|---|---|---|
| NCUT_MiniSys | 北方工业大学 | 5级流水线 | MIPS 31条 | 仿真通过 | 本文档第二章 |
| SUSTech CS202 | 南方科技大学 | 单周期 | MIPS子集 | **Minisys上板 121/100** | 本文档第三章 |
| SEU minisys | 东南大学 | 5级流水线+CP0+BTB | MIPS 57条 | 仿真通过 | `minisys-master/`（含ALC六分类/仲裁器/BTB/CP0/mul等全部模块） |
| riscv-minisys-cpu | 北京邮电大学 | 单周期 | **RV32I 31条** | 仿真通过 | 追加分析 |
| minisys_unified | 组长A预整合 | 4合1统一总线 | MIPS+RV32I | 框架来源 | `reference_repos/minisys_unified/`（已内含SEU全部代码于rtl/cpu/mips_pipe_adv/） |

### 1.2 合并的核心思路

**不是简单复制，而是"设计模式级"的深度提取和 RV32I 适配**：

```text
┌─────────────────────────────────────────────────────────────────┐
│ 步骤1: 分析5个参考仓库（本地reference_repos/），提取各仓库的核心设计模式      │
│                                                                 │
│ 步骤2: 确定本项目不可动摇的底线：                                  │
│   · ISA = RV32I 子集（不是MIPS）                                  │
│   · 第一版 = 多周期FSM（不是单周期也不是5级流水线）                   │
│   · 独有亮点 = MAC自定义指令 + 性能计数器                           │
│   · 平台 = Minisys FPGA (Artix-7 XC7A100T) + EES-329B-V1.1      │
│                                                                 │
│ 步骤3: 从5个仓库中选取最佳设计模式，适配到RV32I：                    │
│   · 总线架构 → SEU minisys 共享总线 + 仲裁器                       │
│   · 外设接口 → 统一6端口 slave 接口                                │
│   · ALU设计 → SEU minisys 六分类方法                               │
│   · 寄存器堆 → NCUT 内部前推模式                                   │
│   · CPU切换 → minisys_unified generate块模式                      │
│   · RV32I译码 → riscv-minisys-cpu opcode驱动                      │
│                                                                 │
│ 步骤4: 代码级统一适配：                                            │
│   · 所有外设从MIPS地址空间 (0xFFFF_FCxx) 直接使用                   │
│   · RV32I CPU 通过统一 ibus/dbus 接入                              │
│   · public.vh 同时覆盖 RV32I 和 MIPS 编码定义                       │
│   · CPU_MODE 参数允许切换不同CPU实现                                │
│                                                                 │
│ 步骤5: 验证和文档同步：                                            │
│   · memory_map.md 更新为统一总线地址                                │
│   · interfaces.md 同步新端口名                                     │
│   · 重新分工规划ABCD                                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## 二、五仓库选型分析

### 2.1 NCUT_MiniSys → 寄存器堆前推 + 流水线寄存器模板

**可取之处**：
- `regfile.v`：内部写后读前推逻辑简洁高效，已直接借鉴到本项目 `regfile.v`
- 流水线寄存器（`if_id.v`/`id_ex.v`/`ex_mem.v`/`mem_wb.v`）：结构清晰，为 P2 流水线冲刺预留

**不可直接用的原因**：
- MIPS ISA（opcode在[31:26]，寄存器位置不同）
- 无MMIO/总线/外设

### 2.2 SUSTech CS202 → 约束交叉验证 + MMIO 地址译码模式

**可取之处**：
- `minisys_cons.xdc`：已验证的 Minisys 约束，与我们的 `constraints/minisys.xdc` 引脚100%一致
- `memio.sv`：通过 `ALU_o[31:10] == 22'h3FFFFF` 区分 Memory 和 IO 空间的思路

**不可直接用的原因**：
- MIPS ISA
- 单周期架构（非多周期FSM）
- 外设接口非标准化

### 2.3 SEU minisys → ★ 共享总线 + ALU六分类 + BTB + CP0（核心借鉴）

> **说明**：文档早期将 SEU minisys 项目（`reference_repos/minisys-master/`）的代码按模块拆分为 "SEU-Class2"（总线/仲裁器/外设接口）和 "SEU-Group16"（ALU分类/BTB/CP0）两个名称。实际上它们来自同一个仓库。`minisys_unified` 已将 SEU minisys 代码整合进 `rtl/cpu/mips_pipe_adv/`，本项目通过 `minisys_unified` 间接获取。

**可取之处（最多，作为本项目架构骨架）**：
- `arbitration.v`：读数据总线仲裁器 → 改造为本项目的 `bus_mux.v`
- `minisys.v` 顶层：CPU + 总线 + 外设的连接模式 → `soc_top.v` 结构
- 外设统一6端口接口（clk/rst/addr/en/byte_sel/data_in/we/data_out）→ 全部外设采用
- `public.v` / `define.v` 宏定义体系 + ALU 六分类（NOP/ARITH/LOGIC/MOVE/SHIFT/JUMP）→ `public.vh` 采用并增加 `ALUTYPE_MAC`
- `cpu_top.v` generate块模式选择 → 直接采用
- `BTB.v`：分支目标缓冲 → P2 流水线冲刺预留
- `CP0.v`：MIPS 协处理器异常框架 → P2 CSR 改造参考

**不可直接用的原因**：
- MIPS 57条指令集（包含 HI/LO/CP0 等 MIPS 特有功能）
- 5级流水线（第一版用多周期）
- 乘除硬件单元（我们做MAC乘加，不做除）

### 2.4 riscv-minisys-cpu → ★ RV32I 指令译码框架（直接参考）

**可取之处（最多，因为ISA一致）**：
- `control_unit.v`：RV32I opcode/funct3/funct7 译码框架 → 本项目 `control_unit.v` 的蓝图
- `alu.v`：11种 RV32I 运算操作 → ALU op 编码映射
- `imm_gen.v`：5种 RV32I 立即数格式 → 直接采用
- `branch_unit.v`：6种 RV32I 分支条件 → 直接采用
- `regfile.v` + `pc.v`：RV32I 规范设计 → 参考

**不可直接用的原因**：
- 单周期架构（所有指令1周期完成，无FSM状态机）
- 无 MAC 指令
- 无性能计数器
- 总线为直连模式（非统一共享总线）
- `mem_map.v` 的地址映射与我们选定的统一总线不一致

### 2.5 minisys_unified → ★★ 统一框架蓝图（最关键的参考）

**可取之处（作为整体框架模板）**：
- `cpu_top.v` 的 generate 块 + CPU_MODE 参数化选择 → 直接采用
- `soc_top.v` 级联 CPU + inst_ram + bus_decoder + data_ram + 外设 + bus_mux → 直接采用
- `bus_decoder.v` + `bus_mux.v` 的完整总线实现 → 直接采用
- `inst_ram.v` + `data_ram.v` 行为级 BRAM → 直接采用
- 全部外设（gpio_led / gpio_switch / seg7）的 bus slave 接口 → 直接采用
- `sync.v` / `debounce.v` / `edge_det.v` 通用模块 → 直接采用

**不可直接用的原因**：
- RISCV_SC 模式仍是单周期（需要改造成多周期FSM）
- 无 MAC 指令、无性能计数器
- MIPS 模式仍占多数（MODE 0/2/3 为 MIPS）
- 尚未经过 Vivado 验证

---

## 三、合并过程中的关键设计决策

### 决策1：总线地址空间的选择

**问题**：旧版 `memory_map.md` 将 MMIO 放在 `0x1000_0xxx`，但 SEU minisys 统一总线使用 `0xFFFF_FCxx` 作为外设区。

**分析**：
- 方案A：修改 bus_decoder 适配旧版地址（工作量大，且失去与参考设计的兼容性）
- 方案B：更新 memory_map.md 适配统一总线地址（文档同步，代码不变）

**选择**：方案B —— 更新 `memory_map.md` 为统一总线地址映射。

**理由**：
1. `0xFFFF_FCxx` 与 Data Memory 区（`0x1000_xxxx`）完全分离，不会发生地址冲突
2. 所有借鉴自 SEU minisys 的外设控制器（LED/Switch/SEG7）原生支持该地址
3. 参考仓库中的测试程序可直接适配（仅需修改地址常量）
4. `addr[9:4]` 二级译码方式扩展性强，最多支持 16 个外设

### 决策2：ALU 操作码扩展

**问题**：旧版 `interfaces.md` 中 ALU 的操作选择 `alu_op` 宽度为"待定"，且未区分操作类别。

**分析**：
- riscv-minisys-cpu 使用 4-bit alu_op
- SEU minisys 使用 8-bit alu_op + 3-bit alu_type（六分类）
- 本项目需要同时支持 RV32I 基础运算和 MAC 乘加

**选择**：采用 SEU minisys 的六分类方案并扩展。

**理由**：
1. `alu_type`（NOP/ARITH/LOGIC/MOVE/SHIFT/JUMP/MAC）使 ALU 结构清晰可维护
2. `alu_op`（8-bit）足够容纳 RV32I 全部操作码 + MAC + 未来扩展（MUL/DIV）
3. 分类与流水线阶段对应：EXECUTE 阶段可根据 `alu_type` 选择不同的数据路径

### 决策3：多周期 FSM 状态设计

**问题**：旧版 `architecture.md` 建议 6 状态 FSM（FETCH/DECODE/EXECUTE/MEMORY/WRITEBACK/HALT），但无具体实现。

**分析**：
- 单周期 CPU（riscv-minisys-cpu）所有指令 1 周期完成，控制简单但时序紧张
- 5级流水线（NCUT/SEU）性能最优但控制和冒险处理复杂
- 多周期 FSM 是中间的"甜点"：控制清晰，便于调试和答辩解释

**选择**：实现 6 状态 FSM，状态转移逻辑集中在 `riscv_mc_cpu.v` 中。

**设计要点**：
- FETCH → DECODE → EXECUTE：所有指令必经
- EXECUTE → MEMORY：仅 LW/SW 进入（访存指令）
- EXECUTE → WRITEBACK：ALU/MAC/JAL/JALR/LUI/AUIPC 进入
- MEMORY → WRITEBACK：LW 进入
- WRITEBACK → FETCH：完成写回，更新 PC
- EBREAK 在 DECODE 阶段触发进入 HALT

### 决策4：CPU_MODE 参数化设计

**问题**：如何在保留本项目 RV32I 多周期主线的前提下，同时利用参考 CPU 进行对比验证？

**选择**：借鉴 minisys_unified 的 `generate` 块 + `CPU_MODE` 参数模式。

**实现**：
```verilog
module cpu_top #(parameter CPU_MODE = 0) (...);
    generate
        if (CPU_MODE == 0)       // RV32I multi-cycle FSM ★ PRIMARY
            riscv_mc_wrapper ...;
        else if (CPU_MODE == 1)  // RV32I single-cycle (reference)
            riscv_sc_wrapper ...;
        // MIPS modes 2-4 as placeholders
    endgenerate
endmodule
```

**好处**：
1. 一个 Vivado 工程，切换参数即可对比不同CPU实现
2. PPA 对比：同一套外设/总线/约束下，CPU核心可以A/B测试
3. 降级方案：若多周期FSM遇到阻塞，可临时切换到已验证的单周期模式

---

## 四、一致性验证报告

### 4.1 板级约束验证 ✓

| 检查项 | minisys.xdc | minisys_top.v | SUSTech minisys_cons.xdc | SEU minisys XDC | 结果 |
|---|---|---|---|---|---|
| clk 引脚 | Y18 | `input clk` | Y18 (fpga_clk) | Y18 (board_clk) | ✅ 一致 |
| rst 引脚 | P20 | `input rst_n` | P20 (fpga_rst) | P20 (board_rst) | ✅ 一致 |
| sw[0]~sw[15] | W4..AB6 (16个) | `input [15:0] sw` | W4..AB6 (switch2N4) | 同 | ✅ 一致 |
| led[0]~led[15] | A21..M17 (16个) | `output [15:0] led` | A21..M17 (led2N4) | 同 | ✅ 一致 |
| an[0]~an[7] | C19..A18 (8个) | `output [7:0] an` | C19..A18 (seg_en) | 同 | ✅ 一致 |
| seg[0]~seg[7] | F15..E13 (8个) | `output [7:0] seg` | F15..E13 (seg_out) | 同 | ✅ 一致 |
| 复位极性 | rst_n (低有效) | `wire rst = ~rst_n` | 同 | 同 | ✅ 一致 |
| 数码管极性 | seg/an 低有效 | `seg7_driver.v` 低有效 | 同 | 同 | ✅ 一致 |
| LED 极性 | 高点亮 | `gpio_led.v` 高有效 | 同 | 同 | ✅ 一致 |

**结论**：三个参考仓库的 Minisys 约束文件与本项目 `constraints/minisys.xdc` **引脚100%一致**。板级端口（clk/rst_n/sw/led/seg/an）和有效电平完全对齐。

### 4.2 ISA 编码验证 ✓

| 检查项 | isa.md 定义 | public.vh 宏 | control_unit.v 实现 | 结果 |
|---|---|---|---|---|
| ADD opcode | `0110011` | `RV_OP_ARITH = 7'b0110011` | 匹配 | ✅ |
| ADD funct3/funct7 | `000`/`0000000` | `RV_F3_ADDSUB`/`RV_F7_ADD` | 匹配 | ✅ |
| SUB funct7 | `0100000` | `RV_F7_SUB = 7'b0100000` | funct7判断分支 | ✅ |
| MAC opcode | `0001011` | `RV_OP_MAC = 7'b0001011` | 匹配 custom-0 | ✅ |
| MAC funct7 | `0000001` | `RV_F7_MAC = 7'b0000001` | 匹配 | ✅ |
| EBREAK 编码 | `0x00100073` | `RV_EBREAK = 32'h00100073` | 全字比较 | ✅ |
| JAL opcode | `1101111` | `RV_OP_JAL = 7'b1101111` | 匹配 | ✅ |
| LW opcode | `0000011` | `RV_OP_LOAD = 7'b0000011` | 匹配 | ✅ |
| SW opcode | `0100011` | `RV_OP_STORE = 7'b0100011` | 匹配 | ✅ |

**结论**：`public.vh` 和 `control_unit.v` 中的 RV32I 编码与 `isa.md` **完全一致**。

### 4.3 接口一致性验证 ✓

| 模块 | interfaces.md 定义 | RTL 实现 | 差异说明 | 结果 |
|---|---|---|---|---|
| regfile | 3读1写，含 rd_old | `regfile.v` 3读1写 + 内部前推 | 增加内部前推（优化） | ✅ |
| alu | a/b/alu_op/result/zero | 增加 `alu_type` | SEU minisys六分类扩展 | ✅ |
| mac_unit | rs1/rs2/rd_old → mac_result | 完全匹配 | ✅ |
| csr_perf_counter | clk/rst/halted/instret/mac → counters | 完全匹配 | ✅ |
| control_unit | instr → 控制信号 | 扩展了更多信号 | 硬件实现需更多细节信号 | ✅ |

**结论**：RTL 实现全部满足或扩展了 `interfaces.md` 的接口定义，无遗漏。

### 4.4 内存映射一致性验证 ✓

| 检查项 | memory_map.md (新版) | bus_decoder.v | 结果 |
|---|---|---|---|
| Instruction Memory | `0x0000_0000 - 0x0000_7FFF` | ibus 直接连接 inst_ram | ✅ |
| Data Memory | `0x1000_0000 - 0x1000_7FFF` | `in_data_ram` 范围匹配 | ✅ |
| LED 地址 | `0xFFFF_FC00` | `periph_id == 6'b00_0000` | ✅ |
| Switch 地址 | `0xFFFF_FC10` | `periph_id == 6'b00_0001` | ✅ |
| SEG7 地址 | `0xFFFF_FC20` | `periph_id == 6'b00_0010` | ✅ |
| UART 地址 | `0xFFFF_FC30` | `periph_id == 6'b00_0011` | ✅ |

**结论**：新版 `memory_map.md` 与 `bus_decoder.v` 地址译码逻辑**完全一致**。

---

## 五、生成的RTL文件清单与追溯

| 文件 | 行数 | 主要参考来源 | 改造程度 |
|---|---|---|---|
| `src/core/public.vh` | 280 | ③public.v + ④define.v | ★★★ 完全重写：RV32I+MIPS双ISA+ALU六分类+总线定义 |
| `src/core/alu.v` | 65 | ④Ex_1.v + ⑤alu.v | ★★ 重写：六分类改为七分类(+MAC)，操作码改为RV32I |
| `src/core/regfile.v` | 70 | ①regfile.v + ⑤regfile.v | ★★ 改造：3读1写+内部前推+MAC第三读口 |
| `src/core/imm_gen.v` | 40 | ⑤imm_gen.v | ★ 轻改造：RV32I五种立即数格式 |
| `src/core/branch_unit.v` | 30 | ⑤branch_unit.v | ★ 轻改造：增加到6种分支条件 |
| `src/core/pc_reg.v` | 40 | ③pc.v + ①pc_reg.v | ★★ 改造：去掉延迟槽，增加stall输入 |
| `src/core/control_unit.v` | 250 | ⑤control_unit.v + ③id.v | ★★★ 核心重写：MIPS→RV32I译码框架，增加MAC |
| `src/core/mac_unit.v` | 30 | 独创 | ★★★ 完全独创：乘加组合逻辑，DSP推断 |
| `src/core/csr_perf_counter.v` | 60 | 独创 | ★★★ 完全独创：3个32bit计数器 |
| `src/core/riscv_mc_cpu.v` | 280 | ⑤riscv_cpu.v + architecture.md | ★★★ 核心重写：单周期→6状态FSM |
| `src/core/riscv_mc_wrapper.v` | 45 | ③各wrapper | ★ 轻改造：统一总线适配 |
| `src/core/cpu_top.v` | 75 | ⑥cpu_top.v | ★ 轻改造：增加MODE-0为主模式 |
| `src/bus/bus_decoder.v` | 65 | ③arbitration.v + ⑥bus_decoder.v | ★ 轻改造：增加perf/result外设 |
| `src/bus/bus_mux.v` | 70 | ③arbitration.v + ⑥bus_mux.v | ★ 轻改造：增加perf/result通道 |
| `src/memory/inst_ram.v` | 55 | ⑥inst_ram.v | ★ 直接采用 |
| `src/memory/data_ram.v` | 60 | ⑥data_ram.v | ★ 直接采用 |
| `src/io/gpio_led.v` | 45 | ⑥gpio_led.v | ★ 直接采用 |
| `src/io/gpio_switch.v` | 55 | ⑥gpio_switch.v | ★ 直接采用 |
| `src/io/seg7_driver.v` | 100 | ⑥seg7.v | ★ 直接采用 |
| `src/common/sync.v` | 30 | ⑥sync.v | ★ 直接采用 |
| `src/common/debounce.v` | 35 | ⑥debounce.v | ★ 直接采用 |
| `src/common/edge_det.v` | 25 | ⑥edge_det.v | ★ 直接采用 |
| `src/soc/soc_top.v` | 200 | ⑥top_minisys.v | ★★ 改造：简化顶层，适配本项目的CPU_MODE |
| `src/board/minisys_top.v` | 75 | 原项目 + ⑥top_minisys.v | ★★ 改造：整合统一SoC |

**统计**：24 个 RTL 文件，总约 2100 行代码。其中：
- ★★★ 完全重写/独创：4 个文件（`public.vh`, `control_unit.v`, `riscv_mc_cpu.v`, `mac_unit.v`）
- ★★ 中度改造：6 个文件
- ★ 轻改造/直接采用：14 个文件

---

## 六、当前项目功能清单

### 6.1 已实现功能（P0基线）

| 功能 | 实现模块 | 验证状态 |
|---|---|---|
| RV32I 子集 31条指令 | `control_unit.v` | 代码完成，待xsim验证 |
| MAC 自定义指令（rd_new=rd_old+rs1*rs2） | `mac_unit.v` + `control_unit.v` | 代码完成，待xsim验证 |
| 多周期 FSM（6状态） | `riscv_mc_cpu.v` | 代码完成，待xsim验证 |
| 32×32 寄存器堆（3读1写，x0=0） | `regfile.v` | 代码完成，待xsim验证 |
| ALU（7类运算） | `alu.v` | 代码完成，待xsim验证 |
| 5种立即数生成（I/S/B/U/J） | `imm_gen.v` | 代码完成，待xsim验证 |
| 6种分支条件判断 | `branch_unit.v` | 代码完成，待xsim验证 |
| EBREAK/HALT 停机 | `control_unit.v` + `riscv_mc_cpu.v` | 代码完成，待xsim验证 |
| 指令 BRAM（32KB，组合读） | `inst_ram.v` | 代码完成，待xsim验证 |
| 数据 BRAM（32KB，字节使能写） | `data_ram.v` | 代码完成，待xsim验证 |
| 统一共享总线（ibus+dbus） | `bus_decoder.v` + `bus_mux.v` | 代码完成，待xsim验证 |
| 16位 LED 输出 | `gpio_led.v` | 代码完成，待xsim验证 |
| 16位拨码开关输入（2级同步） | `gpio_switch.v` | 代码完成，待xsim验证 |
| 8位数码管动态扫描 | `seg7_driver.v` | 代码完成，待xsim验证 |
| 性能计数器（cycle/instret/mac） | `csr_perf_counter.v` | 代码完成，待xsim验证 |
| CPU_MODE 多核切换 | `cpu_top.v` | 代码完成，待综合验证 |
| 板级约束映射 | `minisys_top.v` + `constraints/minisys.xdc` | 约束已确认，待上板 |

### 6.2 待补充功能

| 功能 | 优先级 | 负责人 | 预计时间 |
|---|---|---|---|
| xsim 仿真验证（basic_test.hex） | P0 紧急 | B | 第1-2天 |
| ALU/regfile/control 单元 testbench | P0 | B | 第1-2天 |
| MAC 点积测试程序 | P1 | D | 第3-4天 |
| Vivado 综合/实现/bitstream | P0 | C | 第2-3天 |
| 上板演示（LED/数码管） | P0 | C | 第4-5天 |
| RV32I 单周期 wrapper 接入 | P1 | A | 第3天 |
| 性能计数器 MMIO 暴露 | P1 | D | 第3-4天 |
| UART 外设实现 | P2 | C | 第6天 |
| 五级流水线冲刺 | P2 | D | 第5-7天 |

---
