"""Tests of the APEX GDScript style report contract, without gdtoolkit dependency."""
from __future__ import annotations

from pathlib import Path
import sys
import unittest
from tempfile import TemporaryDirectory
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from gdscript_style_audit import AuditError, lint_findings, run_tool, summarize, to_markdown, tracked_scripts


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

    def test_scan_first_party_without_git_or_symlink(self):
        with TemporaryDirectory() as td:
            root = Path(td)
            source = root / "scripts" / "core"
            source.mkdir(parents=True)
            (source / "race.gd").write_text("extends RefCounted\n", encoding="utf-8")
            (source / "shortcut.gd").symlink_to(root / "outside.gd")
            self.assertEqual(tracked_scripts(root), ["scripts/core/race.gd"])

    def test_only_auditor_executables_allowed(self):
        with TemporaryDirectory() as td:
            with patch("gdscript_style_audit.subprocess.run") as command:
                with self.assertRaises(AuditError):
                    run_tool("bash", ["-c", "echo no"], Path(td), Path(td))
                command.assert_not_called()

    def test_missing_gdlint_is_an_error(self):
        with TemporaryDirectory() as td:
            with patch("gdscript_style_audit.shutil.which", return_value=None):
                with self.assertRaisesRegex(AuditError, "Missing"):
                    run_tool("gdlint", ["--version"], Path(td), Path(td))

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
