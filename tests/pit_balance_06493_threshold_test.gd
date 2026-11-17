extends SceneTree
## Only the noncritical wet-for-wet projected-value stop is adjusted.
## Weather crossover, wear cliff, critical stop, dry plans and manual V21 stay intact.
const AI = preload("res://scripts/core/race_ai_director.gd")
const Race = preload("res://scripts/race_engine.gd")
var failures: Array[String] = []

func _assert(value: bool, message: String) -> void:
    if not value:
        failures.append(message)
        printerr("PIT_BALANCE_06493_FAIL: " + message)

func _initialize() -> void:
    var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
    var track: Dictionary = {}
    for entry in season["tracks"]:
        if str(entry.get("code", "")) == "GBR": track = entry
    _assert(not track.is_empty(), "Silverstone circuit exists")
    var sim = Race.new(season["teams"], "Ferrari", 6403, {}, track, {})
    var car: Dictionary = sim.player_cars()[0].duplicate(true)
    car["laps_done"] = 36
    car["stint_laps"] = 12
    car["last_pit_exit_lap"] = 23
    car["used_tires"] = ["Macio", "Intermediário"]
    car["tire"] = "Intermediário"
    car["pit_request"] = false
    car["pit_left"] = 0.0
    car["pit_scheduled_lap"] = 0
    var w: Dictionary = {"wetness_factor": 0.6, "rain_intensity": 0.4, "water_mm": 3.6, "surface_moisture": 0.6}
    var f3: Dictionary = w.duplicate(true)
    f3["wetness_factor"] = 0.384
    var f6: Dictionary = w.duplicate(true)
    f6["wetness_factor"] = 0.072
    for wear in [57.0, 62.0]:
        car["wear"] = wear
        var p: Dictionary = AI.plan(car, 52, sim.available_pit_compounds(), sim.tyre_specs, w, f3, f6, sim.pit_loss)
        _assert(str(p.get("compound", "")) == "Intermediário", "same wet compound at %.0f%%" % wear)
        _assert(not bool(p.get("pit_now", true)), "skip early wet-for-wet at %.0f%%" % wear)
        _assert(float(p.get("projected_saving_s", 0.0)) > sim.pit_loss, "projection explicitly tempting at %.0f%%" % wear)
    car["wear"] = 72.0
    var late: Dictionary = AI.plan(car, 52, sim.available_pit_compounds(), sim.tyre_specs, w, f3, f6, sim.pit_loss)
    _assert(bool(late.get("pit_now", false)), "do not block high-wear wet replacement")
    car["wear"] = 91.0
    var urgent: Dictionary = AI.plan(car, 52, sim.available_pit_compounds(), sim.tyre_specs, w, f3, f6, sim.pit_loss)
    _assert(bool(urgent.get("pit_now", false)), "critical wet replacement still allowed")
    _assert(bool(urgent.get("critical", false)), "critical flag preserved")
    car["tire"] = "Macio"
    car["wear"] = 72.0
    car["stint_laps"] = 14
    car["used_tires"] = ["Macio"]
    var dry_now: Dictionary = {"wetness_factor": 0.0, "rain_intensity": 0.0, "water_mm": 0.0, "surface_moisture": 0.0}
    var dry: Dictionary = AI.plan(car, 52, sim.available_pit_compounds(), sim.tyre_specs, dry_now, dry_now, dry_now, sim.pit_loss)
    _assert(bool(dry.get("planned_stops", []).size() > 0), "dry optimizer intact")
    var actual: Dictionary = sim.player_cars()[0]
    actual["pit_control_mode"] = "IA"
    _assert(sim.schedule_pit(int(actual["id"]), "Duro", 21), "manual V21 accepted")
    _assert(int(actual.get("pit_scheduled_lap", 0)) == 21, "manual V21 is not rewritten")
    if failures.is_empty():
        print("PIT_BALANCE_06493_PASS wet predictive guard, worn set, critical, dry optimizer, manual V21")
    quit(0 if failures.is_empty() else 1)
