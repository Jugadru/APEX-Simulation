extends SceneTree
const RaceScript = preload("res://scripts/race_engine.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in season["tracks"]:
		if str(t.get("code", "")) == "BEL":
			track = t
	var race = RaceScript.new(season["teams"], "Ferrari", 141, {}, track, {})
	race.configure_weather("Variável")
	race.running = true
	for i in range(240):
		race.step(4.0)
	var payload: Array = []
	for car in race.cars:
		payload.append({"id": car["id"], "progress": snappedf(float(car["progress"]), 0.000001),
			"wear": snappedf(float(car["wear"]), 0.00001), "tyre": car["tire"],
			"stops": car["stops"], "pit_request": car["pit_request"], "pit_left": snappedf(float(car["pit_left"]), 0.000001)})
	payload.sort_custom(func(a, b): return int(a["id"]) < int(b["id"]))
	print("PARITY_0630=" + JSON.stringify({"time": race.clock, "lap": race.lap, "cars": payload}))
	quit(0)
