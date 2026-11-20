"""Contract tests for APEX Scenario Matrix 1.0 (no simulated Godot PASS)."""
import json
from pathlib import Path
import tempfile
import unittest

# Import the repository's namespace package without manipulating sys.path.
from tools import apex_scenario_matrix as matrix


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
            "pits_total": 2, "max_stops": 1,
            "pit_laps_by_player": [[6], [7]] if scenario["mode"] != "IA" else [[], []],
            "wetness_peak": 0.58 if scenario["weather"] == "Chuva intensa" else 0.0,
            "disqualified": 0,

        }



if __name__ == "__main__":
    unittest.main()
