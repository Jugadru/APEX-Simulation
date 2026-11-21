extends SceneTree
## Improvement 15: real Godot setup trade-off and pre-race locking contracts.
const Setup = preload("res://scripts/core/race_weather_setup_15.gd")
const Race = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(reason: String) -> void:
	printerr("WEATHER_SETUP_15_FAIL " + reason)
	quit(1)

func _run() -> void:
	var neutral: Dictionary = Setup.neutral()
	var dry: Dictionary = {"wetness_factor":0.0,"surface_lateral_load":1.0,
		"surface_traction":1.0,"grip_factor":1.0}
	var wet: Dictionary = dry.duplicate(true)
	wet["wetness_factor"] = 0.85
	wet["grip_factor"] = 0.74
	var baseline: Dictionary = Setup.evaluate(neutral, dry)
	if absf(float(baseline["pace_delta_s"])) > 0.000001 or absf(float(baseline["wear_scale"]) - 1.0) > 0.000001:
		_fail("Neutral setup must have exactly neutral physics")
		return
	var high_wing: Dictionary = {"wing":1.0,"brake":0.0,"suspension":0.0}
	if not Setup.valid(high_wing) or Setup.valid({"wing":2.0,"brake":0.0,"suspension":0.0}):
		_fail("Setup range/shape validation")
		return
	if not float(Setup.evaluate(high_wing, wet)["pace_delta_s"]) < float(Setup.evaluate(high_wing, dry)["pace_delta_s"]):
		_fail("Wing must be more useful under wet corner load")
		return
	var soft: Dictionary = {"wing":0.0,"brake":0.0,"suspension":1.0}
	if not float(Setup.evaluate(soft, wet)["pace_delta_s"]) < float(Setup.evaluate(soft, dry)["pace_delta_s"]):
		_fail("Soft suspension must help wet traction and cost dry precision")
		return
	if not float(Setup.evaluate(soft, wet)["wear_scale"]) < 1.0:
		_fail("Wet traction setup must affect tyre wear")
		return
	var raw: String = FileAccess.get_file_as_string("res://data/season_2012.json")
	var season: Variant = JSON.parse_string(raw)
	if not (season is Dictionary):
		_fail("Season fixture missing")
		return
	var track: Dictionary = (season["tracks"][0] as Dictionary).duplicate(true)
	track["laps"] = 10
	track["race_km"] = float(track["lap_km"]) * 10.0
	var race = Race.new(season["teams"], "Ferrari", 15015, {}, track, {})
	var my_cars: Array = race.player_cars()
	if my_cars.size() != 2:
		_fail("Player cars missing")
		return
	var id: int = int(my_cars[0]["id"])
	var requested: Dictionary = {"wing":0.75,"brake":0.2,"suspension":0.6}
	if not race.configure_pre_race_setup(id, requested):
		_fail("Player setup rejected before start")
		return
	if my_cars[0]["race_setup_15"] != requested or not Setup.valid(my_cars[0]["race_setup_15"]):
		_fail("Setup not persisted on actual car state")
		return
	if race.configure_pre_race_setup(id, {"wing":2.0,"brake":0.0,"suspension":0.0}):
		_fail("Invalid setup accepted")
		return
	if race.configure_pre_race_setup(99999, requested):
		_fail("Unknown car setup accepted")
		return
	race.running = true
	if race.configure_pre_race_setup(id, neutral):
		_fail("Mid-race setup edit accepted")
		return
	if my_cars[0]["race_setup_15"] != requested:
		_fail("Invalid call mutated the setup")
		return
	print("WEATHER_SETUP_15_PASS")
	quit(0)
