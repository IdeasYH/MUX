# 极简 OMX 复用手册

## 目标

把 oh-my-codex 从“默认常驻编排层”改成“显式调用的轻量工具层”。

这不是卸载 OMX，也不是否定多 agent 能力。目标是保留真正有价值的执行入口，同时让普通 Codex 对话尽量不被额外 hook、triage、MCP 和大型提示词面干扰。

## 原理

MUX 对 oh-my-claudecode 的极简化改造遵循四个原则：

1. 保留少数核心 operator workflow。
2. 缩短默认注入提示词。
3. 把自动触发改成显式触发。
4. 安装前备份，改坏后可恢复。

OMX 可以采用同样思路，但要注意 Codex 的表面更多：

- `~/.codex/AGENTS.md`
- `~/.codex/config.toml`
- `~/.codex/hooks.json`
- `~/.codex/.omx-config.json`
- `~/.codex/skills/`
- `~/.codex/agents/`
- `~/.codex/prompts/`
- `mcp_servers.*`

极简化要同时处理这些面，否则会出现“提示词说有能力，但配置或文件已经被删”的半坏状态。

## Slim 目标态

保留：

- `$team`
- `$ralph`
- `$ask-claude`
- `$ask-gemini`
- `$cancel`
- `$help`
- agent prompts: `explore`, `planner`, `executor`, `verifier`, `architect`
- role prompts: `explore`, `planner`, `executor`, `verifier`, `architect`
- MCP: `omx_state`

关闭或收窄：

- prompt triage
- explore-first routing
- OMX native hook 常驻注入
- `omx_code_intel`
- `omx_memory`
- `omx_trace`
- `omx_wiki`
- 除白名单外的 skills 和 agent prompts

## 自动化脚本做了什么

运行：

```bash
cd MUX/omx-slim
./install.sh
```

脚本会执行以下步骤。

### 1. 定位 Codex Home

默认使用：

```bash
~/.codex
```

也可以覆盖：

```bash
CODEX_HOME=/path/to/.codex ./install.sh
```

### 2. 备份

备份目录：

```text
~/.codex/backups/omx-slim-<timestamp>/
```

备份内容：

- `AGENTS.md`
- `config.toml`
- `hooks.json`
- `.omx-config.json`
- `skills/`
- `agents/`
- `prompts/`

最新备份路径写入：

```text
~/.codex/backups/omx-slim-latest
```

### 3. 替换 AGENTS.md

把原来的完整 OMX orchestration contract 替换为短版 slim contract。

短版 contract 只说明：

- OMX 在 slim mode。
- 普通对话保持安静。
- 只在用户显式调用 slim skills 时启用 OMX。
- 列出保留的 `$team`、`$ralph`、`$ask-claude`、`$ask-gemini`、`$cancel`、`$help`。

### 4. 修改 config.toml

设置短版 `developer_instructions`：

```toml
developer_instructions = "oh-my-codex is installed in slim mode..."
```

关闭 explore-first routing：

```toml
[env]
USE_OMX_EXPLORE_CMD = "0"
```

保留 Codex hooks 功能本身：

```toml
[features]
codex_hooks = true
```

MCP 改为：

```toml
[mcp_servers.omx_state]
enabled = true

[mcp_servers.omx_code_intel]
enabled = false

[mcp_servers.omx_memory]
enabled = false

[mcp_servers.omx_trace]
enabled = false

[mcp_servers.omx_wiki]
enabled = false
```

### 5. 修改 .omx-config.json

关闭 triage：

```json
{
  "promptRouting": {
    "triage": {
      "enabled": false
    }
  }
}
```

### 6. 清理 hooks.json

从 `hooks.json` 中移除所有命令包含下面路径的 hook：

```text
oh-my-codex/dist/scripts/codex-native-hook.js
```

这样做会停止 OMX 在以下事件中常驻注入：

