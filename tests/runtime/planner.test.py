import json
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RUNTIME_ROOT = ROOT / 'runtime'
if str(RUNTIME_ROOT) not in sys.path:
    sys.path.insert(0, str(RUNTIME_ROOT))

from mux_runtime.planner import build_plan


class PlannerTests(unittest.TestCase):
    def test_build_plan_stays_minimal(self) -> None:
        plan = build_plan('  implement   search page with filters  ')

        self.assertEqual(plan['task'], 'implement search page with filters')
        self.assertGreaterEqual(len(plan['tasks']), 2)
        self.assertLessEqual(len(plan['tasks']), 8)
        self.assertIn('checkpoints', plan)
        self.assertNotIn('architecture', plan)
        self.assertNotIn('scheduler', plan)
        self.assertEqual(plan['blockers'], [])
        self.assertEqual(plan['needs_human'], [])
        self.assertEqual({task['kind'] for task in plan['tasks']}, {'impl', 'verify'})

    def test_runtime_planner_mode_returns_plan_payload(self) -> None:
        command = [sys.executable, str(ROOT / 'runtime' / 'mux_runtime' / '__main__.py')]
        completed = subprocess.run(
            command,
            input=json.dumps({'mode': 'planner', 'task': 'ship search ui'}),
            text=True,
            capture_output=True,
            cwd=ROOT,
            check=False,
        )

        self.assertEqual(completed.returncode, 0, completed.stderr)
        payload = json.loads(completed.stdout)
        self.assertEqual(payload['status'], 'completed')
        self.assertEqual(payload['summary'], 'planner generated minimal task split')
        self.assertEqual(payload['plan']['task'], 'ship search ui')
        self.assertGreaterEqual(len(payload['plan']['tasks']), 2)
        self.assertLessEqual(len(payload['plan']['tasks']), 8)


if __name__ == '__main__':
    unittest.main()
