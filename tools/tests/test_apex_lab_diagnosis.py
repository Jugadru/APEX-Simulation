import json
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_lab_diagnosis as diag
import apex_lab_command as bridge

class DiagnosisTests(unittest.TestCase):
    def check(self, text, status="FAIL", code=1, reason="", marker=None):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "case.log"
            path.write_text(text)
            return diag.diagnose(path, status=status, exit_code=code, reason=reason, marker=marker)

    def test_parse_and_location(self):
        r = self.check("SCRIPT ERROR: Parse Error: bad\n at: res://scripts/core/test.gd:42")
        self.assertEqual(r["kind"], "PARSE")
        self.assertEqual(r["locations"], [{"file": "scripts/core/test.gd", "line": 42}])
        self.assertEqual(r["root_cause"], "NOT_ESTABLISHED")

    def test_resource_runtime_assertion_engine(self):
        for log, kind in (("Failed loading resource: res://assets/test.tres", "RESOURCE"),
                          ("SCRIPT ERROR: Invalid call", "SCRIPT_RUNTIME"),
                          ("Assertion failed", "ASSERTION"), ("ERROR: driver", "ENGINE_ERROR")):
            self.assertEqual(self.check(log)["kind"], kind)

    def test_missing_marker_exit_timeout(self):
        self.assertEqual(self.check("done", code=0, marker="PASS")["kind"], "MISSING_MARKER")
        self.assertEqual(self.check("done", code=9)["kind"], "NONZERO_EXIT")
        self.assertEqual(self.check("", reason="timeout")["kind"], "TIMEOUT")
        self.assertEqual(self.check("", reason="executable unavailable")["kind"], "EXECUTABLE_UNAVAILABLE")

    def test_no_raw_text_or_path_traversal(self):
        r = self.check("SCRIPT ERROR: secret123 /home/user/a res://../bad.gd:5 res://scripts/a.gd:9")
        self.assertNotIn("secret123", json.dumps(r))
        self.assertNotIn("/home/user", json.dumps(r))
        self.assertEqual(r["locations"], [{"file": "scripts/a.gd", "line": 9}])

    def test_bounded_log(self):
        r = self.check("x" * diag.MAX_BYTES + "\nParse Error: bad")
        self.assertTrue(r["log_partial"])
        self.assertEqual(r["kind"], "PARSE")

    def test_real_process_failure_and_success(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            for message, status, kind in (
                ("OK", "PASS", "NONE"),
                ("OK\nSCRIPT ERROR: Parse Error: bad\nres://scripts/a.gd:4", "FAIL", "PARSE"),
                ("no marker", "FAIL", "MISSING_MARKER"),
            ):
                r = bridge.run_case([sys.executable, "-c", "print(" + repr(message) + ")"],
                                    root / "case.log", 5, root, "OK", True)
                self.assertEqual(r["status"], status)
                self.assertEqual(r["diagnosis"]["kind"], kind)

if __name__ == "__main__":
    unittest.main()
