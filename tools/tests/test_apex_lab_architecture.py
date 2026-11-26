from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_lab_architecture as arch

class ArchitectureTests(unittest.TestCase):
    def test_literals_not_comments_or_strings(self):
        src = '''extends "res://scripts/base.gd"
# preload("res://scripts/comment.gd")
const A = preload("res://scripts/a.gd")
const B = "preload(\\"res://scripts/string.gd\\")"
const C = """preload("res://scripts/triple.gd")"""
func run():
    var a = load("res://scripts/runtime.gd")
    obj.preload("res://scripts/member.gd")
    var b = preload("res://scripts/../outside.gd")
'''
        self.assertEqual(arch.literal_edges(src), ["scripts/a.gd", "scripts/base.gd"])

    def test_scc_and_self_edge(self):
        graph = {"a": ["b"], "b": ["a", "c"], "c": [], "d": ["d"]}
        self.assertEqual(arch.cycle_components(graph), [["a", "b"], ["d"]])

    def test_long_chain_no_recursion(self):
        graph = {str(i): [str(i+1)] if i < 2000 else [] for i in range(2001)}
        self.assertEqual(arch.cycle_components(graph), [])

    def test_scan(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "scripts").mkdir()
            (root / "scripts/a.gd").write_text('extends "res://scripts/b.gd"\n')
            (root / "scripts/b.gd").write_text('const A = preload("res://scripts/a.gd")\nconst X = preload("res://other/x.gd")\n')
            r = arch.scan(root, ["scripts/a.gd", "scripts/b.gd", "tests/no.gd"])
            self.assertTrue(r["complete"])
            self.assertEqual(r["edge_count"], 2)
            self.assertEqual(r["cyclic_components"], [["scripts/a.gd", "scripts/b.gd"]])
            self.assertEqual(r["external_literal_targets"], [{"source":"scripts/b.gd","target":"other/x.gd"}])
            self.assertFalse(arch.scan(root, ["scripts/absent.gd"])["complete"])

    def test_function_span(self):
        src = "func long_one():\n" + "    pass\n" * 81 + "func short_one():\n    pass\n"
        self.assertEqual(arch.long_functions(src), [{"function":"long_one","line":1,"physical_span":82}])

    def test_real_coverage(self):
        root = Path(__file__).resolve().parents[2]
        self.assertGreater(arch.coverage(root)["registered_fixture_count"], 0)

if __name__ == "__main__":
    unittest.main()
