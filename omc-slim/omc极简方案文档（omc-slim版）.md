# omc-slim：oh-my-claudecode 极简安装方案

## 文档目的

这份文档记录 omc-slim 的设计思路、保留内容和安装方法。

omc-slim 是对 oh-my-claudecode（OMC）的保守瘦身版本，目标是：

- 只保留 `team`、`ralph`、`ask` 三个核心能力
- 大幅降低启动时的 system prompt token 消耗
- 减少与其他框架（Trellis、自定义 commands/agents）的规则冲突
- 可一键安装，可回滚

## 适用范围

适用于：

- 已安装 oh-my-claudecode 插件
- 主要使用 `team`（tmux 分屏多 agent）、`ralph`（持续执行循环）、`ask`
- 不需要 autopilot、autoresearch、deepinit 等重型 workflow
- 希望普通对话不被 OMC 自动介入

不适用于：

- 想保留 OMC 全部 38 个 skills
- 想使用 autopilot、ralplan、sciomc 等能力

## 保留的能力

| Skill | 保留原因 |
|---|---|
| `team` | 核心需求：tmux 分屏多 agent 并行执行 |
| `ralph` | 核心需求：持续执行直到验证完成 |
| `ask` | 核心需求：调用 codex / gemini |
| `cancel` | ralph 退出时必须调用 |
| `ultrawork` | ralph 内部调用的执行引擎 |
| `ultraqa` | ultrawork 的 QA 循环组件 |
| `ai-slop-cleaner` | ralph deslop 步骤依赖 |
| `verify` | team pipeline 的 verify 阶段 |

删除的 skills（31 个）：autopilot, autoresearch, ccg, configure-notifications, debug, deep-dive, deepinit, deep-interview, external-context, hud, learner, mcp-setup, omc-doctor, omc-reference, omc-setup, omc-teams, plan, project-session-manager, ralplan, release, remember, sciomc, self-improve, setup, skill, skillify, trace, visual-verdict, wiki, writer-memory

## 改动内容

### CLAUDE.md

原始 OMC 注入 116 行，包含完整 agent catalog、38 个 skills 列表、所有 keyword triggers。

omc-slim 精简为 34 行，只保留 team/ralph/ask 的使用说明和必要工具声明。

### skills 目录

原始 38 个 skill 目录 → 精简为 9 个。

### MCP 工具过滤（v2 新增）

原始 OMC 在启动时全量注入 53 个 MCP 工具（约 9,400 tokens），包括 LSP、Wiki、Notepad、Python REPL 等大量不需要的工具。

omc-slim v2 通过两处修改将 MCP 工具精简为 13 个（约 2,000 tokens），节省约 7,400 tokens：

1. **`bridge/mcp-server.cjs`**：在 `buildListToolsResponse` 函数中注入环境变量过滤逻辑，支持 `OMC_TOOLS_INCLUDE`（白名单）和 `OMC_TOOLS_EXCLUDE`（黑名单）。

2. **`.mcp.json`**：通过 `env.OMC_TOOLS_INCLUDE` 只暴露以下 13 个工具：

| 工具组 | 工具 | 用途 |
|--------|------|------|
| state | `state_read/write/clear/get_status/list_active` | ralph/team 状态管理 |
| shared_memory | `shared_memory_read/write/list/delete/cleanup` | 跨 agent 通信 |
| skills | `list_omc_skills/load_omc_skills_local/load_omc_skills_global` | skills 加载 |

如需临时启用其他工具（如 LSP），可在 `.mcp.json` 的 `OMC_TOOLS_INCLUDE` 中追加工具名。

## 安装方法

### 前提

已在 Claude Code 中安装 oh-my-claudecode 插件：

```
/install-plugin oh-my-claudecode@omc
```

### 安装 omc-slim

```bash
git clone https://github.com/IdeasYH/MUX.git
cd MUX/omc-slim
chmod +x install.sh
./install.sh
```

重启 Claude Code 生效。

### 回滚

安装脚本会自动备份原始文件，备份路径格式为：

```
~/.claude/plugins/cache/omc/oh-my-claudecode/<version>/CLAUDE.md.backup-<时间戳>
~/.claude/plugins/cache/omc/oh-my-claudecode/<version>/skills.backup-<时间戳>
```

回滚命令：

```bash
OMC_DIR=~/.claude/plugins/cache/omc/oh-my-claudecode/<version>
cp $OMC_DIR/CLAUDE.md.backup-<时间戳> $OMC_DIR/CLAUDE.md
rm -rf $OMC_DIR/skills
cp -r $OMC_DIR/skills.backup-<时间戳> $OMC_DIR/skills
```

## 注意事项

- 运行 `omc update` 会覆盖 cache 目录，需要重新运行 `install.sh`
- `install.sh` 会自动备份 `mcp-server.cjs` 和 `.mcp.json`，回滚时一并恢复
- MCP 工具过滤通过环境变量实现，不影响 team 的 tmux 分屏功能
- 若 OMC 版本更新导致 `mcp-server.cjs` 中目标函数签名变化，补丁会自动跳过并打印警告
