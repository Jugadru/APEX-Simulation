# Core 2 metadata adapter — Foundation v0.6.0 consumer side

Opt-in developer/CI exporter. No runtime dependency on private APEX-Foundation. Reads exact committed data/season_2012.json and data/teams.json, checks checkout bytes, SHA-1 Git blob and SHA-256, exports metadata to stdout. Core 2 remains sole sporting authority. No writes to saves, settings, runtime scripts or game data; no external package, network or Foundation authentication. Native loader uses season_2012.json (scripts/apex_session_settings.gd). teams.json currently mirrors the same ordered roster; divergence blocks the exporter instead of guessing. The current 2012 game catalog has 12 teams, 24 driver slots and 20 circuits. This is the game's roster, not independently certified historical data or a license grant. Team index, driver slot, circuit index are scoped to the exact Git revision, not stable cross-version IDs. Circuit code is the native source string. No ratings, geometry, model assets, telemetry or save state exported.

```sh
mkdir -p ci-results
python3 tools/apex_foundation_metadata.py > ci-results/foundation-core2-metadata.json
python3 -m unittest discover -s tools/tests -p 'test_apex_foundation_metadata.py' -v
bash tools/apex_ci_isolated_test.sh foundation_metadata_adapter_test.gd
```

Exporter rejects uncommitted source modifications, invalid JSON, mismatched roster, duplicate names/codes and wrong counts. It produces a deterministic body SHA256 over UTF-8 compact JSON with sorted keys; native fixture compares every roster/circuit field to actual Godot session loader and source SHA256. The existing FAST router selects the fixture on relevant changes. The CI exports the actual checked-out integration commit (synthetic merge for PRs); post-merge exports will use the resulting main commit. No arbitrary checkout or player paths accepted. Foundation ingestion and approval are separate reviewed steps; consumer-side export is not proof of Foundation adoption. Rollback: revert adapter PR. Game release identity unchanged.
