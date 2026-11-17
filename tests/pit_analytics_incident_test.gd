extends SceneTree
## Run in Godot 4: godot --headless --path . --script res://tests/pit_analytics_incident_test.gd
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var race = RaceScript.new(season["teams"], "Ferrari", 122,
		{"Motor": 0, "Asa": 0, "Chassi": 0}, season["tracks"][11])
	var player: Dictionary = race.player_cars()[0]
	player["progress"] = 0.949
	race.pit_incident_test_overrides[int(player["id"])] = {
		"service_fault": "Porca travada", "service_delay": 4.0, "release_delay": 3.0}
	race.order_pit(int(player["id"]), "Macio")
	race.running = true
	for step in range(800):
		race.step(0.2)
		if race.get_pit_history("Ferrari").size() > 0:
			break
	var history: Array = race.get_pit_history("Ferrari")
	assert(history.size() == 1)
	var item: Dictionary = history[0]
	assert(float(item["incident_delay"]) >= 6.99)
	assert(str(item["incident"]).contains("Retenção de segurança"))
	assert(float(item["net_vs_untrained"]) < 0.0)
	assert(int(race.get_pit_summary("Ferrari")["incidents"]) == 1)
	print("APEX ANALYTICS INCIDENT OK: 7 seconds reflected in record and engineer metrics")
	quit(0)
