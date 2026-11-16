extends SceneTree
const RaceScript = preload("res://scripts/race_engine.gd")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		printerr("APEX 0638 FAIL: ", label)
func track_for(season: Dictionary, code: String) -> Dictionary:
	for entry in season["tracks"]:
		if str(entry.get("code", "")) == code:
			return entry.duplicate(true)
	return {}
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = track_for(season, "BRA")
	track["laps"] = 12
	track["race_km"] = float(track["lap_km"]) * 12.0
	var race = RaceScript.new(season["teams"], "Ferrari", 321, {"Motor":1, "Chassi":1}, track, {"Agilidade":1})
	race.configure_weather("Seco")
	race.running = true
	var players: Array = race.player_cars()
	var id1: int = int(players[0]["id"])
	var id2: int = int(players[1]["id"])
	check(race.schedule_pit(id1, str(race.available_pit_compounds()[1]), 5), "manual pit V5 accepted")
	check(race.schedule_pit(id2, str(race.available_pit_compounds()[1]), 7), "manual pit V7 accepted")
	var captured: bool = false
	var limit: int = 0
	while not race.finished and limit < 5000:
		race.step(4.0)
		limit += 1
		if not captured and race.lap >= 3:
			captured = true
			var first: Dictionary = race.player_cars()[0]
			check(int(first.get("pit_scheduled_lap", 0)) == 5, "No early V5 pit")
	check(race.finished, "race finished")
	check(race.finish_results_validated, "immutable race classification finalized")
	check(race.first_finish_at > 0, "winner timestamp")
	check(race.get_sorted().size() == 24, "24 classified")
	var order: Array = race.get_sorted()
	var leader: Dictionary = order[0]
	var same_lap_count: int = 0
	for i in range(order.size()):
		var c: Dictionary = order[i]
		check(int(c.get("position", 0)) == i+1, "finished position %s" % str(c["name"]))
		check(float(c.get("best_lap", 9999.0)) >= race.base_lap * 0.70, "no impossible best lap %s" % str(c["name"]))
		check(int(c.get("finish_laps", 0)) > 0, "finish laps reported %s" % str(c["name"]))
		if i > 0 and int(c.get("finish_laps", 0)) == int(leader.get("finish_laps", 0)) and float(c.get("finish_time", -1)) >= 0:
			same_lap_count += 1
			check(absf(float(c.get("gap",0)) - (float(c["finish_time"]) - float(leader["finish_time"]))) < 0.02, "gap measured from finish times")
	check(same_lap_count > 0, "same lap finish times exist")
	var history: Array = race.get_pit_history("Ferrari")
	for item in history:
		if int(item["car_id"]) == id1:
			check(int(item["lap"]) == 5, "V5 pit executed exact")
		if int(item["car_id"]) == id2:
			check(int(item["lap"]) == 7, "V7 pit executed exact")
	var second = RaceScript.new(season["teams"], "Ferrari", 321, {}, track, {})
	second.set_championship_round(8)
	check(second.rival_development_bonus > 0, "rivals grow in career")
	var standalone = RaceScript.new(season["teams"], "Ferrari", 321, {}, track, {})
	check(standalone.rival_development_bonus == 0.0, "rivals no extra in single GP")
	# The HUD must expose the following-car metric, without deleting old ones.
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	scene._start_race()
	await process_frame
	var hud = scene.race_hud_0620
	check(hud != null and hud.METRICS.size() == 6, "HUD has 6 metrics")
	if hud != null:
		for idx in range(6):
			hud.metric_index = idx
			hud.refresh_hud()
			check(hud._standing_value(scene.race.get_sorted(), 0) != "", "HUD metric %d" % idx)
		check(hud._standing_value(scene.race.get_sorted(), 23) == "—", "last has no car behind")
	if failures.is_empty():
		print("APEX 0638 INTEGRITY PASS | 12 laps, 24 cars, exact pits, crossings, gaps, best lap, championship and HUD | steps=", limit, " pits=", history.size())
		quit(0)
	else:
		printerr("APEX 0638 INTEGRITY FAIL COUNT=", failures.size(), " ", failures)
		quit(1)
