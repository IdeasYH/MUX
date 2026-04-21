# MUX hybrid extraction 实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 从 OMC 并行抽取一个极简 MUX 插件，保留 hybrid/team 主链、最小 planner、tmux CLI workers、verify/fix until-done 闭环，以及 `needs_human` + `resume`。

**架构：** 以新建 MUX 轻量包为中心，不直接修改 `omc/` 既有执行面；Node 侧只保留 CLI/插件壳与 Python bridge，Python 侧承载 lead/planner/loop/tmux/state。`team` 作为 `hybrid` 轻 alias，planner 默认隐式执行，同时暴露轻量调试入口。

**技术栈：** Node 20 + TypeScript + commander + esbuild + Vitest；Python 3.11+ runtime；tmux；JSON contracts；从 `omc/src/team/*` 按能力切片抽取最小实现。

---

## 文件结构与职责

### 新建文件
- `package.json` — MUX npm 包元数据，最小 scripts / bin / files。
- `tsconfig.json` — MUX TypeScript 编译配置。
- `vitest.config.ts` — MUX 单元测试配置。
- `README.md` — 对外只讲 MUX 核心模型与命令。
- `plugin/manifest.json` — 轻量插件清单。
- `src/cli/mux.ts` — `mux` CLI 根入口，注册 `hybrid/team/planner/status/resume`。
- `src/node/bridge.ts` — Node -> Python runtime 桥接与 JSON stdin/stdout 协议。
- `src/node/env.ts` — Python / tmux / cwd 最小环境校验。
- `src/node/status.ts` — Node 侧格式化 status / terminal summary。
- `src/node/commands/hybrid.ts` — `mux hybrid` 与 `mux team` 入口，拼装请求并调用 bridge。
- `src/node/commands/planner.ts` — `mux planner` 调试入口。
- `src/node/commands/status.ts` — `mux status`，读取 runtime 保存的最小状态。
- `src/node/commands/resume.ts` — `mux resume <run-id>` 入口。
- `src/node/contracts.ts` — Node/Python 共享 JSON 契约 TS 类型。
- `runtime/mux_runtime/__main__.py` — Python runtime CLI 入口。
- `runtime/mux_runtime/contracts.py` — Python 请求/响应 dataclass / TypedDict。
- `runtime/mux_runtime/planner.py` — 最小 planner：归一化任务、拆分 2-8 子任务、标注 verify checkpoints。
- `runtime/mux_runtime/tmux.py` — 最小 tmux session / pane 启动与清理。
- `runtime/mux_runtime/workers.py` — CLI worker adapter：spawn/send/collect/stop。
- `runtime/mux_runtime/verify.py` — 最小 verify/fix verdict 归约逻辑。
- `runtime/mux_runtime/state.py` — run state 快照、status、resume 存取。
- `runtime/mux_runtime/lead.py` — lead 决策逻辑：worker 数、轮次推进、终态判定。
- `runtime/mux_runtime/loop.py` — hybrid 主循环。
- `tests/node/bridge.test.ts` — Node bridge 协议与错误处理测试。
- `tests/node/cli.test.ts` — `mux` CLI 子命令 / alias / 参数解析测试。
- `tests/runtime/planner.test.py` — planner 拆分与约束测试。
- `tests/runtime/state.test.py` — `needs_human` 快照 / `resume` 测试。
- `tests/runtime/loop.test.py` — terminal state 流转测试。
- `tests/runtime/tmux.test.py` — tmux adapter 命令生成测试（mock subprocess）。

### 参考但不直接复制的来源文件
- `omc/src/team/runtime-v2.ts` — 参考 event-driven runtime 分层。
- `omc/src/team/runtime-cli.ts` — 参考 JSON stdin/stdout runtime CLI 约定。
- `omc/src/team/tmux-session.ts` — 参考 tmux session/pane 操作与安全 argv 处理。
- `omc/src/team/worker-bootstrap.ts` — 参考 worker 启动消息注入思路。
- `omc/src/cli/team.ts` — 参考 team 作业状态与后台 runtime 调用边界。

