extends SceneTree
## Godot 4: godot --headless --path . --script res://tests/double_stack_single_smoke_test.gd
const RaceScript = preload("res://scripts/race_engine.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var season: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var race = RaceScript.new(season["teams"], "Ferrari", 42, {"Motor": 0, "Asa": 0, "Chassi": 0}, season["tracks"][11])
	race.pit_incidents_enabled = false  # baseline, no rare faults
	var car: Dictionary = race.player_cars()[0]
	car["progress"] = 0.949
	race.order_pit(int(car["id"]), "Duro")
	race.running = true
	for i in range(450):
		race.step(0.2)
		if int(car["stops"]) >= 1 and float(car["pit_left"]) <= 0.0:
			break
	assert(int(car["stops"]) == 1)
	assert(float(car["pit_left"]) <= 0.0)
	assert(float(car["pit_last_wait"]) == 0.0, "Solo stop gained unexpected waiting time")
	assert(absf(float(car["pit_last_total"]) - float(car["pit_total"])) < 0.01)
	assert(str(car["tire"]) == "Duro")
	assert(race.pit_crew_owner.is_empty())
	print("APEX SOLO PIT OK: no extra queue time, original duration preserved")
	quit(0)
