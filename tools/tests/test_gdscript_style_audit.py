"""Tests of the APEX GDScript style report contract, without gdtoolkit dependency."""
from __future__ import annotations

from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from gdscript_style_audit import DIAGNOSTIC_RE, lint_findings, summarize, to_markdown


class GDScriptAuditContractTests(unittest.TestCase):
    def test_extracts_errors_from_first_party_files(self):
        log = (
            "scripts/main.gd:3: Error: Invalid name (function-name)\n"
            "scripts/core/race_ai_director.gd:12: Warning: Line too long\n"
            "Unrelated error message\n"
        )
        counts = lint_findings(log)
        self.assertEqual(sum(counts.values()), 2)
        self.assertEqual(counts["scripts/main.gd"], 1)

    def test_ignores_non_diagnostic_text(self):
        self.assertEqual(sum(lint_findings("All files pass\n").values()), 0)

    def test_clean_requires_two_successes(self):
        result = summarize(
            ["scripts/main.gd"],
            {"exit_code": 0, "log": ""},
            {"exit_code": 0, "log": ""},
            "4.5.0",
        )
        self.assertEqual(result["status"], "CLEAN")
        self.assertEqual(result["files_scanned"], 1)
        self.assertFalse(result["source_files_modified"])

    def test_historical_style_findings_are_visible(self):
        result = summarize(
            ["scripts/main.gd"],
            {"exit_code": 1, "log": "scripts/main.gd:2: Error: example"},
            {"exit_code": 1, "log": "would reformat scripts/main.gd"},
            "4.5.0",
        )
        self.assertEqual(result["status"], "FINDINGS")
        self.assertEqual(result["mode"], "INFORMATIONAL")
        self.assertEqual(result["gdlint_diagnostic_lines"], 1)
        self.assertIn("não bloqueia", to_markdown(result))
        self.assertIn("gdformat --check", to_markdown(result))

    def test_formatting_only_findings_are_not_clean(self):
        result = summarize(
            ["scripts/main.gd"],
            {"exit_code": 0, "log": ""},
            {"exit_code": 1, "log": "would reformat"},
            "4.5.0",
        )
        self.assertEqual(result["status"], "FINDINGS")


if __name__ == "__main__":
    unittest.main()
