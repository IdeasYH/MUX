import json
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
RUNTIME_ROOT = ROOT / 'runtime'
if str(RUNTIME_ROOT) not in sys.path:
    sys.path.insert(0, str(RUNTIME_ROOT))

from mux_runtime.loop import run_hybrid
from mux_runtime.workers import WorkerResult


class HybridLoopTests(unittest.TestCase):
    @patch('mux_runtime.loop.run_worker_batch')
    def test_hybrid_returns_completed_when_verify_passes(self, run_worker_batch_mock) -> None:
        run_worker_batch_mock.return_value = [
            WorkerResult(worker='worker-1', status='completed', summary='implemented core path'),
            WorkerResult(worker='worker-2', status='completed', summary='captured verification output'),
        ]

        result = run_hybrid(task='ship search', worker_count=2)

        self.assertEqual(result['status'], 'completed')
        self.assertEqual(result['summary'], 'verification passed')
        self.assertEqual(result['plan']['task'], 'ship search')

    @patch('mux_runtime.loop.build_plan')
    def test_hybrid_returns_needs_human_when_plan_flags_question(self, build_plan_mock) -> None:
        build_plan_mock.return_value = {
            'task': 'ship search',
            'tasks': [],
            'checkpoints': [],
            'blockers': [],
            'needs_human': ['Choose API shape'],
        }

        result = run_hybrid(task='ship search', worker_count=2)

        self.assertEqual(result['status'], 'needs_human')
        self.assertEqual(result['question'], 'Choose API shape')
        self.assertEqual(result['summary'], 'human decision required before execution')

    @patch('mux_runtime.loop.run_worker_batch')
    def test_hybrid_returns_blocked_when_worker_batch_is_blocked(self, run_worker_batch_mock) -> None:
        run_worker_batch_mock.return_value = [
            WorkerResult(worker='worker-1', status='blocked', summary='waiting for credentials'),
        ]

        result = run_hybrid(task='ship search', worker_count=1)

        self.assertEqual(result['status'], 'blocked')
        self.assertEqual(result['summary'], 'worker reported blocked')

    def test_runtime_hybrid_mode_returns_payload(self) -> None:
        command = [sys.executable, str(ROOT / 'runtime' / 'mux_runtime' / '__main__.py')]
        completed = subprocess.run(
            command,
            input=json.dumps({'mode': 'hybrid', 'task': 'ship search ui', 'workerCount': 2}),
            text=True,
            capture_output=True,
            cwd=ROOT,
            check=False,
        )

        self.assertEqual(completed.returncode, 0, completed.stderr)
        payload = json.loads(completed.stdout)
        self.assertEqual(payload['status'], 'completed')
        self.assertEqual(payload['plan']['task'], 'ship search ui')
        self.assertIn('summary', payload)


if __name__ == '__main__':
    unittest.main()
