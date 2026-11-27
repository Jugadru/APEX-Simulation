import tempfile
import unittest
from pathlib import Path
import struct
from benchmark import validate_oracles, validate_checksums, COUNT, MODES


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


if __name__ == "__main__":
    unittest.main()
