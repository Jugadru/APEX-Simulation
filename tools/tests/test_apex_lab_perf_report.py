"""Offline checks for the synthetic Test Lab profiler report contract."""
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_lab_perf_report import LabPerfError, read_log

def valid():
    runs = []
    for weather in ("Seco", "Chuva intensa"):
        for rep in (1, 2):
            runs.append({
                "weather": weather, "repetition": rep, "seed": 991420, "cars": 24,
                "ticks": 500, "finished": False, "sporting_hash": ("a" if weather == "Seco" else "b") * 64,
                "mean_us": 50.0, "p95_us": 70, "max_us": 100,
                "early_mean_us": 45.0, "late_mean_us": 53.0,
                "peak_static_bytes": 12000000, "wall_seconds": 1.0,
                "simulated_seconds_per_wall_second": 500.0,
            })
    return {"schema": 1, "status": "PASS", "track": "LAB", "ticks": 500,
            "runs": runs}

def log(payload):
    return "Godot 4.7.2\nAPEX_LAB_PERF_RESULT " + json.dumps(payload) + "\nAPEX_LAB_PERF_PASS checks=12\n"

class LabProfilerTests(unittest.TestCase):
    def test_valid_four_runs(self):
        data = read_log(log(valid()))
        self.assertEqual(data["cases"], 4)
        self.assertEqual(data["total_ticks"], 2000)
    def test_rejects_changed_sporting_hash(self):
        data = valid()
        data["runs"][1]["sporting_hash"] = "c"*64
        with self.assertRaisesRegex(LabPerfError, "NONDETERMINISTIC"):
            read_log(log(data))
    def test_rejects_wrong_track(self):
        data = valid()
        data["track"] = "MON"
        with self.assertRaisesRegex(LabPerfError, "Wrong synthetic circuit"):
            read_log(log(data))
    def test_rejects_missing_or_duplicate_marker(self):
        with self.assertRaises(LabPerfError):
            read_log("nothing")
        with self.assertRaises(LabPerfError):
            read_log(log(valid()) + log(valid()))
    def test_rejects_fake_or_incomplete_work(self):
        data = valid()
        data["runs"][0]["ticks"] = 100
        with self.assertRaises(LabPerfError):
            read_log(log(data))
    def test_rejects_invalid_cpu_observation(self):
        data = valid()
        data["runs"][0]["p95_us"] = -3
        with self.assertRaisesRegex(LabPerfError, "p95"):
            read_log(log(data))
    def test_rejects_errors_even_with_pass_marker(self):
        with self.assertRaises(LabPerfError):
            read_log(log(valid())+"SCRIPT ERROR: parse failed\n")

if __name__ == "__main__":
    unittest.main()
