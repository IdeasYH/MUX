# Worker 1 routing audit/report

## Live controls changed

1. `~/.codex/.omx-config.json`
   - Set:
     ```json
     {
       "promptRouting": {
         "triage": { "enabled": false }
       }
     }
     ```
   - Effect: disables advisory triage injection in `dist/hooks/triage-config.js` / `dist/scripts/codex-native-hook.js`.

2. `/home/trys/.npm-global/lib/node_modules/oh-my-codex/dist/hooks/keyword-registry.js`
   - Slimmed implicit natural-language triggers to only:
     - `ralph` -> `ralph`
     - `team` -> `team`
     - `ask claude` -> `ask-claude`
     - `ask gemini` -> `ask-gemini`
   - Left all other OMX workflows/skills as explicit-only `$skill` triggers.

3. `/home/trys/.npm-global/lib/node_modules/oh-my-codex/dist/hooks/__tests__/keyword-detector.test.js`
   - Updated compiled test expectations to match the slimmed routing surface.

## Verification evidence

- `readTriageConfig()` reports disabled from `~/.codex/.omx-config.json`.
- `dispatchCodexNativeHook(UserPromptSubmit)` on a normal non-keyword prompt returned `outputJson: null`.
- Enumerating non-`$` registry entries returns only `ralph`, `team`, `ask claude`, `ask gemini`.
- Targeted runtime assertions passed for:
  - positive: `team`, `ralph`, `ask claude`, `ask gemini`
  - negative: `code review`, `deep interview`, `investigate`, `abort now`, `swarm`
- `omx doctor` passes with expected warnings only and reports `Prompt triage: disabled via /home/trys/.codex/.omx-config.json`.

## Integration note

The effective implementation lives in user-scope config plus the installed OMX dist surface, not in this detached worktree's tracked files. This report captures the exact files/controls the leader can integrate or reproduce.
