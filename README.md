# MUX

多 agent 编排方案文档与工具集。

## 目录

```
MUX/
├── omc-slim/                          # oh-my-claudecode 精简安装方案
│   ├── install.sh                     # 一键安装脚本
│   ├── CLAUDE.md                      # 精简后的 OMC 注入内容
│   ├── skills/                        # 保留的 9 个核心 skill
│   └── omc极简方案文档（omc-slim版）.md
├── omx-slim/                          # oh-my-codex 极简安装方案
│   ├── install.sh                     # 一键安装 slim profile
│   ├── restore.sh                     # 从备份回滚
│   ├── AGENTS.md                      # 精简后的 OMX 注入内容
│   ├── README.md                      # 安装与验收说明
│   └── 极简OMX复用手册.md              # 给其他 agent 复用的执行手册
├── omx极简方案文档.md                  # oh-my-codex 极简方案（参考）
├── omx极简方案文档（Claude Code版）.md # OMX → Claude Code 迁移方案（参考）
└── omx极简使用说明文档.md              # OMX 使用说明（参考）
```

---

## omc-slim：oh-my-claudecode 精简版

### 这是什么

[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) 是 Claude Code 的多 agent 编排插件。默认安装后存在两个问题：

1. **启动 token 过多**：38 个 skills + 53 个 MCP 工具全量注入 system prompt，消耗约 14,000+ tokens
2. **自动介入干扰**：大量 keyword trigger 会在普通对话中意外触发 autopilot、ralph 等重型 workflow

omc-slim 是它的精简版，只保留三个核心能力：

- `team` — tmux 分屏多 agent 并行执行
- `ralph` — 持续执行直到验证完成的循环
- `ask` — 调用 codex / gemini

### 精简效果

| 项目 | 原始 | omc-slim | 节省 |
|------|------|----------|------|
| CLAUDE.md 注入 | 116 行 | 34 行 | ~82 行 |
| Skills 数量 | 38 个 | 9 个 | 29 个 |
| MCP 工具数量 | 53 个 (~9,400 tokens) | 13 个 (~2,000 tokens) | ~7,400 tokens |

### 安装步骤

**第一步：在 Claude Code 中安装 oh-my-claudecode 插件**

```
/install-plugin oh-my-claudecode@omc
```

**第二步：克隆本仓库并运行安装脚本**

```bash
git clone https://github.com/IdeasYH/MUX.git
cd MUX/omc-slim
chmod +x install.sh
./install.sh
```

**第三步：重启 Claude Code**

install.sh 自动完成以下操作（全程备份，可回滚）：
- 替换 CLAUDE.md 为精简版
- 删除 29 个不需要的 skill 目录
- patch `bridge/mcp-server.cjs`，支持通过环境变量过滤 MCP 工具
- 修改 `.mcp.json`，只暴露 13 个必要工具（state、shared_memory、skills 相关）

### 使用方法

安装后，在 Claude Code 中直接使用：

```
/oh-my-claudecode:team 3:executor "你的任务描述"
/oh-my-claudecode:ralph "你的任务描述"
/oh-my-claudecode:ask
/oh-my-claudecode:cancel   # 退出 ralph/team 模式
```

### 回滚

安装脚本会自动备份所有修改的文件（后缀 `.backup-<时间戳>`）。如需回滚：

```bash
OMC_DIR=~/.claude/plugins/cache/omc/oh-my-claudecode/<version>

# 恢复 CLAUDE.md 和 skills
cp $OMC_DIR/CLAUDE.md.backup-<时间戳> $OMC_DIR/CLAUDE.md
rm -rf $OMC_DIR/skills
cp -r $OMC_DIR/skills.backup-<时间戳> $OMC_DIR/skills

# 恢复 MCP 相关文件
cp $OMC_DIR/bridge/mcp-server.cjs.backup-<时间戳> $OMC_DIR/bridge/mcp-server.cjs
cp $OMC_DIR/.mcp.json.backup-<时间戳> $OMC_DIR/.mcp.json
```

### 注意

- 运行 `omc update` 会覆盖 cache 目录，需重新执行 `install.sh`
- 如需临时启用其他 MCP 工具（如 LSP），在 `.mcp.json` 的 `OMC_TOOLS_INCLUDE` 中追加工具名即可

---

## omx-slim：oh-my-codex 极简版

### 这是什么

omx-slim 把 oh-my-codex 从默认常驻编排层改成显式调用的轻量工具层。

保留：

- `$team`
- `$ralph`
- `$ask-claude`
- `$ask-gemini`
- `$cancel`
- `$help`

收窄：

- `AGENTS.md` 注入
- `skills/`
- `agents/`
- `prompts/`
- OMX native hooks
- 非核心 OMX MCP

### 安装

```bash
cd MUX/omx-slim
chmod +x install.sh restore.sh
./install.sh
omx doctor
```

安装后重启 Codex。

### 回滚

```bash
cd MUX/omx-slim
./restore.sh
```

也可以运行：

```bash
omx setup --force
```

恢复完整 OMX surface。
