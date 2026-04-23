# OMX 极简方案文档

## 文档目的

这份文档给后续 agent 复用，目标是在**不破坏核心能力**的前提下，对 oh-my-codex 进行一轮保守、可回滚、安全的瘦身。

本方案的核心要求不是“删得越多越好”，而是：

- 保留 `planner -> team` 的执行链路
- 保留 `team`
- 保留 `ralph`
- 保留 `ask claude` / `ask gemini`
- 让普通对话尽量少被 OMX 自动介入
- 降低 token 消耗
- 降低和其他插件的提示词冲突概率

这是一份**可重复执行**的方案说明，不绑定单次会话。

## 适用范围

适用于：

- 已安装 oh-my-codex
- 主要想保留多 agent 执行能力
- 不想让普通聊天被过多自动 workflow 路由
- 可以接受显式 `$skill` 触发非核心 workflow

不适用于：

- 想彻底删除 OMX
- 想把所有 skill 都保留自动触发
- 想做激进精简，例如删除 `codex_hooks`、删除 `team` runtime、删除 `omx_state`

## 方案等级

本文采用的是 `A 保守瘦身`。

原则：

- 优先改配置，不优先改源码
- 优先关闭“自动介入面”，不优先删功能本体
- 优先保留执行骨架，不优先删除工具目录
- 所有动作必须可验证、可回滚

## 需要保留的能力

保留以下能力：

- `planner -> team`
- `team`
- `ralph`
- `ask claude`
- `ask gemini`
- `codex_hooks`
- `omx_state`
- `omx_code_intel`

说明：

- `omx_state` 是 runtime 状态骨架，保留更稳
- `omx_code_intel` 保留可避免部分代码分析体验下降
- `codex_hooks` 不能关，否则保留的自动入口也会一起受影响

## 需要关闭或收紧的能力

关闭或收紧以下面：

- 关闭 `triage` 自动提示路由
- 关闭 `explore routing` 自动引导
- 关闭非核心 MCP：
  - `omx_memory`
  - `omx_trace`
  - `omx_wiki`
- 清理历史遗留 skill 根目录 `~/.agents/skills`

说明：

- `triage` 会对普通自然语言做 advisory 路由，容易带来额外提示词注入
- `explore routing` 会对查找类请求增加默认引导
- `memory/trace/wiki` 不是你当前核心链路的必要常驻面
- 历史 skill 根目录会增加重复 surface 和潜在冲突

## 当前目标状态

执行后应达到以下状态：

### 自动保留的 OMX 面

- `team`
- `ralph`
- `ask claude`
- `ask gemini`

### 非自动保留的 OMX 面

以下能力仍可用，但要求显式触发，例如 `$skill`：

- `autopilot`
- `autoresearch`
- `plan`
- `ralplan`
- `ultrawork`
- `ultraqa`
- `wiki`
- `code-review`
- `security-review`
- 其他未被保留为自然语言入口的 skill

### 关闭的自动介入面

- `triage`
- `explore routing`

### 关闭的 MCP

- `omx_memory = false`
- `omx_trace = false`
- `omx_wiki = false`

### 保留的 MCP

- `omx_state = true`
- `omx_code_intel = true`

## 执行前检查

执行前先做这些检查：

1. 读取当前配置：
   - `/home/trys/.codex/config.toml`
   - `/home/trys/.codex/.omx-config.json` 是否存在
2. 运行一次：
   - `omx doctor`
3. 检查历史 skill 根目录是否存在：
   - `ls -ld /home/trys/.agents /home/trys/.agents/skills`
4. 检查当前安装版关键词行为：
   - `/home/trys/.npm-global/lib/node_modules/oh-my-codex/dist/hooks/keyword-registry.js`
5. 记录当前状态，便于回滚

## 实施步骤

### 第一步：关闭 triage

目标文件：

- `/home/trys/.codex/.omx-config.json`

目标内容：

```json
{
  "promptRouting": {
    "triage": {
      "enabled": false
    }
  }
}
```

说明：

- 这是关闭普通自然语言 advisory 路由的关键配置
- 这是优先级最高的瘦身动作之一

### 第二步：关闭 explore routing

目标文件：

- `/home/trys/.codex/config.toml`

关键配置：

```toml
[env]
USE_OMX_EXPLORE_CMD = "0"
```

注意：

- 这一版 OMX 的 `explore routing` 是**默认开启，显式 opt-out**
- 仅仅删除这一行是不够的
- 必须明确写成 `"0"`、`"false"`、`"off"` 一类关闭值

### 第三步：关闭非核心 MCP

目标文件：

- `/home/trys/.codex/config.toml`

目标状态：

```toml
[mcp_servers.omx_memory]
enabled = false

[mcp_servers.omx_trace]
enabled = false

[mcp_servers.omx_wiki]
enabled = false

[mcp_servers.omx_state]
enabled = true

[mcp_servers.omx_code_intel]
enabled = true
```

说明：

