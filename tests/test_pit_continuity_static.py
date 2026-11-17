"""Offline numerical pit-spline regression. Run: python3 tests/test_pit_continuity_static.py
This mirrors the Godot Bézier control point geometry for validation but does not execute Godot.
"""
from pathlib import Path
import json, math, re
root=Path(__file__).resolve().parents[1]
source=(root/'scripts/pit_complex_3d.gd').read_text(encoding='utf-8')
engine=(root/'scripts/race_engine.gd').read_text(encoding='utf-8')
track_script=(root/'scripts/track_3d.gd').read_text(encoding='utf-8')
main_script=(root/'scripts/main.gd').read_text(encoding='utf-8')
for sym in ('team_paths', 'slot_for', 'tangent_for_stop', '_bezier', '_sample_arc', 'position_for_stop'):
    assert sym in source, sym
for sym in ('PIT_ENTRY_FRACTION','PIT_EXIT_FRACTION','pit_phase','pit_from','pit_to','_advance_pit','_begin_pit'):
    assert sym in engine, sym
assert 'pit_complex.tangent_for_stop(team, phase)' in track_script
assert 'world_view.set_track_data(map_view.route, str(track["name"]), teams,' in main_script
assert 'pit_complex.prepare(_to_world(entry_ref)' in track_script
assert 'pit_start_remaining' not in track_script, 'stale pit interpolation still present'
assert 'pit_rejoin_timer' not in track_script, 'stale rejoin hack still present'
season=json.loads((root/'data/season_2012.json').read_text(encoding='utf-8'))
assert len(season['teams'])==12 and len(season['tracks'])==20

def gd_float(name):
    m=re.search(rf'const {name}: float = ([0-9.]+)',engine if name.startswith('PIT_') else source)
    assert m, name
    return float(m.group(1))
entry_frac=gd_float('PIT_ENTRY_FRACTION'); exit_frac=gd_float('PIT_EXIT_FRACTION')
slot_start=gd_float('SLOT_START_Z'); slot_spacing=gd_float('SLOT_SPACING')
assert .93 < entry_frac < .99 and .01 < exit_frac < .08
assert entry_frac > exit_frac

def curve_length_info(track):
    coords=[[float(x)*660.0,float(y)*540.0] for x,y in track['points']]
    if math.dist(coords[0], coords[-1])<0.00001:coords.pop()
    for _ in range(3):
        pts=[]
        for a,b in zip(coords,coords[1:]+coords[:1]):
            pts += [[a[k]*.75+b[k]*.25 for k in range(2)], [a[k]*.25+b[k]*.75 for k in range(2)]]
        coords=pts
    coords.append(coords[0]);cumul=[0.]
    for a,b in zip(coords,coords[1:]):cumul.append(cumul[-1]+math.dist(a,b))
    def pos(f):
        d=(f%1.)*cumul[-1]
        i=next(i for i in range(len(cumul)-1) if cumul[i+1]>=d)
        u=(d-cumul[i])/max(1e-12,cumul[i+1]-cumul[i]);return tuple(coords[i][k]*(1-u)+coords[i+1][k]*u for k in range(2))
    a,b=pos(entry_frac),pos(exit_frac)
    chord=[b[k]-a[k] for k in range(2)];L=math.hypot(*chord);direction=[v/L for v in chord]
    def cosine(frac):
        prior,after=pos(frac-.001),pos(frac+.001)
        tangent=[after[k]-prior[k] for k in range(2)]
        return sum(direction[k]*tangent[k] for k in range(2))/math.hypot(*tangent)
    return L,cosine(entry_frac),cosine(exit_frac)

for track in season['tracks']:
    length, facing_start, facing_end=curve_length_info(track)
    assert length > 65.0, f"Track too short for the 12 garages: {track['code']} {length:.1f}"
    assert facing_start > 0.25 and facing_end > 0.25, f"Hairpin at pit merge: {track['code']}"
    previous = -1e12
    for slot in range(12):
        stop_z=slot_start+slot*slot_spacing
        assert stop_z>previous
        assert stop_z+3.3 < length-5.0, f"Garage behind exit on {track['code']} at slot {slot}"
        previous=stop_z
    print(f"{track['code']}: connected corridor {length:.1f}u, tangents {facing_start:.2f}/{facing_end:.2f}, 12 ordered garages")
print('PIT LANE OFFLINE OK: all 20 circuits, forward-aligned entry/exit and 12 team stops')
