"""Regression contracts that remain meaningful across Apex releases.

Unlike historical fixed labels or a developer's absolute /mnt/data path, these
checks are portable with the ZIP and still reject missing game systems or altered
physics. Fingerprints were recorded from Apex_0580_Completo(2).zip.
"""
from pathlib import Path
from hashlib import sha256
import re


def version_tuple(value: str) -> tuple[int, ...]:
    parts = tuple(int(n) for n in value.split('.'))
    return parts + (0,) * max(0, 4 - len(parts))


def check_build_version(root: Path, minimum: str) -> None:
    main = (root / 'scripts/main.gd').read_text(encoding='utf-8')
    project = (root / 'project.godot').read_text(encoding='utf-8')
    m = re.search(r'Godot (\d+(?:\.\d+){2,4})', main)
    p = re.search(r'config/name="[^"\n]*?v(\d+(?:\.\d+){2,4})', project)
    assert m is not None, 'Main script lacks project-version label'
    assert p is not None, 'Godot project lacks version label'
    a, b = version_tuple(m.group(1)), version_tuple(p.group(1))
    floor = version_tuple(minimum)
    assert a >= floor, (a, floor)
    assert b >= floor, (b, floor)
    assert a == b, f'Conflicting versions: main={a}, project={b}'


# Existing methods of the 0.5.8.0 workshop remained byte-identical in 0.5.9.0.
# Changes to get_team/_load_data are checked separately for safe save migration.
LEGACY_GARAGE_METHODS = {
    'next_cost': '5921e4ce765dedb5f07f02fcab668d5e3bb44261293fa983b37e8bb92f294452',
    'buy': '1f9f9efd57bfc49f2b938eae0b647ab26e595faf26a325bac2f58339df9ac6b8',
    'crew_next_cost': '6f1794dde76ce6d509f02311f755c0247247ebb9a5f091271a4d0e7d3f8ab55b',
    'buy_crew': 'a3eec7047ee507a736ba836a13a6880fe2622d9fbc203fc1a099c1c71a8c8e77',
    'save': '8d5231b33be6e3d1d9a9ee0748bcb8930f91d3ef5bb30c7cb801f96411cf7e17',
    '_find_previous_godot_save': '4b51db2676f9eca7491d08e197bcdb37d3def914298ce7c909458c54db37386b',
}


def check_legacy_garage_contract(root: Path) -> None:
    garage = (root / 'scripts/garage.gd').read_text(encoding='utf-8')
    for method, expected in LEGACY_GARAGE_METHODS.items():
        m = re.search(r'^func ' + re.escape(method) + r'\(.*?(?=^func |\Z)', garage, re.M | re.S)
        assert m is not None, f'Missing preserved garage function {method}'
        body = m.group(0).rstrip() + '\n'
        assert sha256(body.encode('utf-8')).hexdigest() == expected, f'Old garage function changed: {method}'
    for token in (
        '"budget": INITIAL_BUDGET',
        '"levels": {"Motor": 0, "Asa": 0, "Chassi": 0}',
        '"crew_levels": {"Agilidade": 0, "Precisão": 0, "Coordenação": 0}',
        '"staff_levels": {"Estrategista": 0, "Engenheiro": 0}',
        'func staff_next_cost(team_name: String, role: String) -> int:',
        'func hire_staff(team_name: String, role: String) -> String:',
        'state["budget"] = int(state["budget"]) - cost',
        '"levels": cleaned,', '"crew_levels": cleaned_crew,', '"staff_levels": cleaned_staff',
        'cleaned_staff[role] = clampi(int(raw_staff.get(role, 0)), 0, MAX_LEVEL)',
        'if not state.has("staff_levels")',
        'if not FileAccess.file_exists(SAVE_PATH):',
    ):
        assert token in garage, f'Missing old-data/staff migration guarantee: {token}'


# Immutable modules from the actual 0.5.8.0 user ZIP (not an external path).
RACE_0580_FINGERPRINTS = {
    'scripts/core/race_kers_2012.gd': 'd983fc5c788cfa7671b6fdb4de2094c7cf1b66e487826a8b0d4042972ec5fa2b',
    'scripts/core/race_drs_2012.gd': 'a00e4a6bf132543f1c6b2ffad340141c85e9fa809cb8e9d8bd34d80bdd3b1f59',
    'scripts/core/race_performance.gd': '5e948faea13a0bc6f550aa1f5f74b8382a21923f0f0dee5156f60a24a7087ada',
    'scripts/core/race_wet_physics.gd': 'b0d334bc15e506734c654b065915acc17d4eaff7b23885ca63f66871e4a7ecbf',
    'scripts/core/race_pit_lane.gd': '13526f7863021755534c1fc5f6831359fe5bd8634e156752210b4d316488a487',
    'scripts/core/race_pit_math.gd': '645c7a4bdf58d3a441d7fe09531dd794a411320ee3081c8ecc1fafbceba63268',
    'scripts/core/race_combat.gd': '6ae05386a338144a98fb800a7c3aa5093311d3180f1aae110a15390287e0fd55',
    'data/tyres_2012.json': '4de4eda11de68126b96f518160f779da68f969aa0b47b8c659fd1bd4d9abfd38',
    'scripts/pit_complex_3d.gd': 'c35eabd4fbb08fdbea95b5584a8b0f31bade7d1c5f41bdf15b7689b0d72b3587',
    'scripts/track_3d.gd': 'a90bcddab446cfa8b1ae745c569d3c26b9a9d9d51596e608d98924c34caf77fd',
    'scripts/apex_telemetry.gd': 'ec49ff667602b57087afcc1bbe3f07fee0ebebd7166acb11b414616d926894f6',
}


def check_0580_mechanics(root: Path) -> None:
    for rel, expected in RACE_0580_FINGERPRINTS.items():
        f = root / rel
        assert f.is_file(), f'Missing verified core module {rel}'
        assert sha256(f.read_bytes()).hexdigest() == expected, f'Core 0.5.8.0 changed: {rel}'
