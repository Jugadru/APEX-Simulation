import struct
import tempfile
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import apex_lab_graphics as graphics


def header(width, height):
    # Synthetic header/end data for metadata checks, not a rendered image.
    return (graphics.SIGNATURE + b"\x00\x00\x00\rIHDR" +
            struct.pack(">II", width, height) + b"\x08\x06\x00\x00\x00" +
            b"\x00" * 4 + b"\x00\x00\x00\x00IEND\xaeB\x60\x82")


class GraphicsTests(unittest.TestCase):
    def test_fresh_capture_inventory(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            out = root / "out"
            out.mkdir()
            for items in graphics.CAPTURES.values():
                for path, w, h in items:
                    p = root / path
                    p.parent.mkdir(parents=True, exist_ok=True)
                    p.write_bytes(header(w, h))
            graphics.prepare(root)
            for items in graphics.CAPTURES.values():
                for path, w, h in items:
                    p = root / path
                    self.assertFalse(p.exists())
                    p.write_bytes(header(w, h))
            r = graphics.collect(root, out)
            self.assertEqual(len(r["captures"]), 5)
            self.assertEqual(r["visual_review"], "NOT_RUN")

    def test_missing_wrong_and_truncated(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp).resolve() / "capture.png"
            with self.assertRaises(ValueError):
                graphics.inspect(p, 1280, 720)
            p.write_bytes(header(1600, 900))
            with self.assertRaises(ValueError):
                graphics.inspect(p, 1280, 720)
            p.write_bytes(header(1280, 720)[:-5])
            with self.assertRaises(ValueError):
                graphics.inspect(p, 1280, 720)

    def test_symlink_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            p = root / "source.png"
            p.write_bytes(header(1280, 720))
            link = root / "link.png"
            link.symlink_to(p)
            with self.assertRaises(ValueError):
                graphics.inspect(link, 1280, 720)


if __name__ == "__main__":
    unittest.main()
