# OMX 极简使用说明文档

## 文档目的

这份文档说明瘦身后的 OMX 应该怎么使用，重点是：

- 你还能正常用哪些能力
- 普通对话现在会发生什么
- 什么时候会触发 OMX
- 什么时候不会触发
- 怎样用才最省 token、最不容易和其他插件冲突

这份文档针对的是**已经完成保守瘦身后的环境**。

## 现在的 OMX 是什么状态

当前环境已经做了保守瘦身，结论可以直接记成一句话：

**OMX 还在，但默认变安静了。**

你真正保留下来的核心能力是：

- `planner -> team`
- `team`
- `ralph`
- `ask claude`
- `ask gemini`

普通对话里被关掉的自动介入面是：

- `triage`
- `explore routing`

同时，非核心 MCP 已关闭：

- `omx_memory`
- `omx_trace`
- `omx_wiki`

保留下来的基础骨架是：

- `codex_hooks`
- `omx_state`
- `omx_code_intel`

## 你现在应该怎么理解它

瘦身前：

- 普通聊天更容易被 OMX 自动分析、自动引导、自动插入额外 workflow 倾向

瘦身后：

- 普通聊天大多只会走基础 Codex 对话路径
- 只有你明确碰到保留关键词，OMX 才会明显介入

最重要的变化不是“功能少了”，而是：

- 自动打扰少了
- token 浪费少了
- 和其他插件打架的概率更低了

## 现在还会自动触发什么

默认仍可能自然语言触发的 OMX 面，只保留：

- `team`
- `ralph`
- `ask claude`
- `ask gemini`

可以这样理解：

- 你说“用 team 做这个任务”
- 你说“ralph 继续做到底”
- 你说“ask claude 帮我看一下”
- 你说“ask gemini 帮我分析一下”

这些仍然属于保留入口。

## 现在不会再自动介入什么

普通聊天里，不会再自动因为语气或任务形状而触发这些额外引导：

- triage 自动分类
- explore 默认引导
- memory / trace / wiki 这类常驻增强面

这意味着：

- 你随便问一个问题，OMX 不会像之前那样更积极地判断“你是不是要 plan / analyze / execute / explore”
- 你做普通闲聊、普通提问、普通代码讨论时，被额外塞上下文的概率明显下降

## 现在如何使用保留能力

### 用 team

适合：

- 任务比较大
- 需要多 agent 并行执行
- 需要任务拆分、持续跟踪、分工落地

推荐说法：

- `用 team 做这个任务`
- `team 继续按照计划执行`
- `把这个计划交给 team 落地`

适合场景：

- 多文件改动
- 复杂重构
- 要分多个 worker 协作
- 你已经有计划文档，想直接执行

### 用 ralph

适合：

- 想让单个执行链路一直做到底
- 不想自己频繁手动催促
- 想让同一个执行 owner 持续修复、验证、收尾

推荐说法：

- `ralph 继续做到底`
- `用 ralph 把这个问题彻底解决`
- `ralph 持续修到验证通过`

适合场景：

- 单一问题持续修复
- 一轮轮测试直到通过
- 一条线做完，不想切换太多上下文

### 用 ask claude / ask gemini

适合：

- 想拿额外模型做对照判断
- 想让另一个模型补充思路
- 想让外部模型对方案做二次评估

推荐说法：

- `ask claude 看一下这个方案`
- `ask gemini 帮我分析这个问题`

适合场景：

- 技术选型对照
- 复杂问题二次验证
- 需要不同模型视角

## 其他功能现在怎么用

其他 OMX workflow 不是不能用，而是建议你**显式调用**。

例如：

- `$plan`
- `$ralplan`
- `$analyze`
- `$code-review`
- `$security-review`

这样做的好处是：

- 你知道自己在触发什么
- 不会误触
- token 更可控
- 和其他插件的边界更清楚

## 最推荐的使用方式

### 场景一：普通聊天

直接正常说。

例如：

- 解释这段代码
- 这个报错是什么意思
- 这里应该怎么设计

这类情况现在通常不会被 OMX 额外强干预。

