# 实验室测试验证计划（B + A 明日执行）

> 日期：2026-07-09
> 成员：B 张淇（主执行）+ A 刘文涛（监督协助）
> 目标：在 Vivado 2018.3 + xsim 下验证 RV32I 多周期 FSM CPU 核心模块

---

## 一、环境准备清单

| 序号 | 检查项 | 负责人 | 状态 |
|---|---|---|---|
| 1 | Vivado 2018.3 已安装并可打开 | B | 待确认 |
| 2 | Git 仓库已 clone，确认在 main 分支最新提交 (`2829fbf`)| B | 待确认 |
| 3 | `constraints/minisys.xdc` 与 Minisys 板实物端口核对 | B+A | 待确认 |
| 4 | xsim 仿真工具可用 | B | 待确认 |

---

## 二、测试顺序（按依赖关系排列）

### 测试1：ALU 单元测试（预计 30 分钟）

**文件**：`src/core/alu.v` → `sim/tb/tb_alu.v`（需新建）

**测试向量**：
| 操作 | a | b | alu_op | alu_type | 期望result | 期望zero |
|---|---|---|---|---|---|---|
| ADD | 10 | 20 | ALUOP_ADD | ALUTYPE_ARITH | 30 | 0 |
| ADD | -5 | 5 | ALUOP_ADD | ALUTYPE_ARITH | 0 | 1 |
| SUB | 30 | 10 | ALUOP_SUB | ALUTYPE_ARITH | 20 | 0 |
| AND | 0xFF | 0x0F | ALUOP_AND | ALUTYPE_LOGIC | 0x0F | 0 |
| OR  | 0xF0 | 0x0F | ALUOP_OR  | ALUTYPE_LOGIC | 0xFF | 0 |
| XOR | 0xFF | 0xFF | ALUOP_XOR | ALUTYPE_LOGIC | 0x00 | 1 |
| SLL | 2 | 3 | ALUOP_SLL | ALUTYPE_SHIFT | 3<<2=12 | 0 |
| SRL | 4 | 0xF0 | ALUOP_SRL | ALUTYPE_SHIFT | 0xF0>>4=0x0F | 0 |
| SRA | 4 | -16 | ALUOP_SRA | ALUTYPE_SHIFT | 有符号右移 | 0 |
| SLT | -1 | 1 | ALUOP_SLT | ALUTYPE_ARITH | 1 | 0 |
| SLTU| -1 | 1 | ALUOP_SLTU | ALUTYPE_ARITH | 0 | 0 |
| LUI | x | 0x10000 | ALUOP_LUI | ALUTYPE_MOVE | 0x10000000 | 0 |

**通过标准**：所有12个测试向量 result 和 zero 正确。

---

### 测试2：寄存器堆单元测试（预计 20 分钟）

**文件**：`src/core/regfile.v` → `sim/tb/tb_regfile.v`（需新建）

**测试向量**：
| 操作 | 预期 |
|---|---|
| 读 x0 | rs1_data = 0, rs2_data = 0, rd_old_data = 0 |
| 写 x1=0x12345678, 读 x1 | rs1_data = 0x12345678 |
| 写 x1, 同时读 x1（测试内部前推） | rs1_data = 新写入值（不是旧值） |
| 写 x0=任意值, 读 x0 | rs1_data = 0（x0硬连线） |
| 读 MAC 第三读口 rd_old | rd_old_data = 对应寄存器值 |

**通过标准**：x0=0 恒成立，内部前推正确，3个读口同时工作。

---

### 测试3：控制单元译码验证（预计 30 分钟）

**文件**：`src/core/control_unit.v` → `sim/tb/tb_control_unit.v`（需新建）

**测试方法**：遍历32条指令（31 RV32I + MAC），检查控制信号输出。

**重点验证项**：
| 指令 | 关键信号检查 |
|---|---|
| EBREAK (0x00100073) | `halt = 1`, 其他信号为默认值 |
| ADD x3,x1,x2 | `reg_write=1, alu_type=ARITH, alu_op=ADD, alu_src_imm=0` |
| ADDI x1,x0,10 | `reg_write=1, alu_type=ARITH, alu_op=ADD, alu_src_imm=1` |
| LW x4,0(x6) | `reg_write=1, mem_read=1, wb_sel=MEM, alu_src_imm=1` |
| SW x3,0(x6) | `mem_write=1, reg_write=0, alu_src_imm=1` |
| BEQ x3,x4,off | `branch_type=BEQ, reg_write=0` |
| JAL x1,off | `jump=1, wb_sel=PC4, reg_write=1` |
| MAC x3,x1,x2 | `is_mac=1, wb_sel=MAC, reg_write=1, mac_pulse=1` |
| 非法指令 | `illegal_instr=1` |

**通过标准**：32条指令全部译码正确，EBREAK正确触发halt，非法指令正确标记。

---

### 测试4：CPU 基础程序仿真（预计 40 分钟）

**文件**：
- DUT：`src/core/riscv_mc_cpu.v`
- Testbench：`sim/tb/tb_cpu_basic.v`（需新建）
- 程序：`sim/programs/basic_test.hex`（已修复数据地址bug）

**仿真流程**：
1. 在 testbench 中加载 `basic_test.hex` 到 inst_ram
2. 初始化 data_ram
3. 释放复位，启动 CPU
4. 运行直到 `halted = 1` 或超时（建议 500 周期）
5. 检查：`debug_x10`（通过 regfile rs1 观察）、`debug_pc`、`debug_state`

**预期结果**：
- halted = 1
- 最终 x5 = 1（PASS）
- 未进入 illegal_instr 状态
- 总周期数约 30-40（取决于多周期FSM效率）

**波形检查点**：
- 确认 FETCH → DECODE → EXECUTE → (MEMORY) → WRITEBACK 状态跳转
- 确认 EBREAK 指令在 DECODE 阶段触发 HALT
- 确认 PC 在 BEQ 后正确跳转

---

## 三、常见问题应急预案

| 问题 | 可能原因 | 解决方案 |
|---|---|---|
| xsim 报语法错误 | Vivado 2018.3 SystemVerilog 支持有限 | 检查是否使用了不兼容语法（`$clog2`/`generate`/`localparam`等） |
| 仿真死循环 | FSM 状态卡住 | 检查`next_state`是否有default分支 |
| ALU 结果全0 | alu_op/alu_type 编码不匹配 | 对照`public.vh`逐值检查 |
| regfile 读出全0 | 内部前推逻辑冲突 | 暂时禁用前推，先用基础读写测试 |
| inst_ram 读出全X | hex 文件路径或格式问题 | 检查 testbench 中 `$readmemh` 路径 |
| basic_test 跑到 illegal_instr | 指令编码有误 | 逐条检查 hex 编码与 RV32I spec 对照 |

---

## 四、测试记录模板

每个测试完成后记录：

```
测试名称：
日期：
执行人：
文件：
结果（PASS/FAIL）：
xsim 控制台输出摘要：
发现问题：
修复措施：
波形截图路径：
```

---

## 五、测试完成后输出

1. ✅ 4个 testbench 文件（`tb_alu.v`、`tb_regfile.v`、`tb_control_unit.v`、`tb_cpu_basic.v`）
2. ✅ 4个 xsim 仿真通过的截图
3. ✅ 修复的 bug 列表（如有）
4. ✅ 更新 AI 日志
5. ✅ commit 到 Git
