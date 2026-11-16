extends SceneTree
## Godot 4: godot --headless --path . --script res://tests/double_stack_smoke_test.gd
## Checks overlapping stops, exclusive team crew, wait time, tyre changes and race ranking.
const RaceScript = preload("res://scripts/race_engine.gd")
const PitScript = preload("res://scripts/pit_complex_3d.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var season: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	assert(typeof(season) == TYPE_DICTIONARY)
	var teams: Array = season["teams"]
	var track: Dictionary = season["tracks"][11]
	var race = RaceScript.new(teams, "Ferrari", 125, {"Motor": 0, "Asa": 0, "Chassi": 0}, track)
	race.pit_incidents_enabled = false  # legacy timing and queue regression without rare incidents
	assert(race.cars.size() == 24)
	var pair: Array = race.player_cars()
	assert(pair.size() == 2)
	assert(str(pair[0]["team"]) == str(pair[1]["team"]))
	# Force the second car to arrive within seconds of the first.
	pair[0]["progress"] = 0.949
	pair[1]["progress"] = 0.946
	var target_a: String = "Macio" if str(pair[0]["tire"]) != "Macio" else "Duro"
	var target_b: String = "Duro" if str(pair[1]["tire"]) != "Duro" else "Médio"
	race.order_pit(int(pair[0]["id"]), target_a)
	race.order_pit(int(pair[1]["id"]), target_b)
	race.running = true
	var both_in_pit := false
	var saw_queue := false
	var queued_seconds := 0.0
	var saw_service := false
	var initial_progress: Dictionary = {int(pair[0]["id"]): float(pair[0]["progress"]), int(pair[1]["id"]): float(pair[1]["progress"])}
	for tick in range(600):
		race.step(0.2)
		var service_count := 0
		var pitting_count := 0
		for car in pair:
			var id: int = int(car["id"])
			assert(float(car["progress"]) >= float(initial_progress[id]) - 0.00001, "Pit progress moved backwards")
			initial_progress[id] = float(car["progress"])
			if float(car["pit_left"]) > 0.001:
				pitting_count += 1
			if str(car["pit_stage"]) == "service":
				service_count += 1
				saw_service = true
			if str(car["pit_stage"]) == "queue":
				saw_queue = true
				queued_seconds = maxf(queued_seconds, float(car["pit_wait"]))
				assert(is_equal_approx(float(car["pit_phase"]), float(RaceScript.PIT_QUEUE_PHASE)), "Waiting car left queue position")
		assert(service_count <= 1, "Two cars using the same tyre crew at once")
		both_in_pit = both_in_pit or pitting_count == 2
		if int(pair[0]["stops"]) == 1 and int(pair[1]["stops"]) == 1 and float(pair[0]["pit_left"]) <= 0.0 and float(pair[1]["pit_left"]) <= 0.0:
			break
	assert(both_in_pit, "Both team cars were not in pit lane together")
	assert(saw_queue and queued_seconds > 1.0, "Second car did not wait for double-stack")
	assert(saw_service, "No four-wheel service performed")
	assert(float(pair[0]["pit_left"]) <= 0.0 and float(pair[1]["pit_left"]) <= 0.0)
	assert(bool(pair[0]["pit_service_complete"]) and bool(pair[1]["pit_service_complete"]))
	assert(str(pair[0]["tire"]) == target_a and str(pair[1]["tire"]) == target_b)
	assert(float(pair[0]["pit_last_wait"]) > 0.1 or float(pair[1]["pit_last_wait"]) > 0.1)
	assert(race.pit_crew_owner.is_empty(), "Crew slot not released")
	var serial_time: float = float(pair[0]["pit_last_wait"]) + float(pair[1]["pit_last_wait"])
	assert(serial_time >= queued_seconds - 0.21)
	assert(race.get_sorted().size() == 24)
	assert(race.get_team_pit_status(str(pair[0]["team"]))["owner_id"] == -1)
	var pit = PitScript.new()
	root.add_child(pit)
	assert(int(PitScript.MAX_SLOTS) == 12)
	print("APEX DOUBLE STACK OK: team queue +%.2fs, distinct service, both tyres changed, 24 cars." % serial_time)
	quit(0)
