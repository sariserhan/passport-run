import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("report", Path(__file__).parents[1] / "tools/summarize_events.py")
report = importlib.util.module_from_spec(spec)
spec.loader.exec_module(report)


class ReportTests(unittest.TestCase):
    def test_truncated_starts_and_duplicate_terminals(self):
        result = report.summarize([
            {"event": "run_started", "run_id": "a"},
            {"event": "run_failed", "run_id": "a", "elapsed_ms": 4000, "score": 3},
            {"event": "run_ended", "run_id": "a", "elapsed_ms": 6000},
            {"event": "run_failed", "run_id": "missing", "elapsed_ms": 99000, "score": 5},
        ])
        self.assertEqual(result["observed_terminal_runs_with_start"], 1)
        self.assertEqual(result["mean_observed_run_seconds"], 6)
        self.assertEqual(result["mean_failed_run_tiles"], 4)

    def test_malformed_values_do_not_crash_or_count_as_scores(self):
        result = report.summarize([None, 3, {}, {"event": "wrong_tile", "row": float("nan")}, {"event": "run_failed", "score": True}, {"event": "run_failed", "score": float("inf")}])
        self.assertIsNone(result["mean_failed_run_tiles"])
        self.assertEqual(result["wrong_row_distribution"], [])

    def test_sessions_are_observations_not_population_retention(self):
        result = report.summarize([
            {"event": "session_started", "session_id": "a", "at": 0},
            {"event": "session_started", "session_id": "a", "at": 1},
            {"event": "session_started", "session_id": "b", "at": 86400},
        ])
        self.assertEqual(result["sessions_by_utc_day"], {"1970-01-01": 1, "1970-01-02": 1})
        self.assertIn("No population D1", result["scope"])


if __name__ == "__main__":
    unittest.main()
