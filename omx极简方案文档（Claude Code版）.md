# OMX 极简方案文档（Claude Code 版）

## 文档目的

这份文档不是把 oh-my-codex（OMX）机械搬到 Claude Code，而是把 **OMX 想保留的核心工作方式**，映射到 Claude Code 已有的最小能力面上。

目标只有四个：

- 保留“需要时再介入”的保守风格
- 保留可显式调用的规划、执行、分工能力
- 降低提示词冲突与上下文噪音
- 把长期常驻 token 压到尽量低

这是一份**面向 Claude Code 落地**的极简草案，因此会先做对照分析，再给出建议结构与关键段落。

---

## 一、对照分析：OMX 在做什么，Claude Code 应该怎么接

### 1.1 OMX 极简方案真正要保留的，不是整个 runtime，而是三类能力

对照《omx极简方案文档.md》与《omx极简使用说明文档.md》，OMX 极简版真正想保留的是：

1. **默认安静**：普通对话少被工作流自动打断
2. **显式触发**：需要规划、执行、多人协作时再点名
3. **执行骨架**：保留 planner / team / ralph / ask 这一类稳定入口

换句话说，OMX 极简版并不是追求“功能越多越好”，而是追求：

- 自动介入面尽量小
- 显式入口尽量清楚
- 协作能力够用但不堆 runtime

这个目标与 Claude Code 是兼容的，但映射方式不能照搬。

### 1.2 Claude Code 里可以直接承接这些能力的原生面

根据 Claude Code 官方文档，Claude Code 已经有几类足够接近的原生能力：

- `CLAUDE.md`：承接项目级长期指令、工作约定、输出约束、导入其他文档
- `.claude/settings.json`：承接权限、工具、hooks、项目级行为开关
- `.claude/commands/`：承接显式调用的命令入口，适合替代一部分 OMX skill 触发面
- `.claude/agents/`：承接子代理/专项代理定义，适合替代一部分 OMX agent prompt
- Task / subagents：承接“把某段独立工作交给子代理并行处理”的执行方式

这意味着：**Claude Code 不缺能力面，缺的是一套更克制的组织方式。**

### 1.3 核心映射表

| OMX 概念 | OMX 中的作用 | Claude Code 对应面 | 映射方式 | 说明 |
| --- | --- | --- | --- | --- |
| `AGENTS.md` / 大段系统约束 | 统一工作总约束 | `CLAUDE.md` | 直接映射 | 但应拆小并用 imports，避免一个超长总控文件长期常驻 |
| `config.toml` / `.omx-config.json` | 开关自动路由、MCP、环境行为 | `.claude/settings.json` | 直接映射 | 把默认行为收紧，减少自动注入与噪音 |
| OMX skills | 显式触发 workflow | `.claude/commands/` + 项目内技能文档 | 部分映射 | Claude Code 原生更像 commands，不是 OMX 那种 runtime skill |
| OMX prompts / agents | 不同角色执行面 | `.claude/agents/` | 直接映射 | 适合 planner / executor / reviewer 这类稳定角色 |
| `team` | 多 agent 分工协作 | subagents + agent 组合 | 近似映射 | Claude Code 没有 OMX 那种完整 team runtime 时，建议用“协调者 + 专项子代理”近似实现 |
| `ralph` | 单 owner 持续推进直到完成 | 单主代理 + 明确 completion checklist | 近似映射 | 更适合写成命令约束或 `CLAUDE.md` 工作约定 |
| `ask claude` / `ask gemini` | 外部模型补充视角 | Claude Code 子代理 / 外部工具链 | 非一比一映射 | 如需多模型对照，建议做成显式命令，不要默认常驻 |
| hooks / 自动路由 | 对用户输入自动分流 | hooks + commands + `CLAUDE.md` 约束 | 谨慎映射 | Claude Code 里也应少用自动分流，优先显式命令 |

### 1.4 需要特别说明的两个差异

#### 差异 A：`.claude/skills/` 不是 Claude Code 的强原生中心面

Claude Code 原生更稳定的显式入口是：

- `CLAUDE.md`
- `.claude/commands/`
- `.claude/agents/`
- `.claude/settings.json`

