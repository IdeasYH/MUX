# OMX 极简方案文档（Claude Code 版）

## 文档目的

这份文档不是把 oh-my-codex（OMX）原样搬到 Claude Code，而是把现有《omx极简方案文档.md》与《omx极简使用说明文档.md》里的**设计意图**，翻译成 Claude Code 原生可落地的最小方案。

目标保持不变：

- 保守瘦身
- 低冲突
- 低 token
- 默认安静
- 需要时再显式增强
- 保留多 agent 执行能力，但不把复杂编排变成默认常态

一句话总结：

**在 Claude Code 里，不再复刻 OMX runtime，而是用 `CLAUDE.md + .claude/settings.json + .claude/skills + .claude/agents + git worktree/多会话` 组合出一个更轻、更稳的执行骨架。**

---

## 一、先做对照分析：OMX 极简方案的本质是什么

结合仓库现有两份文档，OMX 极简方案真正保留的，不是某几个文件名，而是下面 4 个原则：

1. **普通对话尽量安静**
   - 不让系统在日常聊天里频繁自动分流、自动注入、自动展开 workflow。
2. **执行能力保留，但尽量显式触发**
   - 真要规划、执行、并行、多模型对照时再启用，不在所有请求上默认介入。
3. **把稳定规则和动态流程拆开**
   - 稳定规则放在常驻指令层；复杂流程按需加载，不做全量常驻。
4. **优先降低冲突面与 token 常驻负担**
   - 少一点全局 prompt、少一点常驻 runtime、少一点重复 surface。

这意味着：

- OMX 文档里强调的 `triage / explore routing / 常驻 MCP` 收紧，本质上是在减少“默认自动介入面”；
- 迁移到 Claude Code 后，也应该继续保留这个思想，而不是重新造一套更重的全局编排层。

---

## 二、Claude Code 与 OMX 的差异判断

Claude Code 原生就提供了几类能力：

- `CLAUDE.md`：共享项目记忆 / 团队规则
- `.claude/settings.json`：权限、环境、工具访问边界
- `.claude/skills/`：按需加载的可复用流程能力
- `.claude/agents/`：可委派的子 agent 角色
- `git worktree + 多个 Claude Code 会话`：并行隔离执行，可作为“agent teams”的实现基础

因此，Claude Code 版本的“极简方案”不需要复刻 OMX 的这些东西：

- 不需要再造一层大型 AGENTS 编排骨架
- 不需要默认常驻的复杂 prompt routing
- 不需要为了“planner -> team”先引入额外 runtime
- 不需要把每个 workflow 都做成默认自动入口

更适合 Claude Code 的做法是：

- **把长期稳定约束放进 `CLAUDE.md`**
- **把权限和边界放进 `.claude/settings.json`**
- **把高频、长流程、可复用的方法收进 `.claude/skills/`**
- **把少量稳定分工角色做成 `.claude/agents/`**
- **只有任务明显可并行时，才用 worktree + 多会话组成 agent teams**

---

## 三、OMX 概念到 Claude Code 的映射

| OMX 概念 | 在现有 OMX 文档里的作用 | Claude Code 对应面 | Claude Code 版极简建议 |
| --- | --- | --- | --- |
| `AGENTS.md` 主骨架 | 常驻总规则、执行风格、验证要求 | `CLAUDE.md` | 只保留稳定规则，不把大段运行时编排搬进去 |
| `config.toml` / runtime 开关 | 控制自动介入面、权限、MCP | `.claude/settings.json` | 只放权限、环境、必要边界，不堆太多行为策略 |
| OMX skills | 按需触发 workflow | `.claude/skills/` | 只保留高复用流程；避免把一次性流程做成 skill |
| specialist prompts / child roles | 专项 agent 分工 | `.claude/agents/` | 保留 2~4 个稳定角色即可，避免 agent 爆炸 |
| `planner -> team` | 先规划再并行执行 | 主会话规划 + 子 agent / worktree 多会话 | 先在主线程收敛计划，再在必要时并行 |
| `team` runtime | 多 worker 并行执行 | 多个 Claude Code 会话 + git worktree + 项目级 agents | 只在大任务启用，不作为默认路径 |
| `ralph` | 单 owner 持续执行直到完成 | 主线程连续执行，或固定 `executor`/`implementer` agent | 适合“单线程做到底”，不一定要多 agent |
| `ask claude / ask gemini` | 外部模型对照 | 可选 skill / slash command / 外部脚本桥接 | 不列入最小必备；需要时作为非核心扩展 |
| `omx_state / trace / wiki` | 持久状态、追踪、知识面 | `CLAUDE.md` 导入、git 历史、issue/PR、外部文档 | 不做 1:1 迁移，按仓库真实需要再补 |

