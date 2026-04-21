# MUX Design Spec

Date: 2026-04-21
Status: Draft approved in conversation; awaiting written-spec review

## 1. Summary

MUX is not a new general-purpose multi-agent framework.

MUX is a minimal extraction of OMC focused on one primary execution path:

**hybrid = Claude lead + minimal planner + Codex workers + verify/fix loop until done**

The goal is to keep only the highest-value team orchestration capabilities, remove the heavy non-core platform surface, and package the result as a lightweight installable plugin.

## 2. Product goals

### 2.1 Primary goals
- Keep multi-agent / team orchestration as the product core.
- Make `hybrid` the single real execution mode.
- Preserve `planner` as an explicit capability, but keep it minimal.
- Keep a minimal until-done loop with terminal outcomes.
- Package MUX as a lightweight Node plugin with a Python runtime core.
- Optimize for simple installation and simple mental model.

### 2.2 User-facing experience goals
- Users should be able to invoke MUX through a small CLI surface.
- Users should also be able to describe the orchestration naturally, for example:
  - "use MUX team"
  - "use the MUX way"
  - "Claude as lead, split into 3 Codex subagents to implement the code"
- `team` should remain a user-facing concept, but not a separate heavy execution universe.

### 2.3 Non-goals
- Rebuilding OMC feature-for-feature.
- Preserving OMC as a broad orchestration platform.
- Keeping heavy hooks, memory systems, HUD, wiki, or staged pipelines.
- Keeping a large role/agent taxonomy.
- Building a general scheduler / analyst / architect ecosystem.
- Creating a heavyweight provider abstraction framework in v1.

## 3. Core product model

### 3.1 Execution model
MUX has one real execution core:
- `hybrid`

User-facing aliases or phrasing may map into the same core:
- `team`
- natural language references to MUX team orchestration

This means:
- `hybrid` is the implementation truth
- `team` is a user-language alias
- all orchestration logic converges to one execution path

### 3.2 Role model
MUX keeps only five minimal role slots:
- `lead`
- `planner`
- `impl`
- `fix`
- `verify`

These are not meant to become a broad role universe.
They exist only to support the hybrid execution loop.

## 4. Planner constraints

Planner is explicitly retained.

### 4.1 Planner responsibilities
Planner may:
- normalize the task
- split the task into 2-8 concrete subtasks
- identify likely verification checkpoints
- identify obvious blockers
- identify obvious `needs_human` decision points

### 4.2 Planner non-responsibilities
Planner must not become:
- a scheduler
- an analyst
- an architect
- a product manager
- a PRD / test-spec pipeline engine
- a staged planning workflow

### 4.3 Planner product shape
- Planner runs implicitly inside `hybrid`.
- Planner remains observable/debuggable via a lightweight `mux planner` command.
- Planner output should stay short, operational, and directly consumable by lead.

## 5. Hybrid architecture

### 5.1 Control loop
1. User invokes `mux hybrid <task>` or an equivalent `team` alias.
2. Lead gathers task and workspace context.
3. Planner produces a minimal task split.
4. Lead assigns work to CLI workers.
5. Workers execute implementation or targeted fixes.
6. Verification runs against checkpoints and acceptance evidence.
7. Lead decides whether to stop or continue.
8. The run ends in one terminal state:
   - `completed`
   - `failed`
   - `blocked`
   - `needs_human`

### 5.2 Lead responsibilities
Lead is responsible for:
- selecting worker count
- invoking planner
- assigning tasks
- aggregating worker outputs
- deciding whether another round is needed
- producing the final run outcome

Lead is not responsible for:
- heavyweight design governance
- large-scale workflow orchestration families
- unrelated mode management

### 5.3 Worker responsibilities
Workers are responsible for:
- executing scoped implementation tasks
- applying targeted fixes after verify feedback
- returning concrete outputs and evidence

Workers are not responsible for:
- redefining the global plan
- expanding the workflow into new modes
- creating their own broader role hierarchy

## 6. Until-done loop

### 6.1 State model
Minimal run states:
- `running`
- `awaiting_verify`
- `awaiting_human`

Minimal terminal outcomes:
- `completed`
- `failed`
- `blocked`
- `needs_human`