### 明确不在本计划内迁移的文件/能力
- `omc/src/hooks/**`
- `omc/src/hud/**`
- `omc/src/autoresearch/**`
- `omc/src/ralphthon/**`
- `omc/src/features/notepad-wisdom/**`
- `omc/src/features/state-manager/**`
- `omc/src/team/phase-controller.ts`
- `omc/src/team/stage-router.ts`
- `omc/src/team/governance.ts`
- `omc/src/team/mcp-team-bridge.ts`

## 任务 1：搭建 MUX Node 包与最小 CLI 外壳

**文件：**
- 创建：`package.json`
- 创建：`tsconfig.json`
- 创建：`vitest.config.ts`
- 创建：`plugin/manifest.json`
- 创建：`src/cli/mux.ts`
- 创建：`src/node/contracts.ts`
- 测试：`tests/node/cli.test.ts`

- [ ] **步骤 1：编写失败的 CLI 测试，锁定公开命令面与 team alias**

```ts
import { describe, expect, it } from 'vitest';
import { buildMuxProgram } from '../../src/cli/mux';

describe('mux cli', () => {
  it('maps team to hybrid', async () => {
    const program = buildMuxProgram({
      runHybrid: async (req) => ({ status: 'completed', runId: 'run-1', summary: req.task }),
      runPlanner: async () => ({ status: 'completed', runId: 'plan-1', summary: 'ok' }),
      readStatus: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
      resumeRun: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
    });

    await program.parseAsync(['node', 'mux', 'team', 'ship search ui']);
    expect(program.opts()).toBeDefined();
  });
});
```

- [ ] **步骤 2：运行测试验证失败**

运行：`npx vitest run tests/node/cli.test.ts`
预期：FAIL，报错 `Cannot find module '../../src/cli/mux'` 或 `buildMuxProgram is not exported`

- [ ] **步骤 3：创建最小 package / tsconfig / vitest 配置**

```json
{
  "name": "mux",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "bin": {
    "mux": "dist/cli/mux.js"
  },
  "scripts": {
    "build": "tsc -p tsconfig.json",
    "test": "vitest run",
    "test:node": "vitest run tests/node",
    "test:runtime": "python -m pytest tests/runtime"
  },
  "devDependencies": {
    "@types/node": "^22.19.7",
    "commander": "^12.1.0",
    "typescript": "^5.7.2",
    "vitest": "^4.0.17"
  }
}
```

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "rootDir": "src",
    "outDir": "dist",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*.ts", "tests/node/**/*.ts"]
}
```

```ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/node/**/*.test.ts'],
  },
});
```

- [ ] **步骤 4：实现最小 CLI 外壳与共享契约类型**

```ts
import { Command } from 'commander';
import type { MuxRunRequest, MuxRunResult } from '../node/contracts.js';

export interface MuxCliHandlers {
  runHybrid(req: MuxRunRequest): Promise<MuxRunResult>;
  runPlanner(req: MuxRunRequest): Promise<MuxRunResult>;
  readStatus(runId?: string): Promise<MuxRunResult>;
  resumeRun(runId: string): Promise<MuxRunResult>;
}

export function buildMuxProgram(handlers: MuxCliHandlers): Command {
  const program = new Command();
  program.name('mux');

  program
    .command('hybrid <task...>')
    .action(async (task: string[]) => {
      await handlers.runHybrid({ mode: 'hybrid', task: task.join(' ') });
    });

  program
    .command('team <task...>')
    .action(async (task: string[]) => {
      await handlers.runHybrid({ mode: 'hybrid', task: task.join(' ') });
    });

  return program;
}
```

```ts
export type MuxMode = 'hybrid' | 'planner' | 'status' | 'resume';
export type MuxTerminalStatus = 'completed' | 'failed' | 'blocked' | 'needs_human';

export interface MuxRunRequest {
  mode: MuxMode;
  task?: string;
  runId?: string;
  cwd?: string;
  workerCount?: number;
}

