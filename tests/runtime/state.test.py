from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNTIME_MAIN = ROOT / 'runtime' / 'mux_runtime' / '__main__.py'

sys.path.insert(0, str(ROOT / 'runtime'))

from mux_runtime.state import load_run_state, save_run_state


class StateRoundTripTest(unittest.TestCase):
    def test_state_roundtrip_for_needs_human(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            payload = {
                'runId': 'run-123',
                'status': 'needs_human',
                'summary': 'human decision required',
                'question': 'Choose API shape',
                'plan': {'task': 'ship search', 'tasks': []},
            }
            save_run_state(tmpdir, payload)
            loaded = load_run_state(tmpdir, 'run-123')
            self.assertEqual(loaded['question'], 'Choose API shape')
            self.assertEqual(loaded['runId'], 'run-123')

    def test_runtime_status_and_resume_flow(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            initial = {
                'runId': 'run-xyz',
                'status': 'needs_human',
                'summary': 'paused for human input',
                'question': 'Choose API shape',
                'plan': {
                    'task': 'ship search ui',
                    'tasks': [],
                    'checkpoints': [],
                    'blockers': [],
                    'needs_human': [],
                },
            }
            save_run_state(tmpdir, initial)

            status_proc = subprocess.run(
                [sys.executable, str(RUNTIME_MAIN)],
                input=json.dumps({'mode': 'status', 'cwd': tmpdir, 'runId': 'run-xyz'}),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(status_proc.returncode, 0, status_proc.stderr)
            status_payload = json.loads(status_proc.stdout)
            self.assertEqual(status_payload['status'], 'needs_human')
            self.assertEqual(status_payload['question'], 'Choose API shape')

            resume_proc = subprocess.run(
                [sys.executable, str(RUNTIME_MAIN)],
                input=json.dumps({'mode': 'resume', 'cwd': tmpdir, 'runId': 'run-xyz', 'workerCount': 1}),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(resume_proc.returncode, 0, resume_proc.stderr)
            resume_payload = json.loads(resume_proc.stdout)
            self.assertEqual(resume_payload['status'], 'completed')
            self.assertEqual(resume_payload['plan']['task'], 'ship search ui')

            latest = load_run_state(tmpdir, 'latest')
            self.assertEqual(latest['runId'], resume_payload['runId'])
            self.assertEqual(latest['status'], 'completed')


if __name__ == '__main__':
    unittest.main()
