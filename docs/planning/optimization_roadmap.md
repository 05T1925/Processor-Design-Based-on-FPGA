# 拓展方向可行性分析与优化路线图

> 文档类型：组长A前瞻规划
> 作者：A 刘文涛
> 日期：2026-07-08
> 基于：Minisys FPGA (Artix-7 XC7A100T) + EES-329B-V1.1 子板，课程"拓展层次—高性能处理器优化设计"要求

---

## 〇、硬件资源约束

### XC7A100T-FGG484 关键资源

| 资源 | 总量 | 备注 |
|---|---|---|
| Logic Cells | 101,440 | 约同级别最大 |
| LUTs | 63,400 | 6输入LUT |
| FFs | 126,800 | 每个LUT可配2个FF |
| Block RAM | 4,860 Kb (135个36Kb块) | 可按18Kb/9Kb拆分 |
| DSP48E1 Slices | 240 | 25×18乘法器+48位累加器 |
| I/O Pins | 285 | FGG484封装可用 |
| MMCM/PLL | 6 | 时钟管理 |
| 板载时钟 | 100 MHz (Y18) | 主时钟源 |

### 资源预算原则

- 基础CPU（多周期FSM + BRAM + 外设）：预计 < 5% 资源
- 所有优化方向总和不超过硬件容量的 80%，保留裕量
- DSP48E1 是稀缺资源（240个），需合理规划

---

## 一、六个拓展方向的可行性分析

### 方向1：流水线冒险的完整解决方案（数据前推、分支预测）

**可行性**：⭐⭐⭐⭐⭐（最高）

**硬件资源估算**：
| 资源 | 基础CPU | +5级流水线 | +forwarding | +BTB预测 | 合计 |
|---|---|---|---|---|---|
| LUTs | ~800 | ~800 | ~300 | ~500 | ~2,400 |
| FFs | ~400 | ~1,200 | ~100 | ~300 | ~2,000 |
| BRAM | 2块 | — | — | 1块(BTB表) | 3块 |
| DSP | 0 | 0 | 0 | 0 | 0 |

**预期性能收益**：
- IPC 从 ~0.2（多周期FSM）提升到 ~0.7-0.9（五级流水线+forwarding）
- 分支预测命中率 > 85% 可减少 15-20% 的流水线冲刷

**与本项目现有基础的契合度**：⭐⭐⭐⭐⭐
- NCUT_MiniSys：完整的五级流水线寄存器模板（`if_id.v`/`id_ex.v`/`ex_mem.v`/`mem_wb.v`）
- NCUT_MiniSys `id.v`：ID 阶段数据前推逻辑（EX/MEM/WB三级前推）
- SEU minisys `BTB.v`：分支目标缓冲参考实现
- SEU minisys `ppl_scheduler.v`：流水线调度器

**实现路径**：
```
P0(已完成) → P1(本周)      → P2(冲刺)
多周期FSM   → 五级流水线     → +BTB分支预测
             → +forwarding   → +branch_miss统计
             → +stall/flush
```

**风险**：
- 中：load-use hazard 检测和 stall 插入需要仔细验证
- 低：forwarding 路径多，但 NCUT 已有完整参考实现

---

### 方向2：Cache 替换策略优化与命中率分析

**可行性**：⭐⭐⭐（中等）

**硬件资源估算**：
| 资源 | 直接映射(4KB) | 2路组相联(4KB) | 4路组相联(8KB) |
|---|---|---|---|
| LUTs | ~1,500 | ~3,000 | ~5,000 |
| FFs | ~800 | ~1,500 | ~2,500 |
| BRAM | 4块 | 8块 | 16块 |

**预期性能收益**：
- BRAM 单周期访问（无Cache时）：0 等待周期
- 有 Cache 时：命中 1 周期，缺失 2+ 周期
- **注意**：由于 BRAM 本身已是单周期，Cache 带来的加速主要体现在隐藏 UART/慢速外设的访问延迟

**与本项目现有基础的契合度**：⭐⭐
- 四个参考仓库均未实现 Cache
- BRAM 已单周期访问，增加 Cache 反而可能降低性能（额外命中检查开销）
- Minisys 板无外部 DRAM（仅 BRAM），Cache 的应用场景受限

**实现路径**：
```
P1(可选)  → P2(考虑)
直接映射   → 2路/4路组相联
Cache      → 替换策略对比(LRU/PLRU/FIFO/Random)
           → 命中率分析（不同benchmark）
```

