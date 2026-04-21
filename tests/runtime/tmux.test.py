import sys
import unittest
from pathlib import Path
from unittest.mock import Mock

ROOT = Path(__file__).resolve().parents[2]
RUNTIME_ROOT = ROOT / 'runtime'
if str(RUNTIME_ROOT) not in sys.path:
    sys.path.insert(0, str(RUNTIME_ROOT))

from mux_runtime.tmux import create_session, split_worker_pane


class TmuxAdapterTests(unittest.TestCase):
    def test_create_session_uses_safe_argv(self) -> None:
        runner = Mock()

        create_session('mux-test', runner=runner)

        runner.assert_called_once_with(['tmux', 'new-session', '-d', '-s', 'mux-test'], check=True)

    def test_split_worker_pane_returns_worker_pane(self) -> None:
        runner = Mock()
        runner.return_value.stdout = '%42\n'

        pane = split_worker_pane('mux-test', 'worker-1', runner=runner)

        runner.assert_called_once_with(
            ['tmux', 'split-window', '-P', '-t', 'mux-test', '-F', '#{pane_id}', '-h'],
            check=True,
            capture_output=True,
            text=True,
        )
        self.assertEqual(pane.pane_id, '%42')
        self.assertEqual(pane.name, 'worker-1')


if __name__ == '__main__':
    unittest.main()
