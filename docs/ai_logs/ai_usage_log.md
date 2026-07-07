# AI 使用日志

## 使用记录模板

```markdown
### 记录编号：AI-YYYYMMDD-XX

- 日期：
- 成员：
- 负责模块：
- 工具：
- 使用阶段：
- 涉及文件：
- 提示词摘要：
- AI 输出摘要：
- 人工审阅内容：
- 人工修改内容：
- 验证方式：
- 验证结果：
- 是否合并：
- 备注：
```

## 记录要求

- 每个成员只记录自己实际使用 AI 的部分。
- 不能把 AI 日志全部交给组长补。
- AI 生成或修改代码、文档、测试思路、报告文字，都需要记录。
- AI 输出必须经过人工审阅。
- 核心 RTL 和测试内容必须经过 Vivado xsim、Vivado 或人工检查后才能合并。
- 最终报告附录会引用该日志。

## 使用记录

### 记录编号：AI-20260706-01

- 日期：2026-07-06
- 成员：刘文涛
- 负责模块：项目资料整理与协作文档
- 工具：Codex
- 使用阶段：项目资料阅读、开发指南可行性检查、仓库目录初始化、第一轮规划日志生成
- 涉及文件：`docs/design/guide_feasibility_review.md`、`docs/design/project_paths.md`、`docs/planning/round1_initial_plan.md`、`docs/ai_logs/ai_usage_log.md`
- 提示词摘要：根据课程资料、Minisys 平台、人工确认的项目口径，检查开发指南可行性，初始化目录，生成第一轮规划日志。
- AI 输出摘要：生成第一轮规划文档、路径规划和 AI 日志初稿。
- 人工审阅内容：需人工确认部分已统一。
- 人工修改内容：待填写。
- 验证方式：人工阅读检查，未进入 RTL 仿真。
- 验证结果：文档已生成。
- 是否合并：已合并到 Git。
- 备注：关联提交 `8b1637f`。

### 记录编号：AI-20260706-02

- 日期：2026-07-06
- 成员：刘文涛
- 负责模块：MVP 协作文档与接口规范
- 工具：Codex
- 使用阶段：项目规划文档拆分与协作规范生成
- 涉及文件：`README.md`、`.gitignore`、`docs/design/*.md`、`docs/planning/round2_mvp_plan.md`
- 提示词摘要：根据第二阶段最小可行实现方案和组长确认决策，拆分生成架构、ISA、接口、测试、演示、开发规范、任务看板、风险和规划文档。
- AI 输出摘要：生成 MVP 协作文档，固化多周期 FSM、MAC 第三读口、EBREAK HALT、xsim 主流程等决策。
- 人工审阅内容：需人工确认部分已统一，具体接口统一规范等待安装好环境后确定。
- 人工修改内容：待填写。
- 验证方式：组长人工审阅；本轮不生成 RTL。
- 验证结果：文档完整性、一致性、目录、`.gitignore`、临时文件检查通过；待组长最终人工审阅。
- 是否合并：待提交。
- 备注：本记录用于报告附页；本轮未生成 RTL/Vivado 工程。

### 记录编号：AI-20260706-03

- 日期：2026-07-06
- 成员：刘文涛
- 负责模块：小组分工、任务看板、协作规范、AI 日志
- 工具：Codex
- 使用阶段：最终人工确认同步、任务状态调整、提交前检查
- 涉及文件：`README.md`、`docs/team/member_roles.md`、`docs/team/daily_workflow.md`、`docs/team/review_checklist.md`、`docs/design/task_board.md`、`docs/design/development_rules.md`、`docs/ai_logs/ai_usage_log.md`、`docs/planning/team_division.md`
- 提示词摘要：根据组长人工确认结果，同步官方 `.xdc` 待确认、姓名学号正确、GitHub 已邀请、贡献度均分、任务看板真实状态，并准备提交推送。
- AI 输出摘要：更新任务看板状态、成员分工确认信息、贡献度说明和本条 AI 使用日志。
- 人工审阅内容：组长已确认姓名学号、贡献度比例和 GitHub 邀请状态；官方 `.xdc` 和板级端口待安装环境后确认。
- 人工修改内容：待提交前最终检查。
- 验证方式：人工阅读检查，`git status` 检查；本轮不生成 RTL、不运行 Vivado。
- 验证结果：文档已同步，待 Git 提交和推送。
- 是否合并：待提交。
- 备注：本轮只修改 Markdown 文档。

