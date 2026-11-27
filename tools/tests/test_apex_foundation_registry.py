import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_foundation_registry as f

class RegistryTest(unittest.TestCase):
    def setUp(self):
        self.reg, self.schemas = f.load_registry()

    def test_registry(self):
        self.assertEqual(f.validate_registry(self.reg, self.schemas)["status"], "PASS")

    def test_duplicate_and_cycle(self):
        for mutate in (
            lambda r: r["modules"].append(r["modules"][0]),
            lambda r: r["modules"][0]["dependencies"].append("foundation"),
            lambda r: r["capabilities"][0].update(module="missing"),
            lambda r: r["compatibility"].append(r["compatibility"][0]),
            lambda r: r["modules"][0]["entrypoints"].append("../secret"),
        ):
            reg = copy.deepcopy(self.reg)
            mutate(reg)
            with self.assertRaises(ValueError):
                f.validate_registry(reg, self.schemas)

    def test_closed_contract(self):
        cap = copy.deepcopy(self.reg["capabilities"][0])
        schema = self.schemas["capability.v1"]
        f.check(cap, schema)
        for change in ({"extra": 1}, {"version": "latest"}, {"permissions": ["shell"]}, {"inputs": True}):
            with self.assertRaises(ValueError):
                f.check(dict(cap, **change), schema)

    def test_compatibility_fail_closed(self):
        row = self.reg["compatibility"][0]
        self.assertTrue(f.compatibility(self.reg, row["right"], row["right_version"], row["left"], row["left_version"])["compatible"])
        self.assertFalse(f.compatibility(self.reg, "core2", "unknown", "godot", "4.7.2")["compatible"])
        self.assertFalse(f.compatibility(self.reg, "asset-factory", "0.1.0", "blender", "5.3.0-candidate")["compatible"])
        self.assertFalse(f.compatibility(self.reg, row["left"], row["left_version"], row["right"], row["right_version"])["authorized"])

    def test_strict_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "input.json"
            for raw in ('{"a":1,"a":2}', '{"a":NaN}', ' ' * (f.LIMIT + 1)):
                path.write_text(raw)
                with self.assertRaises(ValueError):
                    f.read(path)

    def test_unsupported_schema(self):
        with self.assertRaises(ValueError):
            f.schema_check({"type": "string", "unsupported": True})

    def test_search(self):
        self.assertTrue(any(r["id"] == "REF-001" for r in f.search("REF-001")["matches"]))
        self.assertTrue(any(r["id"] == "IDEA-120" for r in f.search("IDEA-120")["matches"]))
        with self.assertRaises(ValueError):
            f.search(" ")

if __name__ == "__main__":
    unittest.main()