- 保留 `state` 和 `code_intel`
- 关闭 `memory/trace/wiki`
- 不建议在保守瘦身阶段关闭 `omx_state`

### 第四步：检查自然语言自动入口

检查文件：

- `/home/trys/.npm-global/lib/node_modules/oh-my-codex/dist/hooks/keyword-registry.js`

验收目标：

- 允许保留的自然语言入口：
  - `team`
  - `ralph`
  - `ask claude`
  - `ask gemini`
- 其他 workflow 只保留 `$skill` 触发，不保留普通自然语言入口

执行原则：

- 如果安装版当前已经满足这个目标，不要多做源码改动
- 只有当安装版实际存在额外普通自然语言入口时，才做最小修补

### 第五步：归档历史 skill 根目录

目标目录：

- `/home/trys/.agents/skills`

推荐动作：

- 不直接删除
- 采用带时间戳的归档改名

示例：

```bash
ts=$(date +%Y%m%d-%H%M%S)
mv /home/trys/.agents/skills "/home/trys/.agents/skills.archived-$ts"
```

说明：

- 这是最稳的处理方式
- 可以去掉 doctor 的 legacy warning
- 不会像直接删除那样增加恢复成本

## 当前已落地的实际配置

本仓库对应环境当前已落地的状态如下。

### 配置文件

- `/home/trys/.codex/config.toml`
- `/home/trys/.codex/.omx-config.json`

### 关键配置值

```toml
[features]
codex_hooks = true

[env]
USE_OMX_EXPLORE_CMD = "0"

[mcp_servers.omx_state]
enabled = true

[mcp_servers.omx_memory]
enabled = false

[mcp_servers.omx_code_intel]
enabled = true

[mcp_servers.omx_trace]
enabled = false

[mcp_servers.omx_wiki]
enabled = false
```

```json
{
  "promptRouting": {
    "triage": {
      "enabled": false
    }
  }
}
```

### 历史 skill 根目录处理结果

当前历史目录已归档为：

- `/home/trys/.agents/skills.archived-20260423-143430`

## 验收步骤

执行以下检查：

1. 查看配置：
   - `sed -n '1,140p' /home/trys/.codex/config.toml`
   - `cat /home/trys/.codex/.omx-config.json`
2. 运行：
   - `omx doctor`
3. 验收 doctor 结果：
   - `0 failed`
   - `Legacy skill roots` warning 消失
4. 检查自然语言入口：
   - 查看 `keyword-registry.js`
   - 确认保留入口仅为 `team / ralph / ask`
5. 在实际使用中验证：
   - 普通聊天不应再被 triage / explore 自动引导
   - `team`、`ralph`、`ask claude`、`ask gemini` 仍然可用

## 推荐验收结果

推荐最终结果应类似：

- `omx doctor` 为 `11 passed / 3 warnings / 0 failed`
- 可接受 warning：
  - `Explore Harness` 未装 Rust
  - `Explore routing` 被显式关闭
  - `Prompt triage` 被显式关闭

说明：

- 这里的 `Explore routing` 和 `Prompt triage` warning 是**期望结果**
- 它们不是故障，而是说明瘦身配置生效

## 回滚方案

如果需要回滚，按下面顺序处理。

### 回滚 triage

删除或改回：

- `/home/trys/.codex/.omx-config.json`

可选改为：

```json
{
  "promptRouting": {
    "triage": {
      "enabled": true
    }
  }
}
```

### 回滚 explore routing

修改：

- `/home/trys/.codex/config.toml`

改回：

```toml
[env]
USE_OMX_EXPLORE_CMD = "1"
```

### 回滚 MCP

将以下项改回：

- `omx_memory.enabled = true`
- `omx_trace.enabled = true`
- `omx_wiki.enabled = true`

### 回滚历史 skill 根目录

如果确认某些旧环境仍依赖旧路径：

```bash
mv /home/trys/.agents/skills.archived-时间戳 /home/trys/.agents/skills
```

## 明确不要做的事

以下动作不属于保守瘦身，不建议在本方案中执行：

- 关闭 `codex_hooks`
- 删除 `team` skill
- 删除 `ralph` skill
- 删除 `ask-claude` 或 `ask-gemini`
- 删除 `omx_state`
- 直接大改 installed runtime 源码
- 在没有验证前大规模删除 `~/.codex/skills`
- 把 AGENTS 主骨架整体清空

## 给后续 agent 的执行准则

后续 agent 如果复用本方案，必须遵守：

1. 先检查，再修改
2. 优先改配置，不优先改源码
3. 优先关自动介入，不优先删功能
4. 对历史目录优先归档，不直接删除
5. 每次改完都跑 `omx doctor`
6. 出现 `0 failed` 之外的结果，不得宣称完成
7. 如果 `team / ralph / ask` 中任一能力失效，必须立即停止继续瘦身并回滚最近一步

## 一句话总结

这套极简方案的本质是：

**保留你真正要用的执行骨架，只关掉普通聊天里的多余自动介入面。**
