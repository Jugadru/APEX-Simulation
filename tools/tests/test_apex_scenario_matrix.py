"""Contract tests for APEX Scenario Matrix 1.0 (no simulated Godot PASS)."""
import json
from pathlib import Path
import sys
import tempfile
import unittest

# Import project-owned module in the same way as the existing CI test suites.
# Avoid dynamically executing a file via importlib.spec_from_file_location.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_scenario_matrix as matrix


class ScenarioMatrixContractTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "data").mkdir()
        (self.root / "data" / "season_2012.json").write_text(
            json.dumps({
                "tracks": [{"code": code} for code in matrix.TRACKS],
                "teams": [{} for _ in range(12)],
            }), encoding="utf-8")
        self.output = self.root / "logs"
        self.output.mkdir()

    @staticmethod
    def good(scenario):
        return {
            **scenario, "status": "PASS", "errors": [], "warnings": [],
            "steps": 210, "finished": True, "finish_results_validated": True,
            "finished_cars": 24, "classified_positions": list(range(1, 25)),
            "race_hash": "f" * 64, "pits_total": 2, "max_stops": 1,
            "pit_laps_by_player": [[6], [7]] if scenario["mode"] != "IA" else [[], []],
            "disqualified": 0, "disqualification_evidence": [],
            "wetness_peak": 0.58 if scenario["weather"] == "Chuva intensa" else 0.0,
            "on_track_pass_events": 5,  # nosec B105: sporting overtakes, not a password
        }

    def write(self, scenario, repetition, row):
        (self.output / f"{scenario['id']}_{repetition}.log").write_text(
            "Godot 4.7.2\n" + matrix.MARKER + json.dumps(row) + "\n", encoding="utf-8")

    def test_smoke_covers_twenty_real_circuits_once(self):
        all_cases = []
        for shard in range(4):
            p = matrix.plan(self.root, "smoke", shard, 4, 12012)
            self.assertEqual(len(p), 5)
            all_cases.extend(p)
        self.assertEqual([c["track"] for c in sorted(all_cases, key=lambda x: matrix.TRACKS.index(x["track"]))],
                         list(matrix.TRACKS))
        self.assertEqual(len({c["seed"] for c in all_cases}), 20)
        self.assertEqual({c["weather"] for c in all_cases}, set(matrix.WEATHERS))
        self.assertEqual({c["mode"] for c in all_cases}, set(matrix.MODES))

    def test_full_cross_product_is_180_cases_and_360_runs(self):
        all_cases = [c for shard in range(4)
                     for c in matrix.plan(self.root, "full", shard, 4, 12012)]
        self.assertEqual(len(all_cases), 180)
        self.assertEqual(len({(c["track"], c["weather"], c["mode"]) for c in all_cases}), 180)
        self.assertEqual(len(all_cases) * matrix.REPEATS, 360)

    def test_master_seed_changes_scenarios_without_uncontrolled_randomness(self):
        first = matrix.plan(self.root, "smoke", 0, 4, 12012)
        again = matrix.plan(self.root, "smoke", 0, 4, 12012)
        changed = matrix.plan(self.root, "smoke", 0, 4, 12013)
        self.assertEqual(first, again)
        self.assertNotEqual([x["seed"] for x in first], [x["seed"] for x in changed])

    def test_rejects_missing_or_reordered_circuits(self):
        source = self.root / "data" / "season_2012.json"
        doc = json.loads(source.read_text(encoding="utf-8"))
        doc["tracks"].reverse()
        source.write_text(json.dumps(doc), encoding="utf-8")
        with self.assertRaises(matrix.MatrixError):
            matrix.plan(self.root, "smoke", 0, 4, 12012)

    def test_rejects_invalid_shard_and_profiles(self):
        for profile, shard, shards, seed in [
            ("unsupported", 0, 4, 12012), ("smoke", 4, 4, 12012),
            ("smoke", 0, 0, 12012), ("smoke", 0, 4, 0),
        ]:
            with self.subTest(profile=profile, shard=shard):
                with self.assertRaises(matrix.MatrixError):
                    matrix.plan(self.root, profile, shard, shards, seed)

    def test_synthetic_parser_roundtrip_without_claiming_real_godot(self):
        cases = matrix.plan(self.root, "smoke", 0, 4, 12012)
        for case in cases:
            for rep in (1, 2):
                self.write(case, rep, self.good(case))
        summary = matrix.validate(self.root, self.output, "smoke", 0, 4, 12012)
        self.assertEqual(summary["cases"], 5)
        self.assertEqual(summary["runs"], 10)
        self.assertEqual(summary["status"], "PASS")
        self.assertEqual(len(summary["tracks"]), 5)

    def test_missing_or_corrupt_result_never_passes(self):
        case = matrix.plan(self.root, "smoke", 0, 4, 12012)[0]
        self.write(case, 1, self.good(case))
        with self.assertRaises(matrix.MatrixError):
            matrix.validate(self.root, self.output, "smoke", 0, 4, 12012)
        self.write(case, 2, self.good(case))
        with self.assertRaises(matrix.MatrixError):
            matrix._parse_marker(self.output / "missing.log")
        fake = self.output / "duplicate.log"
        fake.write_text((matrix.MARKER + "{}\n") * 2, encoding="utf-8")
        with self.assertRaises(matrix.MatrixError):
            matrix._parse_marker(fake)

    def test_different_sporting_hashes_are_a_real_fail(self):
        case = matrix.plan(self.root, "smoke", 0, 4, 12012)[0]
        self.write(case, 1, self.good(case))
        other = self.good(case)
        other["race_hash"] = "a" * 64
        self.write(case, 2, other)
        with self.assertRaisesRegex(matrix.MatrixError, "NONDETERMINISTIC"):
            matrix.validate(self.root, self.output, "smoke", 0, 4, 12012)

    def test_flags_incoherent_classification_invalid_tyres_and_schedule(self):
        case = matrix.plan(self.root, "smoke", 0, 4, 12012)[0]
        invalids = [
            {"classified_positions": [1] * 24},
            {"finished": False},
            {"pits_total": -1},
            {"max_stops": 11},
            {"race_hash": "NOT_A_SHA"},
            {"errors": ["wrong tyre compound"]},
        ]
        if case["mode"] in ("Manual", "Assistido"):
            invalids.append({"pit_laps_by_player": [[4], [7]]})
        for change in invalids:
            bad = {**self.good(case), **change}
            with self.subTest(change=change):
                with self.assertRaises(matrix.MatrixError):
                    matrix._validated(bad, case)

    def test_disqualification_evidence_is_validated_and_deterministic(self):
        case = matrix.plan(self.root, "smoke", 0, 4, 12012)[0]
        row = self.good(case)
        entry = {
            "car_id": 12, "driver": "Paul di Resta", "team": "Force India Mercedes",
            "used_tires": ["Médio", "Médio"], "tyre_rule_violation": True,
            "tire": "Médio", "stops": 1,
        }
        row["disqualified"] = 1
        row["disqualification_evidence"] = [entry]
        self.assertEqual(matrix._validated(row, case)["disqualified"], 1)
        for mutation in [
            {"disqualification_evidence": []},
            {"disqualification_evidence": [dict(entry, car_id=-1)]},
            {"disqualification_evidence": [entry, entry]},
        ]:
            with self.subTest(mutation=mutation):
                bad = {**row, **mutation}
                with self.assertRaisesRegex(matrix.MatrixError, "disqualification evidence"):
                    matrix._validated(bad, case)
        self.write(case, 1, row)
        self.write(case, 2, {**row, "disqualification_evidence": [dict(entry, car_id=13)]})
        with self.assertRaisesRegex(matrix.MatrixError, "NONDETERMINISTIC"):
            matrix.validate(self.root, self.output, "smoke", 0, 4, 12012)

    def test_markdown_shows_warning_reasons(self):
        case = matrix.plan(self.root, "smoke", 0, 4, 12012)[0]
        row = self.good(case)
        warning = "Unusually many stops for ten laps"
        row["warnings"] = [warning]
        summary = {
            "status": "WARN", "profile": "smoke", "shard": 0,
            "shards": 4, "cases": 1, "runs": 2,
            "tracks": [case["track"]], "results": [row],
            "warnings": [{"scenario": case["id"], "message": warning}],
        }
        output = matrix._markdown(summary)
        self.assertIn(warning, output)
        self.assertIn(case["id"], output)

    def test_excess_stops_are_observations_not_assumed_fraud(self):
        case = matrix.plan(self.root, "smoke", 0, 4, 12012)[0]
        good = self.good(case)
        good["warnings"] = ["Unusually many stops for ten laps"]
        self.assertEqual(matrix._validated(good, case)["warnings"], good["warnings"])


if __name__ == "__main__":
    unittest.main()
