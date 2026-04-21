from __future__ import annotations

from mux_runtime.contracts import PlannerPlan


def build_plan(task: str) -> PlannerPlan:
    normalized = ' '.join(task.strip().split()) or 'unspecified task'

    tasks = [
        {
            'id': 'impl-1',
            'title': f'Implement core path for: {normalized}',
            'kind': 'impl',
        },
        {
            'id': 'verify-1',
            'title': f'Verify acceptance for: {normalized}',
            'kind': 'verify',
        },
    ]

    return {
        'task': normalized,
        'tasks': tasks,
        'checkpoints': [
            'code change is present',
            'verification command result is captured',
        ],
        'blockers': [],
        'needs_human': [],
    }
