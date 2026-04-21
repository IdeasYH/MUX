from __future__ import annotations

from typing import Any
from uuid import uuid4

from mux_runtime.lead import decide_next_step
from mux_runtime.planner import build_plan
from mux_runtime.state import save_run_state
from mux_runtime.verify import verify_results
from mux_runtime.workers import run_worker_batch


HybridResult = dict[str, Any]


def run_hybrid(task: str, worker_count: int = 2, root: str = '.') -> HybridResult:
    plan = build_plan(task)
    run_id = f"run-{uuid4().hex[:8]}"

    if plan.get('needs_human'):
        result: HybridResult = {
            'status': 'needs_human',
            'runId': run_id,
            'summary': 'human decision required before execution',
            'question': plan['needs_human'][0],
            'plan': plan,
        }
        save_run_state(root, result)
        return result

    results = run_worker_batch(plan=plan, worker_count=worker_count)
    verification_status, verification_summary = verify_results(results)
    decision = decide_next_step(plan, verification_status)

    payload: HybridResult = {
        'status': decision['status'],
        'runId': run_id,
        'summary': verification_summary,
        'plan': plan,
        'details': {
            'workers': [
                {
                    'worker': item.worker,
                    'status': item.status,
                    'summary': item.summary,
                    'paneId': item.pane_id,
                }
                for item in results
            ]
        },
    }
    if 'question' in decision:
        payload['question'] = decision['question']

    save_run_state(root, payload)
    return payload