因此，如果仓库仍想保留“skills”这个概念，**更稳的做法是把 `.claude/skills/` 当成项目约定目录，而不是把它当成 Claude Code 官方唯一入口**。

推荐定义：

- `.claude/skills/` 只存放短小、可复用、默认不自动注入的技能片段
- 真正触发时，通过 `.claude/commands/` 或 `.claude/agents/` 去引用这些片段
- 不让 `.claude/skills/` 本身变成新的隐性全局提示层

这样既能保留 OMX “显式 skill” 的组织习惯，又不会和 Claude Code 的原生面冲突。

#### 差异 B：Claude Code 没有必要复制 OMX 的整套 team runtime

OMX 的 `team` 很强，但也更重。Claude Code 若要走极简路线，不应该先复制一整套 runtime，而应该优先采用：

- 一个总协调入口
- 少量固定角色 agent
- 需要时才开的 subagent 并行
- 明确的完成标准与回传格式

也就是说，**Claude Code 版极简方案保留“团队协作能力”，但不保留“重量级 team runtime 负担”。**

---

## 二、Claude Code 版的目标状态

落地后的目标状态建议如下。

### 2.1 默认状态：安静、短、少冲突

默认情况下：

- 普通问答走 Claude Code 基础对话路径
- 不因为模糊措辞就自动切换复杂 workflow
- 不把大量技能说明、角色说明、团队说明常驻注入每一轮上下文

一句话概括：

**平时少加载，明确点名再展开。**

### 2.2 显式触发：用 commands 和 agents 替代大面积自动路由

推荐只保留少数几个高价值显式入口，例如：

- 规划类：`/plan`、`/ralplan`
- 执行类：`/execute`、`/team-exec`
- 复核类：`/review`、`/verify`
- 协作类：调用特定 subagent / agent

原则是：

- **默认不用自动猜**
- **需要工作流时再明确触发**
- **入口少而稳定，不要铺满一堆半自动技能**

### 2.3 长期上下文：只保留最小公共约束

`CLAUDE.md` 里只保留这些长期有效、跨任务稳定的内容：

- 仓库目标与边界
- 代码风格与修改原则
- 验证要求
- 什么情况下允许调用 subagent
- 输出格式要求

不要把下列内容长期放进主文件：

- 大量一次性 workflow 细节
- 各类长篇角色提示词
- 低频技能说明全集
- 可放到独立文档的长清单

Claude Code 官方支持从 `CLAUDE.md` 导入其他 Markdown 文件，因此极简方案应优先采用：

- `CLAUDE.md` 做总纲
- 低频细节放到被导入的分文件
- 只有确实稳定、确实常用的约束才进入主干

### 2.4 团队协作：保留能力，不保留重量

如果需要类似 OMX `team` 的效果，Claude Code 版建议保留以下最小骨架：

- 一个协调者 agent
- 两到四个稳定角色 agent（如 planner / executor / reviewer / verifier）
- 一条统一的任务拆分与回传格式
- 明确的“何时并行、何时串行”约定

不建议上来就做：

- 复杂 mailbox
- 大量状态文件
- 重型自动调度
- 默认常驻的多 agent runtime

保守版目标不是“复制 OMX”，而是“保留足够用的协作骨架”。

---

## 三、建议目录结构（Claude Code 版）

下面是一套更适合保守落地的目录结构。

```text
CLAUDE.md
.claude/
  settings.json
  commands/
    plan.md
    team-exec.md
    verify.md
  agents/
    planner.md
    executor.md
    reviewer.md
    verifier.md
  skills/
    plan-checklist.md
    execution-checklist.md
    review-checklist.md
  docs/
    collaboration-rules.md
    verification-rules.md
```

### 结构说明

#### `CLAUDE.md`

作用：

- 项目总约束
- 默认行为边界
- 导入低频细则
- 定义“默认安静、显式触发”的总原则

#### `.claude/settings.json`

作用：

- 权限收敛
- hooks 开关
- 工具行为限制
- 项目级运行习惯

这里应该承接 OMX 里“关闭多余自动介入面”的思想。

