# omx-slim

`omx-slim` is a quiet profile for oh-my-codex.

It follows the same principle as the MUX `omc-slim` experiment: keep the operator workflows that are actually useful, and remove the always-on routing surface that makes normal conversations noisy.

## What It Keeps

- `$team`
- `$ralph`
- `$ask-claude`
- `$ask-gemini`
- `$cancel`
- `$help`
- Minimal native agent prompts: `explore`, `planner`, `executor`, `verifier`, `architect`
- Minimal OMX role prompt files: `explore`, `planner`, `executor`, `verifier`, `architect`
- `omx_state` MCP for runtime state
- Existing non-OMX hooks, if present

## What It Quiets

- OMX prompt triage
- Explore-first routing
- OMX native hook injection on every prompt/tool event
- Non-essential OMX MCP servers: `omx_code_intel`, `omx_memory`, `omx_trace`, `omx_wiki`
- The large default skill and agent prompt surfaces

## Install

```bash
cd MUX/omx-slim
chmod +x install.sh restore.sh
./install.sh
omx doctor
```

Restart Codex after installation so the shorter `AGENTS.md`, skill list, agent list, MCP list, and hooks are reloaded.

## Dry Run

```bash
./install.sh --dry-run
```

## Restore

```bash
./restore.sh
```

Or restore a specific backup:

```bash
./restore.sh ~/.codex/backups/omx-slim-YYYYMMDD-HHMMSS
```

## Expected Doctor Result

`omx doctor` may warn that prompt triage or explore routing is disabled. In slim mode those warnings are expected.

The key acceptance criterion is `0 failed`.
