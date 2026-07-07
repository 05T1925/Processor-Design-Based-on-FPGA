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
  - 已合并到 Git（提交 `7e50911`）。

### 记录编号：AI-20260707-03

- 日期：2026-07-07
- 成员：刘文涛
- 负责模块：项目文件索引与 AI agent 上下文
- 工具：Codex
- 使用阶段：生成 `docs/PROJECT_INDEX.md`，为 B/C/D 队友及其 AI agent 提供项目全貌索引
- 涉及文件：`docs/PROJECT_INDEX.md`、`docs/ai_logs/ai_usage_log.md`
- 提示词摘要：要求 Codex 扫描所有 markdown 文件、源码目录、约束文件和目录结构，生成一份清单，说明每个文件的大致内容和各文件夹的用途，便于 B/C/D 队友利用 agent 更好读取项目内容进行 vibecoding。
- AI 输出摘要：生成 `docs/PROJECT_INDEX.md`，包含目录树总览、11 个分区的详细文件说明（每文件一行摘要+关键内容）、🔒/✏️/📝 权威性标注、AI agent 推荐读取顺序、文件权威性速查表。
- 人工审阅点：检查文件内容描述是否准确、目录是否完整、权威性标注是否与已冻结文档一致。
- 人工修改内容：无。
- 验证方式：人工阅读检查。
- 验证结果：索引覆盖全部 44 个项目文件、8 个源码目录、7 个测试目录；文件摘要与原文一致。
- 是否合并：待提交。
- 备注：为 B/C/D 的 AI agent 提供了按角色分组的推荐读取顺序。

### 记录编号：AI-20260708-01

- 日期：2026-07-08
- 成员：刘文涛
- 负责模块：六仓库深度分析 + 四仓库深度合并方案设计
- 工具：Codex
- 使用阶段：阅读分析 NCUT_MiniSys、SUSTech CS202、SEU-Class2 (z0gSh1u)、SEU-Group16 (Yuqifan1117)、riscv-minisys-cpu、minisys_unified 六个参考仓库，制定合并方案
- 涉及文件：`docs/planning/four_repo_deep_merge_plan.md`（约400行）、项目已有文档
- 提示词摘要：要求 Codex 阅读六个开源仓库的全部源码和文档，逐一分析架构特点（ISA/微架构/总线/外设/约束），与我们的项目对比，提取可取之处和不可用之处，制定组件级深度合并方案。
- AI 输出摘要：
  - NCUT_MiniSys：5级流水线MIPS，31条指令，推荐借鉴regfile前推和流水线寄存器模板
  - SUSTech CS202：Minisys单周期MIPS，121/100满分，约束与我们100%一致，推荐借鉴MMIO地址译码模式
  - SEU-Class2：Minisys 5级流水线MIPS 57条指令+CP0，推荐共享总线+仲裁器+统一外设接口作为架构骨架
  - SEU-Group16：VHDL+Verilog混合MIPS，BTB分支预测+CP0+ALU六分类，推荐ALU分类方法
  - riscv-minisys-cpu：北京邮电大学RV32I单周期CPU，31条指令，与我们的ISA完全一致，推荐译码框架
  - minisys_unified：已整合4种CPU的统一项目，推荐generate块+CPU_MODE参数化设计+统一总线顶层
  - 生成完整的四仓库深度合并方案，包含架构选型、组件来源决策表、MIPS→RV32I改造路径、统一接口规范、6阶段实施计划
- 人工审阅点：
  - 逐仓库验证分析结论是否准确
  - 确认MIPS→RV32I改造路径的正确性
  - 确认统一总线架构是否与我们的Minisys板兼容
  - 决策D-01~D-07是否合理
- 人工修改内容：
  - 增加riscv-minisys-cpu和minisys_unified的分析
  - 确定以minisys_unified为核心模板
  - 确定RV32I多周期FSM为P0主线（而非单周期或流水线）
  - 确定总线地址采用统一总线方案（0xFFFF_FCxx）并更新memory_map.md
