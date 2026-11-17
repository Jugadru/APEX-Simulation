extends SceneTree
## Teste Godot 4: godot --headless --path . --script res://tests/pit_incidents_smoke_test.gd
## Fault and unsafe release are forced ONLY in this test, not in normal gameplay.
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var race = RaceScript.new(season["teams"], "Ferrari", 2027, {"Motor": 0, "Asa": 0, "Chassi": 0}, season["tracks"][11])
	var car: Dictionary = race.player_cars()[0]
	var car_id: int = int(car["id"])
	race.pit_incident_test_overrides[car_id] = {"service_fault": "Porca travada", "service_delay": 4.0, "release_delay": 5.0}
	car["progress"] = 0.949
	var old_tire: String = str(car["tire"])
	var target: String = "Duro" if old_tire != "Duro" else "Macio"
	race.order_pit(car_id, target)
	race.running = true
	var saw_repair := false
	var saw_safety_hold := false
	var saw_service := false
	var last_progress: float = float(car["progress"])
	for i in range(750):
		race.step(0.2)
		var stage: String = str(car["pit_stage"])
		if stage == "service":
			saw_service = true
		if stage == "repair":
			saw_repair = true
			assert(race.pit_crew_owner[str(car["team"])] == car_id, "crew vacated during repair")
			assert(str(car["tire"]) == old_tire, "tyres installed before repair ended")
		if stage == "safety_hold":
			saw_safety_hold = true
			assert(race.pit_crew_owner[str(car["team"])] == car_id, "garage vacated during safety hold")
			assert(str(car["tire"]) == target, "new tyres should be fitted before safety hold")
		assert(float(car["progress"]) >= last_progress - 0.00001, "car went backwards in pit lane")
		last_progress = float(car["progress"])
		if int(car["stops"]) >= 1 and float(car["pit_left"]) <= 0.0:
			break
	assert(saw_service and saw_repair and saw_safety_hold, "incident stages not visited")
	assert(str(car["tire"]) == target)
	assert(absf(float(car["pit_last_extra"]) - 9.0) < 0.03)
	assert(float(car["pit_last_wait"]) == 0.0)
	assert(absf(float(car["pit_last_total"]) - (float(car["pit_total"]) + 9.0)) < 0.04)
	assert(race.pit_crew_owner.is_empty(), "garage not released")
	var mechanical := false
	var safety := false
	for event in race.events:
		mechanical = mechanical or str(event["type"]) == "pit_failure"
		safety = safety or str(event["type"]) == "unsafe_release"
	assert(mechanical and safety, "radio incident notifications missing")
	print("APEX PIT INCIDENTS OK: +4s mechanical, +5s safety, no teleport or early garage release")
	quit(0)
