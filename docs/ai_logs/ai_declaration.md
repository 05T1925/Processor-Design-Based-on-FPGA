# AI 辅助工具使用声明表

> 依据：课程"AI辅助工具使用声明表"要求
> 填写人：A 刘文涛（组长），代表全组填写
> 日期：2026-07-08

---

## 一、AI 工具使用总览

| 工具 | 使用阶段 | 使用范围 | 是否涉及核心代码 |
|---|---|---|---|
| Claude Code (Codex) | 项目规划、代码生成、文档撰写、分析验证 | 架构设计、RTL生成、文档同步、可行性分析 | 是 |

---

## 二、需求与指令集/接口定义（独立完成）

| 工作内容 | 负责人 | AI参与程度 | 独立完成说明 |
|---|---|---|---|
| RV32I 子集指令选择（31条+MAC） | A 刘文涛 | AI辅助分析 | 组长A基于课程任务书和RV32I规范手册，人工确定指令子集范围。AI仅辅助生成编码对照表，所有编码已与RISC-V官方规范逐条人工核对 |
| MAC自定义指令语义定义（rd_new=rd_old+rs1*rs2） | A+D | AI辅助优化 | 组长A独立提出三读口方案，AI辅助分析寄存器堆修改点 |
| memory map 地址空间划分 | A | AI辅助分析 | 组长A对比SEU minisys和SUSTech CS202两个MMIO方案后独立决策采用统一总线地址（0xFFFF_FCxx），AI仅辅助生成地址映射表 |
| 模块接口规范（interfaces.md） | A | AI辅助整理 | 组长A设计接口，AI辅助生成端口表，所有端口定义经组长A人工确认 |
| 统一总线架构设计 | A | AI辅助分析 | 组长A分析SEU minisys的共享总线仲裁器设计后独立决定采用ibus+dbus双总线+addr[9:4]二级译码方案 |

---

## 三、对参考代码的工程审阅与改造说明

### 3.1 参考代码来源

| 仓库 | 原始ISA | 原始架构 | 许可证 |
|---|---|---|---|
| NCUT_MiniSys (kayak4665664) | MIPS 31条 | 5级流水线 | GPL-3.0 |
| SUSTech CS202 (OctCarp) | MIPS子集 | 单周期 | MIT |
| SEU minisys (seu-cs-class2) | MIPS 57条 | 5级流水线+CP0 | 未声明 |
| SEU minisys () | MIPS 57条+ | 5级流水线+BTB | 未声明 |
| riscv-minisys-cpu (BUPT) | RV32I 31条 | 单周期 | 未声明 |
| minisys_unified (组长A初版) | MIPS+RV32I | 4合1统一 | GPL-3.0 |

### 3.2 关键改造说明（逐模块）

| 本项目的模块 | 参考来源 | 原始内容 | 改造内容 | 改造原因 | 独立设计占比 |
|---|---|---|---|---|---|
| `public.vh` | SEU minisys `public.v` + `define.v` | MIPS opcode定义 + ALU六分类 | 完全重写：增加RV32I opcode/funct3/funct7 + MAC编码 + 总线宽度 + 外设地址 + CPU_MODE | 参考仓库只有MIPS定义，需要为RV32I重新设计全部宏 | 85% |
| `control_unit.v` | riscv-minisys-cpu `control_unit.v` | RV32I单周期译码，无MAC/FSM/instret | 重写：采用相同opcode驱动框架，增加MAC custom-0译码、EBREAK检测、illegal_instr标记、instret_pulse/mac_pulse、多周期FSM适配 | 原始为单周期纯组合译码，需改造为多周期FSM兼容的译码方式 | 70% |
| `riscv_mc_cpu.v` | riscv-minisys-cpu `riscv_cpu.v` | RV32I单周期CPU | 完全重写：从单周期组合逻辑改为6状态FSM（FETCH/DECODE/EXECUTE/MEMORY/WRITEBACK/HALT），增加perf_counter集成、MAC数据通路 | 原始为单周期（1指令=1周期），本设计要求多周期FSM | 90% |
| `alu.v` | SEU minisys `Ex_1.v` + riscv-minisys-cpu `alu.v` | MIPS ALU 3分类 / RV32I ALU 4-bit op | 重写：采用SEU的6分类体系（NOP/ARITH/LOGIC/MOVE/SHIFT/JUMP），增加MAC类型，操作码全部改为RV32I | MIPS ALU操作码编码方案与RV32I不兼容 | 75% |
| `regfile.v` | NCUT `regfile.v` | 2读1写，无MAC第三读口 | 改造：增加MAC第三读口（rd_old），保留NCUT的内部写后读前推逻辑，x0硬连线 | MAC需要同时读取rd原值作为累加器输入 | 50% |
| `bus_decoder.v` | SEU minisys `arbitration.v` | MIPS外设地址（0xFFFF_FCxx），10个外设 | 轻改造：扩充到14个外设槽位，增加perf_counters和result_reg | 外设种类不同 | 30% |
| `bus_mux.v` | SEU minisys `arbitration.v` | 10路MUX | 轻改造：扩充到14路MUX | 外设数量增加 | 20% |
| `soc_top.v` | minisys_unified `top_minisys.v` | 4 CPU_MODE + 12外设 | 改造：简化为本项目的CPU_MODE=0主线，移除VGA/键盘/PS2等未使用外设的完整实例化 | 本项目仅需P0外设 | 40% |
| `mac_unit.v` | — | 无参考 | **完全独立设计**：组合逻辑乘加，低32位取积，DSP48E1推断 | 参考仓库均无MAC指令 | 100% |
| `csr_perf_counter.v` | — | 无参考 | **完全独立设计**：3×32bit计数器，halted停止cycle，pulse驱动instret/mac | 参考仓库均无性能计数器 | 100% |
| `imm_gen.v` | riscv-minisys-cpu `imm_gen.v` | RV32I 5种格式 | 轻改造：优化case风格 | RV32I立即数格式为标准规范 | 20% |
| `branch_unit.v` | riscv-minisys-cpu `branch_unit.v` | RV32I 5种条件 | 轻改造：增加到6种条件（BEQ/BNE/BLT/BGE/BLTU/BGEU） | RV32I标准分支条件 | 15% |
| `gpio_led.v` | minisys_unified `gpio_led.v` | 16位LED, bus slave接口 | 直接采用 | bus slave接口标准化 | 5% |
| `gpio_switch.v` | minisys_unified `gpio_switch.v` | 16位Switch, 2级同步 | 直接采用 | bus slave接口标准化 | 5% |
| `seg7_driver.v` | minisys_unified `seg7.v` | 8位数码管动态扫描 | 直接采用 | 共阳极低有效驱动方式与Minisys板一致 | 5% |
| 存储器/通用模块 | minisys_unified | 行为级BRAM/同步器/消抖 | 直接采用 | 通用模块无需ISA相关改造 | 5% |

