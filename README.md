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
├── omx极简方案文档.md                  # oh-my-codex 极简方案（参考）
├── omx极简方案文档（Claude Code版）.md # OMX → Claude Code 迁移方案（参考）
└── omx极简使用说明文档.md              # OMX 使用说明（参考）
```

---

## omc-slim：oh-my-claudecode 精简版

### 这是什么

[oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) 是 Claude Code 的多 agent 编排插件，默认安装 38 个 skills，启动时注入大量 system prompt。

omc-slim 是它的精简版，只保留三个核心能力：

- `team` — tmux 分屏多 agent 并行执行
- `ralph` — 持续执行直到验证完成的循环
- `ask` — 调用 codex / gemini

CLAUDE.md 注入从 116 行压缩到 34 行，skills 从 38 个减少到 9 个。

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

### 使用方法

安装后，在 Claude Code 中直接使用：

```
/oh-my-claudecode:team 3:executor "你的任务描述"
/oh-my-claudecode:ralph "你的任务描述"
/oh-my-claudecode:ask
```

### 回滚

安装脚本会自动备份原始文件。如需回滚：

```bash
OMC_DIR=~/.claude/plugins/cache/omc/oh-my-claudecode/<version>
cp $OMC_DIR/CLAUDE.md.backup-<时间戳> $OMC_DIR/CLAUDE.md
rm -rf $OMC_DIR/skills
cp -r $OMC_DIR/skills.backup-<时间戳> $OMC_DIR/skills
```

### 注意

运行 `omc update` 会覆盖 cache，需重新执行 `install.sh`。