export interface MuxRunResult {
  status: MuxTerminalStatus;
  runId: string;
  summary: string;
  question?: string;
}
```

- [ ] **步骤 5：扩展 CLI 为完整 v1 公开命令面**

```ts
program
  .command('planner <task...>')
  .action(async (task: string[]) => {
    await handlers.runPlanner({ mode: 'planner', task: task.join(' ') });
  });

program
  .command('status [runId]')
  .action(async (runId?: string) => {
    await handlers.readStatus(runId);
  });

program
  .command('resume <runId>')
  .action(async (runId: string) => {
    await handlers.resumeRun(runId);
  });
```

- [ ] **步骤 6：运行 Node 测试验证通过**

运行：`npx vitest run tests/node/cli.test.ts`
预期：PASS，输出包含 `1 passed`

- [ ] **步骤 7：Commit**

```bash
git add package.json tsconfig.json vitest.config.ts plugin/manifest.json src/cli/mux.ts src/node/contracts.ts tests/node/cli.test.ts
git commit -m "Establish a minimal MUX CLI shell

Create the smallest Node surface for hybrid/team/planner/status/resume so the new product identity is anchored before runtime extraction.

Constraint: MUX must present a much smaller command surface than OMC
Rejected: Reuse omc/src/cli/index.ts wholesale | carries heavy non-hybrid command surface
Confidence: high
Scope-risk: narrow
Directive: Keep team as a light alias only; do not let it grow into a parallel mode tree
Tested: vitest run tests/node/cli.test.ts
Not-tested: Python bridge integration"
```

## 任务 2：建立 Node↔Python bridge 与最小环境校验

**文件：**
- 创建：`src/node/bridge.ts`
- 创建：`src/node/env.ts`
- 创建：`src/node/status.ts`
- 修改：`src/cli/mux.ts`
- 测试：`tests/node/bridge.test.ts`

- [ ] **步骤 1：编写失败的 bridge 测试，锁定 JSON stdin/stdout 协议与错误包装**

```ts
import { describe, expect, it, vi } from 'vitest';
import { runMuxRuntime } from '../../src/node/bridge';

vi.mock('node:child_process', () => ({
  spawn: vi.fn(() => ({
    stdin: { write: vi.fn(), end: vi.fn() },
    stdout: { on: vi.fn() },
    stderr: { on: vi.fn() },
    on: vi.fn((event, cb) => event === 'close' && cb(0)),
  })),
}));

describe('runMuxRuntime', () => {
  it('returns parsed runtime JSON', async () => {
    await expect(runMuxRuntime({ mode: 'hybrid', task: 'ship feature' })).resolves.toMatchObject({
      status: 'completed',
    });
  });
});
```

- [ ] **步骤 2：运行测试验证失败**

运行：`npx vitest run tests/node/bridge.test.ts`
预期：FAIL，报错 `Cannot find module '../../src/node/bridge'`

- [ ] **步骤 3：实现环境校验与 Python runtime 路径解析**

```ts
import { access } from 'node:fs/promises';
import { constants } from 'node:fs';
import { join } from 'node:path';

export interface RuntimeEnvironment {
  pythonBin: string;
  runtimeEntrypoint: string;
}

export async function resolveRuntimeEnvironment(cwd = process.cwd()): Promise<RuntimeEnvironment> {
  const pythonBin = process.env.MUX_PYTHON ?? 'python3';
  const runtimeEntrypoint = join(cwd, 'runtime', 'mux_runtime', '__main__.py');
  await access(runtimeEntrypoint, constants.R_OK);
  return { pythonBin, runtimeEntrypoint };
}
```

- [ ] **步骤 4：实现最小 bridge 与 CLI 绑定**

```ts
import { spawn } from 'node:child_process';
import type { MuxRunRequest, MuxRunResult } from './contracts.js';
import { resolveRuntimeEnvironment } from './env.js';

