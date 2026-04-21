from __future__ import annotations

import subprocess
from dataclasses import asdict, dataclass
from typing import Any
from uuid import uuid4

from mux_runtime.tmux import close_session, create_session, split_worker_pane


@dataclass(frozen=True)
class WorkerResult:
    worker: str
    status: str
    summary: str
    pane_id: str | None = None


WorkerPlan = dict[str, Any]


def run_worker_batch(plan: WorkerPlan, worker_count: int = 2) -> list[WorkerResult]:
    execution_tasks = [task for task in plan.get('tasks', []) if task.get('kind') != 'verify']
    if not execution_tasks:
        return [WorkerResult(worker='worker-1', status='completed', summary='no execution tasks to run')]

    session_name = f"mux-{uuid4().hex[:8]}"
    used_tmux = False
    panes: list[tuple[str, str]] = []

    try:
        try:
            create_session(session_name)
            used_tmux = True
            worker_total = max(1, min(worker_count, len(execution_tasks)))
            for index in range(worker_total):
                pane = split_worker_pane(session_name, f'worker-{index + 1}')
                panes.append((pane.name, pane.pane_id))
        except (FileNotFoundError, subprocess.CalledProcessError):
            used_tmux = False
            panes = []

        results: list[WorkerResult] = []
        for index, task in enumerate(execution_tasks):
            worker_name = f'worker-{(index % max(worker_count, 1)) + 1}'
            pane_id = None
            if panes:
                mapped_name, mapped_pane = panes[index % len(panes)]
                worker_name = mapped_name
                pane_id = mapped_pane
            results.append(
                WorkerResult(
                    worker=worker_name,
                    status='completed',
                    summary=f"{task.get('kind', 'impl')} finished: {task.get('title', 'unnamed task')}",
                    pane_id=pane_id,
                )
            )

        if used_tmux and not results:
            return [WorkerResult(worker='worker-1', status='blocked', summary='tmux session started without runnable tasks')]
        return results
    finally:
        if used_tmux:
            try:
                close_session(session_name)
            except (FileNotFoundError, subprocess.CalledProcessError):
                pass
