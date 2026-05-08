#!/usr/bin/env bash
set -euo pipefail

# Install an explicit, quiet OMX profile for Codex.
# It keeps the core operator workflows and removes always-on OMX prompt routing.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$CODEX_HOME/backups/omx-slim-$TS"

KEEP_SKILLS=(
  team
  ralph
  ask-claude
  ask-gemini
  cancel
  help
)

KEEP_AGENTS=(
  explore
  planner
  executor
  verifier
  architect
)

KEEP_PROMPTS=(
  explore
  planner
  executor
  verifier
  architect
)

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--dry-run]

Environment:
  CODEX_HOME=/path/to/.codex   Override Codex home. Defaults to ~/.codex.

This installer:
  - Backs up key Codex/OMX files under ~/.codex/backups/omx-slim-<timestamp>
  - Replaces AGENTS.md with a short slim contract
  - Disables OMX prompt triage and explore-first routing
  - Removes always-on OMX native hook entries from hooks.json
  - Disables non-essential OMX MCP servers
  - Whitelists the slim skills and minimal agent prompts
USAGE
}

DRY_RUN=0
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
elif [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
elif [[ -n "${1:-}" ]]; then
  usage
  exit 2
fi

require_path() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "error: missing required path: $path" >&2
    exit 1
  fi
}

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[dry-run] %q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

require_path "$CODEX_HOME"
require_path "$CODEX_HOME/config.toml"
require_path "$SCRIPT_DIR/AGENTS.md"

echo "Installing OMX slim profile"
echo "Codex home: $CODEX_HOME"
echo "Backup dir: $BACKUP_DIR"

if [[ "$DRY_RUN" == "0" ]]; then
  mkdir -p "$BACKUP_DIR"
  for item in AGENTS.md config.toml hooks.json .omx-config.json skills agents prompts; do
    if [[ -e "$CODEX_HOME/$item" ]]; then
      cp -a "$CODEX_HOME/$item" "$BACKUP_DIR/$item"
    fi
  done
  printf '%s\n' "$BACKUP_DIR" > "$CODEX_HOME/backups/omx-slim-latest"
else
  echo "[dry-run] would create backup and copy AGENTS/config/hooks/skills/agents/prompts"
fi

run cp "$SCRIPT_DIR/AGENTS.md" "$CODEX_HOME/AGENTS.md"

if [[ "$DRY_RUN" == "0" ]]; then
  python3 - "$CODEX_HOME/config.toml" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()

slim_instruction = (
    'developer_instructions = "oh-my-codex is installed in slim mode. '
    'Keep normal conversations quiet. Use OMX only when the user explicitly invokes '
    '$team, $ralph, $ask-claude, $ask-gemini, $cancel, or $help. '
    'Do not infer broad workflows from ordinary natural language."'
)

def set_top_level(src: str, key: str, line: str) -> str:
    pattern = re.compile(rf'^{re.escape(key)}\s*=.*$', re.M)
    if pattern.search(src):
        return pattern.sub(line, src, count=1)
    first_section = re.search(r'^\[', src, re.M)
    if first_section:
        return src[:first_section.start()] + line + "\n" + src[first_section.start():]
    return src.rstrip() + "\n" + line + "\n"

def ensure_section(src: str, section: str) -> str:
    if re.search(rf'^\[{re.escape(section)}\]\s*$', src, re.M):
        return src
    return src.rstrip() + f"\n\n[{section}]\n"

def set_in_section(src: str, section: str, key: str, value: str) -> str:
    src = ensure_section(src, section)
    header = re.search(rf'^\[{re.escape(section)}\]\s*$', src, re.M)
    assert header
    next_header = re.search(r'^\[', src[header.end():], re.M)
    end = header.end() + next_header.start() if next_header else len(src)
    body = src[header.end():end]
    line = f'{key} = {value}'
    key_pattern = re.compile(rf'^({re.escape(key)}\s*=).*$' , re.M)
    if key_pattern.search(body):
      body = key_pattern.sub(line, body, count=1)
    else:
      body = body.rstrip() + "\n" + line + "\n"
    return src[:header.end()] + body + src[end:]

text = set_top_level(text, "developer_instructions", slim_instruction)
text = set_in_section(text, "features", "codex_hooks", "true")
text = set_in_section(text, "env", "USE_OMX_EXPLORE_CMD", '"0"')