**风险**：
- 中高：~16KB BRAM 用于 Cache tag + data，可能挤压指令/数据空间
- 中：无外部DRAM，Cache真实加速效果有限
- **建议**：P0/P1 不做，如果答辩需要可做软件模拟的命中率分析

---

### 方向3：支持浮点运算或乘除法扩展指令

**可行性**：⭐⭐（较低）

**硬件资源估算**：
| 资源 | 硬件乘法器(MUL) | 硬件除法器(DIV) | FP32加法器 | FP32乘法器 |
|---|---|---|---|---|
| LUTs | ~300 | ~800 | ~1,500 | ~2,000 |
| FFs | ~100 | ~400 | ~500 | ~600 |
| DSP | 1-4 | 0 | 2-4 | 3-5 |

**预期性能收益**：
- MUL：1周期（组合逻辑）或 4-8 周期（多周期）
- DIV：8-32 周期
- FP32 ADD/MUL：流水线化后 1 IPC

**与本项目现有基础的契合度**：⭐⭐
- SEU minisys `mul.v`：硬件乘法器参考
- SEU minisys `div` 相关：HI/LO 乘除框架可改造
- 但架构从多周期→流水线改造工作量巨大
- FP32 在 MIPS 参考仓库中均未实现

**实现路径**：
```
P0(已完成)    → P1(可选)       → P2(不考虑)
MAC(组合乘加) → MUL/DIV指令    → FP32
              (复用M扩展子集)
```

**风险**：
- 高：FP32 合规实现工作量远超一周项目范围
- 中：硬件除法器面积大，时序可能成为瓶颈
- **建议**：P1 做 MUL/DIV（RV32I M扩展子集），这也是 SEU minisys 已有的方向，FP32 留给后续课程

---

### 方向4：基于 RISC-V 的自定义 ISA 扩展设计

**可行性**：⭐⭐⭐（中等）

**硬件资源估算**：
| 资源 | CSR寄存器 | 额外指令 | 向量扩展(2×128bit) |
|---|---|---|---|
| LUTs | ~200 | ~300/条 | ~3,000 |
| FFs | ~300 | ~100/条 | ~2,000 |
| BRAM | — | — | 2-4块 |

**与本项目现有基础的契合度**：⭐⭐⭐
- **本项目已实现 MAC 自定义指令**（方向4的实际体现）
- public.vh 中定义了完整的 RV32I+MIPS 双 ISA 宏体系
- CPU_MODE 参数化设计支持自定义 ISA 扩展的独立验证

**已实现的自定义 ISA 扩展示例（MAC）**：
```verilog
// RISC-V custom-0 opcode
opcode = 7'b0001011    // custom-0
funct7 = 7'b0000001    // MAC identifier
funct3 = 3'b000
语义: rd_new = rd_old + rs1 * rs2
```

**可扩展方向**：
```
已实现        → P1(本周)        → P2(冲刺)
MAC单指令      → MUL/MULH/DIV   → 向量点积指令(VEC_DOT)
               → 位操作扩展(B)   → 矩阵乘法加速(MAT_MUL)
               → CSR性能寄存器   → 自定义协处理器
```

**风险**：
- 低：已有 MAC 实现基础，扩展新指令遵循相同模式
- 低：RISC-V custom opcode 空间充足（4组custom：0001011/0101011/1011011/1111011）

---

### 方向5：面向 AI/矩阵计算的自定义加速指令设计（MAC乘加单元）

**可行性**：⭐⭐⭐⭐⭐（最高，已部分实现）

**已完成**：
- ✅ MAC 自定义指令编码（custom-0 opcode=0001011, funct7=0000001）
- ✅ 组合逻辑乘加单元（`mac_unit.v`：`rd_new = rd_old + rs1 * rs2`）
- ✅ 控制信号：`is_mac`/`mac_pulse`/`wb_sel=MAC`
- ✅ 性能计数器：`mac_count`

**待优化（P1）**：
| 优化项 | 当前状态 | P1目标 | 预期收益 |
|---|---|---|---|
| DSP48E1 精调 | 综合器自动推断 | 手工例化DSP48E1 | 时序优化 + Fmax提升 |
| MAC 流水线化 | 组合逻辑(1周期) | 2-3级流水线 | Fmax > 120MHz |
| 点积测试程序 | 仅有basic_test.hex | 完整点积对比 | 量化 speedup |
| 向量化 MAC | 单对单乘加 | VEC_MAC(4×1向量) | 4倍吞吐量 |
| PPA 对比 | — | 普通点积 vs MAC点积 | 答辩核心表格 |

