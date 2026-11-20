"""Importer security regressions; all imports run in disposable worktrees."""
from contextlib import redirect_stdout
import hashlib
import importlib.util
import io
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

SCRIPT = Path(__file__).resolve().parents[2] / '.github/scripts/import_apex_archive.py'
spec = importlib.util.spec_from_file_location('apex_importer', SCRIPT)
importer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(importer)


class ImportArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.repo = self.base / 'repo'
        self.runner = self.base / 'runner'
        self.repo.mkdir()
        self.runner.mkdir()
        self.entries = [('game/project.godot', b'config_version=5\n'),
                        ('game/scripts/main.gd', b'extends Node\n'),
                        ('game/scenes/main.tscn', b'[gd_scene format=3]\n')]
        self.output = io.StringIO()

    def package(self, entries=None, raw=None):
        if raw is None:
            buffer = io.BytesIO()
            with zipfile.ZipFile(buffer, 'w') as archive:
                for name, data in self.entries if entries is None else entries:
                    archive.writestr(name, data)
            raw = buffer.getvalue()
        size = (len(raw) + importer.EXPECTED_PARTS - 1) // importer.EXPECTED_PARTS
        for i in range(importer.EXPECTED_PARTS):
            (self.repo / f'{importer.PART_BASENAME}{i:03d}').write_bytes(raw[i*size:(i+1)*size])
        return raw

    def run_import(self, runner=True):
        env = {'RUNNER_TEMP': str(self.runner)} if runner else {}
        with patch.dict(os.environ, env, clear=True), patch.object(Path, 'cwd', return_value=self.repo), redirect_stdout(self.output):
            importer.main()

    def blocked(self):
        with self.assertRaises(SystemExit) as exc:
            self.run_import()
        self.assertEqual(exc.exception.code, 1)
        self.assertEqual(list(self.runner.iterdir()), [])

    def test_success_cli_digest_and_cleanup(self):
        raw = self.package()
        result = subprocess.run([sys.executable, str(SCRIPT)], cwd=self.repo,
                                env={**os.environ, 'RUNNER_TEMP': str(self.runner),
                                     'GITHUB_STEP_SUMMARY': str(self.base / 'summary.md')},
                                capture_output=True, text=True, timeout=20)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(hashlib.sha256(raw).hexdigest(), result.stdout)
        self.assertEqual((self.repo / 'scripts/main.gd').read_bytes(), self.entries[1][1])
        self.assertEqual(list(self.runner.iterdir()), [])
        self.assertEqual(len(list(self.repo.glob('*.part*'))), 5)

    def test_private_unique_directories_respect_runner_temp(self):
        self.package()
        observed = []
        def inspect(repo, parts, combined):
            observed.append(combined.parent)
            self.assertEqual(combined.parent.parent, self.runner)
            self.assertEqual(stat.S_IMODE(combined.parent.stat().st_mode), 0o700)
        with patch.object(importer, 'import_archive', side_effect=inspect):
            self.run_import()
            self.run_import()
        self.assertNotEqual(*observed)
        self.assertTrue(all(not path.exists() for path in observed))

    def test_system_temp_fallback(self):
        self.package()
        with patch.object(tempfile, 'tempdir', str(self.runner)):
            self.run_import(runner=False)
        self.assertTrue((self.repo / 'project.godot').is_file())
        self.assertEqual(list(self.runner.iterdir()), [])

    def test_fixed_name_symlink_is_untouched(self):
        self.package()
        victim = self.base / 'victim'
        victim.write_bytes(b'keep')
        link = self.runner / 'apex_v0.6.6.8_combined.zip'
        link.symlink_to(victim)
        self.run_import()
        self.assertEqual(victim.read_bytes(), b'keep')
        self.assertEqual(list(self.runner.iterdir()), [link])

    def test_cleanup_on_unexpected_exception(self):
        self.package()
        with patch.object(importer, 'import_archive', side_effect=ValueError('injected')):
            with self.assertRaises(ValueError):
                self.run_import()
        self.assertEqual(list(self.runner.iterdir()), [])

    def test_missing_part(self):
        self.package()
        (self.repo / f'{importer.PART_BASENAME}004').unlink()
        self.blocked()

    def test_invalid_zip(self):
        self.package(raw=b'not a zip')
        self.blocked()

    def test_invalid_runner_temp_fails_closed(self):
        self.package()
        self.runner.rmdir()
        self.runner.write_text('not a directory')
        with self.assertRaises(SystemExit):
            self.run_import()
        self.assertFalse((self.repo / 'project.godot').exists())

    def test_traversal_and_absolute_names(self):
        for name in ('../escape', '/escape', 'game/../../escape', 'game\\escape'):
            with self.subTest(name=name):
                self.package(self.entries + [(name, b'bad')])
                self.blocked()
                self.assertFalse((self.repo / 'project.godot').exists())

    def test_zip_symlink(self):
        info = zipfile.ZipInfo('game/link')
        info.create_system = 3
        info.external_attr = (stat.S_IFLNK | 0o777) << 16
        self.package(self.entries + [(info, b'../outside')])
        self.blocked()

    def test_destination_symlinks_inside_outside_and_dangling(self):
        self.package()
        for target in (self.base / 'outside', self.repo / 'inside', self.base):
            with self.subTest(target=target):
                link = self.repo / 'scripts'
                link.symlink_to(target, target_is_directory=True)
                self.blocked()
                link.unlink()
                self.assertFalse((self.repo / 'project.godot').exists())

    def test_existing_and_protected_files_preserved(self):
        entries = self.entries + [(f'game/{name}', b'overwrite') for name in
                                 ('README.md', '.gitignore', '.github/workflows/evil.yml',
                                  '.git/config', '.godot/cache', 'nested/.git/config')]
        self.package(entries)
        (self.repo / 'README.md').write_bytes(b'original')
        (self.repo / 'scripts').mkdir()
        (self.repo / 'scripts/main.gd').write_bytes(b'original')
        # Still requires at least one new script, as in the original importer.
        self.package(entries + [('game/scripts/new.gd', b'extends Node')])
        self.run_import()
        self.assertEqual((self.repo / 'README.md').read_bytes(), b'original')
        self.assertEqual((self.repo / 'scripts/main.gd').read_bytes(), b'original')
        self.assertFalse((self.repo / '.github').exists())
        self.assertFalse((self.repo / 'nested').exists())

    def test_no_overwrite_if_file_appears_after_planning(self):
        self.package()
        original = importer.validate_destination
        count = 0
        def race(repo, dest):
            nonlocal count
            original(repo, dest)
            count += 1
            if count == 4:  # First extraction after all three planning checks.
                dest.write_bytes(b'concurrent file')
        with patch.object(importer, 'validate_destination', side_effect=race):
            self.blocked()
        self.assertEqual((self.repo / 'project.godot').read_bytes(), b'concurrent file')

    def test_normalized_duplicate(self):
        self.package(self.entries + [('game/scripts/./main.gd', b'duplicate')])
        self.blocked()

    def test_entry_and_size_limits(self):
        self.package()
        for setting in ('MAX_ENTRIES', 'MAX_UNPACKED_BYTES', 'MAX_GIT_FILE_BYTES'):
            with self.subTest(setting=setting), patch.object(importer, setting, 1):
                self.blocked()
                self.assertFalse((self.repo / 'project.godot').exists())

    def test_project_validation(self):
        for entries in (self.entries[1:], self.entries[:2],
                        self.entries + [('another/project.godot', b'other')]):
            with self.subTest(entries=entries):
                self.package(entries)
                self.blocked()

    def test_crc_failure_cleans_temp(self):
        raw = self.package()
        raw = raw.replace(b'extends Node\n', b'extends Xode\n', 1)
        self.package(raw=raw)
        self.blocked()
        self.assertIn('CRC', self.output.getvalue())


if __name__ == '__main__':
    unittest.main()
