extends SceneTree
## APEX Test Lab: synthetic oval for cheap FAST regression. Never changes
## the actual 20 circuit calendar or substitutes 2012 FULL verification.
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const RaceSpace = preload("res://scripts/core/race_space_0655.gd")

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func require(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures.append(message)
        printerr("APEX_LAB_TRACK_FAIL " + message)

func _run() -> void:
    var season_raw: Variant = JSON.parse_string(
        FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track_raw: Variant = JSON.parse_string(
        FileAccess.get_file_as_string("res://tests/fixtures/apex_lab_track.json"))
    if not (season_raw is Dictionary and track_raw is Dictionary):
        require(false, "season and isolated synthetic track must parse")
        _finish()
        return
    var season: Dictionary = season_raw
    var track: Dictionary = track_raw
    require(season["tracks"].size() == 20, "real 2012 calendar remains intact")
    require(str(track.get("code", "")) == "LAB" and
        not season["tracks"].any(func(t): return str(t.get("code", "")) == "LAB"),
        "test track must never enter the real season")
    require(track["points"].size() >= 16 and track["points"][0] == track["points"][-1],
        "synthetic 2D path must close")
    var shape: Dictionary = RaceSpace.profile(track)
    require(float(shape.get("length", 0.0)) > 100.0,
        "real RaceSpace accepts the synthetic track geometry")

    for weather in ["Seco", "Chuva intensa"]:
        var hashes: Array[String] = []
        for iteration in range(2):
            var race = Race.new(season["teams"], "Ferrari", 9913, {}, track, {})
            race.configure_weather(weather)
            require(race.cars.size() == 24 and race.player_cars().size() == 2,
                "test lab retains the complete 2012 24-driver grid")
            require(race.lap_count == 4 and race.track_name == track["name"],
                "4-lap synthetic fixture is isolated from real race distances")
            var car: Dictionary = race.player_cars()[0]
            var id: int = int(car["id"])
            require(race.set_pit_control_mode(id, "Manual"),
                "manual pit control works on synthetic track")
            var nominated: Array = race.available_pit_compounds()
            require(nominated.size() >= 2, "laboratory track has two legal dry compounds")
            var initial: String = str(car.get("tire", ""))
            var target: String = str(nominated[0]) if initial != str(nominated[0]) else str(nominated[1])
            require(race.schedule_pit(id, target, 3),
                "manual BOX V3 accepted with a legal track compound")
            race.running = true
            for tick in range(85):
                race.step(1.0)
            require(int(car.get("pit_scheduled_lap", 0)) == 3 and
                not bool(car.get("pit_request", false)),
                "manual booking not anticipated before V3")
            require(race.get_sorted().size() == 24,
                "laboratory classification keeps 24 cars")
            hashes.append(Codec.sporting_hash(race, {}))
        require(hashes.size() == 2 and hashes[0] == hashes[1] and
            hashes[0].length() == 64,
            "identical seed and weather yield identical sporting SHA-256")
    _finish()

func _finish() -> void:
    if failures.is_empty():
        print("APEX_LAB_TRACK_PASS checks=%d synthetic=true full_tracks_untouched=true" % checks)
    else:
        for message in failures:
            printerr("FAIL: " + message)
    quit(0 if failures.is_empty() else 1)
