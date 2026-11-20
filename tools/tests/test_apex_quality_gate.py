"""Offline unit tests: Quality Gate must never approve stale/missing CI."""
from __future__ import annotations

import io
import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_quality_gate import (
    GateError, GitHubAPI, REQUIREMENTS, assess, assess_requirement,
    markdown_report, run_gate, select_run, validate_identity,
)

SHA = "a" * 40
OTHER = "b" * 40
BASE = "c" * 40
PR = 27


def run_for(req, sha=SHA, event="pull_request", conclusion="success",
            status="completed", run_id=1, pr_number=PR, base_sha=BASE,
            started_at=None, run_attempt=1):
    return {
        "id": run_id,
        "head_sha": sha,
        "path": ".github/workflows/" + req.workflow,
        "event": event,
        "status": status,
        "conclusion": conclusion,
        "created_at": f"2026-11-19T12:{run_id:02d}:00Z",
        "run_attempt": run_attempt,
        "run_started_at": started_at or f"2026-11-19T12:{run_id:02d}:00Z",
        "pull_requests": [
            {"number": pr_number, "base": {"sha": base_sha}, "head": {"sha": sha}}
        ] if event == "pull_request" else [],
        "html_url": f"https://github.com/example/apex/actions/runs/{run_id}",
    }


def success_job(req):
    return [{"name": req.job, "status": "completed", "conclusion": "success"}]


class StubAPI:
    def __init__(self, runs, jobs):
        self._runs = runs
        self._jobs = jobs

    def runs(self, sha):
        if sha != SHA:
            raise AssertionError("unexpected sha")
        return self._runs

    def jobs(self, run_id):
        return self._jobs[run_id]


