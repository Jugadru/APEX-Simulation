import tempfile
import unittest
from pathlib import Path
import struct
import subprocess
from benchmark import validate_oracles, validate_checksums, COUNT, MODES, materialize_git_blobs, blob_id


class TestBinaryTransport(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path=Path(self.tmp.name)
        self.data=struct.pack("<d",-0.0)*(4108*8)

    def test_oracle_exact(self):
        validate_oracles(self.data,self.data,self.path)

    def test_one_bit_and_signed_zero(self):
        for replacement in (struct.pack("<d",0.0), bytes([1])+self.data[1:8]):
            with self.assertRaises(RuntimeError):
                validate_oracles(self.data,replacement+self.data[8:],self.path)
            self.assertTrue((self.path/"micro-first-divergence.json").is_file())

    def test_truncated(self):
        with self.assertRaises(RuntimeError):
            validate_oracles(self.data,self.data[:-1],self.path)

    def test_checksum(self):
        rows=[{"mode":m,"rep":rep,"phases":COUNT,"elapsed_us":1.0,
               "checksum_bits":struct.pack("<d",123.456).hex(),"checksum_finite":True}
              for m in MODES for rep in range(10)]
        validate_checksums(rows,self.path)
        with self.assertRaises(RuntimeError):
            validate_checksums(rows[:-1],self.path)
        rows[-1]["checksum_bits"]=struct.pack("<d",123.457).hex()
        with self.assertRaises(RuntimeError):
            validate_checksums(rows,self.path)
        self.assertTrue((self.path/"micro-checksum-mismatch.json").is_file())



class TestExactGitBaseline(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root=Path(self.tmp.name)
        self.repo=self.root/"repo"
        self.repo.mkdir()
        self.git("init","-q")
        self.git("config","user.name","APEX Test")
        self.git("config","user.email","apex-test@example.invalid")
        self.git("config","core.autocrlf","true")
        self.canonical=b"line one\nline two\n"
        self.binary=b"\x00\xff\r\n\x80"
        for rel,data in (("phase.gd",self.canonical),("fixture.bin",self.binary)):
            oid=self.git("hash-object","-w","--stdin",data=data).strip().decode()
            self.git("update-index","--add","--cacheinfo",f"100644,{oid},{rel}")
        self.git("commit","-q","-m","fixture")
        # Deliberately put CRLF and unrelated bytes in the worktree.
        (self.repo/"phase.gd").write_bytes(self.canonical.replace(b"\n",b"\r\n"))
        (self.repo/"fixture.bin").write_bytes(b"wrong worktree")

    def git(self,*args,data=None):
        return subprocess.run(["git",*args],cwd=self.repo,input=data,stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True).stdout

    def test_exact_bytes_even_with_autocrlf(self):
        dest=self.root/"out"
        manifest=materialize_git_blobs(self.repo,"HEAD",dest,("phase.gd","fixture.bin"),{"phase.gd":blob_id(self.canonical)})
        self.assertEqual((dest/"phase.gd").read_bytes(),self.canonical)
        self.assertEqual((dest/"fixture.bin").read_bytes(),self.binary)
        self.assertEqual(manifest["phase.gd"]["blob"],blob_id(self.canonical))

    def test_wrong_pin_rejected(self):
        with self.assertRaisesRegex(RuntimeError,"pinned baseline mismatch"):
            materialize_git_blobs(self.repo,"HEAD",self.root/"bad",("phase.gd",),{"phase.gd":"0"*40})

    def test_existing_destination_rejected(self):
        dest=self.root/"existing"
        dest.mkdir()
        with self.assertRaisesRegex(RuntimeError,"must not exist"):
            materialize_git_blobs(self.repo,"HEAD",dest,("phase.gd",))


if __name__ == "__main__":
    unittest.main()