### 记录编号：AI-20260707-01

- 日期：2026-07-07
- 成员：刘文涛
- 负责模块：Minisys 板级约束、顶层端口和硬件资料核对
- 工具：Codex
- 使用阶段：老师资料深度阅读、`.xdc` 确认、`minisys_top` 和 LED/拨码/数码管接口统一
- 涉及文件：`constraints/minisys.xdc`、`src/board/minisys_top.v`、`docs/hardware/minisys_pinout.md`、`docs/design/interfaces.md`、`docs/design/board_demo.md`、`docs/design/task_board.md`、`docs/planning/team_division.md`
- 提示词摘要：阅读老师提供的 Minisys 安装包资料，寻找项目未知但需要的 Minisys 官方 `.xdc`，确认并统一 `minisys_top.v`、LED、数码管和拨码开关顶层端口信息。
- AI 输出摘要：确认 `Minisys_Master.xdc` 为主约束来源，结合中文实验约束补齐数码管/LED/拨码引脚，生成项目主线 `constraints/minisys.xdc`、板级顶层外壳和管脚核对文档。
- 人工审阅内容：需人工在 Vivado 2018.3 中加载 `constraints/minisys.xdc` 并结合实物板确认复位按钮实际极性。
- 人工修改内容：待 C/A 上板验证后补充。
- 验证方式：资料交叉核对、`rg` 文档一致性扫描；当前 PATH 下无 Vivado/iverilog/verilator，未做综合或 Verilog 编译。
- 验证结果：主线文档中“等待官方 `.xdc`”状态已清理；约束和顶层端口已统一。
- 是否合并：待提交。
- 备注：本轮未修改用户已有的安装包资料目录。

### 记录编号：AI-20260707-02

- 日期：2026-07-07
- 使用者：A 刘文涛 / Codex
- 使用环节：
  - 复核 Minisys 顶层端口与 `constraints/minisys.xdc`
  - 完善 `README.md`
  - 新增 B/C/D onboarding 文档
  - 新增 setup checklist
  - 同步 daily workflow
- 输入提示词摘要：
  - 要求 Codex 根据现有仓库文档，完善端口约束、README、BCD 协作入口和 AI 日志。
- AI 输出内容摘要：
  - 更新 README 中项目状态、资料清单、下一步顺序。
  - 增加 B/C/D 开发边界。
  - 增加队友下载安装资料清单。
  - 增加 agent 上下文提示语。
- 人工审阅点：
  - 检查是否误改 ISA / memory map / 板级端口。
  - 检查是否把未完成 RTL 写成已完成。
  - 检查是否把其他板卡资料混入 Minisys 主线。
  - 检查是否没有运行 Vivado 却声称 bitstream 通过。
- 验证状态：
  - 文档检查：已完成，所有文件已同步，待 A 最终人工确认。
  - 端口约束复核：`constraints/minisys.xdc` 与 `minisys_top.v` 端口完全一致，无旧端口名残留。
  - bcd_onboarding.md：已完善，包含 B/C/D 开发边界、完整 agent 提示语、禁止事项、完成标准。
  - setup_checklist.md：已完善，包含详细资料文件名、必装清单、可选参考和不用于主线的资料。
  - daily_workflow.md：已复核，互不干扰规则和每日流程完整。
  - Vivado 综合：未验证。
  - bitstream：未验证。
- 是否合并：
  - 待 A 人工 review 后提交。