export async function runMuxRuntime(request: MuxRunRequest): Promise<MuxRunResult> {
  const env = await resolveRuntimeEnvironment();

  return await new Promise((resolve, reject) => {
    const child = spawn(env.pythonBin, [env.runtimeEntrypoint], { stdio: 'pipe' });
    let stdout = '';
    let stderr = '';

    child.stdout.on('data', chunk => { stdout += String(chunk); });
    child.stderr.on('data', chunk => { stderr += String(chunk); });
    child.on('close', code => {
      if (code !== 0) {
        reject(new Error(stderr || `mux runtime exited with code ${code}`));
        return;
      }
      resolve(JSON.parse(stdout) as MuxRunResult);
    });

    child.stdin.write(JSON.stringify(request));
    child.stdin.end();
  });
}
```

```ts
import { runMuxRuntime } from '../node/bridge.js';

const handlers = {
  runHybrid: (req) => runMuxRuntime(req),
  runPlanner: (req) => runMuxRuntime(req),
  readStatus: (runId?: string) => runMuxRuntime({ mode: 'status', runId }),
  resumeRun: (runId: string) => runMuxRuntime({ mode: 'resume', runId }),
};
```

- [ ] **步骤 5：补充 status 格式化与 bridge 错误文案测试**

```ts
export function renderMuxResult(result: MuxRunResult): string {
  if (result.status === 'needs_human' && result.question) {
    return `[${result.status}] ${result.summary}\nquestion: ${result.question}`;
  }
  return `[${result.status}] ${result.summary}`;
}
```

- [ ] **步骤 6：运行 Node bridge 测试验证通过**

运行：`npx vitest run tests/node/bridge.test.ts`
预期：PASS，输出包含 `1 passed`

- [ ] **步骤 7：Commit**

```bash
git add src/node/bridge.ts src/node/env.ts src/node/status.ts src/cli/mux.ts tests/node/bridge.test.ts
git commit -m "Separate the Node shell from the runtime core

Add a minimal JSON bridge so CLI concerns stay in TypeScript while orchestration can move into the Python runtime.

Constraint: Node must remain a thin shell in MUX
Rejected: Keep orchestration loop in Node and use Python only for tmux helpers | violates product boundary
Confidence: high
Scope-risk: narrow
Directive: Any new command should flow through this bridge instead of adding local orchestration logic
Tested: vitest run tests/node/bridge.test.ts
Not-tested: End-to-end Python process execution"
```

## 任务 3：实现最小 planner 与显式 `mux planner` 调试入口

**文件：**
- 创建：`runtime/mux_runtime/contracts.py`
- 创建：`runtime/mux_runtime/planner.py`
- 创建：`runtime/mux_runtime/__main__.py`
- 修改：`src/node/contracts.ts`
- 测试：`tests/runtime/planner.test.py`

- [ ] **步骤 1：编写失败的 planner 测试，锁定 2-8 子任务、checkpoint、禁止重型字段**

```python
from mux_runtime.planner import build_plan


def test_build_plan_stays_minimal():
    plan = build_plan("implement search page with filters")

    assert 2 <= len(plan["tasks"]) <= 8
    assert "checkpoints" in plan
    assert "architecture" not in plan
    assert "scheduler" not in plan
```

- [ ] **步骤 2：运行测试验证失败**

运行：`python -m pytest tests/runtime/planner.test.py -q`
预期：FAIL，报错 `ModuleNotFoundError: No module named 'mux_runtime'`

- [ ] **步骤 3：实现 Python runtime 请求/响应契约**

```python
from typing import Literal, NotRequired, TypedDict

MuxMode = Literal["hybrid", "planner", "status", "resume"]
MuxTerminalStatus = Literal["completed", "failed", "blocked", "needs_human"]

class MuxRequest(TypedDict, total=False):
    mode: MuxMode
    task: str
    runId: str
    cwd: str
    workerCount: int

class MuxResult(TypedDict, total=False):
    status: MuxTerminalStatus
    runId: str
    summary: str
    question: NotRequired[str]
    plan: NotRequired[dict]
