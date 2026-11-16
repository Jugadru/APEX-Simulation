extends SceneTree
## In-engine numeric regression: godot --headless --path . --script res://tests/core_0561_energy_balance_test.gd
const Kers = preload("res://scripts/core/race_kers_2012.gd")
const Drs = preload("res://scripts/core/race_drs_2012.gd")
const Perf = preload("res://scripts/core/race_performance.gd")

func _initialize() -> void:
	var results := {}
	for mode in Kers.MODES:
		results[str(mode)] = _simulate_mode(str(mode))
	assert(float(results["Economizar"]["seconds"]) > float(results["Equilibrado"]["seconds"]))
	assert(float(results["Equilibrado"]["seconds"]) > float(results["Atacar"]["seconds"]))
	assert(float(results["Atacar"]["gain"]) > float(results["Equilibrado"]["gain"]))
	assert(float(results["Equilibrado"]["gain"]) > float(results["Economizar"]["gain"]))
	assert(float(results["Atacar"]["gain"]) < 0.8)
	_test_drs_performance()
	print("APEX 0.5.6.1 PASS: 3 KERS modes differ, energy spread 3 zones, DRS boosts in legal zone")
	quit(0)

func _car() -> Dictionary:
	return {"team": "Ferrari", "pit_left": 0.0, "pace": "Normal",
		"tire": "Médio", "wear": 10.0, "car_rating": 80.0,
		"skill": 80.0, "laps_done": 2, "tyre_heat": 0.0}

func _context() -> Dictionary:
	return {"gap": 0.7, "lap": 3, "race_laps": 44, "base_lap": 110.0,
		"upgrades": {}, "player_car": false,
		"tyre_specs": {"Médio": {"delta": 0.0, "wear": 2.0, "cliff": 65.0}},
		"tyre_track_severity": 1.0, "weather": {"wetness_factor": 0.0,
		"rain_intensity": 0.0}, "kers_power_kw": 0.0, "kers_mode": "Equilibrado", "drs_active": false}

func _simulate_mode(mode: String) -> Dictionary:
	var car := _car()
	Kers.initial_state(car)
	car["kers_mode"] = mode
	var used_zones := {}
	var active_seconds := 0.0
	var gain_seconds := 0.0
	var first_zone_energy := 0.0
	var maximum_power := 0.0
	var context := _context()
	for tick in range(550):
		var dt := 0.20
		var progress := float(tick) * dt / 110.0
		var active: bool = Kers.apply(car, progress, 0.7, dt, {})
		var output_kw: float = float(car["kers_power_kw"])
		maximum_power = maxf(maximum_power, output_kw)
		assert(output_kw <= 60.0001)
		assert(float(car["kers_remaining_kj"]) >= -0.0001)
		if active:
			used_zones[Kers.zone_at(progress)] = true
			active_seconds += output_kw * dt / float(Kers.MODE_POWER_KW[mode])
		context["kers_power_kw"] = output_kw
		context["kers_mode"] = mode
		var pace: Dictionary = Perf.evaluate(car, context)
		context["kers_power_kw"] = 0.0
		var original: Dictionary = Perf.evaluate(car, context)
		gain_seconds += dt * (float(original["target"]) / float(pace["target"]) - 1.0)
		if progress < 0.26:
			first_zone_energy = float(car["kers_used_lap_kj"])
	assert(used_zones.size() == 3)
	assert(first_zone_energy < 160.001) # cannot consume whole battery at first straight
	assert(maximum_power <= Kers.POWER_KW)
	var spent: float = float(car["kers_used_lap_kj"])
	assert(spent <= Kers.ENERGY_PER_LAP_KJ + 0.001)
	if mode == "Economizar":
		assert(spent < 400.0)
	else:
		assert(absf(spent - 400.0) < 0.01)
	Kers.reset_lap(car)
	assert(absf(float(car["kers_remaining_kj"]) - 400.0) < 0.001)
	print("KERS ", mode, " energy=", spent, " duration=", active_seconds, " gain=", gain_seconds)
	return {"seconds": active_seconds, "gain": gain_seconds, "spent": spent}

func _test_drs_performance() -> void:
	var car := _car()
	Drs.initial_state(car)
	var dry := {"drs_allowed": true}
	var wet := {"drs_allowed": false}
	assert(not Drs.update(car, 2.179, 2.182, 0.7, {"code": "BEL"}, dry))
	assert(Drs.update(car, 2.239, 2.242, 2.0, {"code": "BEL"}, dry))
	var context := _context()
	context["drs_active"] = true
	var with_drs: Dictionary = Perf.evaluate(car, context)
	context["drs_active"] = false
	var without_drs: Dictionary = Perf.evaluate(car, context)
	assert(float(without_drs["target"]) - float(with_drs["target"]) > 3.2)
	assert(not Drs.update(car, 2.252, 2.255, 0.7, {"code": "BEL"}, wet))
