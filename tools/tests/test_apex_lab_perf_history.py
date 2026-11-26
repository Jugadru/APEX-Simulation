import copy
import io
import json
from pathlib import Path
import sys
import unittest
from unittest.mock import patch
import zipfile
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_lab_perf_report import read_log
from test_apex_lab_perf_report import valid, log
import apex_lab_perf_history as hist


def record(run=10, attempt=1):
    return hist.observation(read_log(log(valid())), {
        "candidate": "a"*40, "checkout": "a"*40, "probe_blob": "b"*40,
        "run_id": run, "attempt": attempt, "event": "push",
        "godot": "4.7.2.stable.official.ed1daf0bf", "runner_os": "Linux",
        "runner_arch": "X64", "runner_image": "test"})


def archive(value, filename="observation.json"):
    b = io.BytesIO()
    with zipfile.ZipFile(b, "w") as z:
        z.writestr(filename, json.dumps(value))
    return b.getvalue()


class HistoryTests(unittest.TestCase):
    def test_current_only_and_exact_values(self):
        r = hist.history(record(), [])
        self.assertEqual(r["state"], "CURRENT_ONLY")
        self.assertEqual(r["records"][0]["weather"]["Seco"]["mean_us"], 50.0)
        self.assertEqual(r["comparison"], "UNCONTROLLED_HOST_NOT_A_REGRESSION_GATE")

    def test_deduplicate_and_keep_attempts(self):
        r = hist.history(record(10, 2), [record(8), record(10), record(8)])
        self.assertEqual([(x["run_id"], x["attempt"]) for x in r["records"]], [(8, 1), (10, 1), (10, 2)])

    def test_incomplete_invalid_rejected(self):
        for mutate in (lambda x: x["observations"].pop(),
                       lambda x: x["observations"][0].update(p95_us=float("nan")),
                       lambda x: x.update(candidate="main"),
                       lambda x: x["observations"][0].update(repeat=2)):
            r = record()
            mutate(r)
            with self.assertRaises(ValueError):
                hist.validate(r)

    def test_safe_archive(self):
        self.assertEqual(hist.archive_record(archive(record())), record())
        with self.assertRaises(ValueError):
            hist.archive_record(archive(record(), "../observation.json"))

    def test_history_collect_provenance(self):
        run = {"id": 9, "run_attempt": 1, "head_branch": "main", "event": "push",
               "conclusion": "success", "head_sha": "a"*40}
        artifact = {"id": 123, "name": "apex-lab-observation-1", "expired": False, "size_in_bytes": 100}
        with patch.object(hist, "api", side_effect=[
                json.dumps({"workflow_runs": [run]}).encode(),
                json.dumps({"artifacts": [artifact]}).encode(), archive(record(9))]):
            self.assertEqual(hist.collect(record()), ([record(9)], []))
        with patch.object(hist, "api", side_effect=[
                json.dumps({"workflow_runs": [run]}).encode(),
                json.dumps({"artifacts": [artifact]}).encode(), archive(record(8))]):
            rows, issues = hist.collect(record())
            self.assertEqual(rows, [])
            self.assertEqual(len(issues), 1)
            self.assertEqual(hist.history(record(), rows, issues)["state"], "PARTIAL")


if __name__ == "__main__":
    unittest.main()
