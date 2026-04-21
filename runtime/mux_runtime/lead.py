from __future__ import annotations

from typing import Any


LeadDecision = dict[str, str]
PlannerPlan = dict[str, Any]


def decide_next_step(plan: PlannerPlan, verification_status: str) -> LeadDecision:
    if plan.get('needs_human'):
        return {'status': 'needs_human', 'question': plan['needs_human'][0]}
    if verification_status == 'completed':
        return {'status': 'completed'}
    if verification_status == 'blocked':
        return {'status': 'blocked'}
    return {'status': 'failed'}
