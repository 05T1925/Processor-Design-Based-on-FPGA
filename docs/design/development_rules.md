# 小组统一开发规范

用途：规定按成员分工开发、RTL 编码、接口变更、Git、AI、调试日志和 code review 规则。

最后更新时间：2026-07-06

## 1. 协作总原则

- 先文档，后代码。
- 先仿真，后上板。
- `main` 分支保持可运行。
- 每个模块必须可解释。
- 不追求大而全，优先保证一周可交付。
- 测试/性能任务拆分到模块负责人，不单独设置第五个测试负责人。

## 2. 按成员分工开发的约束限制

- 每位成员只能优先修改自己负责路径。
- 修改公共接口必须先更新 `docs/design/interfaces.md`。
- 修改 ISA 必须经过 A 刘文涛确认。
- 修改 memory map 必须经过 A 刘文涛确认。
- 修改 `soc_top` / `minisys_top` 需要通知 C 胡文龙和 A 刘文涛。
- 修改 regfile 第三读口需要通知 B 张淇、D 王博生和 A 刘文涛。
- 修改 MAC 控制信号需要通知 B 张淇、D 王博生和 A 刘文涛。
- 修改 `.xdc` 只能由 C 胡文龙或 A 刘文涛处理。
- 修改 README 和最终报告由 A 刘文涛统一。
- 所有 AI 生成内容必须记录到 `docs/ai_logs/ai_usage_log.md`。

## 3. 成员开发边界

### 3.1 A 刘文涛

可以修改：

- `README.md`
- `docs/`
- `reports/`
- `docs/design/task_board.md`
- `docs/design/interfaces.md`
- `docs/design/architecture.md`

谨慎修改：

- `src/core/`
- `src/soc/`
- `src/board/`

禁止：

- 未经对应成员确认，直接大规模重写 B/C/D 的模块。

### 3.2 B 张淇

可以修改：

- `src/core/alu.v`
- `src/core/regfile.v`
- `src/core/control_unit.v`
- `src/core/imm_gen.v`
- `src/core/branch_unit.v`
- `src/core/cpu_top.v`
- `tests/basic/`
- `tests/load_store/`
- `tests/branch/`
- `sim/tb/tb_cpu_basic.v`

需要沟通后修改：

- `src/core/mac_unit.v`
- `src/core/csr_perf_counter.v`
- `src/memory/`
- `src/soc/`

禁止：

- 私自修改 memory map。
- 私自改变 SoC/MMIO 接口。
- 私自移除 MAC 第三读口需求。

### 3.3 C 胡文龙

可以修改：

- `src/memory/`
- `src/io/`
- `src/soc/`
- `src/board/`
- `constraints/`
- `scripts/vivado*`
- `reports/vivado/`

需要沟通后修改：

- `src/core/cpu_top.v`
- `src/core/csr_perf_counter.v`

禁止：

- 私自修改 ISA。
- 私自修改 CPU 内部控制信号。
- 私自改变 regfile/MAC 接口。

### 3.4 D 王博生

可以修改：

- `src/core/mac_unit.v`
- `src/core/csr_perf_counter.v`
- `tests/mac/`
- `tests/perf/`
- `reports/tables/`
- `docs/design/mac_extension.md`
- `docs/design/performance.md`

需要沟通后修改：

- `src/core/regfile.v`
- `src/core/control_unit.v`
- `src/core/cpu_top.v`

禁止：

- 私自改变基础指令控制逻辑。
- 私自改变 EBREAK/HALT 规则。
- 私自把流水线改成主线必做。
- 私自扩大项目范围。

## 4. RTL 编码规范

- 文件名与模块名一致。
- 模块名小写加下划线。
- 一个模块只负责一类功能。
- x0 恒为 0。
- 不允许 latch。
- 不允许未解释的 magic number。
- 所有位宽必须明确。

## 5. 复位规范

- 内部统一使用 `rst`，高有效同步复位。
- 板级 `rst_n` 在 `minisys_top` 内转换为 `rst`。
- 如果某模块必须异步复位，需先在接口文档说明原因。

## 6. always 块规范

- 时序逻辑：`always @(posedge clk)`。
- 时序逻辑使用非阻塞赋值 `<=`。
- 组合逻辑：`always @(*)`。
- 组合逻辑使用阻塞赋值 `=`。
- `case` 必须有 `default`。
- 组合逻辑所有输出必须有默认赋值。

## 7. 接口变更规范

公共接口包括：

- `cpu_top`
- `regfile`
- `mem_bus`
- `soc_top`
- `minisys_top`

变更流程：

1. 先更新 `docs/design/interfaces.md`。
2. A 刘文涛确认。
3. 通知受影响成员。
4. 修改 RTL。
5. 修改 testbench 或测试程序。
6. 运行 Vivado xsim。
7. 更新任务看板。
8. 提交 Git。

不允许单个成员私自改公共接口。

## 8. Git 分支规范

- `main` 保持可运行。
- 每个成员使用 feature 分支。
- 每次提交必须是一个可解释节点。
- 提交前确认没有 Vivado 临时文件。
- 每天至少保留一个稳定 commit。

Commit message 前缀：

```text
docs:
rtl:
sim:
test:
fix:
report:
```

## 9. AI 使用规范

- 每次使用 Codex/ChatGPT 生成或修改代码、文档、测试思路，必须记录到 `docs/ai_logs/ai_usage_log.md`。
- AI 不允许一次生成整个 CPU。
- 每次只让 AI 生成单个模块、单个 testbench 或单个文档任务。
- AI 输出必须人工审阅。
- AI 输出必须经过 xsim、Vivado 或人工检查后才能合并。

记录内容包括：

- 提示词摘要。
- 输出摘要。
- 人工修改。
- 验证方式。
- 验证结果。

## 10. 调试日志规范

每天记录：

- bug 现象。
- 原因分析。
- 解决方案。
- 关联 commit。
- 波形截图路径。
- Vivado 报告路径。
- 验证结果。

最终报告可直接引用调试日志。

## 11. Code Review 规则

- 公共模块至少一人 review。
- 重点检查复位、位宽、阻塞/非阻塞、x0、非法地址、默认分支。
- Review 前先按 `docs/team/review_checklist.md` 自查。
- Review 后再合并到 `main`。

## 12. 禁止事项

- 禁止绕过接口文档直接改端口。
- 禁止直接在 `main` 上写未验证代码。
- 禁止提交 Vivado 临时文件。
- 禁止一次性让 AI 生成整个 CPU。
- 禁止复制开源 CPU 作为最终代码。
- 禁止擅自扩大项目范围到 DDR3、Cache、VGA、WiFi、蓝牙、电机、触摸屏。
- 禁止没有 testbench 或测试结果就合并核心模块。
