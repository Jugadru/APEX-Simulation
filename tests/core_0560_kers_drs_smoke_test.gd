extends SceneTree
## Run: godot --headless --path . --script res://tests/core_0560_kers_drs_smoke_test.gd
const RaceScript = preload("res://scripts/race_engine.gd")
const Kers = preload("res://scripts/core/race_kers_2012.gd")
const Drs = preload("res://scripts/core/race_drs_2012.gd")

func _initialize() -> void:
	_test_kers_limits()
	_test_drs_gates()
	_test_race_determinism()
	print("APEX v0.5.6.0 KERS + DRS: smoke tests OK")
	quit(0)

func _test_kers_limits() -> void:
	assert(not Kers.equipped("HRT Cosworth"))
	assert(not Kers.equipped("Marussia Cosworth"))
	assert(Kers.equipped("Ferrari"))
	var car := {"team": "Ferrari", "pit_left": 0.0}
	Kers.initial_state(car)
	var total := 0.0
	# A single straight never drains the 400kJ budget: zone #0 is capped.
	for tick in range(120):
		var before: float = float(car["kers_remaining_kj"])
		var active: bool = Kers.apply(car, 0.10, 1.6, 0.2, {})
		var delta: float = before - float(car["kers_remaining_kj"])
		assert(delta >= 0.0 and delta <= 12.00001)
		assert(active == (delta > 0.00001))
		total += delta
	assert(float(car.get("kers_power_kw", 0.0)) <= 60.0)
	assert(absf(total - 140.0) < 0.001) # balanced first zone quota
	assert(float(car["kers_remaining_kj"]) > 250.0)
	for zone_progress in [0.52, 0.81]:
		for tick in range(120):
			Kers.apply(car, zone_progress, 1.6, 0.2, {})
	assert(absf(float(car["kers_remaining_kj"])) < 0.001)
	assert(float(car["kers_remaining_kj"]) >= 0.0)
	Kers.reset_lap(car)
	assert(absf(float(car["kers_remaining_kj"]) - 400.0) < 0.001)
	var hrt := {"team": "HRT Cosworth", "pit_left": 0.0}
	Kers.initial_state(hrt)
	assert(not Kers.apply(hrt, 0.10, 0.5, 0.2, {}))
	assert(float(hrt["kers_remaining_kj"]) == 0.0)

func _test_drs_gates() -> void:
	var dry := {"drs_allowed": true}
	var wet := {"drs_allowed": false}
	var circuit := {"code": "BEL"}
	var car := {"laps_done": 2, "pit_left": 0.0}
	Drs.initial_state(car)
	assert(not Drs.update(car, 2.179, 2.182, 0.6, circuit, dry))
	assert(not Drs.update(car, 2.219, 2.220, 0.6, circuit, dry))
	assert(Drs.update(car, 2.239, 2.241, 3.5, circuit, dry))
	assert(not Drs.update(car, 2.239, 2.241, 0.4, circuit, wet))
	assert(not Drs.update(car, 2.260, 2.262, 0.4, circuit, dry))
	var too_far := {"laps_done": 2, "pit_left": 0.0}
	Drs.initial_state(too_far)
	Drs.update(too_far, 2.179, 2.182, 1.4, circuit, dry)
	assert(not Drs.update(too_far, 2.239, 2.241, 0.1, circuit, dry))
	var too_early := {"laps_done": 1, "pit_left": 0.0}
	Drs.initial_state(too_early)
	Drs.update(too_early, 1.179, 1.182, 0.4, circuit, dry)
	assert(not Drs.update(too_early, 1.239, 1.241, 0.4, circuit, dry))
	# Melbourne shared detection point must arm both activation zones.
	var aus := {"laps_done": 2, "pit_left": 0.0}
	Drs.initial_state(aus)
	Drs.update(aus, 2.059, 2.061, 0.4, {"code": "AUS"}, dry)
	assert(Drs.update(aus, 2.130, 2.132, 0.8, {"code": "AUS"}, dry))
	assert(Drs.update(aus, 2.280, 2.282, 1.8, {"code": "AUS"}, dry))

func _test_race_determinism() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	assert(typeof(parsed) == TYPE_DICTIONARY)
	var season: Dictionary = parsed
	var spa: Dictionary = {}
	for entry in season["tracks"]:
		if str(entry.get("code", "")) == "BEL":
			spa = entry
	assert(not spa.is_empty())
	var first = RaceScript.new(season["teams"], "Ferrari", 912, {}, spa, {})
	var other = RaceScript.new(season["teams"], "Ferrari", 912, {}, spa, {})
	first.configure_weather("Seco")
	other.configure_weather("Seco")
	assert(first.cars.size() == 24)
	for car in first.cars:
		assert(bool(car["kers_equipped"]) == (not ["HRT Cosworth", "Marussia Cosworth"].has(str(car["team"]))))
		assert(car.has("drs_armed_zones"))
	var id: int = int(first.player_cars()[0]["id"])
	first.set_kers_mode(id, "Atacar")
	other.set_kers_mode(id, "Atacar")
	first.running = true
	other.running = true
	for tick in range(300):
		first.step(4.0)
		other.step(4.0)
	for idx in range(first.cars.size()):
		var a: Dictionary = first.cars[idx]
		var b: Dictionary = other.cars[idx]
		assert(is_equal_approx(float(a["progress"]), float(b["progress"])))
		assert(is_equal_approx(float(a["kers_remaining_kj"]), float(b["kers_remaining_kj"])))
		assert(float(a["kers_remaining_kj"]) >= -0.0001)
		assert(float(a["kers_remaining_kj"]) <= Kers.ENERGY_PER_LAP_KJ + 0.0001)
		assert(int(a["combat_passes"]) == int(b["combat_passes"]))
	assert(first.telemetry.position_history.size() > 0)
	assert(first.telemetry.position_history[0].has("kers_remaining_kj"))
	assert(first.telemetry.position_history[0].has("drs_active"))