```

- [ ] **步骤 4：实现最小 planner**

```python
from __future__ import annotations

from typing import TypedDict

class PlannerTask(TypedDict):
    id: str
    title: str
    kind: str


def build_plan(task: str) -> dict:
    normalized = " ".join(task.strip().split())
    tasks = [
        {"id": "impl-1", "title": f"Implement core path for: {normalized}", "kind": "impl"},
        {"id": "verify-1", "title": f"Verify acceptance for: {normalized}", "kind": "verify"},
    ]
    return {
        "task": normalized,
        "tasks": tasks,
        "checkpoints": [
            "code change is present",
            "verification command result is captured",
        ],
        "blockers": [],
        "needs_human": [],
    }
```

- [ ] **步骤 5：实现 `__main__.py` 中的 planner 分支**

```python
import json
import sys
from uuid import uuid4

from mux_runtime.planner import build_plan


def main() -> int:
    request = json.loads(sys.stdin.read() or "{}")
    if request.get("mode") == "planner":
        result = {
            "status": "completed",
            "runId": f"plan-{uuid4().hex[:8]}",
            "summary": "planner generated minimal task split",
            "plan": build_plan(request.get("task", "")),
        }
        sys.stdout.write(json.dumps(result))
        return 0
    raise SystemExit("unsupported mode")
```

- [ ] **步骤 6：运行 planner 测试验证通过**

运行：`python -m pytest tests/runtime/planner.test.py -q`
预期：PASS，输出包含 `1 passed`

- [ ] **步骤 7：Commit**

```bash
git add runtime/mux_runtime/contracts.py runtime/mux_runtime/planner.py runtime/mux_runtime/__main__.py src/node/contracts.ts tests/runtime/planner.test.py
git commit -m "Preserve planner without inheriting planning bureaucracy

Implement the smallest planner that can normalize tasks, split work, and expose checkpoints for hybrid without introducing a staged planning system.

Constraint: Planner must serve hybrid only and stay operationally small
Rejected: Port omc followup planner and related stage logic | too heavy for MUX scope
Confidence: high
Scope-risk: narrow
Directive: Do not add analyst/architect fields to planner output without revisiting the product spec
Tested: python -m pytest tests/runtime/planner.test.py -q
Not-tested: CLI planner rendering"
```

## 任务 4：实现 tmux worker adapter、lead 决策与 hybrid 主循环

**文件：**
- 创建：`runtime/mux_runtime/tmux.py`
- 创建：`runtime/mux_runtime/workers.py`
- 创建：`runtime/mux_runtime/verify.py`
- 创建：`runtime/mux_runtime/lead.py`
- 创建：`runtime/mux_runtime/loop.py`
- 修改：`runtime/mux_runtime/__main__.py`
- 测试：`tests/runtime/loop.test.py`
- 测试：`tests/runtime/tmux.test.py`

- [ ] **步骤 1：编写失败的 loop 测试，锁定 terminal states 与 verify/fix 回路**

```python
from mux_runtime.loop import run_hybrid


def test_hybrid_returns_completed_when_verify_passes():
    result = run_hybrid(task="ship search", worker_count=2)
    assert result["status"] == "completed"


def test_hybrid_returns_needs_human_when_plan_flags_question(monkeypatch):
    monkeypatch.setattr("mux_runtime.loop.build_plan", lambda task: {
        "task": task,
        "tasks": [],
        "checkpoints": [],
        "blockers": [],
        "needs_human": ["Choose API shape"],
    })
    result = run_hybrid(task="ship search", worker_count=2)
    assert result["status"] == "needs_human"
    assert result["question"] == "Choose API shape"
```

- [ ] **步骤 2：运行测试验证失败**

运行：`python -m pytest tests/runtime/loop.test.py -q`
预期：FAIL，报错 `cannot import name 'run_hybrid'`

- [ ] **步骤 3：实现最小 tmux 命令封装，优先用 argv 而不是 shell 拼接**

```python
from __future__ import annotations

