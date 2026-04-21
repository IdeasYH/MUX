from __future__ import annotations

import json
from pathlib import Path
from typing import Any


def _state_dir(root: str | Path) -> Path:
    path = Path(root) / '.mux' / 'runs'
    path.mkdir(parents=True, exist_ok=True)
    return path


def save_run_state(root: str | Path, payload: dict[str, Any]) -> None:
    state_dir = _state_dir(root)
    run_id = payload['runId']
    content = json.dumps(payload, indent=2)
    (state_dir / f'{run_id}.json').write_text(content, encoding='utf-8')
    (state_dir / 'latest.json').write_text(content, encoding='utf-8')


def load_run_state(root: str | Path, run_id: str) -> dict[str, Any]:
    filename = 'latest.json' if run_id == 'latest' else f'{run_id}.json'
    path = _state_dir(root) / filename
    return json.loads(path.read_text(encoding='utf-8'))
