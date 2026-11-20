"""Synthetic contract checks for the Pit Wall analyzer; never pretend to run Godot."""
import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_pitwall_intelligence as analyzer


class PitWallAnalyzerContracts(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "data").mkdir()
        (self.root / "project.godot").write_text("[application]\n", encoding="utf-8")
        (self.root / "data" / "season_2012.json").write_text(json.dumps({
            "tracks": [{"code": x} for x in (
                "AUS", "MAL", "CHN", "BHR", "ESP", "MON", "CAN", "EUR",
                "GBR", "GER", "HUN", "BEL", "ITA", "SIN", "JPN",
                "KOR", "IND", "UAE", "USA", "BRA")],
            "teams": [{} for _ in range(12)],
        }), encoding="utf-8")
        (self.root / "data" / "tyres_2012.json").write_text(json.dumps({
            "tracks": {code: {"dry": ["Médio", "Duro"]} for code in
                       ("AUS", "MAL", "CHN", "BHR", "ESP", "MON", "CAN", "EUR",
                        "GBR", "GER", "HUN", "BEL", "ITA", "SIN", "JPN",
                        "KOR", "IND", "UAE", "USA", "BRA")}
        }), encoding="utf-8")
        self.logs = self.root / "logs"
        self.logs.mkdir()
        self.nom = analyzer.load_nominations(self.root)

    def fixture(self, scenario="ita_dry_auto"):
        track, weather, seed, control = analyzer.SCENARIOS[scenario]
        ids = [5, 6]
        observations = []
        for lap in range(11):
            for driver_id in (5, 6, 7):
                observations.append({
                    "step": lap * 12, "lap": lap, "clock": float(lap * 45),
                    "car_id": driver_id, "driver": str(driver_id),
                    "team": "Ferrari" if driver_id != 7 else "McLaren",
                    "position": driver_id, "control": control if driver_id in ids else "IA",
                    "tire": "Médio", "wear": 4.0 * lap, "wetness": 0.0,
                    "pace": "Normal", "stops": 0,
                    "pit_request": False,
                    "pit_scheduled_lap": 7 if control == "Manual" and driver_id == 5 else 0,
                    "pit_left": 0.0, "pit_order_source": "",
                    "ai_has_plan": False, "ai_pit_now": False,
                    "ai_plan_compound": "", "ai_plan_reason": "",
                    "ai_plan_lap": 0, "coordination": "",
                })
        stop = {
            "car_id": 5, "driver": "5", "team": "Ferrari",
            "lap": 7, "order_origin": "agendamento_manual",
            "old_tire": "Médio", "new_tire": "Duro", "wait": 0.0,
            "incident_delay": 0.0, "position_before": 2, "position_after": 4,
        }
        return {
            "scenario": scenario, "track": track, "weather": weather,
            "control": control, "seed": seed, "lap_count": 10,
            "finished": True, "classified": 24, "steps": 150,
            "race_hash": "a" * 64,
            "manual_v7_laps": [7] if control == "Manual" else [],
            "player_ids": ids, "decisions": observations,
            "pits": [stop] if control == "Manual" else [],
            "radio": [{"type": "engineer_reply", "car_id": 5,
                       "time": 43.0, "message": "Vamos acompanhar os pneus."}],
            "event_counts": {"engineer_reply": 1},
            "errors": [], "status": "PASS",
        }

    def write(self, name, repeat, data):
        (self.logs / f"{name}_{repeat}.log").write_text(
            "Godot start\n" + analyzer.MARKER + json.dumps(data) + "\n",
            encoding="utf-8")

    def test_real_scenario_contracts_cover_dry_wet_variable_manual(self):
        self.assertEqual(len(analyzer.SCENARIOS), 4)
        self.assertEqual({x[1] for x in analyzer.SCENARIOS.values()},
                         {"Seco", "Chuva intensa", "Variável"})
        for scenario in analyzer.SCENARIOS:
            self.assertEqual(analyzer.validate_result(
                self.fixture(scenario), scenario, self.nom)["status"], "PASS")

    def test_not_a_fake_godot_run_missing_marker_or_duplicate(self):
        p = self.logs / "bad.log"
        with self.assertRaises(analyzer.PitWallAnalyzerError):
            analyzer.parse_log(p)
        p.write_text('no Godot results\n', encoding="utf-8")
        with self.assertRaises(analyzer.PitWallAnalyzerError):
            analyzer.parse_log(p)
        p.write_text((analyzer.MARKER + "{}\n") * 2, encoding="utf-8")
        with self.assertRaises(analyzer.PitWallAnalyzerError):
            analyzer.parse_log(p)

    def test_rejects_nondeterministic_sporting_hash_and_radio(self):
        first = self.fixture()
        second = self.fixture()
        second["race_hash"] = "b" * 64
        with self.assertRaisesRegex(analyzer.PitWallAnalyzerError, "NONDETERMINISTIC"):
            analyzer.same_run(first, second)
        second = self.fixture()
        second["radio"][0]["message"] = "Outra fala"
        with self.assertRaisesRegex(analyzer.PitWallAnalyzerError, "NONDETERMINISTIC"):
            analyzer.same_run(first, second)

    def test_full_radio_history_over_140_events_remains_auditable(self):
        # Core 2 HUD keeps a small rolling buffer, but telemetry is unbounded.
        # Verify the analyzer does not silently truncate meaningful evidence.
        case = self.fixture()
        case["radio"] = [
            {"type": "strategy", "car_id": 5, "time": float(i),
             "message": "Strategic event %d" % i}
            for i in range(150)
        ]
        case["event_counts"] = {"strategy": 150}
        validated = analyzer.validate_result(case, "ita_dry_auto", self.nom)
        self.assertEqual(len(analyzer.analyze_case(validated)["evidence"]["radio_events"]), 150)

    def test_broken_classification_manual_order_and_tyre_are_failures(self):
        for patch in (
            {"classified": 23}, {"finished": False}, {"steps": 1800},
            {"manual_v7_laps": [4]}, {"race_hash": "unverified"},
            {"errors": ["broken tyres"]},
        ):
            case = self.fixture("ita_manual_v7")
            case.update(patch)
            with self.subTest(patch=patch):
                with self.assertRaises(analyzer.PitWallAnalyzerError):
                    analyzer.validate_result(case, "ita_manual_v7", self.nom)
        case = self.fixture()
        case["decisions"][0]["tire"] = "Supermacio"
        with self.assertRaisesRegex(analyzer.PitWallAnalyzerError, "non-nominated"):
            analyzer.validate_result(case, "ita_dry_auto", self.nom)

    def test_wet_mismatch_is_review_for_ai_and_context_for_manual(self):
        auto = self.fixture("gbr_wet_auto")
        for d in auto["decisions"]:
            if d["car_id"] == 5 and d["lap"] in (3, 4):
                d["wetness"] = 0.83
        findings = analyzer.analyze_case(auto)["findings"]
        self.assertTrue(any(x["code"] == "WET_TRACK_SLICK" and
                            x["level"] == "REVIEW" for x in findings))
        manual = self.fixture("ita_manual_v7")
        for d in manual["decisions"]:
            if d["car_id"] == 5 and d["lap"] in (3, 4):
                d["wetness"] = 0.83
        manual_findings = analyzer.analyze_case(manual)["findings"]
        self.assertTrue(any(x["code"] == "WET_TRACK_SLICK" and
                            x["level"] == "OBSERVATION" for x in manual_findings))

    def test_one_bad_lap_is_not_invented_ai_failure(self):
        case = self.fixture()
        for d in case["decisions"]:
            if d["car_id"] == 5 and d["lap"] == 3:
                d["wetness"] = 0.88
        self.assertFalse(any(x["code"] == "WET_TRACK_SLICK"
                             for x in analyzer.analyze_case(case)["findings"]))

    def test_pit_queue_is_review_with_incident_context(self):
        case = self.fixture("ita_manual_v7")
        case["pits"][0]["wait"] = 4.0
        case["pits"][0]["incident_delay"] = 2.0
        findings = analyzer.analyze_case(case)["findings"]
        found = next(x for x in findings if x["code"] == "PIT_QUEUE")
        self.assertEqual(found["level"], "REVIEW")
        self.assertEqual(found["evidence"]["incident_s"], 2.0)

    def test_end_to_end_uses_two_actual_log_files_per_case(self):
        for name in analyzer.SCENARIOS:
            for rep in (1, 2):
                self.write(name, rep, self.fixture(name))
        report = analyzer.run(self.root, self.logs)
        self.assertEqual(report["cases"], 4)
        self.assertEqual(report["runs"], 8)
        self.assertEqual(report["status"], "PASS")
        self.assertIn("4", analyzer.markdown(report))

    def test_corrupt_evidence_prevents_final_pass(self):
        for name in analyzer.SCENARIOS:
            for rep in (1, 2):
                self.write(name, rep, self.fixture(name))
        (self.logs / "ita_dry_auto_2.log").unlink()
        with self.assertRaises(analyzer.PitWallAnalyzerError):
            analyzer.run(self.root, self.logs)

    def test_old_benchmark_unaffected_and_py_contract_strict(self):
        self.assertFalse(analyzer.number(True, 0, 1))
        self.assertFalse(analyzer.number(float("nan"), 0, 1))
        self.assertTrue(analyzer.number(0.5, 0, 1))


if __name__ == "__main__":
    unittest.main()