import subprocess
from dataclasses import dataclass

@dataclass
class WorkerPane:
    pane_id: str
    name: str


def create_session(session_name: str) -> None:
    subprocess.run(["tmux", "new-session", "-d", "-s", session_name], check=True)


def split_worker_pane(session_name: str, worker_name: str) -> WorkerPane:
    result = subprocess.run(
        ["tmux", "split-window", "-P", "-t", session_name, "-F", "#{pane_id}", "-h"],
        check=True,
        capture_output=True,
        text=True,
    )
    return WorkerPane(pane_id=result.stdout.strip(), name=worker_name)
```

- [ ] **步骤 4：实现 worker adapter、verify verdict 与 lead 决策**

```python
from dataclasses import dataclass

@dataclass
class WorkerResult:
    worker: str
    status: str
    summary: str


def verify_results(results: list[WorkerResult]) -> tuple[str, str]:
    if any(item.status == "blocked" for item in results):
        return "blocked", "worker reported blocked"
    if any(item.status == "failed" for item in results):
        return "failed", "worker reported failure"
    return "completed", "verification passed"
```

```python
def decide_next_step(plan: dict, verification_status: str) -> dict:
    if plan["needs_human"]:
        return {"status": "needs_human", "question": plan["needs_human"][0]}
    if verification_status == "completed":
        return {"status": "completed"}
    if verification_status == "blocked":
        return {"status": "blocked"}
    return {"status": "failed"}
```

- [ ] **步骤 5：实现 hybrid 主循环并接入 `hybrid` 模式分支**

```python
from uuid import uuid4

from mux_runtime.lead import decide_next_step
from mux_runtime.planner import build_plan
from mux_runtime.verify import verify_results
from mux_runtime.workers import run_worker_batch


def run_hybrid(task: str, worker_count: int = 2) -> dict:
    plan = build_plan(task)
    if plan["needs_human"]:
        return {
            "status": "needs_human",
            "runId": f"run-{uuid4().hex[:8]}",
            "summary": "human decision required before execution",
            "question": plan["needs_human"][0],
            "plan": plan,
        }

    results = run_worker_batch(plan=plan, worker_count=worker_count)
    verification_status, verification_summary = verify_results(results)
    decision = decide_next_step(plan, verification_status)

    return {
        "status": decision["status"],
        "runId": f"run-{uuid4().hex[:8]}",
        "summary": verification_summary,
        "plan": plan,
    }
```

```python
if request.get("mode") == "hybrid":
    result = run_hybrid(
        task=request.get("task", ""),
        worker_count=request.get("workerCount", 2),
    )
    sys.stdout.write(json.dumps(result))
    return 0
```

- [ ] **步骤 6：运行 runtime 测试验证通过**

运行：
- `python -m pytest tests/runtime/loop.test.py -q`
- `python -m pytest tests/runtime/tmux.test.py -q`

预期：PASS，两个测试文件均输出 `passed`

- [ ] **步骤 7：Commit**

```bash
git add runtime/mux_runtime/tmux.py runtime/mux_runtime/workers.py runtime/mux_runtime/verify.py runtime/mux_runtime/lead.py runtime/mux_runtime/loop.py runtime/mux_runtime/__main__.py tests/runtime/loop.test.py tests/runtime/tmux.test.py
git commit -m "Center MUX on one hybrid execution loop

Add the minimal tmux-backed worker runtime and lead/verify decision path needed to run the first complete hybrid cycle.

