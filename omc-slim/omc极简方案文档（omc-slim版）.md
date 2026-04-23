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
- MCP bridge（`bridge/mcp-server.cjs`）不受影响，team 的 tmux 分屏功能正常
- 本方案不修改 OMC 的 hooks 和 MCP server，只改 CLAUDE.md 和 skills 目录
