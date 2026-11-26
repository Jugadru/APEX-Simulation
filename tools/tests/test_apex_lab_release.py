from pathlib import Path
import struct
import sys
import tarfile
import tempfile
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from apex_lab_release import inspect_file, verify_archive

class ReleaseTests(unittest.TestCase):
    def test_elf_pck_and_archive(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            elf, pck = root / "test.x86_64", root / "test.pck"
            header = bytearray(64)
            header[:6] = b"\x7fELF\x02\x01"
            struct.pack_into("<H", header, 18, 62)
            elf.write_bytes(header)
            elf.chmod(0o755)
            pck.write_bytes(b"GDPC" + b"\0"*60)
            rows = [inspect_file(elf, "ELF"), inspect_file(pck, "PCK")]
            tar = root / "test.tar.gz"
            with tarfile.open(tar, "w:gz") as archive:
                for p in (elf, pck):
                    archive.add(p, arcname=p.name)
            verify_archive(tar, {r["file"]: r for r in rows})
            rows[0]["sha256"] = "0"*64
            with self.assertRaises(ValueError):
                verify_archive(tar, {r["file"]: r for r in rows})

    def test_reject_invalid_executable_and_pack(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp).resolve() / "bad"
            p.write_bytes(b"x"*64)
            for kind in ("ELF", "PCK"):
                with self.assertRaises(ValueError):
                    inspect_file(p, kind)

if __name__ == "__main__":
    unittest.main()
