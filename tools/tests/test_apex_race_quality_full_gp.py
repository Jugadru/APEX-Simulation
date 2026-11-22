"""Synthetic parser contracts, never a substitute for 12 real Godot races."""
from pathlib import Path
from tempfile import TemporaryDirectory
import json
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_race_quality_full_gp import (
    GPQualityError, scenarios, checked_run, validate
)


class FullGPContractTests(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "data").mkdir()
        (self.root / "data" / "season_2012.json").write_text(json.dumps({
            "tracks": [{"code": c, "laps": 52 if c == "GBR" else 53}
                       for c in ["GBR", "ITA"] + [f"T{i}" for i in range(18)]],
            "teams": [{} for _ in range(12)]
        }))
        self.out = self.root / "logs"
        self.out.mkdir()

    def record(self, ident, circuit, weather, seed, repeat, **updates):
        laps = 52 if circuit == "GBR" else 53
        wet = .7 if weather == "Chuva intensa" else (
            .4 if weather == "Variável" else 0.0
        )
        data = {
            "track": circuit, "mode": weather, "seed": seed,
            "full_distance": True, "laps": laps, "finished": True,
            "finished_cars": 24, "ticks": 1200, "clock": 4800.0,
            "step_sim_seconds": 4.0, "last_hash": "a" * 64,
            "checkpoints": 0, "events": 12, "pit_history": 25,
            "manual_pit_orders": 2, "samples": [{"step": 100}],
            "min_wetness": 0.0, "max_wetness": wet,
        }
        data.update(updates)
        marker = {
            "track": circuit, "weather": weather, "seed": seed,
            "ticks": data["ticks"], "laps": laps,
            "finished": data["finished"],
            "finished_cars": data["finished_cars"],
            "manual_pit_orders": 2, "hash": data["last_hash"]
        }
        label = f"{ident}_{repeat}"
        (self.out / f"{label}.json").write_text(json.dumps(data))
        (self.out / f"{label}.log").write_text(
            "Godot ready\nAPEX_FULL_GP_DONE " + json.dumps(marker) + "\n"
        )

    def prepare(self):
        for ident, code, weather, seed in scenarios():
            for i in (1, 2):
                self.record(ident, code, weather, seed, i)

    def test_twelve_full_gp_outputs_validate_only_with_evidence(self):
        self.prepare()
        outcome = validate(self.root, self.out)
        self.assertEqual(outcome["status"], "PASS")
        self.assertEqual((outcome["cases"], outcome["runs"]), (6, 12))

    def test_one_missing_or_invalid_record_prevents_pass(self):
        self.prepare()
        (self.out / "GBR_0_1.json").unlink()
        with self.assertRaisesRegex(GPQualityError, "missing"):
            validate(self.root, self.out)
        self.prepare()
        self.record("GBR_0", "GBR", "Seco", 99700, 1, finished=False)
        with self.assertRaises(GPQualityError):
            validate(self.root, self.out)

    def test_same_seed_different_hash_rejected(self):
        self.prepare()
        self.record("GBR_0", "GBR", "Seco", 99700, 2,
                    last_hash="b" * 64)
        with self.assertRaisesRegex(GPQualityError, "NONDETERMINISTIC"):
            validate(self.root, self.out)

    def test_variable_weather_without_observed_change_is_inconclusive(self):
        self.prepare()
        for repeat in (1, 2):
            self.record("ITA_1", "ITA", "Variável", 99711, repeat,
                        min_wetness=0.2, max_wetness=0.2)
        result = validate(self.root, self.out)
        self.assertEqual(result["status"], "INCONCLUSIVE")
        self.assertEqual(len(result["warnings"]), 1)

    def test_negative_wetness_fails(self):
        self.prepare()
        self.record("ITA_2", "ITA", "Chuva intensa", 99712, 1,
                    min_wetness=-.1)
        with self.assertRaisesRegex(GPQualityError, "invalid min_wetness"):
            validate(self.root, self.out)


if __name__ == "__main__":
    unittest.main()
