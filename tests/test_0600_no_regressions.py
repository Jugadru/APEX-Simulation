"""Checks that all Godot physics and approved 2D/3D modules remain byte-identical to 0.5.8.0."""
from pathlib import Path
from hashlib import sha256
r=Path(__file__).resolve().parents[1]
reference={
 'scripts/race_engine.gd':'e0e63a1f1e700a381ded2548050c9e2391037bc2571779e56ec464b32636c708',
 'scripts/track_map.gd':'11a4cf845cf9f077be022b537a4c9b94ad2afa41e4f6043c035238d39cf56410',
 'scripts/track_3d.gd':'a90bcddab446cfa8b1ae745c569d3c26b9a9d9d51596e608d98924c34caf77fd',
 'scripts/tv_director.gd':'6fb42841214235ec0b1458558803edb3afb43be0e1ab2536daeb67ee756ae7ce',
 'data/season_2012.json':'a03843f9ac2b818bdb98a3d3417e42f40d792064b48df4334bf008e2828f94eb',
 'scripts/core/race_team_autonomy.gd':'1f522df4960b845f96052d41ffdb44456240f235e8e2048295eab33a0805fba8',
}
for file,signature in reference.items():
 assert sha256((r/file).read_bytes()).hexdigest()==signature,file
print('PASS 0600: engine, Team Auto, tracks and Director TV unchanged')