---

## 四、硬件平台落地调试（综合、时序收敛、资源适配）

| 工作内容 | 负责人 | 状态 | 说明 |
|---|---|---|---|
| Vivado 工程建立 | C 胡文龙 | 待进行 | 在 Vivado 2018.3 中新建工程，target xc7a100tfgg484-1 |
| 约束文件加载 | C | 已准备 | `constraints/minisys.xdc` 已与三个参考仓库的.xdc交叉验证100%一致 |
| 综合 (Synthesis) | C | 待进行 | 预期：多周期FSM无时序违例，LUT < 2000, FF < 1000 |
| 实现 (Implementation) | C | 待进行 | 关注：100MHz时钟是否满足，WNS/TNS |
| 时序收敛 | C+A | 待进行 | 若有时序违例：优先降低ALU关键路径（流水线化MAC） |
| 资源适配 | C | 待进行 | 预期利用率 < 5%，XC7A100T资源充裕 |
| Bitstream 生成 | C | 待进行 | 生成后烧录到Minisys板 |
| 上板功能验证 | C | 待进行 | LED心跳 + 数码管扫描为最小验证 |
| P20 复位极性实测 | C | 待进行 | `minisys_top.v` 中 `rst = ~rst_n` 需上板确认P20实际电平 |

---

## 五、系统集成与联调验收

| 工作内容 | 负责人 | 协作人 | 状态 | 说明 |
|---|---|---|---|---|
| cpu_top 单独仿真 | B | A | 待进行 | xsim加载basic_test.hex验证多周期FSM |
| soc_top 集成仿真 | B+C | A | 待进行 | CPU+memory+bus+外设联调 |
| MAC 点积验证 | D | B | 待进行 | 普通点积与MAC点积结果一致性 |
| 性能计数器验证 | D | B | 待进行 | cycle/instret/mac计数正确性 |
| 上板联调 | C | A+B+D | 待进行 | 完整系统演示 |
| PPA数据采集 | C+D | A | 待进行 | utilization/timing/CPI/speedup |
| 最终报告整合 | A | B+C+D | 待进行 | 各组员提交小节，A统一格式 |

---

## 六、独立讲解能力确认

每位成员必须能独立讲解自己负责模块的设计原理：

| 成员 | 必须能独立讲解的内容 | 参考材料 |
|---|---|---|
| A 刘文涛 | 统一总线架构选型理由、六仓库分析决策过程、MIPS→RV32I改造路径、CPU_MODE参数化设计、PPA对比方法论 | `integration_report.md`、`four_repo_deep_merge_plan.md` |
| B 张淇 | RV32I 31条指令编码原理、多周期FSM 6状态转移逻辑、控制信号生成、xsim仿真流程、波形分析方法 | `isa.md`、`architecture.md`、`control_unit.v` |
| C 胡文龙 | 统一总线地址译码（ibus/dbus/仲裁器/二级译码）、行为级BRAM vs Vivado IP选择、外设bus slave接口、Vivado综合实现流程、上板调试方法 | `memory_map.md`、`board_demo.md`、`minisys_pinout.md` |
| D 王博生 | MAC指令语义与编码、regfile三读口设计理由、性能计数器设计、点积对比方法、PPA三角分析（Performance/Area/Power）| `mac_extension.md`、`performance.md`、`optimization_roadmap.md` |

---

## 七、学术诚信承诺

本项目组确认：

1. ✅ 所有参考代码的使用均经过工程审阅和适配改造（见第三章逐模块改造说明）
2. ✅ 以下模块为**完全独立设计**：`mac_unit.v`、`csr_perf_counter.v`（参考仓库中无对应实现）
3. ✅ 以下模块为**重度改造**：`public.vh`(85%)、`riscv_mc_cpu.v`(90%)、`alu.v`(75%)、`control_unit.v`(70%)
4. ✅ 以下模块为**标准适配**：`regfile.v`(50%)、`soc_top.v`(40%)、`bus_decoder.v`(30%)
5. ✅ 以下模块为**直接采用通用设计模式**：外设控制器(5%)、存储器(5%)、通用模块(5%)
6. ✅ 每位成员能独立讲解自己负责模块的设计原理
7. ✅ 所有AI使用已如实记录到 `docs/ai_logs/ai_usage_log.md`
8. ✅ GitHub 提交历史完整可追溯