### 6.2 Outcome semantics
- `completed`: required work and checkpoints are satisfied.
- `failed`: execution encountered a non-recoverable failure path.
- `blocked`: execution is blocked by environment, dependency, permission, or runtime conditions.
- `needs_human`: execution requires a user decision, clarification, or explicit tradeoff selection.

### 6.3 Resume behavior
When a run lands in `needs_human`, MUX should support a minimal resume flow.

Saved state should include only what is necessary to continue:
- run id
- task summary
- planner output
- completed subtasks
- unresolved gaps
- exact human question
- enough worker/result context to continue safely

Resume entrypoint:
- `mux resume <run-id>`

### 6.4 Explicit anti-goal
This loop must not recreate the full Ralph system or a heavy global state machine.

## 7. Worker orchestration model

### 7.1 Default v1 model
Default orchestration shape:
- 1 Claude lead
- N Codex CLI workers

### 7.2 Extensibility boundary
MUX v1 should leave room for future worker providers, but only through a thin adapter boundary.

Example adapter responsibilities:
- spawn worker
- send task
- collect result
- stop worker

This boundary exists to avoid hardcoding too much provider logic into the hybrid loop.
It must remain minimal and must not become a provider platform.

### 7.3 Runtime substrate
MUX keeps only the CLI worker runtime needed for hybrid:
- tmux session/pane creation
- worker launch
- task dispatch
- output collection
- health/timeout handling
- worker shutdown

MUX removes or avoids unrelated team-runtime subsystems.

## 8. Packaging and runtime split

### 8.1 Node plugin shell
Node is the product shell.
Responsibilities:
- plugin install surface
- CLI entrypoints
- thin env validation
- forwarding commands to Python runtime
- rendering status and summaries

### 8.2 Python runtime core
Python is the orchestration core.
Responsibilities:
- lead loop
- planner execution
- worker orchestration
- verify/fix continuation logic
- minimal state snapshot and resume

### 8.3 Why this split
This preserves:
- lightweight installation surface
- small plugin shell
- concentrated orchestration logic in one internal runtime
- easier future packaging for plugin markets

## 9. Public CLI surface

### 9.1 Recommended v1 commands
- `mux hybrid "<task>"`
- `mux team "<task>"` (alias into hybrid)
- `mux planner "<task>"`
- `mux status`
- `mux resume <run-id>`

### 9.2 Commands intentionally excluded from v1 public surface
Do not make these first-class public commands in v1:
- `mux worker`
- `mux verify`
- `mux fix`
- `mux lead`
- heavy setup/doctor/hud/wiki/memory commands

The corresponding concepts may exist internally, but should not become part of the main product surface.

## 10. Proposed repository shape

```text
MUX/
  package.json
  README.md
  plugin/
    manifest.json
    index.ts
  src/
    cli/
      mux.ts
    node/
      bridge.ts
      env.ts
      status.ts
      commands/
        hybrid.ts
        planner.ts
        status.ts
        resume.ts
  runtime/
    mux_runtime/
      __main__.py
      contracts.py
      lead.py
      planner.py
      loop.py
      workers.py
      verify.py
      state.py
      tmux.py
```

This structure intentionally keeps the product small and makes the Python runtime boundary explicit.

## 11. OMC extraction strategy

### 11.1 Migration strategy
Adopt parallel extraction:
- keep `omc/` as the source/reference tree temporarily
- create a new lightweight MUX package structure
- extract only the minimal hybrid chain
- avoid cloning the whole OMC world into MUX

### 11.2 Likely extraction candidates from OMC
Potential source material:
- `src/team/runtime-v2.ts`
- `src/team/runtime-cli.ts`
- `src/team/tmux-session.ts`
- `src/team/worker-bootstrap.ts`
- selective minimal pieces from:
  - `src/team/cli-detection.ts`
  - `src/team/model-contract.ts`
  - `src/team/team-status.ts`

These should be treated as extraction candidates, not wholesale carryovers.

### 11.3 Likely exclusions from OMC
Avoid carrying over major non-core systems such as:
- hooks
- HUD
- wiki
- broad skills and commands universe
- staged team pipeline
- governance-heavy routing
- heavy MCP and bridge surfaces unrelated to hybrid runtime
- large persistent memory systems