### 关键判断

Claude Code 版的核心不是“复制 OMX 的每个组件”，而是：

**把 OMX 里“该常驻的少量信息”和“该按需调用的流程能力”彻底拆开。**

这正是低 token、低冲突的关键。

---

## 四、Claude Code 版的目标状态

执行后，仓库内的目标状态建议如下：

### 1）默认常驻层只保留两类东西

- `CLAUDE.md`
- `.claude/settings.json`

它们负责：

- 项目长期规则
- 最小权限边界
- 默认执行偏好
- 安全与验证底线

不负责：

- 大段操作手册
- 所有 workflow 说明
- 每种场景的详细 SOP
- 重型多 agent 编排脚本

### 2）按需增强层才放到 skills / agents

- `.claude/skills/`：长流程、低频但复用价值高的操作说明
- `.claude/agents/`：少量长期稳定的分工角色

### 3）并行层只在必要时启用

- `git worktree`
- 多个 Claude Code 会话
- 需要时再显式指定某些子 agent 负责子任务

也就是说：

**默认是单线程、轻指令、低干扰；只有在任务规模逼近多线程收益时，才升级到 agent teams。**

---

## 五、建议落地目录结构

```text
./CLAUDE.md
./.claude/settings.json
./.claude/skills/
  repo-workflow/
    SKILL.md
  release-checklist/
    SKILL.md
./.claude/agents/
  planner.md
  executor.md
  reviewer.md
```

保守版本甚至可以更小：

```text
./CLAUDE.md
./.claude/settings.json
./.claude/agents/
  executor.md
  reviewer.md
```

建议一开始不要超过：

- `1` 个 `CLAUDE.md`
- `1` 个共享 `settings.json`
- `0~2` 个 skills
- `2~3` 个 agents

这样最符合“极简方案”的初衷。

---

## 六、关键文件应该分别承担什么职责

### 1. `CLAUDE.md`：只放稳定、长期、团队共享的规则

建议放：

- 仓库目标与边界
- 代码风格和命名底线
- 修改前先读哪些文件
- 验证要求（lint / test / typecheck 的最低要求）
- 提交、PR、文档更新等长期约束
- 多 agent 使用原则（何时允许并行，何时不要并行）

不建议放：

- 每次都变的实施计划
- 过长的角色提示词
- 具体一次性任务背景
- 大量样例对话
- 可以拆成 skill 的长操作说明

#### 推荐写法

`CLAUDE.md` 应该像“仓库宪法”，而不是“运行时总控台”。

它只写长期稳定、团队共享、几乎每次都值得加载的内容。凡是低频、长篇、可按需调入的流程，优先移到 `.claude/skills/`，不要长期塞在启动记忆里。

### 2. `.claude/settings.json`：只管权限、环境、工具边界

建议放：

- `permissions.allow / ask / deny`
- 必需的 `env`
- 少量项目共享的工具访问边界
- 必要时的 hooks，但要极度克制

不建议放：

- 试图用 settings 复刻一整套 workflow 编排逻辑
- 大量默认自动执行命令
- 会频繁误触的 hooks
- 与项目无关的个人偏好

#### 推荐写法

`.claude/settings.json` 的任务不是“变聪明”，而是“变稳”。

它优先负责权限最小化、敏感路径隔离、共享环境收敛，而不是让 Claude 在默认情况下做更多事。极简方案里，settings 越像边界层，越不容易制造冲突。

### 3. `.claude/skills/`：承接长流程、复用型、非默认常驻的知识

适合做成 skill 的内容：

- 发版检查流程
- 特定子系统的 debug 手册
- 仓库特有的测试/构建流程
- 文档生成规范
- 外部模型对照流程（如果团队确实保留这类能力）

不适合做成 skill 的内容：

- 每次都要读的短规则
- 一次性任务说明
- 只执行一次就废弃的迁移脚本说明

