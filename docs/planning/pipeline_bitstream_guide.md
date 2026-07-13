# 流水线 CPU 上板操作步骤

> 目标：生成 CPU_MODE=5（RV32I 五级流水线 + BTB）的 bitstream
> 归档状态（2026-07-13）：流水线测试、上板和 PPA 已由负责队友完成。本文件保留为可复现操作指南；不要再据此判断流水线“未完成”。
> 预计耗时：15-25 分钟（取决于电脑性能）

---

## 第一步：修改源码参数

### 1.1 用 VS Code 打开文件

在 VS Code 中打开：
```
c:\Users\28641\Desktop\Project-based Curriculum Stage\src\board\minisys_top.v
```

### 1.2 修改第 9 行

找到第 9 行：
```verilog
    parameter CPU_MODE = `CPU_MODE_RISCV_MC
```

改为：
```verilog
    parameter CPU_MODE = `CPU_MODE_RISCV_PIPE
```

### 1.3 保存文件

`Ctrl+S` 保存。

> **说明**：`CPU_MODE_RISCV_MC = 0`（多周期FSM），`CPU_MODE_RISCV_PIPE = 5`（五级流水线+forwarding+stall/flush+BTB）。只改这一个数字，所有 RTL 自动通过 `public.vh` 中的 `generate` 块切换到流水线实现。

---

## 第二步：打开 Vivado 工程

### 2.1 启动 Vivado

- 双击桌面 Vivado 2018.3 图标
- 或：开始菜单 → Xilinx Design Tools → Vivado 2018.3

### 2.2 打开工程

- Vivado 启动后，在欢迎界面点击 **Open Project**
- 导航到：
  ```
  C:\Users\28641\Desktop\Project-based Curriculum Stage\processor_fpga
  ```
- 选择 `processor_fpga.xpr` → 点击 **OK**

> 如果 Vivado 提示 "Project was created with a newer version" 或类似警告，点击 OK 忽略。

---

## 第三步：运行综合（Synthesis）

### 3.1 启动综合

在左侧 **Flow Navigator** 面板中：
- 点击 **Run Synthesis**（在 "Synthesis" 分组下）

弹出对话框：
- **Number of jobs**：选择你的 CPU 核心数（通常选 4 或 Auto）
- 点击 **OK**

### 3.2 等待综合完成

- 右上角会显示进度条和 "Running synth_design" 状态
- 预计耗时：3-8 分钟
- 期间电脑可以继续使用其他程序，但不要关机

### 3.3 综合完成后的操作

综合完成后会弹出对话框，有三个选项：
1. ☐ Run Implementation
2. ☐ Open Synthesized Design
3. ☐ View Reports

**操作**：
- ✅ 勾选 **Run Implementation**（直接进入下一步）
- ❌ 不勾选另外两个
- 点击 **OK**

### 3.4 检查综合警告（如果综合失败）

如果综合报错（红色 Error），截图发群里。

常见警告（黄色 Warning）可以忽略：
- "BlackBox" 相关警告
- "unconnected ports" 警告
- "TIMING" 相关 INFO

---

## 第四步：运行实现（Implementation）

### 4.1 启动实现

如果上一步已经勾选 "Run Implementation"，会自动开始。

如果没有自动开始：
- 在左侧 **Flow Navigator** → 点击 **Run Implementation**

弹出对话框：
- **Number of jobs**：选择你的 CPU 核心数
- 点击 **OK**

### 4.2 等待实现完成

- 右上角显示进度（opt_design → place_design → route_design）
- 预计耗时：5-12 分钟
- 这是最耗时的步骤

### 4.3 实现完成后的操作

实现完成后弹出对话框，有三个选项：
1. ☐ Generate Bitstream
2. ☐ Open Implemented Design
3. ☐ View Reports

**操作**：
- ✅ 勾选 **Generate Bitstream**（直接进入最后一步）
- 点击 **OK**

---

## 第五步：生成 Bitstream

### 5.1 启动生成

如果上一步已勾选，会自动开始。否则在 Flow Navigator → **Generate Bitstream**。

### 5.2 等待完成

- 预计耗时：1-3 分钟

### 5.3 Bitstream 生成完成

弹出对话框：
- 选择 **Open Hardware Manager**（如果想直接烧录到板子测试）
- 或选择 **Cancel**（仅保存文件，稍后烧录）

---

## 第六步：备份 Bitstream 文件

### 6.1 找到生成的 bitstream

Bitstream 生成在：
```
C:\Users\28641\Desktop\Project-based Curriculum Stage\processor_fpga\processor_fpga.runs\impl_1\minisys_top.bit
```

### 6.2 复制并重命名

