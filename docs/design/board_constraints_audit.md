# Minisys 约束文件审计记录

用途：记录老师资料目录中的约束文件扫描结果、候选判断、最终采用来源和未确认事项。

最后更新时间：2026-07-07

## 1. 扫描范围

本轮扫描范围：

```text
C:\Users\28641\Desktop\Project-based Curriculum Stage\安装包资料
```

扫描对象包括 `.xdc`、`.ucf`、`.v`、`.sv`、`.vhd`、`.xpr`、`.tcl`、`.pdf`、`.docx`、`README/readme`、压缩包和带有 `Minisys`、`constraint`、`pin`、`管脚`、`约束` 等关键词的文件。原始资料目录未移动、未删除、未重命名。

主要使用方法：

```text
rg --files -g '*.xdc' -g '*.ucf' -g '*.v' -g '*.sv' -g '*.vhd' -g '*.xpr' -g '*.tcl' -g '*.pdf' -g '*.docx'
Get-ChildItem -Recurse -File -Filter *.xdc
rg -n "PACKAGE_PIN|IOSTANDARD|CLK100MHZ|seg_an|seg_out|LED|SW"
```

## 2. 候选约束文件清单

| 序号 | 文件路径 | 文件名 | 类型 | 是否像 Minisys 官方约束 | 判断依据 | 备注 |
|---:|---|---|---|---|---|---|
| 1 | `安装包资料/minisys_MIPS_FPGA1/MIPS_FPGA/workspace/project_linux/project_linux.srcs/constrs_1/new/Minisys_Master.xdc` | `Minisys_Master.xdc` | XDC | 是，作为主来源 | 包含 Y18 100MHz、P20 reset、SW/LED/UART/Ethernet、`PACKAGE_PIN`、`IOSTANDARD`；路径属于 Minisys MIPS FPGA 工程 | 端口名带 MIPS 工程痕迹，如 `CLK100MHZ`、`CPU_RESET`、`custom_gpio` |
| 2 | `安装包资料/Minisys基础开发包/Minisys/MINISYS中文配套实验/sources/lab1/constr/flash_led_top.xdc` | `flash_led_top.xdc` | XDC | 是，作为 LED 辅助来源 | 中文 Minisys 实验包流水灯约束，明确 `clk/rst_n/sw0/led[15:0]`，与主来源 LED 引脚吻合 | 只覆盖流水灯所需资源，不是完整主约束 |
| 3 | `安装包资料/Minisys基础开发包/Minisys/MINISYS中文配套实验/sources/lab2/constrs_1/new/KEY_SEG.xdc` | `KEY_SEG.xdc` | XDC | 是，作为数码管辅助来源 | 中文 Minisys 实验包矩阵键盘/数码管约束，包含 `seg_an[7:0]`、`seg_out[7:0]` 引脚 | `seg_out` 中保留过一组注释掉的反向映射，采用未注释且被 lab3 重复使用的版本 |
| 4 | `安装包资料/Minisys基础开发包/Minisys/MINISYS中文配套实验/sources/lab3/constr/uart.xdc` | `uart.xdc` | XDC | 是，作为 UART/数码管交叉核对来源 | 同一中文实验包串口实验，重复确认 Y18/P20、UART 和 `an/seg_code` 引脚 | UART 不进入第一版主线 |
| 5 | `安装包资料/Minisys基础开发包/Minisys/MINISYS中文配套实验/sources/lab4/xdc/display_vga.xdc` | `display_vga.xdc` | XDC | 部分是 | 中文实验包 VGA 约束，包含 VGA 和时钟复位 | VGA 不是第一版主线，未纳入 `constraints/minisys.xdc` |
| 6 | `安装包资料/MIPSfpga-Getting-Started-v1.3_1Mar2016/.../Basys3/mipsfpga_basys3.xdc` | `mipsfpga_basys3.xdc` | XDC | 否 | 明确属于 Basys3，不是 Minisys | 不能用于 Minisys |
| 7 | `安装包资料/MIPSfpga-Getting-Started-v1.3_1Mar2016/.../Nexys4*/mipsfpga_nexys4*.xdc` | `mipsfpga_nexys4*.xdc` | XDC | 否 | 明确属于 Nexys4/Nexys4DDR，不是 Minisys | 不能用于 Minisys |
| 8 | `安装包资料/MIPSfpga_SOC_1_0_2016_03_11/.../Nexys4DDR_Master.xdc` | `Nexys4DDR_Master.xdc` | XDC | 否 | 明确属于 Nexys4DDR，不是 Minisys | 不能用于 Minisys |

## 3. 最终采用结果

最终项目主线约束文件：

```text
constraints/minisys.xdc
```

它不是凭空编写管脚号，而是从以下来源核对后整理：

- `Minisys_Master.xdc`：时钟、复位、前 16 个拨码/LED、UART、以太网等。
- `flash_led_top.xdc`：确认 `led[0:15]` 实验例程引脚。
- `KEY_SEG.xdc` 和 `uart.xdc`：确认 8 位七段数码管 `seg/an` 引脚。
- `Minisys硬件手册1.1_完整版.pdf`：确认 Y18 为 100MHz 主时钟；板上有 24 个拨码开关、24 个 LED、8 位七段数码管；数码管段选和位选低电平有效。

## 4. 项目端口清单

| 功能 | `constraints/minisys.xdc` 端口名 | `minisys_top` 端口 | `soc_top` 内部端口 | 位宽 | 有效电平 | 备注 |
|---|---|---|---|---:|---|---|
| 100MHz 时钟 | `clk` | `clk` | `clk` | 1 | 上升沿 | Y18 |
| 板级复位 | `rst_n` | `rst_n` | `rst` | 1 | 外部按键待实测；内部高有效 | P20，`minisys_top` 负责极性转换 |
| 拨码开关 | `sw[15:0]` | `sw[15:0]` | `sw_i[15:0]` | 16 | 高电平为 1 | 第一版只使用 SW0-SW15 |
| LED | `led[15:0]` | `led[15:0]` | `led_o[15:0]` | 16 | 高电平点亮 | 第一版状态主要使用低 8 位 |
| 七段段选 | `seg[7:0]` | `seg[7:0]` | `seg_data_o[7:0]` | 8 | 低电平点亮 | `seg[0]=CA` ... `seg[7]=DP` |
| 七段位选 | `an[7:0]` | `an[7:0]` | `seg_sel_o[7:0]` | 8 | 低电平选中 | `an[0]=A0` ... `an[7]=A7` |

## 5. 被排除项

- Nexys4/Nexys4DDR/Basys3 相关 `.xdc` 均排除，不能用于 Minisys。
- Vivado IP 自动生成的 OOC/clock/MIG 约束不作为板级主约束。
- VGA、UART、Ethernet、DDR 等资源暂不进入第一版主线，避免扩大约束面。

## 6. 未确认项与人工复核建议

| 项目 | 状态 | 建议 |
|---|---|---|
| P20 复位按钮实际输入极性 | 待实物/Vivado ILA 或最小 bitstream 实测 | 当前文档保留板级 `rst_n` 命名，并在 `minisys_top` 内转换为内部高有效 `rst` |
| `soc_top` 最终内部端口 | 待 RTL 实现时冻结 | 建议使用 `sw_i/led_o/seg_data_o/seg_sel_o`，由 `minisys_top` 映射 |
| bitstream 验证 | 未验证 | 当前 PATH 下无 Vivado，需在 Vivado 2018.3 工程中综合/实现验证 |