**硬件资源估算**：
| 资源 | 当前(组合MAC) | P1(流水MAC) | P2(向量VEC_MAC_4) |
|---|---|---|---|
| LUTs | ~200 | ~400 | ~1,200 |
| FFs | 0 | ~300 | ~800 |
| DSP | 0-4(自动推断) | 4(例化) | 4-8 |
| BRAM | 0 | 0 | 2块(向量缓冲) |

**与本项目现有基础的契合度**：⭐⭐⭐⭐⭐
- MAC 编码已在 `public.vh` 和 `control_unit.v` 中完整实现
- `mac_unit.v` 已有组合逻辑版本，加流水线级即可
- Artix-7 有 240 个 DSP48E1，资源充足
- 这是本项目区别于所有四个参考仓库的**核心创新点**

**实现路径**：
```
P0(已完成)       → P1(本周必须)    → P2(冲刺)
MAC 组合逻辑      → DSP48E1精调     → VEC_MAC(向量化)
MAC 编码+译码     → 点积对比测试    → 矩阵乘法demo
MAC 计数器        → PPA对比表       → AI推理加速原型
```

---

### 方向6：多方案对比分析，PPA 三角约束下的设计权衡

**可行性**：⭐⭐⭐⭐（高，贯穿所有方向）

**本项目的天然优势——CPU_MODE 参数化设计**：
```verilog
CPU_MODE=0: RV32I 多周期FSM   (基线)
CPU_MODE=1: RV32I 单周期      (对比方案1)
CPU_MODE=2: MIPS 单周期       (对比方案2, 参考SUSTech CS202)
CPU_MODE=3: MIPS 5级流水线    (对比方案3, 参考NCUT)
CPU_MODE=4: MIPS 5级+CP0     (对比方案4, 参考SEU minisys)
```
同一 Vivado 工程切换参数即可对比，这是本项目独有的**PPA 实验平台**。

**PPA 对比方案设计**：

| 对比维度 | 方案A(基线) | 方案B | 方案C | 预期发现 |
|---|---|---|---|---|
| 微架构 | 多周期FSM | 单周期 | 5级流水线 | 流水线IPC最高 |
| ISA | RV32I | RV32I+MAC | MIPS | MAC减少指令数 |
| MAC实现 | 软件点积 | 组合MAC | 流水MAC | 流水MAC Fmax更高 |
| 时钟策略 | 100MHz | 50MHz | 分频对比 | 与timing slack相关 |

**需收集的数据字段**：

| 字段 | 来源 | 负责人 |
|---|---|---|
| cycle_count / instret_count / mac_count | CSR 性能计数器 | D |
| LUT / FF / BRAM / DSP / IO | Vivado utilization report | C |
| WNS / TNS / Fmax | Vivado timing summary | C |
| CPI / IPC / speedup | 计算值（cycle/instret） | D |
| 功耗估算 | Vivado power report（可选） | C |
| 代码密度 | 汇编指令数统计 | D |

**PPA 三角分析模板**（答辩核心展示）：

```
                 Performance
                    /\
                   /  \
                  /    \
                 / PPA  \
                /  Zone  \
               /__________\
           Area             Power
         (LUT/FF/         (Vivado
         BRAM/DSP)       Power Report)

方案A(多周期FSM)  → 低面积, 低功耗, 低性能
方案B(单周期)     → 低面积, 中功耗, 中性能
方案C(5级流水线)  → 中面积, 中功耗, 高性能
方案C+MAC(流水)   → 中面积, 中功耗, 最高性能
```

---

## 二、推荐优先级与路线图

### 优先级排序（基于可行性×收益×时间约束）

