import unittest
from pathlib import Path
from batch_candidate import patch_space, patch_macro, replace_once, blob, VEHICLE_PIN, SPACE_PIN

class BatchSourceTests(unittest.TestCase):
    def test_real_pinned_source(self):
        import subprocess
        repo=Path(__file__).resolve().parents[2]
        base="524bd90a19aeaafe6920b4cdb774c77729d78fbd"
        v=subprocess.check_output(["git","show",base+":scripts/core/race_vehicle_dynamics_072.gd"],cwd=repo)
        s=subprocess.check_output(["git","show",base+":scripts/core/race_space_0655.gd"],cwd=repo)
        self.assertEqual(blob(v),VEHICLE_PIN)
        self.assertEqual(blob(s),SPACE_PIN)
        result=patch_space(s.decode("utf-8"))
        self.assertEqual(result.count("Vehicle072.propose_batch("),1)
        self.assertNotIn("physical=Vehicle072.propose(",result)
        self.assertLess(result.index("Vehicle072.propose_batch("),result.index("# Before entering a single corridor"))
        self.assertIn("Longitudinal069.propose(c,curve",result)
        macro=(repo/"experiments/native_core_0723/macro.gd.in").read_text(encoding="utf-8")
        patched=patch_macro(macro)
        self.assertIn("V.batch_reset()",patched)
        self.assertIn("legacy revision called batch",patched)
        self.assertIn('"batch_stats":batch',patched)
        template=(Path(__file__).parent/"vehicle_batch.gd.in").read_text(encoding="utf-8")
        self.assertEqual(template.count('_batch_backend.call("phase_batch"'),2)
        self.assertNotIn("_batch_backend.call(\"phase\"",template)
        self.assertNotIn("rng.",template)

    def test_anchors_fail_closed(self):
        for text in ("missing","anchor anchor"):
            with self.assertRaises(RuntimeError):
                replace_once(text,"anchor","replacement")
