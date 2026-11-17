extends SceneTree
## Optional long-running integration test for the Godot executable.
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var belgium: Dictionary = {}
	for venue in season["tracks"]:
		if str(venue.get("code", "")) == "BEL":
			belgium = venue
			break
	var sim = RaceScript.new(season["teams"], "Ferrari", 911, {}, belgium, {})
	sim.configure_weather("Chuva intensa")
	sim.running = true
	var worn_seconds: Dictionary = {}
	var longest_worn: float = 0.0
	var counted_stops: int = 0
	for driver in sim.cars:
		worn_seconds[int(driver["id"])] = 0.0
	for step_index in range(940):
		if sim.finished:
			break
		sim.step(4.0)
		for driver in sim.cars:
			if str(driver["team"]) == "Ferrari":
				continue
			var driver_id: int = int(driver["id"])
			if float(driver.get("wear", 0.0)) >= 99.9 and float(driver.get("pit_left", 0.0)) <= 0.0:
				worn_seconds[driver_id] = float(worn_seconds[driver_id]) + 4.0
				longest_worn = maxf(longest_worn, float(worn_seconds[driver_id]))
			else:
				worn_seconds[driver_id] = 0.0
	for driver in sim.cars:
		if str(driver["team"]) != "Ferrari":
			counted_stops += int(driver.get("stops", 0))
	assert(counted_stops > 0, "AI did not use the pit lane")
	assert(longest_worn < 310.0, "AI still stays at 100% wear for too long")
	print("APEX 0.5.7.0 LONG PASS: %.1fs, %d AI stops, %.1fs longest 100%% wear" % [sim.clock, counted_stops, longest_worn])
	quit(0)
