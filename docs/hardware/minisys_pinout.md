# Minisys 板级端口与约束核对

最后更新时间：2026-07-07

## 1. 结论

已在老师资料目录中找到可作为 Minisys 主约束来源的 `.xdc`：

```text
安装包资料/minisys_MIPS_FPGA1/MIPS_FPGA/workspace/project_linux/project_linux.srcs/constrs_1/new/Minisys_Master.xdc
```

该文件覆盖 100 MHz 时钟、复位、前 16 个拨码/LED 相关引脚、UART、以太网和 MIPS/EJTAG 相关端口。它的端口名带有 MIPS 工程痕迹，例如 `CLK100MHZ`、`CPU_RESET`、`SW[7:0]`、`LED[7:0]`、`custom_gpio[15:0]`。项目主线不直接沿用这些混杂端口名，而是在 `constraints/minisys.xdc` 中统一为：

```text
clk
rst_n
sw[15:0]
led[15:0]
seg[7:0]
an[7:0]
```

## 2. 辅助核对来源

除 `Minisys_Master.xdc` 外，还核对了：

| 来源 | 用途 |
|---|---|
| `Minisys硬件手册1.1_完整版.pdf` | 确认 Y18 为 100 MHz 主时钟；板上有 24 个拨码、24 个 LED、8 位七段数码管；七段数码管低电平有效 |
| `Minisys基础开发包/.../lab1/constr/flash_led_top.xdc` | 确认 LED[0:15] 的实验例程引脚 |
| `Minisys基础开发包/.../lab2/constrs_1/new/KEY_SEG.xdc` | 确认数码管 `seg_an`、`seg_out` 引脚 |
| `Minisys基础开发包/.../lab3/constr/uart.xdc` | 再次确认数码管引脚和 UART 方向 |

## 3. 项目第一版使用端口

| 项目端口 | 宽度 | 说明 | 有效电平 |
|---|---:|---|---|
| `clk` | 1 | 100 MHz 主时钟，Y18 | 上升沿 |
| `rst_n` | 1 | 板级复位按钮，P20；在 `minisys_top` 内转换为内部 `rst` | 板级低有效约定 |
| `sw` | 16 | 使用 SW0-SW15，演示模式和显示选择 | 高电平为 1 |
| `led` | 16 | 使用 LED0-LED15；第一版状态主要使用低 8 位 | 高电平点亮 |
| `seg` | 8 | CA, CB, CC, CD, CE, CF, CG, DP | 低电平点亮 |
| `an` | 8 | A0-A7 位选 | 低电平选中 |

## 4. 引脚表

| 端口 | FPGA 引脚 | 备注 |
|---|---|---|
| `clk` | Y18 | 100 MHz |
| `rst_n` | P20 | reset button |
| `sw[0]` | W4 | SW0 |
| `sw[1]` | R4 | SW1 |
| `sw[2]` | T4 | SW2 |
| `sw[3]` | T5 | SW3 |
| `sw[4]` | U5 | SW4 |
| `sw[5]` | W6 | SW5 |
| `sw[6]` | W5 | SW6 |
| `sw[7]` | U6 | SW7 |
| `sw[8]` | V5 | SW8 |
| `sw[9]` | R6 | SW9 |
| `sw[10]` | T6 | SW10 |
| `sw[11]` | Y6 | SW11 |
| `sw[12]` | AA6 | SW12 |
| `sw[13]` | V7 | SW13 |
| `sw[14]` | AB7 | SW14 |
| `sw[15]` | AB6 | SW15 |
| `led[0]` | A21 | LED0 |
| `led[1]` | E22 | LED1 |
| `led[2]` | D22 | LED2 |
| `led[3]` | E21 | LED3 |
| `led[4]` | D21 | LED4 |
| `led[5]` | G21 | LED5 |
| `led[6]` | G22 | LED6 |
| `led[7]` | F21 | LED7 |
| `led[8]` | J17 | LED8 |
| `led[9]` | L14 | LED9 |
| `led[10]` | L15 | LED10 |
| `led[11]` | L16 | LED11 |
| `led[12]` | K16 | LED12 |
| `led[13]` | M15 | LED13 |
| `led[14]` | M16 | LED14 |
| `led[15]` | M17 | LED15 |
| `an[0]` | C19 | A0 |
| `an[1]` | E19 | A1 |
| `an[2]` | D19 | A2 |
| `an[3]` | F18 | A3 |
| `an[4]` | E18 | A4 |
| `an[5]` | B20 | A5 |
| `an[6]` | A20 | A6 |
| `an[7]` | A18 | A7 |
| `seg[0]` | F15 | CA |
| `seg[1]` | F13 | CB |
| `seg[2]` | F14 | CC |
| `seg[3]` | F16 | CD |
| `seg[4]` | E17 | CE |
| `seg[5]` | C14 | CF |
| `seg[6]` | C15 | CG |
| `seg[7]` | E13 | DP |

## 5. 暂不进入主线的资源

Minisys 板上还有 SW16-SW23、更多 LED、矩阵键盘、UART、VGA、以太网、DDR 等资源。第一版验收演示不需要它们，暂不写入主线顶层约束，避免未使用端口造成额外综合/实现风险。
