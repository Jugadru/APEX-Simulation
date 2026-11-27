"""Small offline preflight contract regressions."""
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_preflight import indentation_findings, marker_findings, contracts
from apex_ci_tiers import ALWAYS


class PreflightTests(unittest.TestCase):
    def test_missing_fixture(self):
        with tempfile.TemporaryDirectory() as tmp:
            missing, review = marker_findings(Path(tmp), [("test.gd", "PASS")])
            self.assertEqual(len(missing), 1)
            self.assertFalse(review)

    def test_marker_typo_and_fix(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "tests").mkdir()
            path = root / "tests/test.gd"
            path.write_text('print("GEARBOX_V21_PASS")', encoding="utf-8")
            pair = [("test.gd", "GEARBOX_V21_070_PASS")]
            self.assertEqual(len(marker_findings(root, pair)[1]), 1)
            path.write_text('print("GEARBOX_V21_070_PASS")', encoding="utf-8")
            self.assertEqual(marker_findings(root, pair), ([], []))

    def test_indent_advisory_only_added_lines(self):
        self.assertEqual(indentation_findings("+++ b/test.gd\n-\t x\n+\t y\n+\tz"), ["\t y"])

    def test_direct_manifest_fixture_edit(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / ".github").mkdir()
            (root / ".github/apex-quality-suites.json").write_text(
                '{"schema":1,"suites":[{"id":"sample","paths":["scripts/sample.gd"],'
                '"fast_tests":[{"script":"sample.gd","marker":"SAMPLE_PASS"}],"checks":[]}]}',
                encoding="utf-8")
            self.assertIn(("sample.gd", "SAMPLE_PASS"), contracts(root, ["tests/sample.gd"]))

    def test_docs_keeps_baseline(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertEqual(contracts(Path(tmp), ["README.md"]), list(ALWAYS))


if __name__ == "__main__":
    unittest.main()
