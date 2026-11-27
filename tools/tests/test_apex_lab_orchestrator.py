import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_lab_orchestrator as lab

HEAD = "a" * 40


class OrchestrationTests(unittest.TestCase):
    def test_order_and_priority(self):
        manifest = lab.default_manifest()
        manifest["tasks"].reverse()
        self.assertEqual([t["id"] for t in lab.plan(manifest, "read")], ["inventory", "architecture"])
        manifest["tasks"][0]["depends_on"] = []
        manifest["tasks"][0]["priority"] = 90
        self.assertEqual(lab.plan(manifest, "read")[0]["id"], "architecture")

    def test_rejections(self):
        for field, value in (("depends_on", ["missing"]), ("depends_on", ["architecture"]),
                             ("capability", "shell"), ("timeout_seconds", 999),
                             ("timeout_seconds", True), ("permissions", ["write"]),
                             ("acceptance", "anything"), ("id", "../escape"), ("command", "ls")):
            m = lab.default_manifest()
            m["tasks"][0][field] = value
            with self.subTest(field=field, value=value), self.assertRaises(ValueError):
                lab.plan(m, "read")
        m = lab.default_manifest()
        m["tasks"].append(copy.deepcopy(m["tasks"][0]))
        with self.assertRaises(ValueError):
            lab.plan(m, "read")
        with self.assertRaises(ValueError):
            lab.plan(lab.default_manifest(), "publication")

    def test_duplicate_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "input.json"
            p.write_text('{"schema":1,"schema":1,"tasks":[]}')
            with self.assertRaises(ValueError):
                lab.read_manifest(p)

    def execute(self, first="PASS", catalog=False, wrong_sha=False):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "checkout"
            (root / "tools").mkdir(parents=True)
            for cap in lab.CAPABILITIES.values():
                if cap["script"] != "tools/apex_foundation.py":
                    (root / cap["script"]).touch()
            calls = []
            def runner(argv, log, timeout, cwd):
                calls.append(argv)
                log.write_text("controlled fixture")
                if "--output" in argv:
                    Path(argv[-1]).write_text("{}")
                return {"status": first if len(calls) == 1 else "PASS"}
            m = lab.default_manifest()
            if catalog:
                t = m["tasks"][0]
                t.update(capability="foundation.catalog", acceptance="catalog_pass", timeout_seconds=30)
            out = Path(tmp) / "evidence"
            with patch.object(subprocess, "check_output", return_value=("b" * 40 if wrong_sha else HEAD) + "\n"):
                if wrong_sha:
                    with self.assertRaises(ValueError):
                        lab.run(m, "read", root, out, HEAD, runner)
                    self.assertFalse(out.exists())
                    return
                result = lab.run(m, "read", root, out, HEAD, runner)
            self.assertEqual(result, json.loads((out / "report.json").read_text()))
            for task in result["tasks"]:
                for evidence in task["evidence"]:
                    self.assertEqual(evidence["sha256"], lab.digest(out / evidence["path"]))
            return result, calls

    def test_success(self):
        result, calls = self.execute()
        self.assertEqual(result["status"], "PASS")
        self.assertEqual(len(calls), 2)
        self.assertEqual(calls[0][1], "tools/apex_source_inventory.py")

    def test_failure_blocks_dependent_without_retry(self):
        result, calls = self.execute("FAIL")
        self.assertEqual(result["status"], "FAIL")
        self.assertEqual(len(calls), 1)
        self.assertEqual(result["tasks"][1]["status"], "BLOCKED")
        self.assertEqual(result["tasks"][1]["attempts"], 0)

    def test_missing_catalog(self):
        result, calls = self.execute(catalog=True)
        self.assertEqual(result["status"], "BLOCKED")
        self.assertEqual(calls, [])

    def test_exact_sha(self):
        self.execute(wrong_sha=True)


if __name__ == "__main__":
    unittest.main()
