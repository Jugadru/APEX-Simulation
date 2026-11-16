extends SceneTree
## godot --headless --path . --script res://tests/core_0625_dry_strategy_smoke_test.gd
const Optimizer = preload("res://scripts/core/race_stint_optimizer.gd")
const Director = preload("res://scripts/core/race_ai_director.gd")
const Regulations = preload("res://scripts/core/race_tyre_regulations_2012.gd")
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tyres_2012.json"))
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var specs: Dictionary = catalog["compounds"]
	for code in ["CHN", "AUS"]:
		var track: Dictionary = {}
		for entry in season["tracks"]:
			if str(entry["code"]) == code:
				track = entry
				break
		assert(not track.is_empty())
		var slicks: Array = catalog["tracks"][code]["dry"]
		for start_tire in slicks:
			var car: Dictionary = {"tire": start_tire, "wear": 0.0, "laps_done": 0,
				"stint_laps": 0, "pace": "Normal", "track_wear_factor": float(catalog["tracks"][code]["severity"]),
				"used_tires": [start_tire], "pit_request": false, "pit_left": 0.0}
			var plan: Dictionary = Optimizer.optimize(car, int(track["laps"]), slicks + ["Intermediário", "Chuva"], specs, float(track["pit_loss"]))
			assert(bool(plan.get("valid", false)), "%s planner missing" % code)
			assert(int(plan["stop_count"]) >= 1 and int(plan["stop_count"]) <= 3,
				"%s should not request 5 dry stops" % code)
			var worn: Array = [start_tire]
			for step in plan["stops"]:
				worn.append(step["compound"])
			assert(Regulations.compliant(worn, slicks, false), "%s must use both slicks" % code)
			var first_again: Dictionary = Optimizer.optimize(car, int(track["laps"]), slicks + ["Intermediário", "Chuva"], specs, float(track["pit_loss"]))
			assert(plan == first_again, "Dry plan must be deterministic")
			var dry: Dictionary = {"wetness_factor": 0.0}
			var advice: Dictionary = Director.plan(car, int(track["laps"]), slicks + ["Intermediário", "Chuva"], specs,
				dry, dry, dry, float(track["pit_loss"]))
			assert(int(advice["planned_pit_lap"]) == int(plan["pit_lap"]), "AI should use full race plan")
			assert(not bool(advice["pit_now"]), "No first-lap pit on fresh slick")
	assert(not Regulations.compliant(["Macio", "Macio"], ["Macio", "Médio"], false))
	assert(Regulations.compliant(["Macio", "Macio", "Intermediário"], ["Macio", "Médio"], false))
	assert(Regulations.compliant(["Macio"], ["Macio", "Médio"], true))
	var china: Dictionary = {}
	for entry in season["tracks"]:
		if str(entry["code"]) == "CHN":
			china = entry
			break
	var race = RaceScript.new(season["teams"], "Ferrari", 2025, {}, china, {})
	race.configure_weather("Seco")
	var manual: Dictionary = race.player_cars()[0]
	manual["laps_done"] = 12
	manual["wear"] = 56.0
	var before: int = int(manual.get("pit_scheduled_lap", 0))
	var _advice: Dictionary = race.get_engineer_advice(int(manual["id"]))
	assert(not bool(manual["pit_request"]) and int(manual["pit_scheduled_lap"]) == before,
		"Engineer advice must never place a manual pit order")
	assert(race.schedule_pit(int(manual["id"]), "Médio", 21), "Manual V21 order should be accepted")
	race._request_ai_pit(manual, true)
	assert(int(manual["pit_scheduled_lap"]) == 21 and not bool(manual["pit_request"]),
		"Automatic emergency must not override scheduled V21")
	print("APEX 0.6.2.5 DRY STRATEGY PASS: China/Australia, nominated slicks, deterministic plans, manual V21")
	quit(0)
