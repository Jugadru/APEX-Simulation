from pathlib import Path
import hashlib, json
ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT/'tests/0629_preserved_hashes.json').read_text())
for name, original in manifest.items():
    actual = hashlib.sha256((ROOT/name).read_bytes()).hexdigest()
    assert actual == original, f'Arquivo protegido alterado: {name}'
print(f'APEX 0.6.2.9: {len(manifest)} hashes preservados OK')
