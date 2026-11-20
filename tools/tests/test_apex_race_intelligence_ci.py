"""Contract tests for APEX Race Intelligence Tester reporting."""
from __future__ import annotations

import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_race_intelligence_ci import (
    IntelligenceError, check_repeated, markdown, parse_marker, validate_probe,
)

from apex_race_intelligence_ci import read_ci_log

def good(scenario="monza_dry_auto"):
    return {
        "status": "PASS", "scenario": scenario, "circuit": "ITA",
        "seed": 660, "weather": "Seco", "control": "IA", "lap_count": 10,
        "finished": True, "classified": 24, "steps": 250,
        "hash": "a" * 64, "pits_total": 12,
        "manual_v7_pits": [7] if scenario == "monza_manual_v7" else [],
        "on_track_pass_events": 2, "radio_events": 8, "ai_plan_samples": 7,  # nosec B105: overtaking count
        "max_stops_per_car": 3, "wetness_peak": 0.85, "errors": [],
    }


class IntelligenceReportTests(unittest.TestCase):
    def test_marker_parsing_exactly_one_json(self):
        info = parse_marker("Godot started\nAPEX_RIT_RESULT " + json.dumps(good()), "APEX_RIT_RESULT ")
        self.assertEqual(info["scenario"], "monza_dry_auto")

    def test_missing_or_duplicate_marker_rejected(self):
        with self.assertRaises(IntelligenceError):
            parse_marker("No marker", "APEX_RIT_RESULT ")
        value = "APEX_RIT_RESULT " + json.dumps(good())
        with self.assertRaises(IntelligenceError):
            parse_marker(value + "\n" + value, "APEX_RIT_RESULT ")

    def test_invalid_marker_json_rejected(self):
        with self.assertRaises(IntelligenceError):
            parse_marker("APEX_RIT_RESULT {invalid", "APEX_RIT_RESULT ")

    def test_valid_probe_accepted(self):
        self.assertEqual(validate_probe(good(), "monza_dry_auto")["classified"], 24)

    def test_incomplete_race_rejected(self):
        item = good()
        item["finished"] = False
        with self.assertRaises(IntelligenceError):
            validate_probe(item, "monza_dry_auto")

    def test_missing_hash_rejected(self):
        item = good()
        item["hash"] = ""
        with self.assertRaises(IntelligenceError):
            validate_probe(item, "monza_dry_auto")

    def test_early_manual_pit_rejected(self):
        item = good("monza_manual_v7")
        item["manual_v7_pits"] = [4]
        with self.assertRaises(IntelligenceError):
            validate_probe(item, "monza_manual_v7")

    def test_dry_wet_mismatch_rejected(self):
        item = good("silverstone_wet_auto")
        item["wetness_peak"] = 0.0
        with self.assertRaises(IntelligenceError):
            validate_probe(item, "silverstone_wet_auto")

    def test_reproducible_hash_accepted(self):
        check_repeated(good(), good())

    def test_determinism_mismatch_rejected(self):
        first, second = good(), good()
        second["hash"] = "b" * 64
        with self.assertRaisesRegex(IntelligenceError, "NONDETERMINISTIC"):
            check_repeated(first, second)

    def test_negative_observation_not_silent(self):
        info = good()
        info["radio_events"] = -1
        with self.assertRaises(IntelligenceError):
            validate_probe(info, "monza_dry_auto")

    def test_markdown_preserves_limitations(self):
        report = {
            "status": "PASS", "scenarios": {"monza_dry_auto": {
                "pits_total": 10, "on_track_pass_events": 2, "radio_events": 3  # nosec B105: overtaking count
            }}, "targeted": {"tyres": "PASS"}
        }
        txt = markdown(report)
        self.assertIn("10 voltas", txt)
        self.assertIn("observacionais", txt)
        self.assertIn("tyres", txt)

    def test_reads_logs_produced_by_ci(self):
        with TemporaryDirectory() as td:
            output = Path(td)
            (output / "targeted_tyres.log").write_text("APEX v0.5.5.2 PASS\n", encoding="utf-8")
            self.assertIn("PASS", read_ci_log(output, "targeted_tyres"))

    def test_missing_log_rejected(self):
        with TemporaryDirectory() as td:
            with self.assertRaisesRegex(IntelligenceError, "Missing CI-generated"):
                read_ci_log(Path(td), "monza_manual_v7_2")

    def test_invalid_label_rejected(self):
        with TemporaryDirectory() as td:
            with self.assertRaisesRegex(IntelligenceError, "Invalid CI run label"):
                read_ci_log(Path(td), "../anything")



if __name__ == "__main__":
    unittest.main()
