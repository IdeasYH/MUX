# MUX

**MUX** is a minimal multi-agent orchestration tool extracted from OMC and focused on **one execution path only**:

> **hybrid = lead + minimal planner + workers + verify/fix + until-done**

MUX is intentionally **not** a large general-purpose agent framework.
It keeps only the smallest useful set of team capabilities needed to run a practical hybrid loop.

---

# English

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
npm install -g github:YOUR_GITHUB_NAME/MUX
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

### Option A — One-line install from GitHub

```bash
npm install -g github:YOUR_GITHUB_NAME/MUX
```

### Option B — Local development install

If you are working on MUX itself:

```bash
git clone YOUR_MUX_REPO_URL
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
- marks basic blockers / `needs_human`

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

## What MUX removes

Compared with heavier systems, MUX intentionally removes:

- broad hook systems
- heavy memory/state ecosystems
- HUD and wiki systems
- large agent catalogs
- large staged pipelines
- broad orchestration product surfaces unrelated to the hybrid path

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
- tmux integration is practical but not large-scale platformized
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

---

# 中文

## MUX 是什么

MUX 是一个从 OMC 抽取出来的**极简多 Agent 编排工具**，只围绕一条主链工作：

> **hybrid = lead + 最小 planner + workers + verify/fix + until-done**

它不是一个大而全的新框架，而是一个可以在项目目录里直接使用的轻量 CLI 工具。

MUX 保留的核心只有这些：
- 一个真实模式：`hybrid`
- 一个轻别名：`team`
- 一个最小 planner
- 一个最小 runtime 闭环
- 一个最小 status / resume 机制

它**不会**发展成：
- 全能 Agent 平台
- 重型 hooks 运行环境
- 重型规划系统
- HUD / wiki / memory 平台
- staged pipeline 大产品

---

## 使用心智

MUX 应该是：**全局安装一次，在任意项目目录里使用。**

也就是说：
- MUX 安装在你的用户环境里
- MUX 操作的是你当前 shell 所在的项目目录

典型流程：

```bash
npm install -g github:YOUR_GITHUB_NAME/MUX
cd /path/to/your-project
mux planner "新增搜索页"
mux hybrid "实现搜索页"
```

---

## 前置环境

请先自己准备好这些环境：

- Node.js 20+
- Python 3
- tmux

MUX 故意**不**内置重型 setup / 安装器。
只要这些环境已经准备好，MUX 就应该能用尽量少的命令完成安装和使用。

---

## 安装

### 方式 A：从 GitHub 一行安装

```bash
npm install -g github:YOUR_GITHUB_NAME/MUX
```

### 方式 B：本地开发安装

如果你在开发 MUX 本身：

```bash
git clone YOUR_MUX_REPO_URL
cd MUX
npm install
npm run build
npm link
```

之后你就可以在本机全局使用 `mux`。

---

## 验证安装

安装后，进入任意目标项目目录执行：

```bash
cd /path/to/your-project
mux planner "hello world"
```

如果安装正常，你应该能看到一个最小 planner 输出。

典型输出大致如下：

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

## 基本使用

### 1）planner

如果你想先看最小任务拆分：

```bash
mux planner "实现带筛选器的搜索页"
```

planner 是刻意保持极简的。它只负责：
- 归一化任务
- 生成一个很小的执行拆分
- 标出基本 checkpoint
- 标出基础 blocker / `needs_human`

它**不会**变成重型规划系统。

---

### 2）hybrid

运行主执行链：

```bash
mux hybrid "实现带筛选器的搜索页"
```

这才是 MUX 里真正的核心模式。

---

### 3）team

`team` 只是 `hybrid` 的轻 alias：

```bash
mux team "实现带筛选器的搜索页"
```

在 MUX 里，`team` **不是**另一套重型独立系统。
它只是落到同一条 hybrid 主链上。

---

### 4）status

查看最近一次保存的运行状态：

```bash
mux status latest
```

或者查看某个具体 run：

```bash
mux status run-12345678
```

---

### 5）resume

如果某次运行停在 `needs_human`，之后可以恢复：

```bash
mux resume run-12345678
```

---

## 当前命令面

```bash
mux hybrid "<task>"
mux team "<task>"
mux planner "<task>"
mux status [run-id]
mux resume <run-id>
```

---

## MUX 保留了什么

- 多 Agent / team 编排能力
- 唯一真实公共执行路径：`hybrid`
- 最小 planner
- 最小 worker runtime
- 最小 verify/fix 闭环
- 最小 `completed | failed | blocked | needs_human` 闭环
- 最小 status / resume 支持

---

## MUX 删除了什么

相比重型系统，MUX 刻意删掉了：

- 大量 hooks 系统
- 重型 memory / state 体系
- HUD 和 wiki
- 大规模 agent catalog
- staged pipeline
- 与 hybrid 主链无关的大而全产品面

---

## 当前实现说明

现在的 MUX 已经包含：
- Node CLI 外壳
- Node ↔ Python runtime bridge
- 最小 planner
- hybrid loop
- 最小 tmux adapter
- 最小 run-state 持久化
- `status` / `resume`

当前实现刻意保持小。
这意味着：
- worker runtime 仍然是最小实现
- tmux 集成可用，但不是平台级大系统
- 产品目标优先是简单，而不是大而全

---

## 常见问题排查

### `mux: command not found`
通常是全局 npm bin 没有加入 `PATH`。
请确认全局安装成功，并确保 shell 能找到 npm 的全局可执行文件。

### `MUX runtime entrypoint is missing`
通常是包安装不完整，或者 build / 安装过程异常。
请重新安装 MUX。

### Python 找不到
先确认：

```bash
python3 --version
```

### tmux 找不到
先确认：

```bash
tmux -V
```

### Node 版本过低
先确认：

```bash
node --version
```

MUX 需要 Node.js 20+。

---

## 本地开发

安装依赖：

```bash
npm install
```

构建：

```bash
npm run build
```

运行 Node 测试：

```bash
./node_modules/.bin/vitest run tests/node/cli.test.ts
./node_modules/.bin/vitest run tests/node/bridge.test.ts
```

运行 runtime 测试：

```bash
python3 tests/runtime/planner.test.py
python3 tests/runtime/loop.test.py
python3 tests/runtime/state.test.py
python3 tests/runtime/tmux.test.py
```

---

## 设计原则

MUX 的存在意义就是保持小。

如果一个功能会让 MUX 再次变成大而全的编排平台，那大概率就是错误方向。

MUX 应该始终保持：
- 轻
- 单一职责
- 易安装
- 易解释
- 只围绕 hybrid 主链

