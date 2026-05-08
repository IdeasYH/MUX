<!-- OMX:SLIM:START -->
<!-- OMX:SLIM:VERSION:1.0.0 -->

# oh-my-codex slim

OMX is installed in slim mode.

Default behavior:
- Stay quiet during normal Codex conversations.
- Do not infer broad workflows from ordinary natural language.
- Use OMX only when the user explicitly invokes a slim skill.

Available slim skills:
- `$team` - coordinated tmux-based multi-agent execution.
- `$ralph` - persistent single-owner completion and verification loop.
- `$ask-claude` - ask the local Claude CLI and save an artifact.
- `$ask-gemini` - ask the local Gemini CLI and save an artifact.
- `$cancel` - clear active OMX runtime state.
- `$help` - show OMX help.

Runtime contract:
- Prefer direct solo execution for ordinary tasks.
- Use `$team` only for explicit coordinated parallel execution.
- Use `$ralph` only for explicit persistence-until-verified work.
- Use `$ask-claude` and `$ask-gemini` only when explicitly requested.
- Keep changes small, reversible, and verified before reporting completion.

State paths:
- Project state: `.omx/state/`
- Project notes: `.omx/notepad.md`
- Project artifacts: `.omx/artifacts/`

Recovery:
- Run `omx doctor` to verify the install.
- Run `omx setup --force` to restore the full OMX surface.
- Use the `omx-slim/restore.sh` backup restore path when this profile was installed from MUX.

<!-- OMX:SLIM:END -->
