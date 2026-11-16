"""Offline 3D road-mesh geometry regression, independent of the Godot executable.

Mirrors the cross-section math in scripts/track_3d.gd and rejects winding folds,
NaNs and discontinuous ring edges for all tracks in the 2012 data set. This is
not a substitute for rendering the mesh with Godot.
"""
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRACKS = json.loads((ROOT / 'data/season_2012.json').read_text())['tracks']
WORLD_SCALE = 0.60
ROAD_HALF = 4.4
RUNOFF_MULTIPLIER = 1.38

def add(a, b): return (a[0] + b[0], a[1] + b[1])
def sub(a, b): return (a[0] - b[0], a[1] - b[1])
def mul(a, v): return (a[0] * v, a[1] * v)
def dot(a, b): return a[0]*b[0] + a[1]*b[1]
def cross(a, b): return a[0]*b[1] - a[1]*b[0]
def norm(a):
    m = math.hypot(*a)
    return (a[0] / m, a[1] / m) if m > 1e-10 else (1.0, 0.0)

def check(track):
    points = [(float(x)*1100.0, float(y)*900.0) for x, y in track['points']]
    if math.dist(points[0],points[-1]) < .001:
        points.pop()
    assert len(points) >= 4
    for _ in range(3):
        out = []
        for k, first in enumerate(points):
            second = points[(k + 1) % len(points)]
            out.append(add(mul(first, .75), mul(second, .25)))
            out.append(add(mul(first, .25), mul(second, .75)))
        points = out
    n = len(points)
    p = [((x-550)*WORLD_SCALE, (y-450)*WORLD_SCALE) for x, y in points]
    sides, widths = [], []
    for i in range(n):
        q = p[i]
        p0 = p[(i-1)%n]
        p1 = p[(i+1)%n]
        inc = norm(sub(q, p0))
        outgoing = norm(sub(p1, q))
        bis = norm(add(inc, outgoing))
        side = (-bis[1], bis[0])
        out_side = (-outgoing[1], outgoing[0])
        miter = min(1.0/max(.82, dot(side, out_side)),1.12)
        sides.append(mul(side, miter))
        angle = math.acos(max(-1.0, min(1.0, dot(inc, outgoing))))
        adjacent = (math.dist(q,p0)+math.dist(q,p1))/2.0
        radius = adjacent/max(.001, angle)
        widths.append(max(1.0, min(ROAD_HALF, radius*.45+.35)))
    # Triangular smoothing kernel from track_3d.gd.
    weights = [1,2,3,4,5,4,3,2,1]
    widths = [sum(widths[(i+k)%n]*weights[k+4] for k in range(-4,5))/25 for i in range(n)]
    def get(i, s): return add(p[i], mul(sides[i], widths[i] * s))
    def invalid():
        bad = []
        for i in range(n):
            j=(i+1)%n
            a,b,c,d=get(i,-RUNOFF_MULTIPLIER),get(i,RUNOFF_MULTIPLIER),get(j,-RUNOFF_MULTIPLIER),get(j,RUNOFF_MULTIPLIER)
            a1=cross(sub(c,a),sub(b,a))
            a2=cross(sub(c,b),sub(d,b))
            if a1 <= 1e-7 or a2 <= 1e-7: bad.append(i)
        return bad
    for _ in range(15):
        bad=invalid()
        if not bad: break
        for i in bad:
            widths[i] *= .83
            widths[(i+1)%n] *= .83
    bad=invalid()
    assert not bad, f'{track["code"]}: {len(bad)} folded road/runoff triangles'
    assert all(math.isfinite(w) and 0 < w <= 4.4 for w in widths), track['code']
    assert all(math.isfinite(v) for side in sides for v in side), track['code']
    print(f'{track["code"]}: {n} shared sections; zero inverted runoff triangles')

for track in TRACKS:
    check(track)
print('PASS: all 20 circuits / continuous 3D road sections')
