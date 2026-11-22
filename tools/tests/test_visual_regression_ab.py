"""Tests for real-image APEX 2D/3D visual A/B comparisons."""
from __future__ import annotations

import json
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest

from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from visual_regression_ab import (
    CAPTURES, CAPTURE_SCRIPT, LIMITS, THRESHOLD_PER_CHANNEL, VisualError, compare_one, load_manifest, validate_sources,
)


class VisualRegressionTests(unittest.TestCase):
    def create_pair(self, folder: Path, changed_rectangle=None, dimensions=(1600, 900)):
        folder.mkdir(parents=True, exist_ok=True)
        before = folder / "before.png"
        after = folder / "after.png"
        Image.new("RGB", dimensions, (20, 35, 55)).save(before)
        candidate = Image.new("RGB", dimensions, (20, 35, 55))
        if changed_rectangle is not None:
            ImageDraw.Draw(candidate).rectangle(changed_rectangle, fill=(250, 230, 10))
        candidate.save(after)
        return before, after

    def test_redesigned_hud_preserves_strict_visual_thresholds(self):
        # PR #84 intentionally changed the layout; its 2026-11-22 A/B FAIL is
        # retained for review. New PRs use the merged HUD as their baseline,
        # not higher tolerances that would conceal future regressions.
        self.assertEqual(THRESHOLD_PER_CHANNEL, 24)
        self.assertEqual(
            LIMITS,
            {
                "silverstone_2d_broadcast": (0.010, 1.50),
                "silverstone_2d_compact": (0.010, 1.50),
                "silverstone_3d_compact": (0.025, 3.00),
            },
        )

    def test_intentional_redesign_must_fail_against_old_visual_baseline(self):
        # A >5% HUD alteration must not be silently accepted merely because
        # a newer HUD design is intentional.
        with TemporaryDirectory() as td:
            folder = Path(td)
            before, after = self.create_pair(folder, (0, 0, 250, 350))
            result = compare_one(before, after, folder / "diff.png", CAPTURES[0])
            self.assertEqual(result["status"], "FAIL")
            self.assertGreater(result["changed_fraction"], 0.05)
            self.assertEqual(result["allowed_changed_fraction"], 0.010)

    def test_identical_images_pass(self):
        with TemporaryDirectory() as td:
            folder = Path(td)
            before, after = self.create_pair(folder)
            result = compare_one(before, after, folder / "diff.png", CAPTURES[0])
            self.assertEqual(result["status"], "PASS")
            self.assertEqual(result["changed_pixels"], 0)
            self.assertTrue((folder / "diff.png").exists())

    def test_large_hud_regression_fails(self):
        with TemporaryDirectory() as td:
            folder = Path(td)
            before, after = self.create_pair(folder, (10, 10, 750, 600))
            result = compare_one(before, after, folder / "diff.png", CAPTURES[1])
            self.assertEqual(result["status"], "FAIL")
            self.assertGreater(result["changed_fraction"], 0.1)

    def test_small_change_below_tolerance_is_reported(self):
        with TemporaryDirectory() as td:
            folder = Path(td)
            before, after = self.create_pair(folder, (10, 10, 20, 20))
            result = compare_one(before, after, folder / "diff.png", CAPTURES[2])
            self.assertEqual(result["status"], "PASS")
            self.assertGreater(result["changed_pixels"], 0)

    def test_dimension_drift_is_rejected(self):
        with TemporaryDirectory() as td:
            folder = Path(td)
            before, after = self.create_pair(folder, dimensions=(1599, 900))
            Image.new("RGB", (1600, 900)).save(after)
            with self.assertRaises(VisualError):
                compare_one(before, after, folder / "diff.png", CAPTURES[0])

    def test_fixture_drift_is_rejected(self):
        with TemporaryDirectory() as td:
            root = Path(td)
            base = root / "base" / CAPTURE_SCRIPT
            candidate = root / "candidate" / CAPTURE_SCRIPT
            base.parent.mkdir(parents=True)
            candidate.parent.mkdir(parents=True)
            base.write_text("extends SceneTree\n", encoding="utf-8")
            candidate.write_text("extends Node\n", encoding="utf-8")
            with self.assertRaisesRegex(VisualError, "INCOMPARABLE"):
                validate_sources(root / "base", root / "candidate")
            candidate.write_bytes(base.read_bytes())
            self.assertIsInstance(validate_sources(root / "base", root / "candidate"), str)

    def test_manifest_failure_is_not_a_valid_comparison(self):
        with TemporaryDirectory() as td:
            folder = Path(td)
            (folder / "manifest.json").write_text(
                json.dumps({"status": "FAIL", "captures": []}), encoding="utf-8"
            )
            with self.assertRaises(VisualError):
                load_manifest(folder)


if __name__ == "__main__":
    unittest.main()
