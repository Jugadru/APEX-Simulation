import copy
import hashlib
import json
import os
from unittest.mock import patch
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_foundation_metadata as m

class MetadataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = m.export()
        cls.season = m.parse((m.ROOT / m.PATHS[0]).read_bytes())
        cls.teams = m.parse((m.ROOT / m.PATHS[1]).read_bytes())

    def test_actual_catalog(self):
        c = self.report["body"]["catalog"]
        self.assertEqual((c["season"],len(c["teams"]),len(c["drivers"]),len(c["circuits"])),(2012,12,24,20))
        self.assertEqual(c["teams"][0]["name"],self.season["teams"][0]["name"])
        self.assertEqual(c["drivers"][0]["name"],self.season["teams"][0]["drivers"][0]["name"])
        self.assertEqual(c["circuits"][-1]["code"],self.season["tracks"][-1]["code"])
        self.assertEqual(self.report["body"]["identity_scope"],"EXACT_REVISION_ONLY")

    def test_deterministic_and_sources(self):
        self.assertEqual(m.export(),self.report)
        b=self.report["body"]
        self.assertEqual(self.report["body_sha256"],m.digest(b))
        self.assertFalse(b["runtime_applied"])
        self.assertFalse(b["execution_authorized"])
        for source in b["sources"]:
            raw=(m.ROOT/source["path"]).read_bytes()
            self.assertEqual(source["sha256"],hashlib.sha256(raw).hexdigest())
            self.assertEqual(source["size_bytes"],len(raw))
        self.assertNotIn("skill",json.dumps(b))
        self.assertNotIn("points",json.dumps(b))

    def test_divergent_team_catalog(self):
        teams=copy.deepcopy(self.teams)
        teams[0]["name"]="Changed"
        with self.assertRaises(ValueError):
            m.build(self.season,teams)

    def test_duplicate_driver_and_track(self):
        season=copy.deepcopy(self.season)
        season["teams"][1]["drivers"][0]["name"]=season["teams"][0]["drivers"][0]["name"]
        with self.assertRaises(ValueError):
            m.build(season,season["teams"])
        season=copy.deepcopy(self.season)
        season["tracks"][1]["code"]=season["tracks"][0]["code"]
        with self.assertRaises(ValueError):
            m.build(season,season["teams"])

    def test_invalid_schema_and_json(self):
        for raw in (b'{"x":1,"x":2}',b'{"x":NaN}',b"",b"x"*(m.MAX_BYTES+1)):
            with self.subTest(raw=raw[:20]),self.assertRaises(ValueError):
                m.parse(raw)
        for value in (True,0,201):
            season=copy.deepcopy(self.season)
            season["tracks"][0]["laps"]=value
            with self.assertRaises(ValueError):
                m.build(season,season["teams"])

    def test_inherited_git_environment_ignored(self):
        with patch.dict(os.environ,{"GIT_DIR":"/nonexistent/git","GIT_WORK_TREE":"/nonexistent",
                                    "GIT_CONFIG_COUNT":"1","GIT_CONFIG_KEY_0":"core.bare",
                                    "GIT_CONFIG_VALUE_0":"true"}):
            self.assertEqual(m.export(),self.report)

    def test_replacement_ref_and_nonregular_tree_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            def raw_git(*args):
                return subprocess.check_output(["git","-C",str(root),*args]).decode().strip()
            def commit(message):
                raw_git("add","data")
                raw_git("-c","user.name=Fixture","-c","user.email=fixture@example.invalid","commit","-qm",message)
            raw_git("init","-q")
            for path in m.PATHS:
                target=root/path
                target.parent.mkdir(parents=True,exist_ok=True)
                target.write_bytes((m.ROOT/path).read_bytes())
            commit("original")
            baseline=m.export(root)
            revision=baseline["body"]["revision"]
            target=root/m.PATHS[0]
            original=target.read_bytes()
            target.write_bytes(original+b"\n")
            commit("replacement")
            replacement=raw_git("rev-parse","HEAD")
            raw_git("checkout","-q","--detach",revision)
            raw_git("replace",revision,replacement)
            self.assertNotEqual(raw_git("rev-parse",revision+":"+m.PATHS[0]),baseline["body"]["sources"][0]["git_blob"])
            self.assertEqual(m.export(root),baseline)
            target.write_bytes(original+b"\n")
            with self.assertRaises(ValueError):
                m.export(root)
            raw_git("replace","-d",revision)
            target.unlink()
            target.symlink_to("teams.json")
            commit("nonregular")
            with self.assertRaisesRegex(ValueError,"regular source blob"):
                m.export(root)

    def test_checkout_tamper_and_symlink(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            subprocess.run(["git","init","-q",str(root)],check=True)
            for path in m.PATHS:
                target=root/path
                target.parent.mkdir(parents=True,exist_ok=True)
                target.write_bytes((m.ROOT/path).read_bytes())
            subprocess.run(["git","-C",str(root),"add","data"],check=True)
            subprocess.run(["git","-C",str(root),"-c","user.name=Fixture","-c","user.email=fixture@example.invalid",
                            "commit","-qm","fixture"],check=True)
            self.assertEqual(m.export(root)["body"]["catalog"],self.report["body"]["catalog"])
            target=root/m.PATHS[0]
            original=target.read_bytes()
            target.write_bytes(original.replace(b"2012",b"2013",1))
            with self.assertRaises(ValueError):
                m.export(root)
            target.unlink()
            target.symlink_to(m.ROOT/m.PATHS[0])
            with self.assertRaises(ValueError):
                m.export(root)

if __name__=="__main__":
    unittest.main()
