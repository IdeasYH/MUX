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

# 补丁 mcp-server.cjs：注入 OMC_TOOLS_INCLUDE 过滤逻辑
MCP_SERVER="$OMC_DIR/bridge/mcp-server.cjs"
OLD_FN='function buildListToolsResponse() {
  return {
    tools: allTools.map((tool) => ({
      name: tool.name,
      description: tool.description,
      inputSchema: zodToJsonSchema2(tool.schema),
      ...tool.annotations ? { annotations: tool.annotations } : {}
    }))
  };
}'
NEW_FN='function buildListToolsResponse() {
  const include = process.env.OMC_TOOLS_INCLUDE
    ? new Set(process.env.OMC_TOOLS_INCLUDE.split(",").map((s) => s.trim()))
    : null;
  const exclude = process.env.OMC_TOOLS_EXCLUDE
    ? new Set(process.env.OMC_TOOLS_EXCLUDE.split(",").map((s) => s.trim()))
    : null;
  const filtered = allTools.filter((tool) => {
    if (include) return include.has(tool.name);
    if (exclude) return !exclude.has(tool.name);
    return true;
  });
  return {
    tools: filtered.map((tool) => ({
      name: tool.name,
      description: tool.description,
      inputSchema: zodToJsonSchema2(tool.schema),
      ...tool.annotations ? { annotations: tool.annotations } : {}
    }))
  };
}'

if grep -q "OMC_TOOLS_INCLUDE" "$MCP_SERVER" 2>/dev/null; then
  echo "mcp-server.cjs 已包含过滤补丁，跳过。"
else
  cp "$MCP_SERVER" "$MCP_SERVER.backup-$TS"
  python3 - "$MCP_SERVER" <<'PYEOF'
import sys
path = sys.argv[1]
content = open(path).read()
old = '''function buildListToolsResponse() {
  return {
    tools: allTools.map((tool) => ({
      name: tool.name,
      description: tool.description,
      inputSchema: zodToJsonSchema2(tool.schema),
      ...tool.annotations ? { annotations: tool.annotations } : {}
    }))
  };
}'''
new = '''function buildListToolsResponse() {
  const include = process.env.OMC_TOOLS_INCLUDE
    ? new Set(process.env.OMC_TOOLS_INCLUDE.split(",").map((s) => s.trim()))
    : null;
  const exclude = process.env.OMC_TOOLS_EXCLUDE
    ? new Set(process.env.OMC_TOOLS_EXCLUDE.split(",").map((s) => s.trim()))
    : null;
  const filtered = allTools.filter((tool) => {
    if (include) return include.has(tool.name);
    if (exclude) return !exclude.has(tool.name);
    return true;
  });
  return {
    tools: filtered.map((tool) => ({
      name: tool.name,
      description: tool.description,
      inputSchema: zodToJsonSchema2(tool.schema),
      ...tool.annotations ? { annotations: tool.annotations } : {}
    }))
  };
}'''
if old not in content:
    print("警告：未找到目标函数，mcp-server.cjs 可能已更新，跳过补丁。")
    sys.exit(0)
open(path, 'w').write(content.replace(old, new, 1))
print("mcp-server.cjs 补丁已应用。")
PYEOF
fi

# 注入 .mcp.json env 配置
MCP_JSON="$OMC_DIR/.mcp.json"
if grep -q "OMC_TOOLS_INCLUDE" "$MCP_JSON" 2>/dev/null; then
  echo ".mcp.json 已包含 env 配置，跳过。"
else
  cp "$MCP_JSON" "$MCP_JSON.backup-$TS"
  python3 - "$MCP_JSON" <<'PYEOF'
import sys, json
path = sys.argv[1]
data = json.load(open(path))
data["mcpServers"]["t"]["env"] = {
    "OMC_TOOLS_INCLUDE": "state_read,state_write,state_clear,state_get_status,state_list_active,shared_memory_read,shared_memory_write,shared_memory_list,shared_memory_delete,shared_memory_cleanup,list_omc_skills,load_omc_skills_local,load_omc_skills_global"
}
json.dump(data, open(path, 'w'), indent=2)
print(".mcp.json env 配置已注入。")
PYEOF
fi

echo "安装完成。保留的 skills：team, ralph, ask, cancel, ultrawork, ultraqa, ai-slop-cleaner, verify"
echo "MCP 工具已精简为 13 个（节省约 7,400 tokens）。"
echo "重启 Claude Code 生效。"
