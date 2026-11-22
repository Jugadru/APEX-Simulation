"""Offline contracts for the v9.9 release gate; never emulate Godot CI PASS."""
from __future__ import annotations

from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_race_quality_release_gate import ALL_REQUIREMENTS, FULL_MATRIX_POLICY, audit
from apex_quality_gate import GateError

SHA = "a" * 40
BASE = "b" * 40
PR = 87


class Stub:
    repo = "Jugadru/APEX-Simulation"

    def __init__(self, runs, jobs):
        self._runs, self._jobs = runs, jobs

    def runs(self, sha):
        assert sha == SHA
        return self._runs

    def jobs(self, run_id):
        return self._jobs[run_id]


class ReleaseGateContracts(unittest.TestCase):
    def setUp(self):
        self.temp = TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        workflow = self.root / ".github" / "workflows"
        workflow.mkdir(parents=True)
        for req in ALL_REQUIREMENTS:
            (workflow / req.workflow).write_text("name: test\n", encoding="utf-8")
        (workflow / "apex-scenario-matrix-ci.yml").write_text(
            FULL_MATRIX_POLICY + "\n", encoding="utf-8"
        )

    @staticmethod
    def evidence():
        runs, jobs = [], {}
        for i, req in enumerate(ALL_REQUIREMENTS, 1):
            run = {
                "id": i, "head_sha": SHA,
                "path": ".github/workflows/" + req.workflow,
                "event": "pull_request", "status": "completed",
                "conclusion": "success",
                "created_at": f"2026-11-22T05:{i:02d}:00Z",
                "run_attempt": 1,
                "pull_requests": [
                    {"number": PR, "base": {"sha": BASE}, "head": {"sha": SHA}},
                ],
            }
            if req.workflow == "apex-scenario-matrix-ci.yml":
                # The four matrix requirements share one workflow run.
                previous = next((r for r in runs if r["path"] == run["path"]), None)
                if previous:
                    run = previous
                else:
                    runs.append(run)
            else:
                runs.append(run)
            jobs.setdefault(run["id"], []).append({
                "name": req.job, "status": "completed", "conclusion": "success"
            })
        return runs, jobs

    def test_full_18_job_evidence_ready(self):
        runs, jobs = self.evidence()
        report = audit(self.root, SHA, PR, BASE, Stub(runs, jobs))
        self.assertEqual(report["status"], "READY")
        self.assertEqual(report["passed"], 18)
        self.assertEqual(report["total"], 18)

    def test_missing_one_matrix_shard_blocks(self):
        runs, jobs = self.evidence()
        for row in jobs.values():
            row[:] = [x for x in row if x["name"] != "Matrix 2012 / grupo 3 de 4"]
        report = audit(self.root, SHA, PR, BASE, Stub(runs, jobs))
        self.assertEqual(report["status"], "BLOCKED")
        self.assertTrue(any(x["key"] == "matrix_3"
                            and x["status"] == "JOB_NOT_SUCCESSFUL"
                            for x in report["checks"]))

    def test_old_commit_or_wrong_base_not_accepted(self):
        runs, jobs = self.evidence()
        runs[0]["head_sha"] = "c" * 40
        report = audit(self.root, SHA, PR, BASE, Stub(runs, jobs))
        self.assertEqual(report["status"], "BLOCKED")
        runs, jobs = self.evidence()
        report = audit(self.root, SHA, PR, "d" * 40, Stub(runs, jobs))
        self.assertEqual(report["status"], "BLOCKED")

    def test_full_matrix_policy_mandatory(self):
        path = self.root / ".github" / "workflows" / "apex-scenario-matrix-ci.yml"
        path.write_text("APEX_MATRIX_PROFILE: smoke\n", encoding="utf-8")
        runs, jobs = self.evidence()
        with self.assertRaisesRegex(GateError, "Full 180"):
            audit(self.root, SHA, PR, BASE, Stub(runs, jobs))


if __name__ == "__main__":
    unittest.main()
