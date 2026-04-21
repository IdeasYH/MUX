from __future__ import annotations

from typing import Any, Literal, NotRequired, TypedDict

MuxMode = Literal['hybrid', 'planner', 'status', 'resume']
MuxTerminalStatus = Literal['completed', 'failed', 'blocked', 'needs_human']


class MuxRequest(TypedDict, total=False):
    mode: MuxMode
    task: str
    runId: str
    cwd: str
    workerCount: int


class PlannerTask(TypedDict):
    id: str
    title: str
    kind: Literal['impl', 'fix', 'verify']


class PlannerPlan(TypedDict):
    task: str
    tasks: list[PlannerTask]
    checkpoints: list[str]
    blockers: list[str]
    needs_human: list[str]


class MuxResult(TypedDict):
    status: MuxTerminalStatus
    runId: str
    summary: str
    question: NotRequired[str]
    plan: NotRequired[PlannerPlan]
    details: NotRequired[dict[str, Any]]
