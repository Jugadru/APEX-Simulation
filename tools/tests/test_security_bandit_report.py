"""Contract tests for APEX static Python security reports."""
from __future__ import annotations

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from security_bandit_report import ReportError, markdown, summarize


def fixture(results=None, errors=None):
    return {
        "results": [] if results is None else results,
        "errors": [] if errors is None else errors,
        "metrics": {"_totals": {"loc": 42}, "tools/report.py": {"loc": 42}},
    }


class SecurityReportTests(unittest.TestCase):
    def test_empty_valid_report_is_clean(self):
        info = summarize(fixture())
        self.assertEqual(info["status"], "CLEAN")
        self.assertEqual(info["finding_count"], 0)

    def test_findings_counted_without_failing_audit(self):
        info = summarize(fixture(results=[
            {"issue_severity": "HIGH", "issue_confidence": "HIGH", "test_id": "B602"},
            {"issue_severity": "LOW", "issue_confidence": "MEDIUM", "test_id": "B101"},
        ]))
        self.assertEqual(info["status"], "FINDINGS")
        self.assertEqual(info["by_severity"]["HIGH"], 1)
        self.assertEqual(info["by_severity"]["LOW"], 1)
        self.assertIn("CodeQL", markdown(info))

    def test_report_errors_must_not_pass(self):
        with self.assertRaises(ReportError):
            summarize(fixture(errors=[{"filename": "bad.py", "reason": "SyntaxError"}]))

    def test_missing_results_must_not_pass(self):
        with self.assertRaises(ReportError):
            summarize({"errors": [], "metrics": {}})

    def test_missing_metrics_must_not_pass(self):
        with self.assertRaises(ReportError):
            summarize({"results": [], "errors": []})

    def test_empty_metrics_never_claim_clean(self):
        report = fixture()
        report["metrics"] = {}
        with self.assertRaises(ReportError):
            summarize(report)

    def test_zero_line_scan_rejected(self):
        report = fixture()
        report["metrics"]["_totals"]["loc"] = 0
        with self.assertRaises(ReportError):
            summarize(report)

    def test_no_per_file_scan_evidence_rejected(self):
        report = fixture()
        del report["metrics"]["tools/report.py"]
        with self.assertRaises(ReportError):
            summarize(report)

    def test_invalid_finding_must_not_pass(self):
        with self.assertRaises(ReportError):
            summarize(fixture(results=["invalid finding"]))


if __name__ == "__main__":
    unittest.main()
