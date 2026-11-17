extends SceneTree
## Optional complete physics check on Godot:
## godot --headless --path . --script res://tests/core_0625_china_long_run.gd
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var china: Dictionary = {}
	for entry in season["tracks"]:
		if str(entry["code"]) == "CHN":
			china = entry
			break
	assert(not china.is_empty())
	var race = RaceScript.new(season["teams"], "Ferrari", 12345, {}, china, {})
	race.configure_weather("Seco")
	race.running = true
	for tick in range(2700):
		if race.finished:
			break
		race.step(4.0)
	assert(race.finished, "China full run did not finish")
	var ai_count: int = 0
	var violations: int = 0
	var max_pits: int = 0
	for car in race.cars:
		if str(car["team"]) == "Ferrari":
			continue
		ai_count += 1
		if bool(car.get("tyre_rule_violation", false)):
			violations += 1
		max_pits = maxi(max_pits, int(car.get("stops", 0)))
		assert((car.get("used_tires", []) as Array).has("Macio") and (car.get("used_tires", []) as Array).has("Médio"),
			"China dry AI failed to use both slicks: %s" % str(car["name"]))
		assert(int(car.get("stops", 0)) <= 4, "Too many China dry stops: %s" % str(car["name"]))
	assert(ai_count > 0 and violations == 0)
	print("APEX 0.6.2.5 CHINA PASS: %d AI drivers; max pits %d; no single-compound AI result" % [ai_count, max_pits])
	quit(0)
