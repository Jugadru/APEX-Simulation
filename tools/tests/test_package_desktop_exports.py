"""Offline contract tests for Linux/Windows ZIP export verification."""
from __future__ import annotations

from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from package_desktop_exports import PackageError, package, validate_target


class DesktopExportsTests(unittest.TestCase):
    def create_fixture(self, root: Path, platform: str) -> Path:
        name = ("APEX_Motorsport_Manager.x86_64" if platform == "linux"
                else "APEX_Motorsport_Manager.exe")
        directory = root / platform
        directory.mkdir(parents=True, exist_ok=True)
        binary = directory / name
        magic = b"\x7fELF" if platform == "linux" else b"MZ"
        binary.write_bytes(magic + b"\0" * 1_000_001)
        if platform == "linux":
            binary.chmod(0o755)
        (directory / "APEX_Motorsport_Manager.pck").write_bytes(b"GDPC" + b"x" * 10_010)
        return binary

    def test_validates_both_exports_and_packages(self):
        with TemporaryDirectory() as td:
            root = Path(td)
            self.create_fixture(root, "linux")
            self.create_fixture(root, "windows")
            output = root / "dist"
            info = package(root, output, "4.7.2-stable")
            self.assertEqual(info["status"], "PASS")
            self.assertEqual(len(info["platforms"]), 2)
            self.assertTrue((output / info["platforms"]["linux"]["archive"]).is_file())
            self.assertEqual(len(info["platforms"]["windows"]["files"]), 2)

    def test_missing_pck_is_failure(self):
        with TemporaryDirectory() as td:
            root = Path(td)
            binary = self.create_fixture(root, "linux")
            binary.with_suffix(".pck").unlink()
            with self.assertRaises(PackageError):
                validate_target(root / "linux", "linux")

    def test_wrong_binary_header_is_failure(self):
        with TemporaryDirectory() as td:
            root = Path(td)
            binary = self.create_fixture(root, "windows")
            binary.write_bytes(b"XX" + binary.read_bytes()[2:])
            with self.assertRaises(PackageError):
                validate_target(root / "windows", "windows")

    def test_unsafe_version_name_is_failure(self):
        with TemporaryDirectory() as td:
            root = Path(td)
            with self.assertRaises(PackageError):
                package(root, root / "dist", "../unsafe")


if __name__ == "__main__":
    unittest.main()
