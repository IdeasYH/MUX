<!-- OMC:START -->
<!-- OMC:VERSION:4.9.1-slim -->

# oh-my-claudecode (slim)

OMC is active. Available skills: `team`, `ralph`, `ask`.

<tools>
OMC State: `state_read`, `state_write`, `state_clear`, `state_list_active`, `state_get_status`
Teams: `TeamCreate`, `TeamDelete`, `SendMessage`, `TaskCreate`, `TaskList`, `TaskGet`, `TaskUpdate`
</tools>

<skills>
- `/oh-my-claudecode:team [N:agent-type] <task>` — spawn N coordinated agents with tmux panes
- `/oh-my-claudecode:ralph <task>` — persistence loop until verified completion. Keyword: "ralph"
- `/oh-my-claudecode:ask` — ask codex or gemini
- `/oh-my-claudecode:cancel` — exit ralph/team mode and clean up state
</skills>

<team_pipeline>
Stages: `team-plan` → `team-prd` → `team-exec` → `team-verify` → `team-fix` (loop).
`team ralph` links both modes.
</team_pipeline>

<hooks_and_context>
Hooks inject `<system-reminder>` tags. Key patterns: `[MAGIC KEYWORD: RALPH]` → invoke ralph skill.
Kill switches: `DISABLE_OMC`, `OMC_SKIP_HOOKS`.
</hooks_and_context>

<worktree_paths>
State: `.omc/state/`, `.omc/notepad.md`, `.omc/project-memory.json`
</worktree_paths>

<!-- OMC:END -->
