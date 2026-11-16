"""Offline tests of licensed geometry, official pace anchors and table hotfix."""
from pathlib import Path
import json, math

ROOT=Path(__file__).resolve().parents[1]
season=json.loads((ROOT/'data/season_2012.json').read_text(encoding='utf-8'))
tracks=season['tracks']
assert len(tracks)==20
expected_codes={"AUS","MAL","CHN","BHR","ESP","MON","CAN","EUR","GBR","GER","HUN","BEL","ITA","SIN","JPN","KOR","IND","UAE","USA","BRA"}
assert {t['code'] for t in tracks}==expected_codes
licensed=0
for track in tracks:
    pts=track['points']
    assert len(pts)>=20,(track['code'],len(pts))
    assert pts[0]==pts[-1],track['code']
    assert all(len(x)==2 and all(math.isfinite(v) for v in x) for x in pts),track['code']
    assert all(0<=v<=1.02 for p in pts for v in p), track['code']
    assert 70<=track['base_lap']<=120,track['code']
    fastest=track['fastest_lap_2012'].split(':')
    fl_sec=int(fastest[0])*60+float(fastest[1])
    assert abs(track['base_lap']-fl_sec-0.5)<0.00001,track['code']
    if track['geometry_quality']=='licensed_geojson_reference':
        assert len(pts)==97
        assert track['geometry_source_id']
        licensed+=1
    else:
        assert track['code'] in {'EUR','KOR','IND'}
assert licensed==17,licensed
for must in ['data/LICENSE-f1-circuits-MIT.txt','data/geometry_credits.txt']:
    assert (ROOT/must).is_file()
main=(ROOT/'scripts/main.gd').read_text(encoding='utf-8')
assert 'var table_mode_label: Label' in main
assert 'is_instance_valid(table_mode_label)' in main
track=(ROOT/'scripts/track_map.gd').read_text(encoding='utf-8')
assert 'Closed Chaikin corner cutting' in track
assert 'func point_on_track' in track
print('PASS: 20 GPs, 17 licensed outlines, 3 marked schematic, all official pace anchors, table fix kept.')
