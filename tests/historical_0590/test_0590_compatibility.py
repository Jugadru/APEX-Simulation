#!/usr/bin/env python3
"""Positive and negative controls of portable version/garage/physics contracts."""
from pathlib import Path
from shutil import copyfile
from tempfile import TemporaryDirectory
from apex_contracts import (check_build_version, check_legacy_garage_contract,
                            check_0580_mechanics)
root = Path(__file__).resolve().parents[1]
check_build_version(root, '0.5.9.0')
check_legacy_garage_contract(root)
check_0580_mechanics(root)

# A newer requirement must be rejected, rather than an always-true check.
try:
    check_build_version(root, '0.6.0')
except AssertionError:
    pass
else:
    raise AssertionError('Version guard accepted a future-only release')

# Deliberately corrupt a COPIED legacy purchase method; no game file is changed.
with TemporaryDirectory() as d:
    mock = Path(d)
    (mock / 'scripts').mkdir()
    target = mock / 'scripts/garage.gd'
    original = (root / 'scripts/garage.gd').read_text()
    target.write_text(original.replace('return "Nível máximo atingido."',
                                       'return "NOT A VALID GARAGE CONTRACT."', 1))
    try:
        check_legacy_garage_contract(mock)
    except AssertionError:
        pass
    else:
        raise AssertionError('Legacy garage check missed a changed legacy method')

# Deliberately corrupt a COPIED unchanged core, using the original for other files.
with TemporaryDirectory() as d:
    mock = Path(d)
    for rel in (
        'scripts/core/race_kers_2012.gd', 'scripts/core/race_drs_2012.gd',
        'scripts/core/race_performance.gd', 'scripts/core/race_wet_physics.gd',
        'scripts/core/race_pit_lane.gd', 'scripts/core/race_pit_math.gd',
        'scripts/core/race_combat.gd', 'data/tyres_2012.json',
        'scripts/pit_complex_3d.gd', 'scripts/track_3d.gd',
        'scripts/apex_telemetry.gd',
    ):
        f = mock / rel
        f.parent.mkdir(parents=True, exist_ok=True)
        copyfile(root / rel, f)
    with (mock / 'scripts/core/race_kers_2012.gd').open('ab') as f:
        f.write(b'\n# deliberately broken fingerprint')
    try:
        check_0580_mechanics(mock)
    except AssertionError:
        pass
    else:
        raise AssertionError('Physics checks missed the deliberate modification')

print('PASS: portable version gates, old saves, preserved physics and negative controls')
