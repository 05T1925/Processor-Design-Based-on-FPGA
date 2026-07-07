# Memory Map 与 MMIO 设计（统一总线版本）

用途：定义统一总线 SoC 的地址空间、MMIO 寄存器、地址译码和非法地址处理策略。

最后更新时间：2026-07-08（组长A：配合四仓库深度合并，更新为统一总线架构地址映射）

## 1. 地址空间总览（统一总线架构）

采用 SEU-Class2 的统一共享总线架构（ibus + dbus），地址空间分为三个区域：

| 地址范围 | 名称 | 大小 | 说明 |
|---|---|---|---|
| `0x0000_0000 - 0x0000_7FFF` | Instruction Memory | 32KB | 程序指令（ibus 只读） |
| `0x1000_0000 - 0x1000_7FFF` | Data Memory | 32KB | 数据区（dbus 读写，字节使能） |
| `0xFFFF_FC00 - 0xFFFF_FCCF` | Peripherals (MMIO) | 208B | 外设寄存器（dbus，addr[9:4] 二级译码） |

### 为何从旧版 (0x1000_0xxx) 调整为统一总线地址 (0xFFFF_FCxx)

旧版内存映射将 MMIO 放在 `0x1000_0000` 起，与 Data Memory 地址重叠。统一总线架构采用 SEU-Class2 的独立 MMIO 区域（`0xFFFF_FCxx`），好处是：

1. **地址空间清晰分离**：Data Memory 区（0x1000_xxxx）与外设区（0xFFFF_FCxx）不会冲突
2. **与参考设计兼容**：SEU-Class2 和 minisys_unified 的外设控制器直接运行在 0xFFFF_FCxx 空间
3. **扩展性强**：每个外设分配 16 字节地址槽，最多支持 16 个外设，通过 `addr[9:4]` 二级译码
4. **调试友好**：高位地址的外设访问在波形中一眼可辨

## 2. 指令存储器（Instruction Memory）

- 范围：`0x0000_0000 - 0x0000_7FFF`（32KB）
- 通过 ibus（指令总线）只读访问
- 实现模块：`src/memory/inst_ram.v`
- 组合逻辑读取，单周期延迟
- 支持 `$readmemh` 初始化（仿真）
- 预留 UART 编程写入端口（P2）

## 3. 数据存储器（Data Memory）

- 范围：`0x1000_0000 - 0x1000_7FFF`（32KB）
- 通过 dbus（数据总线）读写访问
- 实现模块：`src/memory/data_ram.v`
- 同步写 + 组合读，支持字节使能（byte_sel[3:0]）
- 地址译码：`bus_decoder.v` 判断 `dbus_addr[31:15] == 17'h1000_0`

## 4. MMIO 外设寄存器（Peripherals）

外设区域统一位于 `0xFFFF_FC00 - 0xFFFF_FCCF`，通过 `dbus_addr[9:4]` 进行二级译码，每个外设分配 16 字节地址空间。

| 地址 | addr[9:4] | 名称 | 读写 | 用途 | 状态 |
|---|---|---|---|---|---|
| `0xFFFF_FC00` | `00_0000` | LED | R/W | 16位LED输出（读回当前状态） | ✅ 已实现 |
| `0xFFFF_FC10` | `00_0001` | SWITCH | R | 16位拨码开关输入（含2级同步器） | ✅ 已实现 |
| `0xFFFF_FC20` | `00_0010` | SEG7 | R/W | 8位数码管显示（32位×8段） | ✅ 已实现 |
| `0xFFFF_FC30` | `00_0011` | UART | R/W | UART 串口（TX/RX） | 📝 P2 预留 |
| `0xFFFF_FC40` | `00_0100` | VGA | R/W | VGA 显示 | 📝 P2 预留 |
| `0xFFFF_FC50` | `00_0101` | KBD4X4 | R | 4×4 矩阵键盘 | 📝 P2 预留 |
| `0xFFFF_FC60` | `00_0110` | PS/2 | R/W | PS/2 键盘鼠标 | 📝 P2 预留 |
| `0xFFFF_FC70` | `00_0111` | TIMER | R/W | 定时器 | 📝 P1 预留 |
| `0xFFFF_FC80` | `00_1000` | PWM | R/W | PWM 输出 | 📝 P1 预留 |
| `0xFFFF_FC90` | `00_1001` | BUZZER | R/W | 蜂鸣器 | 📝 P2 预留 |
| `0xFFFF_FCA0` | `00_1010` | WDT | R/W | 看门狗定时器 | 📝 P2 预留 |
| `0xFFFF_FCB0` | `00_1011` | PERF | R | 性能计数器（cycle/instret/mac） | 🔄 待接入 |

## 5. 性能计数器寄存器

性能计数器集成在 CPU 核心内部（`csr_perf_counter.v`），通过 MMIO 暴露：

| 偏移 | 寄存器 | 位宽 | 说明 |
|---|---|---|---|
| `0xFFFF_FCB0` | `cycle_count` | 32bit | CPU 未 HALT 时每周期加 1 |
| `0xFFFF_FCB4` | `instret_count` | 32bit | 指令退休时加 1 |
| `0xFFFF_FCB8` | `mac_count` | 32bit | MAC 指令完成时加 1 |

## 6. 地址译码实现

`bus_decoder.v` 中的地址译码逻辑：

```verilog
// 一级译码：区分 Data RAM 和 Peripherals
assign in_data_ram = (dbus_addr >= 32'h1000_0000) && (dbus_addr <  32'h1000_8000);
assign in_periph   = (dbus_addr >= 32'hFFFF_FC00) && (dbus_addr <= 32'hFFFF_FCCF);

// 二级译码：addr[9:4] 选择具体外设
wire [5:0] periph_id = dbus_addr[9:4];
assign led_sel    = dbus_en && in_periph && (periph_id == 6'b00_0000);
assign switch_sel = dbus_en && in_periph && (periph_id == 6'b00_0001);
// ...
```

## 7. 对齐规则

- 第一版只支持 32 bit word 访问（LW/SW）
- LW/SW 地址必须 4 字节对齐
- data_ram 支持字节使能（byte_sel），为后续半字/字节访问预留

## 8. 非法地址处理

- 读非法地址：`bus_mux.v` 默认返回 `0x0000_0000`
- 写非法地址：无外设片选 → 数据被忽略
- 后续可在 status_reg 中增加 error 标志位

## 9. 数码管显示策略

- 使用 `seg7_driver.v` 动态扫描，~381Hz 刷新率
- 写入 32 位数据，每字节控制一个数码管段选（低有效）
- 显示内容选择通过软件实现（CPU 写不同值到 SEG7 寄存器）
- result/cycle_count/mac_count 的切换由软件控制

## 10. UART 预留

`0xFFFF_FC30` 起预留给 UART（P2 实现），用于：
- 程序在线加载（替代 JTAG）
- 性能统计数据输出
- 调试信息打印
