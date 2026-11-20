"""Unit tests for the APEX benchmark comparator (no Godot dependency)."""
import json
from pathlib import Path
import sys
import unittest
from tempfile import TemporaryDirectory

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from compare_apex_benchmarks import BenchmarkError, parse_growth_log, read_run_log, summarize, verify_warmups


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

    def test_warmup_matching_measured_hash_passes(self):
        sample = parse_growth_log(make_log(), 500)
        verify_warmups({"base": sample, "candidate": sample},
                       {"base": [sample], "candidate": [sample]})

    def test_warmup_different_hash_is_not_silently_discarded(self):
        warmup = parse_growth_log(make_log(sporting_hash="warmup"), 500)
        measured = parse_growth_log(make_log(sporting_hash="measured"), 500)
        with self.assertRaisesRegex(BenchmarkError, "NONDETERMINISTIC"):
            verify_warmups({"base": warmup, "candidate": measured},
                           {"base": [measured], "candidate": [measured]})

    def test_missing_warmup_rejected(self):
        sample = parse_growth_log(make_log(), 500)
        with self.assertRaises(BenchmarkError):
            verify_warmups({}, {"base": [sample], "candidate": [sample]})

    def test_ci_log_is_parsed_without_external_command(self):
        with TemporaryDirectory() as td:
            root = Path(td)
            (root / "base-0.log").write_text(make_log(), encoding="utf-8")
            self.assertEqual(read_run_log(root, "base", 0, 500)["ticks"], 500)

    def test_missing_log_rejected(self):
        with TemporaryDirectory() as td:
            with self.assertRaisesRegex(BenchmarkError, "Missing CI-generated"):
                read_run_log(Path(td), "candidate", 2, 500)

    def test_untrusted_label_rejected(self):
        with TemporaryDirectory() as td:
            with self.assertRaisesRegex(BenchmarkError, "Invalid benchmark log identity"):
                read_run_log(Path(td), "../outside", 0, 500)

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
