# Performance Recovery Consolidated REV2

Candidate only; no release, sporting-rule revision, or game merge. REV1 PR #142, commit 947c400bd3174558768a228baed80d183ca7e588 and A/B 45728257802/1 remain immutable evidence: all nine short timing pairs favored REV1, overall performance PASS, leader improvement, inclusive finalization INCONCLUSIVE. No change to the 15% policy or discarded measurements.

## Implemented

- Race Space finalization: cache directed pair eligibility, corridor flags, offset and headroom during the first physical sweep; retain original i,j order, live resolved leader progress and strict comparisons. Store each changed follower progress once after the ordered inner loop. No new sporting fields.
- Shared Spatial Cache 2.0: TrafficPack optionally emits exact signed distances as a sidecar; reuse in tactical neighbor lookup, third-car forecast and lateral occupancy. No across-tick caching; keep legacy paths and fallback for absent IDs.
- Sporting hash: cache the filtered engine property schema and skip repeated exclusions; preserve String keys, declaration order, fresh values, SHA-256 and revision 040. Differential oracle compares to uncached digest.
- Tests: original physical reference fixtures plus sparse IDs, reverse order, direct versus cached traffic observations, lap-line ties, pit exclusion, replay hash oracle and pause.
- Native graphical probe: real UI and hardware renderer only, reports wall-frame p50/p95/p99/max, FPS, measured acceleration and sporting ticks. Verifies MSAA, shadow and SSAO profile. Headless benchmarks are not GPU evidence.

## Real GPU/interactive test (manual, isolated)

Check out the reviewed candidate in a separate working copy. Import once with Godot 4.7.2. Close other heavy apps, keep resolution, renderer, window and camera comparable. Test both default and GTX 1650 profiles at 1x forced 3D and 10/16/32x Auto (optional additional forced 3D cases). One fresh XDG workspace per case; never point at the normal player save. Run from project root with the actual Godot binary:

```bash
GODOT_BIN=/opt/apex-tools/godot/godot
"$GODOT_BIN" --headless --path . --import
mkdir -p /tmp/apex-graphics-rev2
for speed in 1 10 16 32; do
  mode=auto; [ "$speed" != 1 ] || mode=3d
  for profile in default gtx1650; do
    work=$(mktemp -d /tmp/apex-graphics-rev2/case.XXXXXXXX)
    gfx=""; [ "$profile" != gtx1650 ] || gfx=gtx1650
    XDG_DATA_HOME="$work/data" XDG_CONFIG_HOME="$work/config" XDG_CACHE_HOME="$work/cache" \
      APEX_GRAPHICS_PROBE=1 APEX_GRAPHICS_PROFILE="$gfx" APEX_GRAPHICS_SPEED="$speed" APEX_GRAPHICS_MODE="$mode" \
      "$GODOT_BIN" --path . --windowed --resolution 1280x720 --disable-vsync \
      --script res://scripts/debug/apex_graphics_probe_rev2.gd \
      > "/tmp/apex-graphics-rev2/${profile}-${speed}.log" 2>&1 || exit 1
  done
done
```

Keep the logs and visually compare road, cars, shadows, HUD, camera, pit scene and wet-weather readability separately. Native test NOT_RUN until evidence received. Actual GPU timings are not collected; FPS/latency and actual speed are wall-clock observations. The opt-in profile remains off by default.

## Acceptance

Exact candidate FAST and targeted regressions, prospective one-shot A/B on same original baseline, 24 short cases and eight per-tick parity probes; keep all historical evidence. Separate exploratory spike telemetry must not be used to select or discard acceptance pairs. No FULL, merge or claimed FPS without evidence.
