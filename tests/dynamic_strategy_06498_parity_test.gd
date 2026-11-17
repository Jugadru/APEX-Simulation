extends SceneTree
## Compare two identical Silverstone native races; chart only reads one.
const Race = preload("res://scripts/race_engine.gd")
const Model = preload("res://scripts/core/race_strategy_graph_data_06498.gd")
var fails: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _check(flag: bool, desc: String) -> void:
	if not flag:
		fails.append(desc)
		printerr("PARITY_06498_FAIL: " + desc)
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in season["tracks"]:
		if str(t.get("code", "")) == "GBR":
			track = t
	var baseline = Race.new(season["teams"], "Ferrari", 6403, {}, track, {})
	var visualized = Race.new(season["teams"], "Ferrari", 6403, {}, track, {})
	baseline.configure_weather("Variável")
	visualized.configure_weather("Variável")
	for car in baseline.player_cars():
		car["pit_control_mode"] = "IA"
	for car in visualized.player_cars():
		car["pit_control_mode"] = "IA"
	var model = Model.new()
	model.reset(visualized)
	_check(JSON.stringify(baseline.get_state_snapshot()) == JSON.stringify(visualized.get_state_snapshot()),"initial race parity")
	baseline.running = true
	visualized.running = true
	for tick in range(360):
		baseline.step(4.0)
		visualized.step(4.0)
		model.capture(visualized)
		for car in visualized.player_cars():
			var snapshot: Dictionary = model.view(visualized,car)
			_check(int(snapshot.get("lap",0)) == int(car.get("laps_done",0)), "lap counter")
		if tick % 36 == 0:
			_check(JSON.stringify(baseline.get_state_snapshot()) == JSON.stringify(visualized.get_state_snapshot()),"engine same with charts tick=" + str(tick))
	_check(JSON.stringify(baseline.get_state_snapshot()) == JSON.stringify(visualized.get_state_snapshot()),"final engine parity")
	if fails.is_empty():
		print("APEX_06498_PARITY_PASS Silverstone live charts have zero influence over race RNG, physics, AI or pits; 360 native 4s ticks")
	quit(0 if fails.is_empty() else 1)