#### 推荐写法

Skill 是 Claude Code 里最适合承接“原本会把 `AGENTS.md` 撑得很长的流程说明”的地方。

凡是你希望“需要时再加载，而不是每轮对话都常驻”的内容，都优先考虑放到 `.claude/skills/`。这一步直接决定 token 是否可控。

### 4. `.claude/agents/`：只保留少量稳定角色

建议初始只保留：

- `planner`：收敛方案、明确验收标准
- `executor`：实现与验证
- `reviewer`：质量/风险复核

如果仓库长期需要，再增加：

- `debugger`
- `test-engineer`

不建议：

- 一开始就创建十几个角色
- 按每个子目录建一个 agent
- 为一次性任务创建临时 agent 并长期保留

#### 推荐写法

Agent 的目标是稳定分工，不是角色收藏。

如果一个角色在连续多类任务里都能复用，再把它沉淀进 `.claude/agents/`；否则就让主线程直接做，或者把方法沉淀为 skill，而不是继续增加角色数量。

### 5. agent teams：对应 Claude Code 的最小实现方式

这里的 `agent teams` 建议理解为：

- 一个主会话负责收敛目标与集成结果
- 多个子会话在不同 git worktree 中并行执行
- 项目级 agents 负责稳定分工

也就是说，Claude Code 版的 team 不一定是“内建 runtime”，而是：

**主线程 + 子 agent + 多 worktree 会话** 的组合。

#### 推荐写法

只有在以下情况才升级为 agent teams：

- 任务明显可拆成 2 个以上相对独立子块
- 子块之间写入冲突可控
- 主线程能承担集成与最终验证
- 并行收益明显大于上下文同步成本

普通修复、小型重构、文档改动，默认不要起 team。

---

## 七、Claude Code 版极简方案的建议结构

如果要把这份方案真正落到仓库，建议文档结构按下面写。

### 建议目录

1. 文档目的
2. 设计目标
3. OMX → Claude Code 概念映射
4. 默认常驻层设计（`CLAUDE.md` / `settings.json`）
5. 按需增强层设计（skills / agents）
6. agent teams 的启用条件
7. 推荐最小目录结构
8. 迁移顺序
9. 不建议做的事
10. 一句话总结

---

## 八、可直接落地的关键段落草案

下面这些段落可以直接复用到正式仓库文档中。

### 段落 A：总原则

Claude Code 版极简方案的核心，不是复制 OMX runtime，而是保留 OMX 的设计目标：默认安静、边界清楚、流程按需加载、多 agent 只在必要时启用。所有长期稳定规则放入 `CLAUDE.md`，所有权限和环境约束放入 `.claude/settings.json`，所有长流程和可复用方法放入 `.claude/skills/`，所有稳定角色分工放入 `.claude/agents/`。除此之外，不再额外叠加一层重型常驻编排。

### 段落 B：`CLAUDE.md` 定位

`CLAUDE.md` 只承担项目级长期记忆，不承担运行时工作流总控。它应该足够短，让 Claude 每次启动都值得读；也应该足够稳，避免随着单次任务反复膨胀。凡是可以按需加载的长说明，优先迁移到 skills，而不是继续堆在 `CLAUDE.md` 中。

### 段落 C：`settings.json` 定位

`.claude/settings.json` 的目标是收紧边界，不是扩大默认自动化。极简方案下，settings 只保留最小必要权限、敏感路径屏蔽、团队共享环境变量与少量必要 hooks。任何可能显著增加误触、冲突或 token 消耗的默认行为，都不应放进共享 settings。

### 段落 D：skills 定位

skills 负责承接“很长、很有用、但不值得每次常驻”的方法论。一个流程只有在满足“复用频率高、内容较长、按需加载明显省 token”这三个条件时，才值得做成 skill。否则宁可留在普通文档里，也不要把 skill 体系做重。

### 段落 E：agents 定位

agents 负责稳定分工，而不是模拟组织架构。推荐只保留少数几个跨任务可复用角色，例如 planner、executor、reviewer。角色数量越多，自动选择越难稳定，指令冲突和维护成本也越高，这与极简目标相违背。

### 段落 F：agent teams 定位

