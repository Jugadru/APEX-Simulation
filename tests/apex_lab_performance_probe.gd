extends SceneTree
## APEX Test Lab 2.0 — headless 24-car CPU observations, NOT GPU/FPS.
## Isolated synthetic circuit; neither the 2012 season nor gameplay is modified.
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const TICKS: int = 500
const BLOCK: int = 100
const SEED: int = 991420
const WEATHER: Array[String] = ["Seco", "Chuva intensa"]

var errors: Array[String] = []
var checks: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _check(condition: bool, name: String) -> void:
    checks += 1
    if not condition:
        errors.append(name)
        printerr("APEX_LAB_PERF_FAIL " + name)

func _run() -> void:
    var season: Variant = JSON.parse_string(
        FileAccess.get_file_as_string("res://data/season_2012.json"))
    var fixture: Variant = JSON.parse_string(
        FileAccess.get_file_as_string("res://tests/fixtures/apex_lab_track.json"))
    if not (season is Dictionary and fixture is Dictionary):
        _check(false, "season or synthetic fixture invalid")
        quit(1)
        return
    var source: Dictionary = season
    var track: Dictionary = fixture.duplicate(true)
    track["laps"] = 30
    track["race_km"] = 30.0 * float(track["lap_km"])
    _check(source["tracks"].size() == 20, "2012 calendar unchanged")
    _check(str(track.get("code", "")) == "LAB", "synthetic-only circuit")

    var runs: Array[Dictionary] = []
    for weather in WEATHER:
        var hashes: Array[String] = []
        for repetition in [1, 2]:
            var race = Race.new(source["teams"], "Ferrari", SEED, {}, track, {})
            race.configure_weather(weather)
            _check(race.cars.size() == 24 and race.lap_count == 30,
                "24 real cars on isolated thirty-lap stress fixture")
            race.running = true
            var samples: Array[int] = []
            var peak_static_bytes: int = 0
            var wall_start: int = Time.get_ticks_usec()
            for tick in range(TICKS):
                var start: int = Time.get_ticks_usec()
                race.step(1.0)
                samples.append(maxi(1, Time.get_ticks_usec() - start))
                if tick % BLOCK == BLOCK - 1:
                    peak_static_bytes = maxi(peak_static_bytes,
                        int(Performance.get_monitor(Performance.MEMORY_STATIC)))
            var wall_usec: int = maxi(1, Time.get_ticks_usec() - wall_start)
            _check(not race.finished, "race must not finish before profiling ends")
            _check(samples.size() == TICKS, "all benchmark ticks completed")
            var first_us: int = 0
            var last_us: int = 0
            var total_us: int = 0
            for index in range(samples.size()):
                total_us += samples[index]
                if index < BLOCK:
                    first_us += samples[index]
                if index >= TICKS - BLOCK:
                    last_us += samples[index]
            samples.sort()
            var hash_value: String = Codec.sporting_hash(race, {})
            hashes.append(hash_value)
            var wall_seconds: float = float(wall_usec) / 1000000.0
            runs.append({
                "weather": weather,
                "repetition": repetition,
                "seed": SEED,
                "cars": race.cars.size(),
                "ticks": TICKS,
                "finished": race.finished,
                "sporting_hash": hash_value,
                "mean_us": float(total_us) / float(TICKS),
                "p95_us": samples[int(floor(float(TICKS - 1) * 0.95))],
                "max_us": samples[-1],
                "early_mean_us": float(first_us) / float(BLOCK),
                "late_mean_us": float(last_us) / float(BLOCK),
                "peak_static_bytes": peak_static_bytes,
                "wall_seconds": wall_seconds,
                "simulated_seconds_per_wall_second": float(TICKS) / wall_seconds,
            })
        _check(hashes.size() == 2 and hashes[0] == hashes[1] and hashes[0].length() == 64,
            "same weather and seed reproduce sporting SHA-256")
    if errors.is_empty():
        print("APEX_LAB_PERF_RESULT ", JSON.stringify({
            "schema": 1, "status": "PASS", "track": "LAB", "ticks": TICKS,
            "checks": checks, "runs": runs,
            "limitations": "Godot headless CPU tick timing and memory_static monitor; not GPU FPS/VRAM"
        }))
        print("APEX_LAB_PERF_PASS checks=%d" % checks)
        quit(0)
    else:
        quit(1)