#### `.claude/commands/`

作用：

- 承接显式工作流入口
- 替代一大块“靠自然语言模糊触发”的技能入口
- 保持低歧义、低冲突

这是 Claude Code 版极简方案的关键入口层。

#### `.claude/agents/`

作用：

- 承接稳定角色
- 给复杂任务提供清楚的职责边界
- 用最小角色集支持并行与复核

这里更适合放长期稳定角色，不适合堆几十个一次性 agent。

#### `.claude/skills/`

作用：

- 作为**项目自定义约定层**保存复用片段
- 不默认常驻，不直接承担主入口职责
- 供 commands / agents 引用

这能保留 OMX 的“skill 资产组织习惯”，但避免把它做成新的全局噪音源。

---

## 四、建议的保守落地原则

### 原则 1：默认安静优先于自动聪明

如果一个能力必须靠大量自动判断、自动注入、自动分流才显得“好用”，那它就不适合放进极简主干。

Claude Code 版应该优先追求：

- 少判断
- 少自动切换
- 少常驻说明
- 少跨层冲突

而不是追求“用户一说得模糊，系统也能猜对很多事”。

### 原则 2：显式入口优先于隐式路由

保留能力时，优先顺序建议是：

1. 明确命令
2. 明确 agent
3. 明确 checklist
4. 最后才考虑自动 hooks

也就是说，能靠 `/plan` 解决的，不要先做隐式路由；能靠 `planner agent` 解决的，不要先做复杂 team runtime。

### 原则 3：少量固定角色优先于大规模角色库

建议先固定四类角色就够了：

- planner
- executor
- reviewer
- verifier

只有在仓库长期反复需要某类专职能力时，才新增 agent。

### 原则 4：把 token 花在任务上，不是花在框架自述上

极简方案下最应该避免的是：

- 每轮都加载很长的工作流说明
- 一个任务还没开始，先注入大量角色 catalog
- skill / agent / command 三套文案重复表达同一件事

推荐做法：

- 总纲只写一次
- 低频细则放独立文档
- commands 与 agents 只保留最小必要说明
- 同一约束只保留一个权威来源

---

## 五、可直接落地的关键段落

下面这些段落可以直接作为仓库文档草案或 `CLAUDE.md` / `.claude` 配套文案基础。

### 5.1 总体定位段

> 本仓库对 Claude Code 采用保守极简方案：默认保持安静，普通对话不自动升级为复杂工作流；只有在显式调用 command、agent 或明确要求并行协作时，才展开额外执行骨架。目标是减少 token 常驻消耗、降低提示层冲突，并保留必要的规划、执行、复核能力。

### 5.2 `CLAUDE.md` 总原则段

> `CLAUDE.md` 只保存跨任务稳定、长期有效的项目规则；低频流程、专项技能、角色细则应拆到独立文档，由显式命令或 agent 在需要时再引用。不要把一次性需求、低频 workflow 或冗长角色说明长期放入全局上下文。

### 5.3 `.claude/settings.json` 设计段

> `.claude/settings.json` 只负责项目级行为收敛，不承担大段流程说明。配置目标是“减少默认自动介入”，而不是“把所有能力都做成自动触发”。hooks、权限与工具行为应以保守、低冲突、可预测为优先原则。

### 5.4 `.claude/skills/` 定位段

> `.claude/skills/` 在本仓库中是自定义约定层，不视为 Claude Code 的默认全局入口。该目录只存放可复用、短小、非自动注入的技能片段，供 `.claude/commands/` 或 `.claude/agents/` 按需引用。新增 skill 时，优先检查是否已能由现有 command、agent 或共享规则覆盖，避免重复造层。

### 5.5 `.claude/agents/` 定位段

> `.claude/agents/` 只保留少量长期稳定角色，例如 planner、executor、reviewer、verifier。agent 的职责应边界清晰、输出格式明确、默认不争抢主流程控制权。若任务不需要并行或专项视角，优先由主代理直接完成，而不是为了“像 team”而强行拆分。

### 5.6 agent teams 映射段

