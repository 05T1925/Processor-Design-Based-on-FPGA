# 上板演示方案

用途：定义 Minisys 第一版演示方式、端口命名、LED/拨码/数码管约定和演示流程。

最后更新时间：2026-07-06

## 1. 演示目标

第一版演示不依赖 UART，使用 LED、拨码开关和 8 位七段数码管完成：

- 普通点积运行。
- MAC 点积运行。
- 结果一致性展示。
- 周期数/指令数/MAC 次数展示。
- running/done/error/mac_mode 状态展示。

## 2. Minisys 顶层端口暂定命名

官方 `.xdc` 到位前：

```text
input        clk
input        rst_n
input [23:0] sw
output [7:0] led
output [7:0] seg
output [7:0] an
```

官方 `.xdc` 到位后按官方命名统一。若官方命名不同，由 `minisys_top` 做映射。

## 3. 拨码开关功能

```text
SW0      运行模式：0=普通点积，1=MAC 点积
SW2:SW1  数码管显示选择
         00=result
         01=cycle_count 低位
         10=instret_count 低位
         11=mac_count 或 status
SW3      可选 start/reset；优先使用板上复位键
```

## 4. LED 显示约定

```text
LED0 = running
LED1 = done
LED2 = error
LED3 = mac_mode
LED4 = mem_access
LED5 = branch_taken
LED6 = reserved
LED7 = heartbeat
```

## 5. 数码管显示约定

- 第一版显示十六进制。
- `result` 显示低 32 位。
- `cycle_count` 显示低 32 位。
- `instret_count` 显示低 32 位。
- `mac_count/status` 根据 SW 选择。
- 不在硬件里计算 speedup，报告中计算。

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
| xdc 未到位 | 只完成仿真和综合前检查 |

## 10. 需要留存材料

- 上板全景照片。
- result 显示照片。
- cycle_count 显示照片。
- mac_count/status 显示照片。
- Vivado bitstream 成功截图。
- utilization 截图。
- timing summary 截图。