| 优先级 | 方向 | 可行性 | 预期收益 | 时间投入 | 已有基础 | 总分 |
|---|---|---|---|---|---|---|
| **P0(已)** | ⑤ MAC加速 | ⭐⭐⭐⭐⭐ | 高 | 已完成 | 100% | — |
| **P1-1** | ① 流水线+forwarding | ⭐⭐⭐⭐⭐ | 最高 | 2天 | 60% | 9.5 |
| **P1-2** | ⑥ PPA多方案对比 | ⭐⭐⭐⭐ | 高 | 1天 | 70% | 8.5 |
| **P1-3** | ④ 自定义ISA扩展(MUL/DIV) | ⭐⭐⭐ | 中 | 1.5天 | 40% | 6.5 |
| **P2-1** | ① BTB分支预测 | ⭐⭐⭐⭐ | 中高 | 1天 | 20% | 6.0 |
| **P2-2** | ⑤ VEC_MAC向量化 | ⭐⭐⭐ | 高 | 2天 | 30% | 5.5 |
| **P2-3** | ② Cache分析(软件模拟) | ⭐⭐ | 低 | 1天 | 0% | 3.0 |
| **❌ 不推荐** | ③ FP32浮点 | ⭐ | 低 | 3天+ | 0% | 1.0 |

### 一周优化路线图

```
Day 1-2 (P1-1): 五级流水线 + forwarding + stall/flush
  ├── D: 实现流水线寄存器 (参考NCUT if_id/id_ex/ex_mem/mem_wb)
  ├── D+B: 实现 forwarding_unit (参考NCUT id.v前推逻辑)
  ├── D+B: 实现 hazard_detection (参考SEU minisys ppl_scheduler)
  ├── B: xsim验证流水线CPU跑通basic program
  └── D: 记录IPC提升数据

Day 3-4 (P1-2 + P1-3): PPA对比 + MUL/DIV扩展
  ├── C: Vivado 综合多周期FSM版本 → utilization/timing
  ├── C: Vivado 综合流水线版本 → utilization/timing
  ├── D: 对比数据填充PPA表格
  ├── D: 实现 MUL/DIV 指令（参考SEU minisys mul.v）
  ├── B: 验证 MUL/DIV 指令
  └── A: 复检PPA数据，统一报告口径

Day 5-6 (P1继续 + P2): 冲刺项
  ├── D: BTB分支预测 (参考SEU minisys BTB.v)
  ├── C: (如有时间) DSP48E1 例化精调
  ├── D: 点积程序优化对比
  ├── B+C+D: 各自的报告小节
  └── A: PPA表格终审 + 答辩材料

Day 7: 最终报告整合
  ├── A: 整合报告 + 答辩PPT
  ├── B: CPU + 流水线章节
  ├── C: SoC + 上板验证 + Vivado数据章节
  ├── D: MAC + 性能 + PPA章节
  └── 全员: 最终检查 + AI日志补全 + Git提交
```

---

## 三、与本项目现有基础的衔接

### 已就位的优化基础设施

| 基础组件 | 为哪些优化方向服务 |
|---|---|
| `src/core/pipeline/` 目录 | ① 流水线寄存器、forwarding、hazard、BTB |
| `public.vh` 中的 `CPU_MODE` | ⑥ 多方案PPA对比（一键切换） |
| `csr_perf_counter.v` | ⑥ 性能数据采集 |
| `mac_unit.v`（组合逻辑版） | ⑤ DSP精调、流水线化、向量化 |
| `control_unit.v` MAC 译码 | ⑤ 新指令扩展模式 |
| RV32I custom-0 opcode 预留 | ④ 更多自定义指令 |
| 统一总线架构 | 全部方向（外设访问不受CPU改动影响） |

### PPA 数据管道已就位

```text
csr_perf_counter → MMIO(0xFFFF_FCB0) → CPU读 → 软件统计
Vivado utilization → reports/vivado/ → D分析 → PPA表
Vivado timing      → reports/vivado/ → D分析 → WNS/TNS/Fmax
```

---

## 四、最具答辩价值的推荐组合

**推荐答辩主线**："从多周期到流水线——基于RISC-V自定义MAC指令的处理器PPA优化之旅"

```text
Chapter 1: 基线系统 — RV32I 多周期 FSM CPU + 统一总线 SoC
Chapter 2: 创新点 — MAC 自定义指令（组合→流水线→DSP48E1精调）
Chapter 3: 架构演进 — 五级流水线 + forwarding + stall/flush
Chapter 4: 量化分析 — 三种方案(多周期/单周期/流水线)的PPA三角对比
Chapter 5: 展望 — BTB分支预测 + 向量化MAC + Cache分析
```

这种结构最大化了：
1. **现有工作**（Chapter 1-2：多周期FSM基线 + MAC = 已全部完成）
2. **本周冲刺**（Chapter 3-4：流水线PPA对比 = 最高ROI）
3. **学术深度**（Chapter 5：展望 = 方向2+4可选）