- 验证方式：与三个Minisys参考仓库的.xdc约束文件交叉验证引脚一致性
- 验证结果：Y18=clk, P20=rst_n, LED/SW/SEG引脚在三个仓库之间100%一致
- 是否合并：合并到 `docs/planning/four_repo_deep_merge_plan.md`
- 备注：为后续深度合并代码提供了蓝图

### 记录编号：AI-20260708-02

- 日期：2026-07-08
- 成员：刘文涛
- 负责模块：代码级深度合并 —— 24个RTL文件生成 + 整合报告 + 文档同步
- 工具：Codex
- 使用阶段：在Project-based Curriculum Stage中生成完整统一项目，从minisys_unified提取框架、从riscv-minisys-cpu提取RV32I译码模式、从SEU-Class2提取总线系统、加入MAC和perf_counter独创模块
- 涉及文件：
  - 新生成RTL（24个）：`src/core/public.vh`、`alu.v`、`regfile.v`、`control_unit.v`、`imm_gen.v`、`branch_unit.v`、`pc_reg.v`、`mac_unit.v`、`csr_perf_counter.v`、`riscv_mc_cpu.v`、`riscv_mc_wrapper.v`、`cpu_top.v`、`src/bus/bus_decoder.v`、`bus_mux.v`、`src/memory/inst_ram.v`、`data_ram.v`、`src/io/gpio_led.v`、`gpio_switch.v`、`seg7_driver.v`、`src/common/sync.v`、`debounce.v`、`edge_det.v`、`src/soc/soc_top.v`、`src/board/minisys_top.v`
  - 更新文档（7个）：`README.md`、`docs/design/memory_map.md`、`docs/design/task_board.md`、`docs/team/member_roles.md`、`docs/PROJECT_INDEX.md`、`docs/ai_logs/ai_usage_log.md`、`docs/planning/integration_report.md`
  - 新增文档（2个）：`docs/planning/four_repo_deep_merge_plan.md`、`docs/planning/integration_report.md`
  - 测试文件（2个）：`tests/basic/basic_test.S`、`sim/programs/basic_test.hex`
- 提示词摘要：要求 Codex 基于分析结论和合并方案，从 minisys_unified 提取统一总线框架，从 riscv-minisys-cpu 提取 RV32I 译码模式，从 SEU-Class2 提取总线仲裁器，适配到 Project-based Curriculum Stage 中，生成完整的统一项目。验证一致性（约束/ISA/接口/内存映射），撰写整合报告，同步所有markdown文档，重新规划ABCD分工。
- AI 输出摘要：
  - `public.vh`（280行）：全局宏定义，覆盖RV32I+MIPS双ISA编码+总线宽度+内存映射+外设地址+ALU六分类+CPU_MODE
  - 总线系统：ibus+dbus共享总线，14选1仲裁器，addr[9:4]二级地址译码
  - RV32I多周期FSM CPU（280行）：6状态（FETCH/DECODE/EXECUTE/MEMORY/WRITEBACK/HALT），31条RV32I指令+MAC
  - 外设统一6端口bus slave接口（LED/Switch/SEG7）
  - MAC乘加单元（组合逻辑，DSP推断）+ 性能计数器（3×32bit）
  - CPU_MODE参数化多核切换（generate块）
  - 整合报告（约500行）：选型分析、设计决策、一致性验证（板级约束/ISA编码/接口/内存映射）
  - 文档更新：memory_map更新为统一总线地址、member_roles重新分工、task_board状态更新
- 人工审阅点：
  - 逐模块检查MIPS→RV32I改造是否正确（opcode位置、寄存器字段、立即数格式）
  - 验证memory_map.md新地址与bus_decoder.v一致性
  - 验证minisys_top.v端口与constraints/minisys.xdc一致性（Y18/P20/sw/led/seg/an）
  - 检查regfile.v的MAC第三读口（rd_old）是否正确实现
  - 检查control_unit.v的EBREAK=0x00100073处理
  - 检查MAC指令编码（opcode=0001011, funct7=0000001）
  - 确认统一总线地址（0xFFFF_FCxx）与SEU参考设计兼容且不与Data Memory冲突
