import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_ci_merge_guard as guard

BASE, HEAD, MERGE, TREE = "a"*40, "b"*40, "c"*40, "d"*40
REPO = "Jugadru/APEX-Simulation"
def pr():
    return {"number": 12, "state": "open", "draft": True, "mergeable": True,
            "merge_commit_sha": MERGE,
            "base": {"sha": BASE, "ref": "main", "repo": {"full_name": REPO}},
            "head": {"sha": HEAD, "repo": {"full_name": REPO}}}

def env():
    return {"GITHUB_EVENT_NAME": "pull_request", "GITHUB_SHA": MERGE,
            "GITHUB_REPOSITORY": REPO, "APEX_BASE_SHA": BASE, "APEX_HEAD_SHA": HEAD,
            "GITHUB_RUN_ID": "123", "GITHUB_RUN_ATTEMPT": "1"}

class MergeGuardTests(unittest.TestCase):
    def test_exact_merge_parents(self):
        with patch.object(guard, "git", side_effect=[MERGE, BASE+" "+HEAD, TREE]):
            expected = guard.identity({"pull_request": pr()}, env(), Path("."))
        self.assertEqual(expected["tree"], TREE)
        guard.verify_live(expected, pr())
        for key in ("base", "head"):
            changed = pr()
            changed[key]["sha"] = "e"*40
            with self.assertRaises(ValueError):
                guard.verify_live(expected, changed)
        changed = pr()
        changed["mergeable"] = False
        with self.assertRaises(ValueError):
            guard.verify_live(expected, changed)

    def test_wrong_checkout_or_parent_rejected(self):
        for values in ([HEAD], [MERGE, HEAD+" "+BASE], [MERGE, "e"*40+" "+HEAD]):
            with patch.object(guard, "git", side_effect=values):
                with self.assertRaises(ValueError):
                    guard.identity({"pull_request": pr()}, env(), Path("."))

    def test_complete_evidence_and_blocked_fixtures(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            rows = [s+"|"+m for s,m in guard.ALWAYS]
            for name in ("fast-plan.tsv", "test-plan.txt"):
                (root/name).write_text("\n".join(rows)+"\n")
            for s,m in guard.ALWAYS:
                (root/(s[:-3]+".log")).write_text(m+"\n")
            (root/"lab-perf").mkdir()
            (root/"lab-perf/report.json").write_text(json.dumps(
                {"status":"PASS", "cases":4, "total_ticks":2000}))
            self.assertEqual(len(guard.evidence(root)), len(rows))
            (root/(guard.ALWAYS[0][0][:-3]+".log")).write_text("SCRIPT ERROR: failure\n"+guard.ALWAYS[0][1])
            with self.assertRaises(ValueError):
                guard.evidence(root)
            (root/"test-plan.txt").write_text("\n".join(rows[:-1])+"\n")
            with self.assertRaises(ValueError):
                guard.evidence(root)

if __name__ == "__main__":
    unittest.main()
