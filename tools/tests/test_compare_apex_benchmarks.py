"""Unit tests for the APEX benchmark comparator (no Godot dependency)."""
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from compare_apex_benchmarks import BenchmarkError, parse_growth_log, summarize


def make_log(ticks=500, block_ms=250.0, sporting_hash="stable"):
    rows = [
        {"tick": tick, "block_ms": block_ms,
         "memory_static_bytes": 1234567}
        for tick in range(250, ticks + 1, 250)
    ]
    return "Godot startup\nGROWTH_DONE " + json.dumps({
        "ticks": ticks, "rows": rows, "hash": sporting_hash,
    }) + "\n"


class BenchmarkComparatorTests(unittest.TestCase):
    def test_parses_completed_measurements(self):
        result = parse_growth_log(make_log(), 500)
        self.assertEqual(result["ticks"], 500)
        self.assertEqual(result["sporting_hash"], "stable")
        self.assertEqual(result["ms_per_tick"], 1.0)
        self.assertEqual(result["peak_static_monitor_bytes"], 1234567)

    def test_missing_completion_marker_is_not_success(self):
        with self.assertRaises(BenchmarkError):
            parse_growth_log("ERROR: test stopped", 500)

    def test_partial_ticks_rejected(self):
        with self.assertRaises(BenchmarkError):
            parse_growth_log(make_log(500), 1000)

    def test_non_finite_measurement_rejected(self):
        with self.assertRaises(BenchmarkError):
            parse_growth_log(make_log(block_ms=float("nan")), 500)

    def test_identical_hash_and_script_allows_comparison(self):
        base = [parse_growth_log(make_log(block_ms=250), 500) for _ in range(3)]
        candidate = [parse_growth_log(make_log(block_ms=225), 500) for _ in range(3)]
        summary = summarize(base, candidate, "script", "script")
        self.assertEqual(summary["status"], "COMPARABLE")
        self.assertAlmostEqual(summary["delta_percent"], -10.0)

    def test_changed_sporting_hash_blocks_percent(self):
        base = [parse_growth_log(make_log(sporting_hash="before"), 500)] * 2
        candidate = [parse_growth_log(make_log(sporting_hash="after"), 500)] * 2
        summary = summarize(base, candidate, "same", "same")
        self.assertEqual(summary["status"], "INCOMPARABLE")
        self.assertIsNone(summary["delta_percent"])

    def test_changed_benchmark_code_blocks_percent(self):
        data = [parse_growth_log(make_log(), 500)] * 2
        summary = summarize(data, data, "old", "new")
        self.assertEqual(summary["status"], "INCOMPARABLE")

    def test_inconsistent_repeats_fail(self):
        base = [parse_growth_log(make_log(sporting_hash="a"), 500),
                parse_growth_log(make_log(sporting_hash="b"), 500)]
        candidate = [parse_growth_log(make_log(), 500)] * 2
        with self.assertRaisesRegex(BenchmarkError, "NONDETERMINISTIC"):
            summarize(base, candidate, "same", "same")


if __name__ == "__main__":
    unittest.main()
