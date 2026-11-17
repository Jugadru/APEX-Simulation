#!/usr/bin/env python3
"""Run all portable Apex Python regression scripts; report failures accurately."""
from pathlib import Path
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
suite = sorted((root / 'tests').glob('test_*.py'))
failed = []
for test in suite:
    result = subprocess.run([sys.executable, str(test)], cwd=root,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            text=True, timeout=90, check=False)
    output = result.stdout.strip().replace('\n', ' | ')
    print(('PASS' if result.returncode == 0 else 'FAIL') +
          f'  {test.name}: {output[-250:]}', flush=True)
    if result.returncode != 0:
        failed.append(test.name)
print(f'RESULTADO: {len(suite)-len(failed)}/{len(suite)} scripts Python OK')
if failed:
    print('FALHAS:', ', '.join(failed))
    sys.exit(1)
