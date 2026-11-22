"""APEX Dynamic Quality Gate 2.0 — offline, fail-closed contract tests."""
from __future__ import annotations
import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_quality_manifest import load_suites, fast_tests_for, full_checks
from apex_ci_tiers import select
from apex_quality_gate import REQUIREMENTS, assess, run_gate, GateError

SHA = "a" * 40


def write_registry(root, suites):
    target = root / ".github" / "apex-quality-suites.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps({"schema": 1, "suites": suites}), encoding="utf-8")


def suite(checks=None, fast=None):
    return {"id": "new_driver_module", "paths": ["scripts/core/new_driver_*.gd"],
            "fast_tests": fast if fast is not None else [],
            "checks": checks if checks is not None else []}


def job(key="driver_ci"):
    return {"key": key, "workflow": "apex-new-driver-ci.yml",
            "job": "Driver Intelligence / deterministic", "area": "Pilotos", "comparison": False}


class DynamicGateTests(unittest.TestCase):
    def test_manifest_registers_new_fast_without_code_changes(self):
        with TemporaryDirectory() as d:
            root = Path(d)
            write_registry(root, [suite(fast=[{"script": "new_driver_test.gd", "marker": "NEW_DRIVER_PASS"}])])
            (root / "tests").mkdir()
            (root / "tests/new_driver_test.gd").touch()
            plan = select(["scripts/core/new_driver_logic.gd"], root)
            self.assertIn(("new_driver_test.gd", "NEW_DRIVER_PASS"), plan)

    def test_missing_registered_fast_test_fails_closed(self):
        with TemporaryDirectory() as d:
            root = Path(d)
            write_registry(root, [suite(fast=[{"script": "new_driver_test.gd", "marker": "NEW_DRIVER_PASS"}])])
            with self.assertRaisesRegex(ValueError, "Missing mandatory FAST"):
                select(["scripts/core/new_driver_logic.gd"], root)

    def test_candidate_cannot_delete_trusted_full_requirements(self):
        with TemporaryDirectory() as td, TemporaryDirectory() as cd:
            trusted, candidate = Path(td), Path(cd)
            write_registry(trusted, [suite(checks=[job()])])
            write_registry(candidate, [suite(fast=[{"script": "new_driver_test.gd", "marker": "NEW_DRIVER_PASS"}])])
            suites = load_suites(candidate, trusted)
            self.assertEqual(len(full_checks(suites)), 1)
            self.assertEqual(len(fast_tests_for(["scripts/core/new_driver_logic.gd"], suites)), 1)

    def test_bad_manifest_rejected(self):
        with TemporaryDirectory() as d:
            root = Path(d)
            write_registry(root, [dict(suite(fast=[{"script": "../evil.gd", "marker": "PWN"}]))])
            with self.assertRaises(ValueError):
                load_suites(root)

    def test_duplicate_check_key_cannot_change_job(self):
        with TemporaryDirectory() as d:
            root = Path(d)
            first = suite(checks=[job()])
            second = {"id": "another_module", "paths": ["scripts/another.gd"],
                      "fast_tests": [], "checks": [dict(job(), job="Other job")]}
            write_registry(root, [first, second])
            with self.assertRaisesRegex(ValueError, "Conflicting"):
                full_checks(load_suites(root))

    def test_new_full_check_blocks_even_when_original_ten_pass(self):
        with TemporaryDirectory() as d:
            root = Path(d)
            (root / ".github/workflows").mkdir(parents=True)
            write_registry(root, [suite(checks=[job()])])
            class API:
                def runs(self, sha): return []
                def jobs(self, run_id): return []
            code, report = run_gate(root, "Jugadru/APEX-Simulation", SHA, "enforce", root / "out", API())
            self.assertEqual(code, 1)
            self.assertEqual(report["total"], len(REQUIREMENTS) + 1)
            self.assertEqual(report["checks"][-1]["status"], "MISSING_WORKFLOW")

    def test_unknown_core_still_expands_existing_coverage(self):
        from apex_ci_tiers import categories_for, CASES
        self.assertTrue(set(CASES).issubset(categories_for(["scripts/core/new_unmapped_thing.gd"])))

    def test_unknown_noncore_module_and_data_trigger_all_legacy_tests(self):
        from apex_ci_tiers import categories_for, CASES
        self.assertTrue(set(CASES).issubset(categories_for(["scripts/new_feature.gd"])))
        self.assertTrue(set(CASES).issubset(categories_for(["data/new_parameters.json"])))


if __name__ == "__main__":
    unittest.main()
