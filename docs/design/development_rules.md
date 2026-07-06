# 小组统一开发规范

用途：规定 RTL 编码、接口变更、Git、AI、调试日志和 code review 规则。

最后更新时间：2026-07-06

## 1. 协作总原则

- 先文档，后代码。
- 先仿真，后上板。
- `main` 分支保持可运行。
- 每个模块必须可解释。
- 不追求大而全，优先保证一周可交付。

## 2. RTL 编码规范

- 文件名与模块名一致。
- 模块名小写加下划线。
- 一个模块只负责一类功能。
- x0 恒为 0。
- 不允许 latch。
- 不允许未解释的 magic number。
- 所有位宽必须明确。

## 3. 复位规范

- 内部统一使用 `rst`，高有效同步复位。
- 板级 `rst_n` 在 `minisys_top` 内转换为 `rst`。
- 如果某模块必须异步复位，需先在接口文档说明原因。

## 4. always 块规范

- 时序逻辑：`always @(posedge clk)`。
- 时序逻辑使用非阻塞赋值 `<=`。
- 组合逻辑：`always @(*)`。
- 组合逻辑使用阻塞赋值 `=`。
- `case` 必须有 `default`。
- 组合逻辑所有输出必须有默认赋值。

## 5. 接口变更规范

公共接口包括：

- `cpu_top`
- `regfile`
- `mem_bus`
- `soc_top`
- `minisys_top`

变更流程：

1. 先更新 `docs/design/interfaces.md`。
2. 组长确认。
3. 修改 RTL。
4. 修改 testbench。
5. 跑仿真。
6. 提交 Git。

不允许单个成员私自改公共接口。

## 6. Git 分支规范

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

## 7. AI 使用规范

- 每次使用 Codex/ChatGPT 生成或修改代码，必须记录到 `docs/ai_logs/ai_usage_log.md`。
- AI 不允许一次生成整个 CPU。
- 每次只让 AI 生成单个模块或单个 testbench。
- AI 输出必须人工审阅。
- AI 输出必须经过仿真或人工检查后才能合并。

记录内容包括：

- 提示词摘要。
- 输出摘要。
- 人工修改。
- 验证方式。
- 验证结果。

## 8. 调试日志规范

每天记录：

- bug 现象。
- 原因分析。
- 解决方案。
- 关联 commit。
- 波形截图路径。
- Vivado 报告路径。

最终报告可直接引用调试日志。

## 9. Code Review 规则

- 公共模块至少一人 review。
- 重点检查复位、位宽、阻塞/非阻塞、x0、非法地址、默认分支。
- Review 后再合并到 `main`。

## 10. 禁止事项

- 不直接做 DDR3/Cache/VGA/WiFi/蓝牙/电机/触摸屏。
- 不直接套用开源 CPU 项目。
- 不提交 Vivado 临时文件。
- 不在未更新文档的情况下修改公共接口。
- 不让 AI 一次性生成完整 CPU。