agent teams 不是默认执行方式，而是任务规模达到阈值后的升级选项。默认路径仍应是主线程直接完成；只有在任务可以明确拆分、并行收益显著、且主线程能承担最终集成时，才使用多 worktree、多 Claude 会话、子 agent 协作的 team 形态。

---

## 九、推荐最小模板

### 1）`CLAUDE.md` 最小骨架

```md
# Project Rules

## Goals
- 默认优先最小改动
- 先验证再宣称完成
- 非必要不增加新依赖

## Working Style
- 先阅读相关文件，再修改
- 优先复用现有模式
- 小任务默认单线程完成
- 只有明确可拆分时才启用多 agent / 多 worktree

## Verification
- 修改代码后运行对应 lint / test / typecheck
- 修改文档时至少做格式与链接自检

## Safety
- 不读取或提交 secrets
- 涉及破坏性命令时先确认
```

### 2）`.claude/settings.json` 最小骨架

```json
{
  "permissions": {
    "allow": [
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(rg:*)",
      "Bash(git status:*)",
      "Bash(git diff:*)"
    ],
    "ask": [
      "Bash(git commit:*)",
      "Bash(npm test:*)",
      "Bash(pnpm test:*)",
      "Bash(pytest:*)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  }
}
```

### 3）`executor` agent 最小骨架

```md
---
name: executor
description: 实现功能、修复问题并完成验证；适用于已经明确范围的执行型任务
tools: Read, Edit, MultiEdit, Write, Bash, Grep, Glob
---

你是执行型 agent。

要求：
- 优先做最小正确改动
- 修改后必须验证
- 若任务可直接完成，不要过度规划
- 遇到共享文件冲突时，先报告再扩写范围
```

### 4）`repo-workflow` skill 最小骨架

```md
---
name: repo-workflow
description: 当任务涉及本仓库标准执行流程、验证步骤或提交流程时使用
---

先确认改动范围，再按以下顺序执行：
1. 阅读相关文件
2. 做最小修改
3. 运行对应验证
4. 汇总变更与风险
```

---

## 十、推荐迁移顺序

### 第一步：先收敛 `CLAUDE.md`

把现有 OMX 文档里真正长期稳定的部分抽出来，只留下：

- 默认执行风格
- 安全边界
- 验证要求
- 多 agent 何时启用

### 第二步：再补 `.claude/settings.json`

只配置：

- 权限 allow / ask / deny
- 必要 env
- 少量共享边界

### 第三步：最后再决定要不要建 skills / agents

判断标准：

- 如果是高频长流程，建 skill
- 如果是稳定分工，建 agent
- 如果只是一次性任务，不建任何新抽象

### 第四步：把 team 能力留作升级层

只有当任务长期需要并行执行时，才把：

- git worktree
- 多 Claude 会话
- 项目 agents

组合成 agent teams。

---

## 十一、明确不建议做的事

以下动作不符合 Claude Code 版极简方案：

- 把现有大型 `AGENTS.md` 原封不动复制到 `CLAUDE.md`
- 一开始就创建大量 `.claude/agents/`
- 把所有文档流程都做成 skills
- 用 hooks 或 settings 复刻复杂自动路由
- 小任务默认启用多 agent
- 为了追求“功能齐全”而牺牲常驻上下文长度

---

## 十二、一句话结论

Claude Code 版的 OMX 极简方案，不是“把 OMX 重新实现一遍”，而是：

**用最少的常驻记忆、最薄的权限配置、最少量的可复用 skill/agent，保留需要时才升级到多 agent 的执行能力。**

---

## 参考资料（Claude Code 官方）

- Claude Code Memory / `CLAUDE.md`：<https://docs.anthropic.com/en/docs/claude-code/memory>
- Claude Code Settings / `.claude/settings.json`：<https://docs.anthropic.com/en/docs/claude-code/settings>
- Claude Code Subagents / `.claude/agents/`：<https://docs.anthropic.com/en/docs/claude-code/sub-agents>
- Claude Code Common Workflows（含 git worktree 并行会话）：<https://docs.anthropic.com/en/docs/claude-code/common-workflows>
- Claude Code Agent Skills / `.claude/skills/`：<https://docs.claude.com/en/docs/claude-code/skills>

> 注：本文将“agent teams”解释为 Claude Code 中基于子 agent、git worktree 与多会话并行的团队化工作方式，而不是要求额外复刻 OMX 的 team runtime。
