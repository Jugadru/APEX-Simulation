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



if __name__ == "__main__":
    unittest.main()
