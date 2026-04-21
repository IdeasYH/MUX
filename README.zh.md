# MUX

[English](./README.md)

**MUX** 是一个极简多 Agent 编排工具，只围绕**一条执行主链**工作：

> **hybrid = lead + 最小 planner + workers + verify/fix + until-done**

MUX 刻意**不是**一个大而全的通用 Agent 框架。
它只保留运行一条实用 hybrid 闭环所需的最小团队能力。

---

## MUX 是什么

MUX 是一个轻量 CLI 工具，用来在你的项目目录中运行一个最小多 Agent 工作流。

它只保留这些核心概念：
- 一个真实模式：`hybrid`
- 一个轻别名：`team`
- 一个最小 planner
- 一个最小 runtime 闭环
- 一个最小 status / resume 机制

它**不会**变成：
- 全功能 Agent 平台
- 重型 hook 运行环境
- 大型规划系统
- HUD / wiki / memory 系统
- 分阶段编排大产品

---

## 使用心智

**全局安装一次**，然后在**任意项目目录里使用**。

也就是说：
- MUX 本身安装在你的用户环境中
- MUX 操作的是你当前 shell 所在的项目目录

典型流程：

```bash
npm install -g github:IdeasYH/MUX
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

MUX 刻意**不**内置重型 setup / 安装器。
只要这些环境已经准备好，MUX 就应该能用尽量少的命令完成安装和使用。

---

## 安装

### GitHub 一行安装

```bash
npm install -g github:IdeasYH/MUX
```

### 本地开发安装

如果你在开发 MUX 本身：

```bash
git clone https://github.com/IdeasYH/MUX.git
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

如果安装正常，你应该能看到最小 planner 输出。

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

先看最小任务拆分：

```bash
mux planner "实现带筛选器的搜索页"
```

planner 是刻意保持极简的。它只负责：
- 归一化任务
- 生成一个很小的执行拆分
- 标出基本 checkpoint
- 标出基础 blocker
- 标出基础 `needs_human`

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

## MUX 不想变成什么

- 大型 hook 系统
- 重型 memory/state 平台
- HUD 或 wiki 系统
- 大规模 agent catalog
- staged orchestration pipeline
- 与 hybrid 主链无关的大型编排产品

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
