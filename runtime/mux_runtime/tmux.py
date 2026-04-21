from __future__ import annotations

import subprocess
from dataclasses import dataclass
from typing import Callable, Protocol


class RunLike(Protocol):
    def __call__(self, *args: object, **kwargs: object) -> subprocess.CompletedProcess[str]:
        ...


@dataclass(frozen=True)
class WorkerPane:
    pane_id: str
    name: str


def create_session(session_name: str, runner: RunLike = subprocess.run) -> None:
    runner(['tmux', 'new-session', '-d', '-s', session_name], check=True)


def split_worker_pane(
    session_name: str,
    worker_name: str,
    runner: RunLike = subprocess.run,
) -> WorkerPane:
    result = runner(
        ['tmux', 'split-window', '-P', '-t', session_name, '-F', '#{pane_id}', '-h'],
        check=True,
        capture_output=True,
        text=True,
    )
    return WorkerPane(pane_id=result.stdout.strip(), name=worker_name)


def close_session(session_name: str, runner: RunLike = subprocess.run) -> None:
    runner(['tmux', 'kill-session', '-t', session_name], check=True)
