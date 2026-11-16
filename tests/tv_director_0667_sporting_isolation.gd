extends SceneTree
## Twin live engines, same seed and step stream. Only one has a viewer.
const Race = preload("res://scripts/race_engine.gd")
const Director = preload("res://scripts/tv_director.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in data.tracks:
		if str(t.code) == "GBR": track = t.duplicate(true)
	assert(not track.is_empty())
	track.laps = 3
	var observed = Race.new(data.teams, "Ferrari", 660, {}, track, {})
	var untouched = Race.new(data.teams, "Ferrari", 660, {}, track, {})
	observed.configure_weather("Chuva intensa")
	untouched.configure_weather("Chuva intensa")
	var director = Director.new()
	var selected: Dictionary = {}
	var first_id: int = int(observed.get_sorted()[0]["id"])
	for tick in range(750):
		observed.step(0.2)
		untouched.step(0.2)
		if tick % 4 == 0:
			director.screen_clock += 0.8
			var target: int = director.select(observed, first_id, observed.clock)
			selected[target] = true
		if tick % 100 == 0:
			assert(Codec.sporting_hash(observed, {}) == Codec.sporting_hash(untouched, {}), "TV changed the sport at tick %d" % tick)
	assert(Codec.sporting_hash(observed, {}) == Codec.sporting_hash(untouched, {}))
	assert(Codec.digest(Codec.fields(observed.telemetry)) == Codec.digest(Codec.fields(untouched.telemetry)))
	var report: Dictionary = {"pass":true, "ticks":750, "track":"GBR", "weather":"Chuva intensa", "seed":660, "hash":Codec.sporting_hash(observed, {}), "unique_focal_cars":selected.size(), "telemetry_identical":true, "race_rng_state_identical":observed.rng.state == untouched.rng.state}
	assert(report["race_rng_state_identical"])
	var file := FileAccess.open("res://qa/tv_director_0667/sporting_isolation.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("TV_DIRECTOR_0667_ISOLATION_PASS ", JSON.stringify(report))
	quit(0)