### 场景二：你已经想让 OMX 介入

直接明确点名。

例如：

- `用 team 做`
- `ralph 继续`
- `ask claude`
- `$plan`

原则很简单：

- 普通对话就普通说
- 真想启用某个 workflow，就明确说

## 最省 token 的日常习惯

推荐这样用：

1. 普通问题直接正常问
2. 只有需要执行工作流时再点名 `team / ralph / ask`
3. 其他 skill 尽量用显式 `$skill`
4. 不要在普通问题里混入太多 workflow 名词
5. 如果你只是想聊天或讨论，尽量不要顺口带上 `team`、`ralph`、`ask`

这样可以最大化瘦身收益。

## 和其他插件一起用时怎么避免冲突

你之前担心的是像 `superpowers` 这样的插件和 OMX 抢路由。瘦身后已经好很多，但仍建议这样用。

### 建议一：把 OMX 当成“执行层”

推荐分工：

- `superpowers` 这类插件负责提问、澄清、发散、结构化思考
- OMX 负责明确执行：
  - `team`
  - `ralph`
  - `ask`

一句话：

- 想思考，用别的插件
- 想执行，用 OMX

### 建议二：避免同一句里混太多插件意图

不推荐：

- 一句话里同时要求苏格拉底提问、再 plan、再 team、再 code review

推荐：

1. 先澄清需求
2. 再单独说：
   - `用 team 落地`
   - `ralph 继续修`

### 建议三：用明确动词，不用模糊暗示

推荐：

- `用 team 执行`
- `ralph 接手`
- `ask claude`

不推荐：

- `你看看是不是应该 team 一下`
- `我想要不要 maybe 用 ralph`

越明确，越不容易和别的提示层抢方向。

## 现在的 warning 怎么理解

你运行 `omx doctor` 还会看到几个 warning，这里解释一下。

### `Explore routing: disabled`

这是正常的。

说明：

- 我们就是故意把它关掉的
- 这不是故障，是极简方案生效的证据

### `Prompt triage: disabled`

这也是正常的。

说明：

- 我们就是故意把 triage 关掉
- 这样普通聊天更安静

### `Explore Harness` 未装 Rust

这和你当前保留的核心能力无直接冲突。

只有当你未来明确想深用 `omx explore` 对应能力时，才需要再处理。

## 如果你感觉 OMX 又“变吵了”，先检查什么

先按这个顺序排查：

1. 检查 `/home/trys/.codex/config.toml`
   - 是否还保留：
   - `USE_OMX_EXPLORE_CMD = "0"`
2. 检查 `/home/trys/.codex/.omx-config.json`
   - `promptRouting.triage.enabled` 是否还是 `false`
3. 跑一次：
   - `omx doctor`
4. 检查是否又出现了 `~/.agents/skills`
5. 检查是否被 `omx setup --force` 覆盖了配置

## 如果你以后要升级到更激进的极简模式

下一步才考虑这些：

- 继续精简 `AGENTS.md`
- 继续精简 `developer_instructions`
- 把 `ask` 也改成只允许显式触发
- 重新评估是否还要保留 `omx_code_intel`

在当前阶段，不建议再往下砍。

## 日常最佳实践

推荐你之后这样用：

### 普通对话

直接聊，不点 workflow。

### 需要规划

显式用：

- `$plan`
- `$ralplan`

### 需要执行

显式用：

- `team`
- `ralph`

### 需要外部模型参考

显式用：

- `ask claude`
- `ask gemini`

这就是瘦身后最稳定、最省 token 的使用方式。

## 故障边界

如果出现下面任何一种情况，说明极简配置可能被破坏了：

- `team` 明确点名后不再工作
- `ralph` 明确点名后不再工作
- `ask claude` 或 `ask gemini` 明确点名后不再工作
- 普通聊天又开始被明显 workflow 化
- `omx doctor` 出现 `failed`

一旦出现这些情况，先不要继续改动，先做配置核对和回滚。

## 一句话总结

瘦身后的 OMX 最适合这样理解：

**平时少说话，需要时再出手；明确点名就执行，不点名就尽量别介入。**
