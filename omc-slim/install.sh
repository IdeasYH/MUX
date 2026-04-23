#!/usr/bin/env bash
set -e

# omc-slim 安装脚本
# 前提：已安装 oh-my-claudecode 插件（通过 Claude Code /install-plugin）

OMC_CACHE="$HOME/.claude/plugins/cache/omc/oh-my-claudecode"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 找到已安装的 OMC 版本目录
OMC_DIR=$(ls -d "$OMC_CACHE"/*/  2>/dev/null | sort -V | tail -1)

if [ -z "$OMC_DIR" ]; then
  echo "错误：未找到 oh-my-claudecode 安装目录。"
  echo "请先在 Claude Code 中运行：/install-plugin oh-my-claudecode@omc"
  exit 1
fi

OMC_DIR="${OMC_DIR%/}"
echo "找到 OMC 安装目录：$OMC_DIR"

# 备份
TS=$(date +%Y%m%d-%H%M%S)
cp "$OMC_DIR/CLAUDE.md" "$OMC_DIR/CLAUDE.md.backup-$TS"
cp -r "$OMC_DIR/skills" "$OMC_DIR/skills.backup-$TS"
echo "已备份原始文件（后缀 .backup-$TS）"

# 覆盖 CLAUDE.md
cp "$SCRIPT_DIR/CLAUDE.md" "$OMC_DIR/CLAUDE.md"

# 覆盖 skills：先清空，再复制精简版
rm -rf "$OMC_DIR/skills"
cp -r "$SCRIPT_DIR/skills" "$OMC_DIR/skills"

echo "安装完成。保留的 skills：team, ralph, ask, cancel, ultrawork, ultraqa, ai-slop-cleaner, verify"
echo "重启 Claude Code 生效。"
