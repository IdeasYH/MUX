from __future__ import annotations

from mux_runtime.workers import WorkerResult


VerificationVerdict = tuple[str, str]


def verify_results(results: list[WorkerResult]) -> VerificationVerdict:
    if any(item.status == 'blocked' for item in results):
        return 'blocked', 'worker reported blocked'
    if any(item.status == 'failed' for item in results):
        return 'failed', 'worker reported failure'
    return 'completed', 'verification passed'