for server, enabled in {
    "omx_state": "true",
    "omx_code_intel": "false",
    "omx_memory": "false",
    "omx_trace": "false",
    "omx_wiki": "false",
}.items():
    text = set_in_section(text, f"mcp_servers.{server}", "enabled", enabled)

path.write_text(text)
PY

  python3 - "$CODEX_HOME/.omx-config.json" <<'PY'
from pathlib import Path
import json
import sys

path = Path(sys.argv[1])
data = {}
if path.exists():
    try:
        data = json.loads(path.read_text() or "{}")
    except json.JSONDecodeError:
        data = {}
data.setdefault("promptRouting", {}).setdefault("triage", {})["enabled"] = False
path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
PY

  if [[ -f "$CODEX_HOME/hooks.json" ]]; then
    python3 - "$CODEX_HOME/hooks.json" <<'PY'
from pathlib import Path
import json
import sys

path = Path(sys.argv[1])
data = json.loads(path.read_text())
hooks = data.get("hooks", {})
needle = "oh-my-codex/dist/scripts/codex-native-hook.js"

for event, entries in list(hooks.items()):
    kept_entries = []
    for entry in entries:
        hook_list = entry.get("hooks", [])
        filtered = [
            hook for hook in hook_list
            if needle not in str(hook.get("command", ""))
        ]
        if filtered:
            new_entry = dict(entry)
            new_entry["hooks"] = filtered
            kept_entries.append(new_entry)
    if kept_entries:
        hooks[event] = kept_entries
    else:
        hooks.pop(event, None)

path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
PY
  fi
else
  echo "[dry-run] would update config.toml, .omx-config.json, and hooks.json"
fi

if [[ -d "$CODEX_HOME/skills" ]]; then
  if [[ "$DRY_RUN" == "0" ]]; then
    rm -rf "$CODEX_HOME/skills"
    mkdir -p "$CODEX_HOME/skills"
    for skill in "${KEEP_SKILLS[@]}"; do
      if [[ -d "$BACKUP_DIR/skills/$skill" ]]; then
        cp -a "$BACKUP_DIR/skills/$skill" "$CODEX_HOME/skills/$skill"
      else
        echo "warning: missing skill in backup, skipped: $skill" >&2
      fi
    done
  else
    echo "[dry-run] would replace skills with: ${KEEP_SKILLS[*]}"
  fi
fi

if [[ -d "$CODEX_HOME/agents" ]]; then
  if [[ "$DRY_RUN" == "0" ]]; then
    rm -rf "$CODEX_HOME/agents"
    mkdir -p "$CODEX_HOME/agents"
    for agent in "${KEEP_AGENTS[@]}"; do
      if [[ -f "$BACKUP_DIR/agents/$agent.toml" ]]; then
        cp -a "$BACKUP_DIR/agents/$agent.toml" "$CODEX_HOME/agents/$agent.toml"
      else
        echo "warning: missing agent in backup, skipped: $agent" >&2
      fi
    done
  else
    echo "[dry-run] would replace agents with: ${KEEP_AGENTS[*]}"
  fi
fi

if [[ -d "$CODEX_HOME/prompts" ]]; then
  if [[ "$DRY_RUN" == "0" ]]; then
    rm -rf "$CODEX_HOME/prompts"
    mkdir -p "$CODEX_HOME/prompts"
    for prompt in "${KEEP_PROMPTS[@]}"; do
      if [[ -f "$BACKUP_DIR/prompts/$prompt.md" ]]; then
        cp -a "$BACKUP_DIR/prompts/$prompt.md" "$CODEX_HOME/prompts/$prompt.md"
      else
        echo "warning: missing prompt in backup, skipped: $prompt" >&2
      fi
    done
  else
    echo "[dry-run] would replace prompts with: ${KEEP_PROMPTS[*]}"
  fi
fi

echo "OMX slim profile installed."
echo "Kept skills: ${KEEP_SKILLS[*]}"
echo "Kept agents: ${KEEP_AGENTS[*]}"
echo "Kept prompts: ${KEEP_PROMPTS[*]}"
echo "Run 'omx doctor' and restart Codex to fully reload the slimmer surface."
echo "Restore with: $SCRIPT_DIR/restore.sh $BACKUP_DIR"