> Claude Code 版的“agent teams”不追求复制 OMX team runtime，而采用更轻的组织方式：由主代理负责拆分任务、选择是否启用子代理、收敛结果并统一验证；子代理只处理边界清楚、可并行、可验证的小块工作。没有必要为普通任务长期维持复杂调度层。

### 5.7 显式触发段

> 本仓库默认推荐显式触发：需要规划时使用 `/plan`，需要多人分工时使用 `/team-exec` 或指定 agent，需复核时使用 `/verify` 或 reviewer/verifier agent。普通讨论、普通问答、普通代码解释不默认切换到复杂工作流。

---

## 六、推荐的最小命令面

如果要把 OMX 的使用体验迁移到 Claude Code，建议先只落这几个入口：

- `/plan`：输出短计划、风险、验证路径
- `/team-exec`：在需要时启用“协调者 + 子代理”模式
- `/verify`：执行收尾检查、列出证据、明确剩余风险

这样已经足够覆盖 OMX 极简版最核心的三段：

- 先规划
- 再执行
- 最后验证

而且比把大量 skill 全部搬过来更省 token、更低冲突。

---

## 七、推荐的最小 agent 面

建议先只保留四个 agent：

- `planner`
- `executor`
- `reviewer`
- `verifier`

对应关系如下：

- `planner`：近似承接 OMX 的 plan / ralplan 思路
- `executor`：近似承接单线落实与主实施工作
- `reviewer`：近似承接代码或文档复核
- `verifier`：近似承接完成证据、收尾验证、验收判断

如果后续真的存在高频专项任务，再考虑增加如 `debugger`、`security-reviewer`、`writer` 这类角色。

---

## 八、推荐验收标准

Claude Code 版极简方案落地后，建议用下面标准判断是否成功。

### 必须满足

- 普通问答时，不会被长篇工作流说明持续干扰
- 需要工作流时，可以通过显式 command 或 agent 进入
- `CLAUDE.md` 维持短总纲，不堆大型说明全集
- `.claude/agents/` 数量克制、角色边界清楚
- `.claude/skills/` 不成为新的隐式全局层
- 团队协作能力可以按需开启，而不是默认常驻

### 最好满足

- 新增一个 workflow 时，优先新增 command 或 agent，而不是扩大全局提示
- 同一规则只保留一个权威来源
- 每个 command / agent 都能说清“何时用、何时不用、输出什么”

---

## 九、明确不建议做的事

以下动作不符合保守极简方向：

- 把 OMX 的整套 runtime 文件、状态机、自动路由一比一照搬进 Claude Code
- 把大量角色提示词全部塞进 `CLAUDE.md`
- 把 `.claude/skills/` 做成新的隐式常驻总入口
- 为了模拟 team 而默认启用复杂多 agent 调度
- command、agent、skill 三层重复写同一套规则

Claude Code 版真正该做的是：**保留结构，不复制重量。**

---

## 十、一句话总结

Claude Code 版的 OMX 极简方案，本质上不是“把 OMX 迁移过来”，而是：

**用 `CLAUDE.md`、`.claude/settings.json`、`.claude/commands/`、`.claude/agents/` 和按需 subagents，重建一套更轻、更静、更显式的执行骨架。**

---

## 参考依据（官方文档）

- Claude Code memory / `CLAUDE.md`：<https://docs.anthropic.com/en/docs/claude-code/memory>
- Claude Code settings：<https://docs.anthropic.com/en/docs/claude-code/settings>
- Claude Code slash commands：<https://docs.anthropic.com/en/docs/claude-code/slash-commands>
- Claude Code subagents：<https://docs.anthropic.com/en/docs/claude-code/sub-agents>

说明：

- 上述“`CLAUDE.md`、`.claude/settings.json`、`.claude/agents/`”属于 Claude Code 官方能力面。
- 上述“`.claude/skills/` 作为项目技能目录”是本文给出的**仓库级组织建议**，不是 Claude Code 官方唯一原生约定。
- “agent teams”在本文中指的是通过主代理 + subagents 组合出来的轻量协作方式，这部分属于**基于官方能力面的保守推导**，不是对 OMX team runtime 的一比一复制。
