"""Offline policy regressions: changing a module never disables core safety."""
import sys
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_ci_tiers import ALWAYS, CASES, categories_for, select, changed_files


class SmartCITests(unittest.TestCase):
    def test_docs_only_still_runs_invariants(self):
        with TemporaryDirectory() as tmp:
            self.assertEqual(select(["README.md"], Path(tmp)), list(ALWAYS))

    def test_race_engine_activates_strategy_and_pit(self):
        tags = categories_for(["scripts/race_engine.gd"])
        self.assertTrue({"ai", "pit", "wet", "orders", "staff"}.issubset(tags))

    def test_isolated_strategist_is_targeted(self):
        tags = categories_for(["scripts/core/race_strategy_staff_intelligence_066910.gd"])
        self.assertIn("staff", tags)
        self.assertNotIn("hud", tags)

    def test_optional_suite_only_if_file_exists(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            path = ["scripts/core/race_strategy_staff_intelligence_066910.gd"]
            self.assertNotIn(CASES["staff"], select(path, root))
            (root / "tests").mkdir()
            (root / "tests" / CASES["staff"][0]).touch()
            self.assertIn(CASES["staff"], select(path, root))

    def test_engine_and_replay_tests_deduplicated(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "tests").mkdir()
            for case in CASES.values(): (root / "tests" / case[0]).touch()
            p = ["scripts/race_engine.gd", "scripts/core/race_replay_0660.gd"]
            plan = select(p, root)
            self.assertEqual(len(plan), len(set(plan)))
            self.assertEqual(plan, select(list(reversed(p)), root))

    def test_unknown_core_file_never_skips_strategy(self):
        self.assertIn("wet", categories_for(["scripts/core/unrecognized_future_feature.gd"]))

    def test_invalid_git_identity_rejected(self):
        with self.assertRaises(ValueError):
            changed_files(Path("."), "main", "a" * 40)


if __name__ == "__main__":
    unittest.main()