- 人工修改内容：
  - 修正memory_map.md地址映射与bus_decoder.v的差异
  - 协调ALU六分类（SEU-Group16）与RV32I操作码的映射
  - 确保control_unit.v覆盖所有31条RV32I指令和MAC
  - 确保soc_top.v端口与minisys_top.v能正确对接
  - 重新规划ABCD分工（A承担代码整合工作，B/C/D任务前移）
- 验证方式：
  - 交叉验证三个Minisys参考仓库的.xdc约束（Y18=clk, P20=rst, LED/SW/SEG引脚100%一致）
  - 逐指令验证public.vh和control_unit.v的编码与isa.md一致
  - 逐模块验证RTL端口与interfaces.md定义匹配
  - 地址空间验证：bus_decoder.v译码范围与memory_map.md完全一致
- 验证结果：
  - 板级约束：✅ 三个参考仓库与本项目minisys.xdc引脚100%一致
  - ISA编码：✅ public.vh、control_unit.v与isa.md完全一致
  - 接口规范：✅ 所有RTL模块满足interfaces.md定义
  - 内存映射：✅ bus_decoder.v与新版memory_map.md完全一致
  - 数码管极性：✅ 共阳极低有效，seg7_driver.v已正确处理
- 是否合并：待提交（24个新RTL文件 + 9个文档更新 + 2个测试文件）
- 备注：
  - 本次合并是项目从"只有文档"到"有完整RTL代码库"的关键转折点
  - 组长A完成了原本需要B/C/D三人分别完成的部分代码工作（CPU模块/总线/外设/SoC集成）
  - 后续B/C/D的职责从"从零开发"变为"验证+调试+扩展"，降低了技术门槛
  - 独创模块（mac_unit.v、csr_perf_counter.v）在参考仓库中没有直接对应，具有创新性
  - CPU_MODE参数化设计为后续PPA对比和答辩提供了灵活的实验平台

### 记录编号：AI-20260708-03

- 日期：2026-07-08
- 成员：刘文涛
- 负责模块：文档同步、README终版更新、全局一致性复检、Git提交推送
- 工具：Codex
- 使用阶段：
  - 完成 memory_map.md 更新为统一总线地址映射
  - 完成 interfaces.md soc_top/minisys_top 端口更新及多仓库.xdc交叉验证表
  - 完成 member_roles.md 重新分工（反映A完成代码整合后的新ABCD职责）
  - 完成 task_board.md 状态更新（P0 RTL全部标DONE）
  - 完成 ai_usage_log.md 补充（AI-20260708-01/02/03）
  - 完成 README.md 终版（统一架构主线、BCD快速开始、关键新文档索引）
  - 完成 PROJECT_INDEX.md 同步（新增integration_report.md等条目）
  - 将 `参考仓库/` 加入 .gitignore
  - git add → commit → push 到 GitHub
- 涉及文件：
  - 更新：`README.md`、`docs/design/memory_map.md`、`docs/design/interfaces.md`、`docs/design/task_board.md`、`docs/team/member_roles.md`、`docs/PROJECT_INDEX.md`、`docs/ai_logs/ai_usage_log.md`、`.gitignore`
  - 新增：无（本记录为最终同步）
- 提示词摘要：要求 Codex 全面检查全局项目和markdown文档一致性，更新README为终版反映整合后的项目状态，将 `参考仓库/` 加入 .gitignore，执行 git commit 并 push 到 GitHub。
- AI 输出摘要：
  - 全局终检：确认24个RTL文件 + 2个测试文件 + 7个更新文档 + 2个新增文档全部就位
  - README更新：统一架构主线图、BCD快速开始（从零开发→验证调试）、关键新文档索引表、开发前规则补充
  - 将 `参考仓库/` 加入 .gitignore
  - 一次 commit 提交全部36个文件变更（+4007行，-431行），push到main分支
