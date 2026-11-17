extends SceneTree
## Real race scene + a few native simulation ticks per circuit.
## Smoke coverage only, not a complete GP or long-run regression.
var results: Array = []
var failures: Array[String] = []
const SCENARIOS := [
	{"code":"GBR","weather":"Seco","name":"Silverstone dry"},
	{"code":"BEL","weather":"Chuva intensa","name":"Spa heavy rain"},
	{"code":"ITA","weather":"Seco","name":"Monza dry"},
	{"code":"SIN","weather":"Chuva intensa","name":"Singapore heavy rain"}
]
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1600,900)
	var scene: PackedScene = load("res://scenes/main.tscn")
	for scenario in SCENARIOS:
		var game = scene.instantiate()
		root.add_child(game)
		await process_frame
		game.set_process(false)
		game.seed_picker.value = 660
		var track_found := false
		for i in range(game.season_tracks.size()):
			if str(game.season_tracks[i].get("code", "")) == str(scenario["code"]):
				game.selected_track_index = i
				track_found = true
				break
		var weather_found := false
		if game.weather_mode_picker != null:
			for i in range(game.weather_mode_picker.item_count):
				if game.weather_mode_picker.get_item_text(i) == str(scenario["weather"]):
					game.weather_mode_picker.select(i)
					weather_found = true
					break
		if not track_found or not weather_found:
			failures.append("scenario setup " + str(scenario))
			game.queue_free()
			await process_frame
			continue
		game._start_race()
		var hud = game.race_hud_0620
		var ticks := 0
		for _i in range(12):
			if game.replay_session.step_tick():
				ticks += 1
			else:
				break
		for mode in range(3):
			hud._change_hud_mode(mode)
			hud.refresh_hud()
		if ticks != 12 or game.race.cars.size() != 24 or hud.standing_rows.size() != 24:
			failures.append(str(scenario["name"]) + " ticks=" + str(ticks))
		results.append({"scenario":str(scenario["name"]),"ticks":ticks,"cars":game.race.cars.size(),"pass":ticks==12})
		game.queue_free()
		for _i in range(2): await process_frame
	print("HUD_REBROADCAST_SCENARIOS ", JSON.stringify({"pass":failures.is_empty(),"results":results,"errors":failures}))
	quit(0 if failures.is_empty() else 1)
