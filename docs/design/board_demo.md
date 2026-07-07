# 上板演示方案

用途：定义 Minisys 第一版演示方式、端口命名、LED/拨码/数码管约定和演示流程。

最后更新时间：2026-07-07

## 1. 演示目标

第一版演示不依赖 UART，使用 LED、拨码开关和 8 位七段数码管完成：

- 普通点积运行。
- MAC 点积运行。
- 结果一致性展示。
- 周期数/指令数/MAC 次数展示。
- running/done/error/mac_mode 状态展示。

## 2. Minisys 顶层端口命名

老师资料中的 Minisys `.xdc` 已确认。项目主线使用 `constraints/minisys.xdc`，板级顶层固定为：

```text
input        clk
input        rst_n
input [15:0] sw
output [15:0] led
output [7:0] seg
output [7:0] an
```

原始 `Minisys_Master.xdc` 中存在 `CLK100MHZ`、`CPU_RESET`、`custom_gpio` 等 MIPS 工程端口名。项目统一在 `minisys_top`/`constraints/minisys.xdc` 中映射为上述端口，不允许各模块私自改端口风格。

## 3. 拨码开关功能

```text
SW1:SW0  数码管显示选择
         00=result
         01=cycle_count 低位
         10=instret_count 或 mac_count 低位
         11=status/error code
SW2      运行模式：0=普通点积，1=MAC 点积
SW3      可选 start；优先使用板上复位键完成 reset
SW15:SW4 保留
```

## 4. LED 显示约定

```text
LED0 = running
LED1 = done
LED2 = error
LED3 = mac_mode
LED5:LED4 = display_mode
LED6 = mem_access 或 reserved
LED7 = heartbeat
LED15:LED8 = reserved/debug
```

## 5. 数码管显示约定

- 第一版显示十六进制。
- Minisys 数码管为共阳极，`seg` 和 `an` 低电平有效。
- `result` 显示低 32 位。
- `cycle_count` 显示低 32 位。
- `instret_count` 显示低 32 位。
- `mac_count/status` 根据 SW 选择。
- 不在硬件里计算 speedup，报告中计算。
- `seg7_driver` 后续实现必须包含 0-F 十六进制编码表，编码输出为低有效。
- 建议扫描刷新频率落在约 500 Hz-2 kHz 的人眼稳定范围；具体计数器参数在 RTL 实现时记录。

显示模式：

| `SW1:SW0` | 数码管显示 | 说明 |
|---|---|---|
| `00` | `result[31:0]` | 点积结果低 32 位 |
| `01` | `cycle_count[31:0]` | 周期计数低 32 位 |
| `10` | `instret_count[31:0]` 或 `mac_count[31:0]` | 由 RTL 实现时最终冻结 |
| `11` | `status/error code` | 便于验收说明异常状态 |

当前 `src/board/minisys_top.v` 只是板级外壳和最小心跳/拨码显示占位，完整 `soc_top`、`seg7_driver`、display mux 尚未实现，不能把上述显示模式标为已完成。

## 6. 普通点积演示流程

1. 上电。
2. 复位。
3. 设置 `SW0=0`。
4. 等待 `done=1`。
5. `SW2:SW1=00`，查看 result。
6. `SW2:SW1=01`，查看 cycle_count。
7. 拍照或录像。

## 7. MAC 点积演示流程

1. 复位。
2. 设置 `SW0=1`。
3. 等待 `done=1`。
4. `SW2:SW1=00`，确认 result 与普通版一致。
5. `SW2:SW1=01`，查看 cycle_count。
6. `SW2:SW1=11`，查看 mac_count/status。
7. 与普通版周期数对比。

## 8. 周期数对比展示方法

上板只显示低 32 位计数。报告中记录完整仿真/硬件观察结果，并计算：

```text
speedup = normal_cycle_count / mac_cycle_count
```

## 9. 异常降级演示

| 异常 | 降级方案 |
|---|---|
| 数码管显示异常 | LED 显示 result 低 8 位 |
| 拨码读取异常 | 固定模式综合两个 bitstream |
| MAC timing 异常 | 使用基础 CPU 演示，MAC 放仿真和报告 |
| 约束或顶层端口不匹配 | 以 `constraints/minisys.xdc` 和 `docs/hardware/minisys_pinout.md` 为准修正 `minisys_top` |

## 10. 需要留存材料

- 上板全景照片。
- result 显示照片。
- cycle_count 显示照片。
- mac_count/status 显示照片。
- Vivado bitstream 成功截图。
- utilization 截图。
- timing summary 截图。