### 11.4 Extraction principle
Do not copy the `team/` subsystem whole.
Extract only along the minimal MUX chain:
- worker launch
- tmux control
- thin status/result contracts
- minimal orchestration loop inputs/outputs

## 12. Error handling

### 12.1 Runtime errors
If a worker crashes or times out:
- lead should capture the failure
- decide whether retry/fix is possible
- continue only if the path remains bounded and meaningful
- otherwise return `failed` or `blocked`

### 12.2 Verification failures
If verify fails:
- produce a compact failure summary
- route only the relevant gaps into a fix round
- avoid re-planning the entire task unless the current split is clearly invalid

### 12.3 Human-decision errors
If the task cannot proceed without a human decision:
- return `needs_human`
- persist the exact question and relevant context
- allow resume after the answer is provided

## 13. Testing strategy

### 13.1 Unit-level priorities
Test the minimal core contracts:
- planner output shape
- lead loop transition rules
- terminal state behavior
- resume state serialization
- worker adapter contract

### 13.2 Runtime-level priorities
Test the operational path:
- tmux worker startup
- task dispatch and collection
- verify/fix re-entry
- `needs_human` snapshot and resume

### 13.3 Regression priorities
Use OMC as a behavioral reference only where needed for:
- worker launch reliability
- task/result contract stability
- tmux control edge cases

### 13.4 Explicit testing boundary
Do not inherit OMC's full testing universe.
Write tests only for the minimal MUX architecture and the extraction points required to keep it stable.

## 14. Success criteria

MUX v1 is successful if:
- it is installable as a lightweight plugin
- it has one obvious primary mode: `hybrid`
- `team` works as a light alias / natural-language entry
- planner is clearly present but clearly minimal
- Claude lead + Codex workers run reliably
- verify/fix can loop until a terminal state
- `needs_human` + resume work without a heavy framework
- the codebase and concept surface are much smaller than OMC

## 15. Implementation tracking

Current implementation status in this workspace:
- Node shell is implemented under `src/cli/` and `src/node/`.
- Python runtime is implemented under `runtime/mux_runtime/`.
- Minimal status snapshots are persisted under `.mux/runs/`.
- OMC remains under `omc/` as an extraction reference tree and is not the active product surface.

Implemented v1 surfaces:
- `mux hybrid`
- `mux team`
- `mux planner`
- `mux status`
- `mux resume`

Implemented minimal runtime pieces:
- planner
- hybrid loop
- tmux adapter
- worker batch execution
- verify verdict reduction
- `needs_human` state save/load and resume

## 15. Final scope guardrails

MUX must not drift into:
- a broad orchestration platform
- a heavy role ecosystem
- a full staged workflow engine
- a hook-driven operating system
- an everything-plugin

When a design choice is ambiguous, prefer:
- fewer commands
- fewer modes
- fewer concepts
- smaller contracts
- one clear execution path


## 16. Implementation tracking

### 16.1 Completed in the current extraction pass
- [x] Minimal Node CLI shell exists for `hybrid`, `team`, `planner`, `status`, and `resume`.
- [x] Thin Node ↔ Python JSON bridge is in place.
- [x] Minimal runtime environment validation exists in the Node shell.
- [x] Minimal planner contract and planner runtime branch are implemented.
- [x] Minimal hybrid loop exists with planner -> worker batch -> verify -> terminal result flow.
- [x] Minimal tmux adapter exists for hybrid worker orchestration.
- [x] Minimal state snapshot support exists for terminal outcomes and `needs_human`.
- [x] `status` and `resume` runtime branches are implemented.
- [x] Node tests and runtime tests exist for the extracted minimal path.

### 16.2 Intentionally still minimal / deferred
- [ ] Real worker execution remains intentionally thin and is not yet a production-complete provider runtime.
- [ ] CLI presentation is intentionally compact and has not been expanded into a richer TUI / HUD layer.
- [ ] Provider abstraction remains intentionally thin and is not a general worker platform.
- [ ] Packaging is still repo-local and has not yet been finalized for marketplace distribution.

### 16.3 Scope guard for follow-up work
Any follow-up work should preserve the approved MUX constraints:
- do not reintroduce staged pipelines
- do not expand planner into scheduler / architect / analyst roles
- do not restore heavy hooks, memory, HUD, or wiki systems
- do not turn team aliasing into a separate heavy execution universe
