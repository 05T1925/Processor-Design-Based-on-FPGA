# 项目目录与文件路径规划

## 1. 当前资料保留路径

当前资料已经按用途整理到 `docs/` 下。根目录旧 `Course Materials/` 中的无关板卡资料不再作为主线资料保留。

| 文件 | 用途 |
|---|---|
| `docs/course/2026项目式课程阶段二-修订完成版.pdf` | 课程任务书与验收规则 |
| `docs/course/2024版课程教学大纲-项目式课程阶段2.doc` | 课程目标与考核支撑 |
| `docs/hardware/Minisys硬件手册1.1.pdf` | Minisys 主板硬件资源 |
| `docs/hardware/EES329b功能测试20170817.pdf` | EES-329B 扩展板备用资料 |
| `docs/course/vivado.docx` | Vivado 2018.3 和 ModelSim 环境说明 |

后续如果要继续细化，应统一更新 README、设计文档和报告引用，避免路径漂移。

## 2. 设计文档路径

| 路径 | 计划内容 |
|---|---|
| `docs/design/项目B_vibecoding开发指南.md` | 已有总体开发指南 |
| `docs/design/guide_feasibility_review.md` | 本轮可行性检查与目标分级 |
| `docs/design/project_paths.md` | 仓库目录与文件路径规划 |
| `docs/design/architecture.md` | 系统总体架构，后续编写 |
| `docs/design/isa.md` | RV32I 子集与 MAC 指令编码，后续编写 |
| `docs/design/memory_map.md` | BRAM 与 memory-mapped I/O 地址规划，后续编写 |
| `docs/design/mac_extension.md` | MAC 指令设计与性能对比方案，后续编写 |
| `docs/design/performance.md` | CPI、周期、资源、PPA 记录，后续编写 |

## 3. AI 与规划日志路径

| 路径 | 计划内容 |
|---|---|
| `docs/ai_logs/ai_usage_log.md` | AI 使用记录总表，后续持续追加 |
| `docs/planning/round1_initial_plan.md` | 第一轮初步规划日志 |

## 4. RTL 源码路径

本轮不写代码，仅初始化目录。

| 路径 | 计划内容 |
|---|---|
| `src/core/` | CPU 核心模块 |
| `src/memory/` | 指令/数据存储器与总线 |
| `src/io/` | LED、拨码、数码管、UART 等 I/O |
| `src/soc/` | SoC 顶层集成 |
| `src/board/` | Minisys 顶层封装 |

## 5. 仿真与测试路径

| 路径 | 计划内容 |
|---|---|
| `sim/tb/` | testbench |
| `sim/programs/` | 汇编/机器码/初始化文件 |
| `sim/wave/` | 仿真波形输出，不建议提交大文件 |
| `tests/basic/` | 基础指令测试 |
| `tests/load_store/` | 访存测试 |
| `tests/branch/` | 分支跳转测试 |
| `tests/hazard/` | 流水线冒险测试 |
| `tests/mac/` | MAC 指令与点积测试 |

## 6. 约束、脚本与报告路径

| 路径 | 计划内容 |
|---|---|
| `constraints/minisys.xdc` | Minisys 官方约束文件，等待老师资料 |
| `scripts/` | Vivado/仿真/数据收集脚本 |
| `reports/figures/` | 架构图、波形图、上板照片 |
| `reports/tables/` | 性能和资源表 |
| `reports/vivado/` | utilization、timing 等 Vivado 报告 |
| `reports/final_report/` | 最终报告材料 |

## 7. 暂存与归档路径

| 路径 | 计划内容 |
|---|---|
| `archive/unrelated_boards/` | 与 Minisys 无关资料的归档位置 |

目前 TEC-PLUS、Nexys4DDR、EGO1 等资料已从工作树中删除或不再保留，不应再作为项目主线依据。