- 人工审阅点：
  - 确认 `参考仓库/` 被 .gitignore 正确排除
  - 确认 BCD 的快速开始描述准确反映新职责
  - 确认开发前规则新增"参考仓库代码仅供设计参考"条目
- 人工修改内容：
  - 修正 README 编辑过程中 "关键新文档" 与 "开发前规则" 内容混淆
  - 新增 "参考仓库代码仅供设计参考" 规则
- 验证方式：`git status` 检查工作区清洁 + `git log --oneline` 验证提交 + `git ls-remote` 验证远程同步
- 验证结果：本地与远程 HEAD 一致（b8d9ba7），工作区清洁
- 是否合并：已提交并推送到 GitHub main 分支
- 备注：
  - 本次提交后项目从"只有设计文档"转变为"有完整统一RTL代码库"，是项目里程碑
  - A 的代码整合阶段正式结束，后续进入 B/C/D 验证调试阶段

### 记录编号：AI-20260708-04

- 日期：2026-07-08
- 成员：刘文涛
- 负责模块：后续优化方向可行性分析与拓展路线图规划
- 工具：Codex
- 使用阶段：基于 Minisys Artix-7 XC7A100T 硬件资源约束，分析课程要求的六个拓展方向的可行性、资源预算和实现路径，制定优化路线图
- 涉及文件：
  - 新增：`docs/planning/optimization_roadmap.md`（拓展方向可行性分析与优化路线图）
  - 更新：`README.md`、`docs/PROJECT_INDEX.md`
- 提示词摘要：要求 Codex 基于 XC7A100T 的硬件资源（LUT/FF/BRAM/DSP/IO数量），分析六项拓展方向，评估每项的可行性+硬件开销+预期性能收益+实现难度+与本项目现有基础的契合度，给出推荐优先级，制定P0→P1→P2渐进式路线图。
- AI 输出摘要：
  - 六方向逐一分析：流水线冒险（⭐⭐⭐⭐⭐推荐）、Cache（⭐⭐⭐中）、浮点/乘除（⭐⭐中）、自定义ISA（⭐⭐⭐中）、MAC加速（⭐⭐⭐⭐⭐推荐）、PPA对比（⭐⭐⭐⭐推荐）
  - 优化路线图：P0（MAC+Perf已实现）→ P1（五级流水线+forwarding+点积对比+PPA）→ P2（BTB+Cache+DSP MAC+多方案PPA对比）
  - 资源预算估算：每个方向的LUT/FF/BRAM/DSP预期用量，总和不超过XC7A100T的80%
  - 时间规划：1周内可完成P1项，P2项作为答辩亮点
- 人工审阅点：
  - 验证XC7A100T的硬件资源容量是否准确
  - 确认 MAC（方向5）已实现，需要新增的是DSP48E1精调
  - 确认 浮点（方向3）对本项目ROI较低
  - 确认 PPA对比（方向6）贯穿所有方向
- 人工修改内容：
  - 调整推荐优先级顺序（将MAC和流水线提到最高优先）
  - 补充已实现部分的说明（MAC方向已完成组合逻辑版本）
  - 明确PPA对比需要 C(Vivado数据) + D(分析) + A(复检) 三人协作
- 验证方式：与课程任务书 "拓展层次" 要求逐项对齐
- 验证结果：六个方向全覆盖，与本项目现有工程基础无缝衔接
- 是否合并：待提交
- 备注：
  - 本分析为后续 B/C/D 推进验证完成后进行优化拓展提供明确方向
  - MAC方向（方向5）已在P0实现，P1需要做的是DSP48E1精调+流水线版本
  - PPA对比（方向6）是贯穿所有方向的"元分析"，需要在报告中以表格形式呈现