- `SessionStart`
- `UserPromptSubmit`
- `PreToolUse`
- `PostToolUse`
- `Stop`

脚本会保留非 OMX hook，例如项目自己的 planning hooks。

### 7. 白名单 skills

把 `~/.codex/skills` 替换为只包含：

- `team`
- `ralph`
- `ask-claude`
- `ask-gemini`
- `cancel`
- `help`

源文件来自备份目录，避免依赖脚本仓库复制旧版本 skill。

### 8. 白名单 agents

把 `~/.codex/agents` 替换为只包含：

- `explore`
- `planner`
- `executor`
- `verifier`
- `architect`

这些足够覆盖日常 explore、计划、执行、验证和 Ralph/Team 的基础审查需求。

### 9. 白名单 prompts

把 `~/.codex/prompts` 替换为只包含：

- `explore`
- `planner`
- `executor`
- `verifier`
- `architect`

`agents/` 是 Codex native subagent 定义，`prompts/` 是 OMX 角色提示词目录。两个目录都要收窄，否则 `omx doctor` 仍会显示完整 prompt surface。

## 验收

运行：

```bash
omx doctor
```

验收标准：

- `0 failed`
- 允许出现 triage disabled 或 explore routing disabled 的 warning
- `Skills` 数量应明显减少
- `Prompts` 或 agent prompts 数量应明显减少

检查 hooks：

```bash
rg 'codex-native-hook|oh-my-codex' ~/.codex/hooks.json
```

期望：

- 不再出现 `codex-native-hook.js`

检查 skills：

```bash
find ~/.codex/skills -maxdepth 1 -mindepth 1 -type d -printf '%f\n' | sort
```

期望：

```text
ask-claude
ask-gemini
cancel
help
ralph
team
```

检查 agents：

```bash
find ~/.codex/agents -maxdepth 1 -name '*.toml' -printf '%f\n' | sort
```

期望：

```text
architect.toml
executor.toml
explore.toml
planner.toml
verifier.toml
```

检查 prompts：

```bash
find ~/.codex/prompts -maxdepth 1 -name '*.md' -printf '%f\n' | sort
```

期望：

```text
architect.md
executor.md
explore.md
planner.md
verifier.md
```

## 回滚

自动回滚最新备份：

```bash
cd MUX/omx-slim
./restore.sh
```

回滚指定备份：

```bash
./restore.sh ~/.codex/backups/omx-slim-YYYYMMDD-HHMMSS
```

如果不用本脚本，也可以用 OMX 自身恢复完整安装：

```bash
omx setup --force
```

## 给其他 Agent 的执行准则

1. 先读当前 `~/.codex/config.toml`、`hooks.json`、`.omx-config.json`。
2. 先备份，再修改。
3. 不要直接删除 OMX npm 包。
4. 不要关闭 `codex_hooks` feature，除非你确认用户不需要任何 Codex hooks。
5. 移除的是 `codex-native-hook.js` 条目，不是所有 hooks。
6. skills 和 agents 用白名单重建，不在原目录里逐个乱删。
7. prompts 也要用白名单重建，否则 role prompt surface 仍然偏重。
8. 改完必须跑 `omx doctor`。
9. doctor 有 failed 就回滚，不宣称完成。
10. 提醒用户重启 Codex 才能完整加载 slim surface。

## 与保守瘦身方案的区别

仓库根目录的 `omx极简方案文档.md` 是保守瘦身：保留更多 MCP 和 hook 面，只关闭自动路由。

`omx-slim` 是更接近 MUX/OMC slim 原理的极简安装态：

- 更短的 AGENTS 注入。
- 更少 skills。
- 更少 agent prompts。
- 更少 role prompts。
- 更少 MCP。
- 移除 OMX native hook 常驻注入。

如果用户只想降低误触发，优先用保守瘦身。

如果用户想最大限度减少默认干扰和 token 面，使用 `omx-slim`。
