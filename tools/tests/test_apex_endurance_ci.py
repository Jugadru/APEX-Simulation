"""Standalone contract checks for APEX endurance reports (no Godot needed)."""
from __future__ import annotations

import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_endurance_ci import (
    EnduranceError, check_repetitions, marker_json, parse_career,
    parse_full_gp, parse_growth, read_linux_rss_bytes, write_report,
)

from apex_endurance_ci import read_ci_run

def growth_fixture(ticks: int = 1000, stable_hash: str = "same") -> str:
    rows = [
        {"tick": n, "block_ms": 125.0, "memory_static_bytes": 120_000_000 + n}
        for n in range(250, ticks + 1, 250)
    ]
    return "Engine started\nGROWTH_DONE " + json.dumps(
        {"rows": rows, "ticks": ticks, "hash": stable_hash}
    ) + "\n"


def gp_fixture(track: str = "ITA", weather: str = "Seco") -> dict:
    return {
        "track": track, "mode": weather, "seed": 660,
        "full_distance": True, "finished": True,
        "last_hash": "stable", "ticks": 1500, "laps": 53,
        "samples": [{"tick": 500}],
        "step_sim_seconds": 4.0,
        "finished_cars": 24, "manual_pit_orders": 2,
        "pit_history": 4,
    }


def career_fixture() -> str:
    return "CAREER_20_SEASON_STRESS " + json.dumps({
        "pass": True, "seasons": 20, "races_committed": 400,  # nosec B105: pass is a test-result flag
        "errors": [], "checks": 1500, "last_save_bytes": 23456,
    })


class EnduranceContractTests(unittest.TestCase):
    def test_growth_parses_complete_250_tick_blocks(self):
        info = parse_growth(growth_fixture(), 1000)
        self.assertEqual(info["samples"], 4)
        self.assertEqual(info["ticks"], 1000)
        self.assertGreater(info["static_growth_bytes"], 0)
        self.assertEqual(info["sporting_hash"], "same")

    def test_growth_rejects_missing_completion_marker(self):
        with self.assertRaises(EnduranceError):
            parse_growth("GROWTH {not completed}", 1000)

    def test_growth_rejects_partial_tick_count(self):
        with self.assertRaises(EnduranceError):
            parse_growth(growth_fixture(), 1250)

    def test_growth_rejects_corrupted_measurement(self):
        obj = marker_json(growth_fixture(), "GROWTH_DONE ")
        obj["rows"][2]["block_ms"] = float("nan")
        with self.assertRaises(EnduranceError):
            parse_growth("GROWTH_DONE " + json.dumps(obj), 1000)

    def test_full_gp_rejects_unfinished_race(self):
        info = gp_fixture()
        info["finished"] = False
        with self.assertRaises(EnduranceError):
            parse_full_gp(info, "ITA", "Seco", 660)

    def test_full_gp_accepts_full_distance_scenario(self):
        info = parse_full_gp(gp_fixture(), "ITA", "Seco", 660)
        self.assertEqual(info["laps"], 53)
        self.assertTrue(info["finished"])

    def test_full_gp_rejects_wrong_weather_or_seed(self):
        with self.assertRaises(EnduranceError):
            parse_full_gp(gp_fixture(), "ITA", "Chuva intensa", 660)
        with self.assertRaises(EnduranceError):
            parse_full_gp(gp_fixture(), "ITA", "Seco", 661)

    def test_career_requires_all_400_administrative_rounds(self):
        self.assertEqual(parse_career(career_fixture())["administrative_rounds"], 400)
        invalid = career_fixture().replace('"races_committed": 400', '"races_committed": 399')
        with self.assertRaises(EnduranceError):
            parse_career(invalid)

    def test_different_hashes_fail_determinism(self):
        with self.assertRaisesRegex(EnduranceError, "NONDETERMINISTIC"):
            check_repetitions(
                "growth_monza", {"sporting_hash": "before"},
                {"sporting_hash": "after"}, ("sporting_hash",),
            )

    def test_peak_rss_unavailable_is_not_fabricated(self):
        self.assertIsNone(read_linux_rss_bytes(-123456789))

    def test_markdown_and_json_reports_written(self):
        with TemporaryDirectory() as td:
            folder = Path(td)
            write_report({
                "status": "PASS",
                "scenarios": {"growth_monza": [{"sporting_hash": "x"}] * 2},
                "growth_ticks": 1000, "full_gp_scenarios": 2, "warnings": [],
            }, folder)
            self.assertIn("PASS", (folder / "report.md").read_text(encoding="utf-8"))
            self.assertTrue((folder / "report.json").is_file())

    def test_valid_gnu_time_metrics_are_read(self):
        with TemporaryDirectory() as td:
            out = Path(td)
            (out / "growth_monza_1.log").write_text(growth_fixture(), encoding="utf-8")
            (out / "growth_monza_1.metrics").write_text("12.50 65536\n", encoding="utf-8")
            info = read_ci_run(out, "growth_monza_1")
            self.assertEqual(info["peak_rss_bytes_observed"], 65536 * 1024)
            self.assertEqual(info["wall_seconds"], 12.5)

    def test_missing_endurance_metrics_rejected(self):
        with TemporaryDirectory() as td:
            (Path(td) / "career_admin_1.log").write_text(career_fixture(), encoding="utf-8")
            with self.assertRaisesRegex(EnduranceError, "missing real-Godot"):
                read_ci_run(Path(td), "career_admin_1")

    def test_invalid_endurance_metrics_rejected(self):
        with TemporaryDirectory() as td:
            out = Path(td)
            (out / "full_gp_ITA_1.log").write_text("some result", encoding="utf-8")
            (out / "full_gp_ITA_1.metrics").write_text("bad 2048\n", encoding="utf-8")
            with self.assertRaisesRegex(EnduranceError, "invalid time or RSS"):
                read_ci_run(out, "full_gp_ITA_1")

    def test_endurance_metrics_reject_budget_exceeded(self):
        with TemporaryDirectory() as td:
            out = Path(td)
            (out / "full_gp_GBR_2.log").write_text("some result", encoding="utf-8")
            (out / "full_gp_GBR_2.metrics").write_text("10.5 2200000\n", encoding="utf-8")
            with self.assertRaisesRegex(EnduranceError, "exceeds 2 GiB"):
                read_ci_run(out, "full_gp_GBR_2")

    def test_invalid_endurance_label_rejected(self):
        with TemporaryDirectory() as td:
            with self.assertRaisesRegex(EnduranceError, "Invalid endurance"):
                read_ci_run(Path(td), "../anything")


if __name__ == "__main__":
    unittest.main()