在文件资源管理器中：
1. 打开 `processor_fpga\processor_fpga.runs\impl_1\`
2. 找到 `minisys_top.bit`
3. 复制 → 粘贴到 `processor_fpga\` 目录
4. 重命名为 `minisys_top_pipeline.bit`

> ⚠️ **重要**：一定要先复制出来再重命名！下次综合会覆盖 `impl_1\minisys_top.bit`。

### 6.3 导出 Utilization 报告

在 Vivado 底部 **Tcl Console** 中依次输入以下命令：

```tcl
# 导出资源利用率报告
report_utilization -file C:/Users/28641/Desktop/Project-based\ Curriculum\ Stage/reports/vivado/utilization_pipeline.txt

# 导出时序报告
report_timing_summary -file C:/Users/28641/Desktop/Project-based\ Curriculum\ Stage/reports/vivado/timing_pipeline.txt
```

---

## 第七步：恢复多周期版本并重新生成

### 7.1 改回多周期参数

在 VS Code 中重新打开 `minisys_top.v`，将第 9 行改回：
```verilog
    parameter CPU_MODE = `CPU_MODE_RISCV_MC
```

保存文件。

### 7.2 在 Vivado 中重新综合

回到 Vivado 窗口：
1. Flow Navigator → **Run Synthesis** → OK
2. 综合完成后 → **Run Implementation** → OK
3. 实现完成后 → **Generate Bitstream** → OK

### 7.3 备份多周期 bitstream

同样操作：复制 `impl_1\minisys_top.bit` → 粘贴到 `processor_fpga\` → 重命名为 `minisys_top_multicycle.bit`

### 7.4 导出多周期报告

在 Tcl Console 中：
```tcl
report_utilization -file C:/Users/28641/Desktop/Project-based\ Curriculum\ Stage/reports/vivado/utilization_multicycle.txt
report_timing_summary -file C:/Users/28641/Desktop/Project-based\ Curriculum\ Stage/reports/vivado/timing_multicycle.txt
```

---

## 第八步：上板验证（可选）

### 8.1 烧录流水线 bitstream

1. 用 USB 线连接 Minisys 板和电脑
2. Vivado → Flow Navigator → **Open Hardware Manager** → **Open Target** → **Auto Connect**
3. 在 Hardware 窗口中右键 FPGA 器件 → **Program Device**
4. 在弹出窗口中选择 `minisys_top_pipeline.bit`
5. 点击 **Program**

### 8.2 验证流水线模式

上板后观察：
- PAGE 1 第 9 行应显示 **`MODE PIPE`**（而非 `MODE MULTI`）
- PAGE 1 的 STAGE 字段应显示 **bit flags**（而非 0~6 的 FSM 状态）
- PAGE 2 的 CPI×100 应显示约 **100~120**（多周期约 400）——性能提升明显可见

### 8.3 对比测试

1. 先烧录 `minisys_top_multicycle.bit` → 记录 PAGE 2 的 CPI×100 和 MIPS×10
2. 再烧录 `minisys_top_pipeline.bit` → 记录同样的值
3. 计算加速比：speedup = CPI_multi / CPI_pipe ≈ 400/108 ≈ 3.7×

---

## 最终文件清单

完成后 `processor_fpga\` 目录下应有：

```
processor_fpga\
├── processor_fpga.xpr                    # Vivado 工程
├── processor_fpga.runs\
│   └── impl_1\
│       └── minisys_top.bit               # 最后一次综合生成的 bitstream
├── minisys_top_multicycle.bit            # ★ 多周期 FSM 版本 (CPU_MODE=0)
├── minisys_top_pipeline.bit              # ★ 五级流水线版本 (CPU_MODE=5)
└── minisys_top_cpu_tetris.bit            # 与 multicycle 相同（可删除）
```

`reports/vivado/` 目录下应有：
```
reports\vivado\
├── utilization_multicycle.txt
├── timing_multicycle.txt
├── utilization_pipeline.txt
└── timing_pipeline.txt
```

---

## 常见问题

| 问题 | 解决方案 |
|---|---|
| Vivado 闪退 | 重启 Vivado，综合默认是增量式的会自动续上 |
| 综合报错 "unresolved module" | 检查 `src/core/` 下是否缺少文件，截图发群 |
| 实现报错 "DRC violation" | 通常是管脚约束问题，检查 `constraints/minisys.xdc` |
| 时序不通过（WNS < 0）| 流水线逻辑更复杂，可能需要降频。在 `minisys_top.v` 不改时钟，综合后查看时序报告中的 WNS 值 |
| Bitstream 下载失败 | 检查 USB 线连接、板子电源、驱动是否安装 |
