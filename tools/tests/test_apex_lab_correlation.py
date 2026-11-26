from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_lab_correlation as corr

HEAD = "a" * 40
BASE = "b" * 40

def context(*paths):
    return {"head": HEAD, "base": BASE, "changed_files": list(paths), "domains": ["driver"]}

def failure(path="scripts/a.gd"):
    return {"name": "fixture.gd", "status": "FAIL",
            "diagnosis": {"kind": "PARSE", "locations": [{"file": path, "line": 12}],
                          "next_action": "Inspect script", "log_partial": False}}

class CorrelationTests(unittest.TestCase):
    def test_direct_and_both_graph_directions(self):
        graph = {"complete": True, "edges": {
            "scripts/a.gd": ["scripts/b.gd"], "scripts/b.gd": ["scripts/c.gd"],
            "scripts/c.gd": [], "scripts/d.gd": ["scripts/a.gd"]}}
        r = corr.correlate(context("scripts/a.gd", "scripts/c.gd", "scripts/d.gd", "scripts/unrelated.gd"),
                           [failure()], [{"script": "fixture.gd"}, {"script": "later.gd"}], graph)
        candidates = r["failures"][0]["candidates"]
        self.assertEqual([c["file"] for c in candidates], ["scripts/a.gd", "scripts/d.gd", "scripts/c.gd"])
        self.assertEqual([c["relation"] for c in candidates],
                         ["direct_path_match", "literal_consumer", "literal_dependency"])
        self.assertEqual(r["failures"][0]["root_cause"], "NOT_ESTABLISHED")
        self.assertEqual(r["planned_not_executed"], ["later.gd"])

    def test_missing_graph_and_no_match(self):
        r = corr.correlate(context("scripts/x.gd"), [failure()], [], None)
        self.assertFalse(r["graph_complete"])
        self.assertEqual(r["failures"][0]["candidate_count"], 0)
        self.assertEqual(r["state"], "FAILURE_EVIDENCE")

    def test_no_failure_not_approval(self):
        r = corr.correlate(context("scripts/a.gd"), [{"name": "import", "status": "PASS"}],
                           [{"script": "fixture.gd"}])
        self.assertEqual(r["state"], "NO_CASE_FAILURE_OBSERVED")
        self.assertEqual(r["planned_not_executed"], ["fixture.gd"])
        self.assertEqual(r["failures"], [])

    def test_bounded_paths_and_cycles(self):
        graph = {"a": ["b"], "b": ["c"], "c": ["d"], "d": ["e", "a"], "e": []}
        paths = list(corr.neighborhood(graph, ["a"]))
        self.assertTrue(all(len(chain) <= 4 for _, _, chain in paths))
        self.assertNotIn(("e", "literal_dependency", ["a","b","c","d","e"]), paths)
        self.assertFalse(any(target == "a" for target, _, _ in paths))

    def test_real_git_diff(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            def git(*args):
                return subprocess.check_output(["git", *args], cwd=root, text=True).strip()
            git("init", "-q")
            git("config", "user.name", "Test")
            git("config", "user.email", "test@example.invalid")
            (root / "scripts").mkdir()
            p = root / "scripts/race_engine.gd"
            p.write_text("first")
            git("add", ".")
            git("commit", "-qm", "base")
            base = git("rev-parse", "HEAD")
            p.write_text("second")
            git("add", ".")
            git("commit", "-qm", "candidate")
            head = git("rev-parse", "HEAD")
            r = corr.change_context(root, "", head)
            self.assertEqual(r["base"], base)
            self.assertEqual(r["changed_files"], ["scripts/race_engine.gd"])
            self.assertIn("ai", r["domains"])

if __name__ == "__main__":
    unittest.main()
