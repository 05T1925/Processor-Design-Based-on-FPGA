# Memory Map 与 MMIO 设计

用途：定义第一版 SoC 的地址空间、MMIO 寄存器、地址译码和非法地址处理策略。

最后更新时间：2026-07-06

## 1. 地址空间总览

第一版只使用 BRAM 和 MMIO，不使用 DDR3/Cache。

| 地址范围/地址 | 名称 | 读写 | 用途 |
|---|---|---|---|
| `0x0000_0000 - 0x0000_0FFF` | Instruction Memory | R | 程序指令 |
| `0x0000_1000 - 0x0000_1FFF` | Data Memory | R/W | 数据区 |
| `0x1000_0000` | LED | W | LED 输出 |
| `0x1000_0004` | SWITCH | R | 拨码开关输入 |
| `0x1000_0008` | SEG7 | W | 数码管显示寄存器 |
| `0x1000_000C` | cycle_count | R | 周期计数 |
| `0x1000_0010` | instret_count | R | 指令退休计数 |
| `0x1000_0014` | mac_count | R | MAC 指令计数 |
| `0x1000_0018` | result_reg | R/W | 演示结果寄存器 |
| `0x1000_001C` | status_reg | R | 状态寄存器 |
| `0x1000_0020` | UART reserved | R/W | 后续 UART 预留 |

## 2. Instruction Memory

- 范围：`0x0000_0000 - 0x0000_0FFF`。
- 第一版作为只读程序存储器。
- 初期允许手写少量 hex。
- 第二阶段使用 `scripts/gen_mem.py` 生成 `.mem`。
- 不开发完整 assembler。

## 3. Data Memory

- 范围：`0x0000_1000 - 0x0000_1FFF`。
- 支持 word 对齐的 LW/SW。
- BRAM 内部可截取地址低位寻址。

## 4. MMIO 访问规则

第一版 MMIO 单周期读写。

地址译码建议：

```text
addr[31:28] == 0x0 -> instruction/data memory 区
addr[31:28] == 0x1 -> MMIO 区
```

具体是否访问 data memory 由范围判断：

- `0x0000_1000 - 0x0000_1FFF`：data memory。
- `0x1000_0000 - 0x1000_00FF`：MMIO。

## 5. 对齐规则

- 第一版只支持 32 bit word 访问。
- LW/SW 地址必须 4 字节对齐。
- 非对齐访问置 `error=1`，返回 0 或忽略写入。

## 6. 非法地址处理

非法地址策略：

- 读非法地址：返回 `0x0000_0000`。
- 写非法地址：忽略写入。
- `status_reg.error` 或 CPU `error` 置 1。

## 7. 数码管显示策略

第一版优先使用 `display_mux` 根据拨码选择显示：

- result。
- cycle_count 低 32 位。
- instret_count 低 32 位。
- mac_count 或 status。

这比让 CPU 进行复杂格式转换更适合快速上板。CPU 写 `SEG7` 寄存器作为可选路径保留。

## 8. UART 预留

`0x1000_0020` 起预留给 UART：

- `0x1000_0020`：UART_TXDATA。
- `0x1000_0024`：UART_STATUS。

UART 是 P2/P1 后期选项，不作为第一版阻塞项。