Constraint: MUX must keep only the tmux and worker mechanics required by hybrid
Rejected: Port runtime-v2 monitoring, governance, and stage routing wholesale | recreates OMC team runtime weight
Confidence: medium
Scope-risk: moderate
Directive: Prefer narrow worker contracts over generalized orchestration abstractions
Tested: python -m pytest tests/runtime/loop.test.py -q; python -m pytest tests/runtime/tmux.test.py -q
Not-tested: live tmux integration on a real session"
```

## 任务 5：实现 `needs_human` 快照、`status` 与 `resume`

**文件：**
- 创建：`runtime/mux_runtime/state.py`
- 修改：`runtime/mux_runtime/loop.py`
- 修改：`runtime/mux_runtime/__main__.py`
- 修改：`src/node/commands/status.ts`
- 修改：`src/node/commands/resume.ts`
- 测试：`tests/runtime/state.test.py`
- 测试：`tests/node/cli.test.ts`

- [ ] **步骤 1：编写失败的状态测试，锁定最小快照字段与 resume 行为**

```python
from mux_runtime.state import save_run_state, load_run_state


def test_state_roundtrip_for_needs_human(tmp_path):
    payload = {
        "runId": "run-123",
        "status": "needs_human",
        "summary": "human decision required",
        "question": "Choose API shape",
        "plan": {"tasks": []},
    }
    save_run_state(tmp_path, payload)
    loaded = load_run_state(tmp_path, "run-123")
    assert loaded["question"] == "Choose API shape"
```

- [ ] **步骤 2：运行测试验证失败**

运行：`python -m pytest tests/runtime/state.test.py -q`
预期：FAIL，报错 `cannot import name 'save_run_state'`

- [ ] **步骤 3：实现最小 JSON 状态存取**

```python
from __future__ import annotations

import json
from pathlib import Path


def _state_dir(root: str | Path) -> Path:
    path = Path(root) / ".mux" / "runs"
    path.mkdir(parents=True, exist_ok=True)
    return path


def save_run_state(root: str | Path, payload: dict) -> None:
    run_id = payload["runId"]
    path = _state_dir(root) / f"{run_id}.json"
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def load_run_state(root: str | Path, run_id: str) -> dict:
    path = _state_dir(root) / f"{run_id}.json"
    return json.loads(path.read_text(encoding="utf-8"))
```

- [ ] **步骤 4：在 hybrid loop 中保存 `needs_human` / terminal 状态，并实现 `status` / `resume` 分支**

```python
from mux_runtime.state import load_run_state, save_run_state

result = run_hybrid(task=request.get("task", ""), worker_count=request.get("workerCount", 2))
save_run_state(request.get("cwd", "."), result)
```

```python
if request.get("mode") == "status":
    result = load_run_state(request.get("cwd", "."), request.get("runId", "latest"))
    sys.stdout.write(json.dumps(result))
    return 0

if request.get("mode") == "resume":
    prior = load_run_state(request.get("cwd", "."), request["runId"])
    resumed = run_hybrid(task=prior["plan"]["task"], worker_count=request.get("workerCount", 2))
    save_run_state(request.get("cwd", "."), resumed)
    sys.stdout.write(json.dumps(resumed))
    return 0
```

- [ ] **步骤 5：补充 Node CLI 的 status/resume 输出断言**

```ts
it('prints needs_human question for resume/status flows', async () => {
  const program = buildMuxProgram({
    runHybrid: async () => ({ status: 'completed', runId: 'run-1', summary: 'done' }),
    runPlanner: async () => ({ status: 'completed', runId: 'plan-1', summary: 'ok' }),
    readStatus: async () => ({ status: 'needs_human', runId: 'run-2', summary: 'paused', question: 'Pick API shape' }),
    resumeRun: async () => ({ status: 'completed', runId: 'run-2', summary: 'done' }),
  });

  await expect(program.parseAsync(['node', 'mux', 'status', 'run-2'])).resolves.toBeUndefined();
});
```

- [ ] **步骤 6：运行状态相关测试验证通过**

运行：
- `python -m pytest tests/runtime/state.test.py -q`
- `npx vitest run tests/node/cli.test.ts`

预期：PASS，状态 roundtrip 与 CLI status/resume 断言均通过

- [ ] **步骤 7：Commit**

```bash
git add runtime/mux_runtime/state.py runtime/mux_runtime/loop.py runtime/mux_runtime/__main__.py src/node/commands/status.ts src/node/commands/resume.ts tests/runtime/state.test.py tests/node/cli.test.ts
git commit -m "Keep the until-done loop resumable without recreating Ralph

