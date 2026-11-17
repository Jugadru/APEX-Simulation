extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Model = preload("res://scripts/core/race_strategy_graph_data_06498.gd")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		printerr("APEX_06498_DATA_FAIL " + label)
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var circuit: Dictionary = {}
	for item in season["tracks"]:
		if str(item.get("code", "")) == "GBR":
			circuit = item
			break
	check(not circuit.is_empty(), "Silverstone found")
	if circuit.is_empty():
		quit(2)
		return
	var sim = Race.new(season["teams"], "Ferrari", 6403, {}, circuit, {})
	sim.configure_weather("Seco")
	var model = Model.new()
	var before: String = JSON.stringify(sim.get_state_snapshot())
	model.reset(sim)
	check(before == JSON.stringify(sim.get_state_snapshot()), "model reset has no simulation side effects")
	check(model.initial_plans.size() == 2, "pre-race plan for both team drivers")
	for car in sim.player_cars():
		var v: Dictionary = model.view(sim, car)
		check(int(v["lap"]) == 0 and v["history"].size() == 1, "grid sample")
		check(float(v["rate"]) > 0.0, "model reads live wear rate")
	check(before == JSON.stringify(sim.get_state_snapshot()), "view queries do not mutate simulator")
	var c0: Dictionary = sim.player_cars()[0]
	var c1: Dictionary = sim.player_cars()[1]
	var v0: Dictionary = model.view(sim,c0)
	var v1: Dictionary = model.view(sim,c1)
	check(str(Model.garage_status(v0,v1)["kind"]) in ["LIVRE","POTENCIAL"],"garage state at grid")
	var same_lap: int = 12
	v0["scheduled"] = same_lap
	v1["scheduled"] = same_lap
	check(str(Model.garage_status(v0,v1)["kind"]) == "CONFIRMADO", "genuine simultaneous bookings labelled confirmed")
	v1["scheduled"] = 0
	v1["window_start"] = same_lap
	check(str(Model.garage_status(v0,v1)["kind"]) == "POTENCIAL", "advice vs booking only potential")
	v1["window_start"] = 0
	check(str(Model.garage_status(v0,v1)["kind"]) == "LIVRE", "no false conflict")
	# Sample fewer than every lap deliberately: never invent missing samples.
	sim.running = true
	for i in range(105):
		sim.step(4.0)
	model.capture(sim)  # one new sample at last crossed lap
	var history: Array = model.observations[int(c0["id"])]
	check(history.size() == 2, "missing laps never invented")
	check(int(history[-1]["lap"]) > 1,"progressed beyond one lap")
	check(not Model._measured_rate(history) > 0.0, "unobserved increments not used for measured trend")
	var origin: String = JSON.stringify(model.initial_plans)
	model.capture(sim)
	check(JSON.stringify(model.initial_plans) == origin,"initial plans immutable across capture")
	if failures.is_empty():
		print("APEX_06498_DATA_PASS pure read-only snapshots, missing laps, actual engine rate, initial plan and garage conflicts")
	quit(0 if failures.is_empty() else 1)
