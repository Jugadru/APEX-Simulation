import copy
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_lab_command as lab

HEAD = "a" * 40
BASE = "b" * 40

def event():
    return {"action": "created", "repository": {"full_name": lab.REPO},
            "sender": {"login": lab.OWNER}, "comment": {"user": {"login": lab.OWNER},
            "author_association": "OWNER", "body": "/lab replay " + HEAD},
            "issue": {"number": 141}}

def pr():
    return {"state": "open", "head": {"repo": {"full_name": lab.REPO}, "sha": HEAD},
            "base": {"repo": {"full_name": lab.REPO}, "sha": BASE, "ref": "main"}}

class CommandTests(unittest.TestCase):
    def test_main(self):
        self.assertEqual(lab.authorize(event(), lab.OWNER, HEAD, None)["head"], HEAD)

    def test_every_command(self):
        for command in lab.COMMANDS:
            e = event()
            e["comment"]["body"] = "/lab " + command + " " + HEAD
            self.assertEqual(lab.authorize(e, lab.OWNER, HEAD, None)["command"], command)

    def test_bad_commands(self):
        for body in ("/lab publish " + HEAD, "/lab full " + HEAD, "/lab replay main",
                     "/lab replay " + HEAD + "; ls", "/lab replay " + HEAD + "\n/lab audit " + HEAD,
                     "/lab replay " + HEAD + " extra", "/lab performance-local " + HEAD):
            e = event()
            e["comment"]["body"] = body
            with self.assertRaises(ValueError):
                lab.authorize(e, lab.OWNER, HEAD, None)

    def test_nonowner(self):
        for actor, sender, association in (("other", lab.OWNER, "OWNER"),
                  (lab.OWNER, "other", "OWNER"), (lab.OWNER, lab.OWNER, "MEMBER")):
            e = event()
            e["sender"]["login"] = sender
            e["comment"]["author_association"] = association
            with self.assertRaises(ValueError):
                lab.authorize(e, actor, HEAD, None)

    def test_issue_and_revision(self):
        e = event()
        e["issue"]["number"] = 99
        with self.assertRaises(ValueError):
            lab.authorize(e, lab.OWNER, HEAD, None)
        with self.assertRaises(ValueError):
            lab.authorize(event(), lab.OWNER, BASE, None)

    def test_pr(self):
        e = event()
        e["issue"] = {"number": 145, "pull_request": {}}
        self.assertEqual(lab.authorize(e, lab.OWNER, BASE, lambda _: pr())["base"], BASE)
        for change in ("fork", "closed", "moved", "otherbase", "deleted"):
            p = pr()
            if change == "fork": p["head"]["repo"]["full_name"] = "other/fork"
            if change == "closed": p["state"] = "closed"
            if change == "moved": p["head"]["sha"] = BASE
            if change == "otherbase": p["base"]["ref"] = "dev"
            if change == "deleted": p["head"]["repo"] = None
            with self.assertRaises(ValueError):
                lab.authorize(e, lab.OWNER, BASE, lambda _: p)

    def test_missing_fixture_and_routing(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "tests").mkdir()
            with self.assertRaises(ValueError):
                lab.select_tests("replay", BASE, HEAD, root)
            for name, marker in lab.TESTS["replay"]:
                (root / "tests" / name).touch()
            self.assertEqual(lab.select_tests("replay", BASE, HEAD, root), list(lab.TESTS["replay"]))
            self.assertEqual(lab.select_tests("audit", BASE, HEAD, root), [])
            self.assertEqual(lab.select_tests("build", BASE, HEAD, root), [])
            with patch.object(lab.subprocess, "check_output", return_value="bad|x\n"):
                with self.assertRaises(ValueError):
                    lab.select_tests("fast", BASE, HEAD, root)

    def test_real_checkout_fixture_list(self):
        root = Path(__file__).resolve().parents[2]
        for command in lab.TESTS:
            self.assertTrue(lab.select_tests(command, BASE, HEAD, root))

    def test_case_markers(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            log = root / "run.log"
            for output, status in (("OK", "PASS"), ("no", "FAIL"), ("OK\nSCRIPT ERROR: bad", "FAIL")):
                self.assertEqual(lab.run_case([sys.executable, "-c", "print(" + repr(output) + ")"],
                    log, 5, root, "OK", True)["status"], status)

if __name__ == "__main__":
    unittest.main()