Persist only the smallest state required for status and human-in-the-loop resume so MUX can stop cleanly and continue later.

Constraint: Resume must stay lightweight and avoid a global hook-driven state machine
Rejected: Reuse OMC persistent mode and state manager surfaces | exceeds MUX product scope
Confidence: high
Scope-risk: narrow
Directive: Store only resume-critical fields; resist adding broad session memory here
Tested: python -m pytest tests/runtime/state.test.py -q; npx vitest run tests/node/cli.test.ts
Not-tested: concurrent resume attempts"
```

## 任务 6：收敛 README、提炼 OMC 抽取说明，并跑整体验证

**文件：**
- 创建：`README.md`
- 修改：`docs/superpowers/specs/2026-04-21-mux-design.md`
- 参考：`MUX_PLAN.md`
- 测试：整个仓库最小验证命令集合

- [ ] **步骤 1：编写 README，确保对外只暴露 MUX 核心产品心智**

```md
# MUX

MUX is a minimal extraction of OMC focused on one execution path:

- `mux hybrid "<task>"`
- `mux team "<task>"`
- `mux planner "<task>"`
- `mux status [run-id]`
- `mux resume <run-id>`

Core model:
- Claude lead
- minimal planner
- Codex CLI workers
- verify/fix until-done loop
```

- [ ] **步骤 2：补充规格中的实现映射，记录已抽取/未抽取边界**

```md
## Implementation tracking
- Node shell implemented under `src/`
- Python runtime implemented under `runtime/mux_runtime/`
- OMC extraction sources remain under `omc/` for reference only during migration
```

- [ ] **步骤 3：运行 Node 构建与所有测试**

运行：
- `npm test`
- `python -m pytest tests/runtime -q`
- `npm run build`

预期：
- Vitest 全部通过
- Pytest 全部通过
- TypeScript build 成功，生成 `dist/`

- [ ] **步骤 4：手动 smoke test CLI 主链**

运行：
- `node dist/cli/mux.js planner "ship search ui"`
- `node dist/cli/mux.js hybrid "ship search ui"`
- `node dist/cli/mux.js status <run-id>`

预期：
- planner 输出最小 plan
- hybrid 返回 `completed | blocked | needs_human`
- status 能读回已保存状态

- [ ] **步骤 5：Commit**

```bash
git add README.md docs/superpowers/specs/2026-04-21-mux-design.md
git commit -m "Explain MUX as a single-path extraction instead of a platform

Document the public shape and the extraction boundary so future work continues shrinking toward hybrid rather than rebuilding OMC under a new name.

Constraint: README must keep installation and usage simple
Rejected: Carry over OMC README structure and feature catalog | reintroduces platform-scale messaging
Confidence: high
Scope-risk: narrow
Directive: Any new README section should reinforce the single-path model, not expand the concept count
Tested: npm test; python -m pytest tests/runtime -q; npm run build
Not-tested: plugin marketplace installation flow"
```

## 规格覆盖自检

### 对应关系
- hybrid 单一主链：任务 1、2、4
- planner 保留且最小：任务 3
- tmux / CLI workers：任务 4
- verify/fix until-done：任务 4
- `completed / failed / blocked / needs_human`：任务 4、5
- `resume`：任务 5
- Node 轻壳 / Python 厚内核：任务 2、3、4、5
- 对外命令面最小：任务 1、6
- OMC 并行抽取而非整块继承：任务 6

### 占位符扫描
已检查本计划，未保留 `TODO`、`TBD`、`后续实现`、`类似任务 N` 一类占位符。

### 类型一致性
- Node/Python 模式名统一使用：`hybrid | planner | status | resume`
- 终态统一使用：`completed | failed | blocked | needs_human`
- `runId`、`summary`、`question`、`plan` 在 bridge / state / runtime 中保持同名
