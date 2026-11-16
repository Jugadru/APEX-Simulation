extends SceneTree
## Run in Godot 4: godot --headless --path . --script res://tests/pit_analytics_smoke_test.gd
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var race = RaceScript.new(season["teams"], "Ferrari", 125,
		{"Motor": 0, "Asa": 0, "Chassi": 0}, season["tracks"][11],
		{"Agilidade": 2, "Precisão": 0, "Coordenação": 1})
	race.pit_incidents_enabled = false
	assert(race.get_pit_history().is_empty())
	assert(int(race.get_pit_summary("Ferrari")["stops"]) == 0)
	var pair: Array = race.player_cars()
	assert(pair.size() == 2)
	pair[0]["progress"] = 0.949
	pair[1]["progress"] = 0.946
	race.order_pit(int(pair[0]["id"]), "Duro" if str(pair[0]["tire"]) != "Duro" else "Macio")
	race.order_pit(int(pair[1]["id"]), "Médio" if str(pair[1]["tire"]) != "Médio" else "Duro")
	race.running = true
	for step in range(850):
		race.step(0.2)
		if race.get_pit_history().size() >= 2:
			break
	var history: Array = race.get_pit_history("Ferrari")
	assert(history.size() == 2, "Double stack should generate exactly two entries")
	assert(int(history[0]["car_id"]) != int(history[1]["car_id"]))
	var summary: Dictionary = race.get_pit_summary("Ferrari")
	assert(int(summary["stops"]) == 2)
	assert(float(summary["mean_service"]) > 2.0)
	assert(float(summary["sum_queue"]) > 0.1, "Second car queue must count")
	assert(float(summary["sum_pit_time"]) > 0.0)
	assert(is_equal_approx(float(summary["sum_queue"]), float(history[0]["wait"]) + float(history[1]["wait"])))
	assert(float(summary["sum_training_saving"]) > 0.0)
	for item in history:
		assert(int(item["lap"]) >= 1)
		assert(int(item["position_before"]) >= 1)
		assert(int(item["position_after"]) >= 1)
		assert(float(item["exited_at"]) >= float(item["entered_at"]))
		assert(float(item["total"]) >= float(item["service"]))
		assert(float(item["untrained_service"]) >= float(item["service"]))
	var originals: Array = race.get_pit_history()
	originals[0]["driver"] = "tampered"
	assert(str(race.get_pit_history()[0]["driver"]) != "tampered", "History must be immutable to callers")
	var compared: Array = race.get_team_pit_comparison()
	assert(compared.size() >= 1)
	for i in range(1, compared.size()):
		assert(float(compared[i - 1]["mean_service"]) <= float(compared[i]["mean_service"]))
	for step in range(40):
		race.step(0.2)
	assert(race.get_pit_history("Ferrari").size() == 2, "Stops must not be duplicated")
	print("APEX ANALYTICS OK: 2 independent records, queue, savings, comparison, immutable snapshots")
	quit(0)
