from __future__ import annotations

import json
import sys
from pathlib import Path
from uuid import uuid4

if __package__ in {None, ''}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from mux_runtime.contracts import MuxRequest, MuxResult
from mux_runtime.loop import run_hybrid
from mux_runtime.planner import build_plan
from mux_runtime.state import load_run_state


def main() -> int:
    raw_request = sys.stdin.read() or '{}'
    request: MuxRequest = json.loads(raw_request)
    mode = request.get('mode')
    root = request.get('cwd', '.')

    if mode == 'planner':
        result: MuxResult = {
            'status': 'completed',
            'runId': f"plan-{uuid4().hex[:8]}",
            'summary': 'planner generated minimal task split',
            'plan': build_plan(request.get('task', '')),
        }
        sys.stdout.write(json.dumps(result))
        return 0

    if mode == 'hybrid':
        result = run_hybrid(
            task=request.get('task', ''),
            worker_count=request.get('workerCount', 2),
            root=root,
        )
        sys.stdout.write(json.dumps(result))
        return 0

    if mode == 'status':
        result = load_run_state(root, request.get('runId', 'latest'))
        sys.stdout.write(json.dumps(result))
        return 0

    if mode == 'resume':
        prior = load_run_state(root, request['runId'])
        resumed = run_hybrid(
            task=prior['plan']['task'],
            worker_count=request.get('workerCount', 2),
            root=root,
        )
        sys.stdout.write(json.dumps(resumed))
        return 0

    sys.stderr.write(f'unsupported mode: {mode}\n')
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