class QualityGateTests(unittest.TestCase):
    def test_require_exact_commit_and_repository(self):
        validate_identity("Quereni/APEX-Simulation", SHA)
        with self.assertRaises(GateError):
            validate_identity("bad", SHA)
        with self.assertRaises(GateError):
            validate_identity("Quereni/APEX-Simulation", "main")

    def test_missing_workflow_is_blocked_even_if_other_branch_passed(self):
        req = REQUIREMENTS[0]
        row = assess_requirement(req, set(), [run_for(req, sha=OTHER)], SHA, lambda _: success_job(req))
        self.assertEqual(row["status"], "MISSING_WORKFLOW")

    def test_run_from_other_sha_is_never_accepted(self):
        req = REQUIREMENTS[0]
        row = assess_requirement(req, {req.workflow}, [run_for(req, sha=OTHER)], SHA, lambda _: success_job(req))
        self.assertEqual(row["status"], "NO_RUN")

    def test_comparison_requires_pull_request_not_manual_default(self):
        req = REQUIREMENTS[1]
        row = assess_requirement(req, {req.workflow}, [run_for(req, event="workflow_dispatch")], SHA, lambda _: success_job(req))
        self.assertEqual(row["status"], "NO_RUN")

    def test_non_comparison_can_use_manual_run_same_commit(self):
        req = REQUIREMENTS[0]
        row = assess_requirement(req, {req.workflow}, [run_for(req, event="workflow_dispatch")], SHA, lambda _: success_job(req))
        self.assertEqual(row["status"], "PASSED")

    def test_pending_is_not_green(self):
        req = REQUIREMENTS[0]
        row = assess_requirement(req, {req.workflow}, [run_for(req, status="in_progress", conclusion=None)], SHA, lambda _: success_job(req))
        self.assertEqual(row["status"], "PENDING")

    def test_failed_or_cancelled_not_green(self):
        req = REQUIREMENTS[0]
        for bad in ("failure", "cancelled", "timed_out"):
            row = assess_requirement(req, {req.workflow}, [run_for(req, conclusion=bad)], SHA, lambda _: success_job(req))
            self.assertEqual(row["status"], "FAILED")

    def test_skipped_required_job_not_green(self):
        req = REQUIREMENTS[4]
        def skipped(_):
            return [{"name": req.job, "status": "completed", "conclusion": "skipped"}]
        row = assess_requirement(req, {req.workflow}, [run_for(req)], SHA, skipped)
        self.assertEqual(row["status"], "JOB_NOT_SUCCESSFUL")

    def test_codeql_skipped_does_not_affect_bandit_success(self):
        req = REQUIREMENTS[4]
        def jobs(_):
            return success_job(req) + [{"name": "CodeQL Python / necessita GitHub Code Security",
                                        "status": "completed", "conclusion": "skipped"}]
        row = assess_requirement(req, {req.workflow}, [run_for(req)], SHA, jobs)
        self.assertEqual(row["status"], "PASSED")
        self.assertIn("informational", row["note"])

    def test_latest_failure_overrides_older_success_same_sha(self):
        req = REQUIREMENTS[0]
        earlier = run_for(req, run_id=1)
        latest = run_for(req, run_id=2, conclusion="failure")
        selected = select_run([latest, earlier], req, SHA)
        self.assertEqual(selected["id"], 2)
        row = assess_requirement(req, {req.workflow}, [earlier, latest], SHA, lambda _: success_job(req))
        self.assertEqual(row["status"], "FAILED")

    def test_all_ten_true_jobs_required_for_ready(self):
        runs = [run_for(req, run_id=i + 1) for i, req in enumerate(REQUIREMENTS)]
        jobs = {i + 1: success_job(req) for i, req in enumerate(REQUIREMENTS)}
        result = assess({req.workflow for req in REQUIREMENTS}, runs, SHA, lambda idx: jobs[idx], pr_number=PR, base_sha=BASE)
        self.assertEqual(result["status"], "READY")
        self.assertEqual(result["passed"], 10)
        self.assertEqual(result["total"], 10)

    def test_missing_one_blocks_full_matrix(self):
        runs = [run_for(req, run_id=i + 1) for i, req in enumerate(REQUIREMENTS[:-1])]
        jobs = {i + 1: success_job(req) for i, req in enumerate(REQUIREMENTS[:-1])}
        result = assess({req.workflow for req in REQUIREMENTS}, runs, SHA, lambda idx: jobs[idx], pr_number=PR, base_sha=BASE)
        self.assertEqual(result["status"], "BLOCKED")
        self.assertEqual(result["passed"], 9)
        self.assertEqual(result["checks"][-1]["status"], "NO_RUN")

    def test_audit_reports_blocked_without_approving_release(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".github" / "workflows").mkdir(parents=True)
            api = StubAPI([], {})
            output = root / "out"
            status, report = run_gate(root, "Quereni/APEX-Simulation", SHA, "audit", output, api)
            self.assertEqual(status, 0)
            self.assertEqual(report["status"], "BLOCKED")
            self.assertIn("BLOCKED", (output / "report.md").read_text(encoding="utf-8"))
            self.assertEqual(json.loads((output / "report.json").read_text(encoding="utf-8"))["passed"], 0)

    def test_enforce_fails_closed_when_missing(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".github" / "workflows").mkdir(parents=True)
            status, report = run_gate(root, "Quereni/APEX-Simulation", SHA, "enforce", root / "out", StubAPI([], {}))
            self.assertEqual(status, 1)
            self.assertEqual(report["status"], "BLOCKED")

    def test_enforce_succeeds_only_with_ten_compliant_jobs(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            folder = root / ".github" / "workflows"
            folder.mkdir(parents=True)
            for req in REQUIREMENTS:
                (folder / req.workflow).write_text("name: test\n", encoding="utf-8")
            runs = [run_for(req, run_id=i + 1) for i, req in enumerate(REQUIREMENTS)]
            jobs = {i + 1: success_job(req) for i, req in enumerate(REQUIREMENTS)}
            status, report = run_gate(root, "Quereni/APEX-Simulation", SHA, "enforce", root / "out", StubAPI(runs, jobs), PR, BASE)
            self.assertEqual(status, 0)
            self.assertEqual(report["status"], "READY")
            self.assertIn("10/10", markdown_report(report, "enforce"))

    def test_comparison_requires_same_pr_and_base(self):
        req = REQUIREMENTS[1]
        wrong_pr = run_for(req, pr_number=8)
        wrong_base = run_for(req, base_sha=OTHER)
        for item in (wrong_pr, wrong_base):
            row = assess_requirement(
                req, {req.workflow}, [item], SHA,
                lambda _: success_job(req), PR, BASE
            )
            self.assertEqual(row["status"], "NO_RUN")
        correct = assess_requirement(
            req, {req.workflow}, [run_for(req)], SHA,
            lambda _: success_job(req), PR, BASE
        )
        self.assertEqual(correct["status"], "PASSED")

    def test_comparison_requires_context_even_for_correct_pr_run(self):
        req = REQUIREMENTS[1]
        row = assess_requirement(
            req, {req.workflow}, [run_for(req)], SHA, lambda _: success_job(req)
        )
        self.assertEqual(row["status"], "NO_RUN")

    def test_rerun_of_older_run_started_later_overrides_newer(self):
        req = REQUIREMENTS[0]
        old_rerun = run_for(
            req, run_id=1, run_attempt=3, started_at="2026-11-19T14:00:00Z",
            conclusion="failure"
        )
        newer = run_for(
            req, run_id=2, started_at="2026-11-19T13:00:00Z",
            conclusion="success"
        )
        selected = select_run([newer, old_rerun], req, SHA)
        self.assertEqual(selected["id"], 1)
        row = assess_requirement(
            req, {req.workflow}, [old_rerun, newer], SHA,
            lambda _: success_job(req)
        )
        self.assertEqual(row["status"], "FAILED")

    def test_api_rejects_untrusted_endpoint_before_network(self):
        api = GitHubAPI("Quereni/APEX-Simulation", "test-token")
        with patch("apex_quality_gate.request.urlopen") as network:
            with self.assertRaises(GateError):
                api.get("https://evil.example.com/steal")
            with self.assertRaises(GateError):
                api.get("/actions/runs/1/../../secrets")
            network.assert_not_called()

    def test_api_reports_network_failure(self):
        from urllib.error import URLError
        api = GitHubAPI("Quereni/APEX-Simulation", "test-token")
        with patch("apex_quality_gate.request.urlopen", side_effect=URLError("offline")):
            with self.assertRaisesRegex(GateError, "unavailable"):
                api.runs(SHA)

    def test_api_rejects_malformed_response(self):
        api = GitHubAPI("Quereni/APEX-Simulation", "test-token")
        body = '{"workflow_runs": "not an array"}'
        with patch("apex_quality_gate.request.urlopen", return_value=io.BytesIO(body.encode())):
            with self.assertRaisesRegex(GateError, "Unexpected"):
                api.runs(SHA)

    def test_pr_context_requires_valid_number_and_base(self):
        from apex_quality_gate import validate_pr_context
        validate_pr_context(PR, BASE)
        for pr, base in ((PR, ""), (0, BASE), (-1, ""), (PR, "main")):
            with self.assertRaises(GateError):
                validate_pr_context(pr, base)

    def test_diagnostics_distinguish_codeql_and_informational_checks(self):
        report = assess(set(), [], SHA, lambda _: [])
        text = markdown_report(report, "audit")
        self.assertIn("CodeQL", text)
        self.assertIn("GDScript Toolkit", "\n".join(report["limitations"]))
        self.assertIn("não autoriza merge", text)


if __name__ == "__main__":
    unittest.main()
