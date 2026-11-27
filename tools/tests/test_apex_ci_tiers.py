"""Offline policy regressions: changing a module never disables core safety."""
import sys
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_ci_tiers import ALWAYS, CASES, categories_for, select, changed_files


def populate(root):
    (root / "tests").mkdir(exist_ok=True)
    for script, _ in (*ALWAYS, *CASES.values()):
        (root / "tests" / script).touch()


class SmartCITests(unittest.TestCase):
    def test_docs_only_still_runs_invariants(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            populate(root)
            self.assertEqual(select(["README.md"], root), list(ALWAYS))

    def test_race_engine_activates_strategy_and_pit(self):
        tags = categories_for(["scripts/race_engine.gd"])
        self.assertTrue({"ai", "pit", "wet", "orders", "staff"}.issubset(tags))

    def test_isolated_strategist_is_targeted(self):
        tags = categories_for(["scripts/core/race_strategy_staff_intelligence_066910.gd"])
        self.assertIn("staff", tags)
        self.assertNotIn("hud", tags)

    def test_selected_test_missing_blocks_plan(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            populate(root)
            path = ["scripts/core/race_strategy_staff_intelligence_066910.gd"]
            (root / "tests" / CASES["staff"][0]).unlink()
            with self.assertRaisesRegex(ValueError, "Missing mandatory FAST"):
                select(path, root)

    def test_baseline_manifest_cannot_be_removed(self):
        with TemporaryDirectory() as tmp, TemporaryDirectory() as prior:
            root, trusted = Path(tmp), Path(prior)
            populate(root)
            (trusted / ".github").mkdir()
            (trusted / ".github/apex-quality-suites.json").write_text(json.dumps({
                "schema": 1, "suites": [{"id": "trusted_test", "paths": ["README.md"],
                "fast_tests": [{"script": "legacy.gd", "marker": "LEGACY_PASS"}],
                "checks": []}]}))
            (root / "tests/legacy.gd").touch()
            self.assertIn(("legacy.gd", "LEGACY_PASS"), select(["README.md"], root, trusted))
            (root / "tests/legacy.gd").unlink()
            with self.assertRaisesRegex(ValueError, "Missing mandatory FAST"):
                select(["README.md"], root, trusted)

    def test_missing_always_fixture_blocks_plan(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            populate(root)
            (root / "tests" / ALWAYS[0][0]).unlink()
            with self.assertRaisesRegex(ValueError, "Missing mandatory FAST"):
                select(["README.md"], root)

    def test_engine_and_replay_tests_deduplicated(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            populate(root)
            p = ["scripts/race_engine.gd", "scripts/core/race_replay_0660.gd"]
            plan = select(p, root)
            self.assertEqual(len(plan), len(set(plan)))
            self.assertEqual(plan, select(list(reversed(p)), root))

    def test_unknown_core_file_never_skips_strategy(self):
        self.assertIn("wet", categories_for(["scripts/core/unrecognized_future_feature.gd"]))

    def test_save_codec_selects_migration_regression(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            populate(root)
            self.assertIn(CASES["save"], select(["scripts/core/race_state_codec_0660.gd"], root))

    def test_driver_traffic_is_selected_without_separate_version_workflow(self):
        from apex_ci_tiers import categories_for
        self.assertIn("traffic", categories_for(["scripts/core/race_driver_traffic_06693.gd"]))
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            populate(root)
            self.assertIn(CASES["traffic"],
                          select(["scripts/core/race_driver_traffic_06693.gd"], root))

    def test_fast_always_includes_real_lab(self):
        self.assertIn(("apex_lab_track_smoke.gd", "APEX_LAB_TRACK_PASS"), ALWAYS)
        self.assertIn(("apex_lab_performance_probe.gd", "APEX_LAB_PERF_PASS"), ALWAYS)

    def test_invalid_git_identity_rejected(self):
        with self.assertRaises(ValueError):
            changed_files(Path("."), "main", "a" * 40)


if __name__ == "__main__":
    unittest.main()
