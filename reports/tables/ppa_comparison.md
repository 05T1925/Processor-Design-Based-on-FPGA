# PPA 对比表

日期：2026-07-12
负责人：D 王博生 + AI 辅助

---

## 一、正式 PPA 表（待 Vivado 综合填充）

| 版本 | CPU_MODE | LUT | FF | BRAM | DSP | IO | WNS | TNS | 目标频率 | 状态 |
|---|:---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| 完整 SoC 基线（多周期FSM） | 0 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 100 MHz | 🔄 待综合 |
| 完整 SoC + MAC 点积 | 0 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 待测 | 100 MHz | 🔄 待综合 |
| **完整 SoC 流水线（静态预测）** | **5** | **待测** | **待测** | **待测** | **待测** | **待测** | **待测** | **待测** | **100 MHz** | **🔄 待综合** |
| **完整 SoC 流水线 + BTB** | **5** | **待测** | **待测** | **待测** | **待测** | **待测** | **待测** | **待测** | **100 MHz** | **🔄 待综合** |

---

## 二、PPA 估计值（基于模块分解，供答辩参考）

| 版本 | LUT (est) | FF (est) | BRAM | DSP | WNS (est) | CPI (est) | 吞吐量 (est) |
|------|----------|----------|------|-----|-----------|-----------|-------------|
| 多周期 FSM (MODE=0) | ~800 | ~350 | 0 | 1 | +7.212ns ✅ | ~4.0 | ~25 MIPS |
| 5级流水线 静态 (MODE=5) | ~950 | ~1650 | 0 | 1 | +4~6ns | ~1.16 | ~86 MIPS |
| 5级流水线 + BTB (MODE=5) | ~1200 | ~1880 | 0 | 1 | +2~5ns | ~1.08 | ~92 MIPS |
| 理想流水线（理论上限） | — | — | — | — | — | 1.00 | 100 MIPS |

### 资源分解

| 组件 | LUT | FF | 说明 |
|------|-----|-----|------|
| 组合逻辑（复用多周期） | ~420 | 0 | control_unit + alu + branch + imm_gen + mac |
| regfile | ~80 | 1024 | 3R1W, 32×32 |
| 流水线寄存器 (4组) | 0 | ~802 | IF/ID(65) + ID/EX(210) + EX/MEM(155) + MEM/WB(72) |
| 转发 MUX | ~200 | 0 | 2× 3:1 MUX @32bit |
| 冒险检测 | ~35 | 0 | load-use + flush control |
| **BTB (16条目)** 🆕 | **~200** | **~130** | **标记+目标+计数器; 分布式RAM** |
| **BTB 统计计数器** 🆕 | **~50** | **~100** | **br_total/mispred/hit** |
| PC + 总线接口 | ~40 | 32 | 多优先级 MUX |
| 性能计数器 | ~30 | 96→192 | cycle + instret + mac + br ×3 |
| **总计 (流水线+BTB)** | **~1055** | **~1880** | |
| **总计 (流水线 静态)** | **~805** | **~1650** | 减去 BTB 组件 |

---

## 三、性能对比（实测数据待采集）

| 指标 | 多周期 FSM | 流水线 静态 | 流水线 + BTB | 理想 |
|------|----------|-----------|-------------|------|
| CPI (basic_test) | 待测 | 待测 | 待测 | 1.0 |
| CPI (dot_product) | 4.1333 ✅ | 待测 | 待测 | 1.0 |
| CPI (dot_product MAC) | 4.1538 ✅ | 待测 | 待测 | 1.0 |
| LW/SW 功能测试 | PASS ✅ | 待测 | 待测 | PASS |
| BEQ/BNE 功能测试 | PASS ✅ | 待测 | 待测 | PASS |
| CPI (branch_loop) | 待测 | 待测 | 待测 | 1.0 |
| VGA + 按键小游戏骨架 | PASS ✅ | N/A | N/A | 可演示 |
| 分支预测正确率 | N/A | ~50% | ~85-92% | 100% |
| Load-Use 停顿率 | N/A | ~2% | ~2% | 0% |
| 吞吐量 @100MHz | ~25 MIPS | ~86 MIPS | ~92 MIPS | 100 MIPS |
| 效率 (MIPS/KLUT) | ~31 | ~91 | ~77 | — |

---

## 四、为什么没有填写仓库中现有的 Vivado 数值

仓库中的原始报告：

- `processor_fpga/processor_fpga.runs/impl_1/minisys_top_utilization_placed.rpt`
- `processor_fpga/processor_fpga.runs/impl_1/minisys_top_timing_summary_routed.rpt`

记录的是：

| LUT | FF | BRAM | DSP | WNS | TNS |
|---:|---:|---:|---:|---:|---:|
| 2 | 24 | 0 | 0 | +7.212 ns | 0 ns |

对应 synthesis Tcl 只读取了 `src/core/public.vh` 和
`src/board/minisys_top.v`，cell usage 只有 heartbeat 计数器相关的
24 个触发器。该结果不是完整 CPU/SoC，更不是 CPU+MAC 的 PPA 数据，因此不得
填入正式对比表。

---

## 五、B/C 重新导出数据时的验收条件

1. Vivado compile order 包含 `src/core/`（含 `src/core/pipeline/`）、`src/bus/`、`src/memory/`、
   `src/io/`、`src/soc/` 和 `src/board/` 的完整主线 RTL。
2. 顶层为 `minisys_top`，且没有定义 `MINISYS_USE_HEARTBEAT`。
3. 层次利用率中能看到 `u_soc_top`、CPU、regfile、RAM、MAC、**BTB**。
4. MAC 版本应检查 DSP48 是否被推断；若 DSP=0，先确认 MAC 逻辑没有被优化掉。
5. BTB 版本应确认分布式 RAM 推断（LUTRAM），检查 BRAM 是否仍为 0。
6. 两个版本使用相同器件、XDC、100 MHz 时钟和实现策略。
7. 报告复制到 `reports/vivado/`，并在本表中记录具体来源路径。
8. VGA/按键小游戏骨架属于板级演示功能，不纳入 CPU_MODE PPA 对比；若综合包含该模块，需要在报告中单独说明额外 I/O 和显示逻辑开销。

---

## 六、流水线 PPA 采集清单

- [ ] **MODE=0** (多周期 FSM) post-implementation utilization + timing
- [ ] **MODE=5 + 静态预测** post-implementation utilization + timing
- [ ] **MODE=5 + BTB** post-implementation utilization + timing
- [ ] 所有模式 WNS/TNS/WHS/THS timing summary
- [ ] DSP48E1 推断确认（层次利用率截图）
- [ ] BTB 分布式 RAM 推断确认
- [ ] 报告归档到 `reports/vivado/`

当前 PPA 状态是"模板完成、估计值已补充、真实数据待完整 SoC 重新综合"，不能用 heartbeat 数据冒充完成。
