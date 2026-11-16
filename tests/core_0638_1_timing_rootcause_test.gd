extends SceneTree
## Root-cause regression: an incident just beyond a timing line must not
## rewind the car and create a second 2-4-second phantom lap.
const RaceScript = preload("res://scripts/race_engine.gd")
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, description: String) -> void:
    if not ok:
        failures.append(description)
        printerr("TIMING ROOT CAUSE FAILURE: ", description)

func track_for(season: Dictionary, code: String) -> Dictionary:
    for entry in season["tracks"]:
        if str(entry.get("code", "")) == code:
            return entry.duplicate(true)
    return {}

func _run() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var race = RaceScript.new(season["teams"], "Ferrari", 321, {}, track_for(season, "BRA"), {})
    race.configure_weather("Seco")
    var car: Dictionary = race.player_cars()[0]
    car["progress"] = 4.0002
    car["laps_done"] = 4
    race.clock = 400.0
    car["lap_started"] = 400.0
    var start_pos: float = float(car["progress"])
    var trial := RandomNumberGenerator.new()
    var incident_seed: int = -1
    for candidate in range(1, 25000):
        trial.seed = candidate
        if trial.randf() < 0.002:
            incident_seed = candidate
            break
    check(incident_seed > 0, "deterministic incident seed located")
    if incident_seed > 0:
        race.rng.seed = incident_seed
        race._on_lap_cross(car)
        var incident: bool = false
        for event in race.events:
            if str(event.get("type", "")) == "incident" and int(event.get("driver_id", -1)) == int(car["id"]):
                incident = true
        check(incident, "forced driver incident triggered")
        check(absf(float(car["progress"]) - start_pos) < 0.000001, "no rewind behind the same line")
        var lost_time: float = float(car.get("combat_hesitation_s", 0.0))
        check(lost_time >= 1.5 and lost_time <= 3.5, "incident adds simulated time penalty")
        race.running = true
        race.step(4.0)
        check(int(car["laps_done"]) == 4, "no second lap in four seconds")
        check(int(car.get("invalid_lap_count", 0)) == 0, "no phantom recorded lap")
        check(float(car["progress"]) >= start_pos, "monotonic distance during delay")
        check(float(car.get("combat_hesitation_s", 0.0)) < 0.01, "time penalty consumed through step")
        # Even if an older save or future subsystem rewinds across a line,
        # crossing a previously counted marker cannot overwrite best lap.
        var before_invalid: int = int(car.get("invalid_lap_count", 0))
        car["progress"] = 4.0003
        race._record_lap_cross(car, 3.9997, false)
        check(int(car["laps_done"]) == 4, "previously completed lap not counted twice")
        check(int(car.get("invalid_lap_count", 0)) == before_invalid, "duplicate crossing cannot create record")

    print("APEX 0638.1 TARGETED | failures=", failures.size())
    if OS.get_cmdline_user_args().has("quick"):
        quit(0 if failures.is_empty() else 1)
        return
    # Seed 321 generated a 3.4s Petrov lap at t=406.2 and 2.6s
    # Karthikeyan lap at t=496.2 in the original v0.6.3.8.
    var replay = RaceScript.new(season["teams"], "Ferrari", 321,
        {"Motor":1,"Asa":1,"Chassi":1}, track_for(season,"BRA"), {"Agilidade":1,"Precisão":1})
    replay.configure_weather("Seco")
    replay.running = true
    var old_progress: Dictionary = {}
    for entry in replay.cars:
        old_progress[int(entry["id"])] = float(entry["progress"])
    while replay.clock < 560.0:
        replay.step(4.0)
        if int(replay.clock) % 80 == 0:
            print("APEX 0638.1 REPLAY progress=", replay.clock)
        for entry in replay.cars:
            var id: int = int(entry["id"])
            check(float(entry["progress"]) >= float(old_progress[id]) - 0.000001, "nondecreasing position %s" % entry["name"])
            old_progress[id] = float(entry["progress"])
    var invalid: int = 0
    for entry in replay.cars:
        invalid += int(entry.get("invalid_lap_count", 0))
    check(invalid == 0, "seed=321 no invalid lap through 560s")
    if failures.is_empty():
        print("APEX 0638.1 ROOT-CAUSE PASS | forced incident, delayed time, monotonic crossing, seed321 560s, invalid=",invalid)
        quit(0)
    else:
        printerr("APEX 0638.1 ROOT-CAUSE FAILURES=", failures)
        quit(1)
