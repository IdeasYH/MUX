# MUX

[中文说明](./README.zh.md)

**MUX** is a minimal multi-agent orchestration tool focused on **one execution path only**:

> **hybrid = lead + minimal planner + workers + verify/fix + until-done**

MUX is intentionally **not** a large general-purpose agent framework.
It keeps only the smallest useful set of team capabilities needed to run a practical hybrid loop.

---

## What MUX is

MUX is a lightweight CLI tool for running a minimal multi-agent workflow inside your project directory.

It keeps these core ideas:
- one real mode: `hybrid`
- one light alias: `team`
- one minimal planner
- one minimal runtime loop
- one minimal resume/status mechanism

It does **not** try to be:
- a full agent platform
- a hook-heavy operating environment
- a large planning framework
- a HUD/wiki/memory system
- a big staged orchestration product

---

## Mental model

Install MUX **globally once**, then use it **inside any project**.

That means:
- MUX itself lives in your user environment
- MUX works on the project in your current shell directory

Typical flow:

```bash
npm install -g github:IdeasYH/MUX
cd /path/to/your-project
mux planner "add a search page"
mux hybrid "implement the search page"
```

---

## Prerequisites

Please install these yourself before installing MUX:

- Node.js 20+
- Python 3
- tmux

MUX intentionally does **not** include a heavy setup or environment installer.
If your environment is ready, MUX should install and run with very few commands.

---

## Install

### One-line install from GitHub

```bash
npm install -g github:IdeasYH/MUX
```

### Local development install

If you are working on MUX itself:

```bash
git clone https://github.com/IdeasYH/MUX.git
cd MUX
npm install
npm run build
npm link
```

Then you can use `mux` globally on your machine.

---

## Verify installation

After installing MUX, go to any target project directory and run:

```bash
cd /path/to/your-project
mux planner "hello world"
```

You should see a minimal planner result.

A typical output looks like:

```text
[completed] planner generated minimal task split
{
  "task": "hello world",
  "tasks": [
    {
      "id": "impl-1",
      "title": "Implement core path for: hello world",
      "kind": "impl"
    },
    {
      "id": "verify-1",
      "title": "Verify acceptance for: hello world",
      "kind": "verify"
    }
  ],
  "checkpoints": [
    "code change is present",
    "verification command result is captured"
  ],
  "blockers": [],
  "needs_human": []
}
```

---

## Basic usage

### 1. Planner

Use planner to preview the minimal split before execution:

```bash
mux planner "implement search page with filters"
```

Planner is intentionally small.
It only:
- normalizes the task
- creates a tiny execution split
- marks basic checkpoints
- marks basic blockers
- marks basic `needs_human`

It does **not** become a heavy planning system.

---

### 2. Hybrid

Run the main execution path:

```bash
mux hybrid "implement search page with filters"
```

This is the real core mode.

---

### 3. Team

`team` is just a light alias to `hybrid`:

```bash
mux team "implement search page with filters"
```

In MUX, `team` is **not** a second large execution system.
It maps into the same hybrid loop.

---

### 4. Status

Read the latest saved run state:

```bash
mux status latest
```

Or read a specific run:

```bash
mux status run-12345678
```

---

### 5. Resume

If a run stopped at `needs_human`, you can resume it later:

```bash
mux resume run-12345678
```

---

## Current command surface

```bash
mux hybrid "<task>"
mux team "<task>"
mux planner "<task>"
mux status [run-id]
mux resume <run-id>
```

---

## What MUX keeps

- multi-agent / team orchestration
- one real public execution path: `hybrid`
- minimal planner
- minimal worker runtime
- minimal verify/fix loop
- minimal `completed | failed | blocked | needs_human` closure
- minimal status/resume support

---

## What MUX does not try to be

- a broad hook system
- a heavy memory/state platform
- a HUD or wiki system
- a large agent catalog
- a staged orchestration pipeline
- a broad orchestration product unrelated to the hybrid path

---

## Current implementation notes

Today MUX already includes:
- Node CLI shell
- Node ↔ Python runtime bridge
- minimal planner
- hybrid loop
- minimal tmux adapter
- minimal run-state persistence
- `status` / `resume`

Current implementation is intentionally small.
That means:
- worker runtime is still minimal
- tmux integration is practical but not platformized
- the product is optimized for simplicity, not breadth

---

## Troubleshooting

### `mux: command not found`
Your global npm bin path may not be on `PATH`.
Try reinstalling globally and ensure your shell can find npm global binaries.

### `MUX runtime entrypoint is missing`
The package may not have been built or installed correctly.
Reinstall MUX.

### Python not found
Install Python 3 and verify:

```bash
python3 --version
```

### tmux not found
Install tmux and verify:

```bash
tmux -V
```

### Node version too old
Check:

```bash
node --version
```

MUX expects Node.js 20+.

---

## Local development

Install dependencies:

```bash
npm install
```

Build:

```bash
npm run build
```

Run Node tests:

```bash
./node_modules/.bin/vitest run tests/node/cli.test.ts
./node_modules/.bin/vitest run tests/node/bridge.test.ts
```

Run runtime tests:

```bash
python3 tests/runtime/planner.test.py
python3 tests/runtime/loop.test.py
python3 tests/runtime/state.test.py
python3 tests/runtime/tmux.test.py
```

---

## Philosophy

MUX exists to stay small.

If a feature makes MUX feel like a large orchestration platform again, it is probably the wrong direction.

MUX should remain:
- light
- single-purpose
- easy to install
- easy to explain
- centered on the hybrid path only
