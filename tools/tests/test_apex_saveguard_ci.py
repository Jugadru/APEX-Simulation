"""Contracts for APEX SaveGuard cross-revision report verification."""
from __future__ import annotations

import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_saveguard_ci import SaveGuardError, find_exact, marker_json, markdown, validate_result

from apex_saveguard_ci import read_ci_log, read_snapshot_hash

def example():
    return {
        "status": "PASS", "test": "apex_saveguard_cross_revision",
        "checks": 42, "errors": [],
        "observations": {
            "career": {"final_round": 20},
            "garage": {"historic_budget": 6500000},
            "replay": {"ticks": 350},
            "source_sha256": {
                "career": "a" * 64, "garage": "b" * 64, "replay": "c" * 64,
            },
        },
    }


class SaveGuardContracts(unittest.TestCase):
    def test_valid_report_accepted(self):
        self.assertEqual(validate_result(example())["status"], "PASS")

    def test_corruption_report_must_fail(self):
        data = example()
        data["status"] = "FAIL"
        with self.assertRaises(SaveGuardError):
            validate_result(data)

    def test_missing_checks_must_fail(self):
        data = example()
        data["checks"] = 4
        with self.assertRaises(SaveGuardError):
            validate_result(data)

    def test_missing_replay_evidence_must_fail(self):
        data = example()
        del data["observations"]["replay"]
        with self.assertRaises(SaveGuardError):
            validate_result(data)

    def test_wrong_career_progress_must_fail(self):
        data = example()
        data["observations"]["career"]["final_round"] = 0
        with self.assertRaises(SaveGuardError):
            validate_result(data)

    def test_wrong_garage_budget_must_fail(self):
        data = example()
        data["observations"]["garage"]["historic_budget"] = 0
        with self.assertRaises(SaveGuardError):
            validate_result(data)

    def test_replay_incomplete_must_fail(self):
        data = example()
        data["observations"]["replay"]["ticks"] = 100
        with self.assertRaises(SaveGuardError):
            validate_result(data)

    def test_marker_requires_single_json(self):
        log = "APEX_SAVEGUARD_RESULT " + json.dumps(example())
        self.assertEqual(marker_json(log, "APEX_SAVEGUARD_RESULT ")["checks"], 42)
        with self.assertRaises(SaveGuardError):
            marker_json(log + "\n" + log, "APEX_SAVEGUARD_RESULT ")

    def test_missing_or_malformed_marker_must_fail(self):
        with self.assertRaises(SaveGuardError):
            marker_json("", "APEX_SAVEGUARD_RESULT ")
        with self.assertRaises(SaveGuardError):
            marker_json("APEX_SAVEGUARD_RESULT {not json", "APEX_SAVEGUARD_RESULT ")

    def test_fixtures_found_only_when_unique(self):
        with TemporaryDirectory() as td:
            root = Path(td)
            with self.assertRaises(SaveGuardError):
                find_exact(root, "career.json")
            folder = root / "old"
            folder.mkdir()
            (folder / "career.json").write_text("x" * 200, encoding="utf-8")
            self.assertEqual(find_exact(root, "career.json"), folder / "career.json")
            another = root / "new"
            another.mkdir()
            (another / "career.json").write_text("y" * 200, encoding="utf-8")
            with self.assertRaises(SaveGuardError):
                find_exact(root, "career.json")

    def test_documentation_does_not_claim_auto_restore(self):
        self.assertIn("não o restaura sozinha", markdown({**example(), "checks": 42}))

    def test_existing_ci_logs_are_read(self):
        with TemporaryDirectory() as td:
            root = Path(td)
            (root / "baseline_replay.log").write_text("LEGACY_RECORD_PASS\n", encoding="utf-8")
            self.assertIn("LEGACY_RECORD_PASS", read_ci_log(root, "baseline_replay"))

    def test_missing_ci_logs_cannot_pass(self):
        with TemporaryDirectory() as td:
            with self.assertRaises(SaveGuardError):
                read_ci_log(Path(td), "candidate_saveguard")

    def test_untrusted_log_labels_rejected(self):
        with TemporaryDirectory() as td:
            with self.assertRaisesRegex(SaveGuardError, "Invalid CI log label"):
                read_ci_log(Path(td), "../outside")

    def test_snapshot_hash_requires_64_hex_characters(self):
        with TemporaryDirectory() as td:
            root = Path(td)
            (root / "career.sha").write_text("a" * 64 + "\n", encoding="utf-8")
            self.assertEqual(read_snapshot_hash(root, "career"), "a" * 64)
            (root / "career.sha").write_text("not a real sha", encoding="utf-8")
            with self.assertRaises(SaveGuardError):
                read_snapshot_hash(root, "career")



if __name__ == "__main__":
    unittest.main()
