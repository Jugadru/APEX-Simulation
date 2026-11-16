extends SceneTree
## Real Godot 4.7.2 tests for new independent rain, surface moisture and water level.
const Weather = preload("res://scripts/core/race_weather.gd")
const Gate = preload("res://scripts/core/race_rain_hysteresis_0642.gd")
const Race = preload("res://scripts/race_engine.gd")
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("run")
func ok(value: bool, label: String) -> void:
	if not value:
		failures.append(label)
		printerr("APEX 0643 FAILURE ", label)
func run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = season["tracks"][1]
	var simulator = Weather.new()
	simulator.setup(track, 321, "Seco")
	var dry: Dictionary = simulator.advance(4.0, 4.0, 0.0)
	ok(float(dry["water_mm"]) <= 0.00001 and float(dry["rain_intensity"]) == 0.0, "dry stays dry")
	ok(float(dry["surface_moisture"]) == 0.0, "no fabricated moisture in dry mode")
	# Create a deterministic test shower independent of a driver's RNG.
	simulator.setup(track, 321, "Automático")
	simulator.rain_events.clear()
	simulator.rain_events.append({"start": 10.0, "duration": 1200.0, "power": 0.91})
	var max_rain: float = 0.0
	var max_water: float = 0.0
	var raining: Dictionary = {}
	var end_shower: Dictionary = {}
	for i in range(380):
		var current: float = float(i+1)*4.0
		var state: Dictionary = simulator.advance(4.0,current, current/5000.0)
		max_rain = maxf(max_rain, float(state["rain_intensity"]))
		max_water = maxf(max_water, float(state["water_mm"]))
		if current >= 580.0 and current <= 584.0:
			raining = state.duplicate(true)
		if current >= 1230.0 and current <= 1234.0:
			end_shower = state.duplicate(true)
	ok(max_rain > 0.8 and max_water > 2.0, "storm builds standing water")
	ok(float(raining.get("water_mm", 0.0)) > 0.0 and float(raining.get("surface_moisture", 0.0)) > 0.0, "rain and moisture separately computed")
	ok(float(end_shower.get("rain_intensity", 99.0)) < 0.01 and float(end_shower.get("water_mm", 0.0)) > 0.4, "rain ends but water remains on asphalt")
	ok(float(end_shower.get("off_line_water_mm", 0.0)) >= float(end_shower.get("water_mm", 99.0)), "racing line dries ahead of off-line asphalt")
	var saved: Dictionary = simulator.snapshot()
	var forecast: Dictionary = simulator.forecast(1520.0, 240.0)
	ok(simulator.snapshot() == saved, "forecast does not mutate current conditions")
	for i in range(60):
		simulator.advance(4.0, 1520.0+4.0*float(i+1), 0.5)
	ok(absf(float(simulator.snapshot()["water_mm"]) - float(forecast["water_mm"])) < 0.04, "forecast and actual integrated water match")
	ok(float(simulator.snapshot()["surface_moisture"]) >= 0.0, "residual moisture valid")
	# Wet tyres chosen for water, never just for falling rain.
	ok(not bool(Gate.validate("Médio", "Intermediário", 20.0, false, 0.02, 0.95, 0.04, 0.10, 0.20, 0.4)["allowed"]), "rain alone cannot command intermediates")
	ok(bool(Gate.validate("Médio", "Intermediário", 20.0, false, 0.40, 0.65, 0.56, 2.0, 2.8, 0.9)["allowed"]), "enough water allows intermediates")
	ok(not bool(Gate.validate("Intermediário", "Chuva", 25.0, false, 0.50, 0.9, 0.67, 2.5, 3.4, 0.9)["allowed"]), "wet tyre blocked before full-water crossover")
	ok(bool(Gate.validate("Intermediário", "Chuva", 25.0, false, 0.83, 0.8, 0.85, 4.15, 4.25, 1.0)["allowed"]), "full wets allowed with standing water")
	ok(not bool(Gate.validate("Chuva", "Intermediário", 25.0, false, 0.82, 0.0, 0.54, 4.10, 2.7, 0.9)["allowed"]), "forecast alone cannot force premature exit from wets")
	ok(bool(Gate.validate("Intermediário", "Médio", 25.0, false, 0.07, 0.0, 0.05, 0.35, 0.24, 0.1)["allowed"]), "slicks allowed after track genuinely dries")
	ok(bool(Gate.validate("Intermediário", "Médio", 95.0, true, 0.80, 0.7, 0.8, 4.0, 4.0, 1.0)["allowed"]), "emergency wear not blocked by crossover")
	# A manual future stop remains protected while real rain is simulated.
	var four_teams: Array = [season["teams"][0], season["teams"][1]]
	var race = Race.new(four_teams, str(four_teams[0]["name"]), 321, {}, season["tracks"][0], {})
	race.configure_weather("Automático")
	var player: Dictionary = race.player_cars()[0]
	var cid: int = int(player["id"])
	ok(race.schedule_pit(cid, str(race.available_pit_compounds()[1]), 21), "V21 manual reserved")
	race.running = true
	for i in range(30):
		race.step(4.0)
	ok(int(player["pit_scheduled_lap"]) == 21 and not bool(player["pit_request"]), "V21 unaffected by water engine")
	# Actual 2D HUD should expose both measured moisture and line water.
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game._start_race()
	await process_frame
	game.race_hud_0620.refresh_hud()
	ok(game.race_hud_0620.weather_line.text.contains("mm") and game.race_hud_0620.weather_line.text.contains("Úmida"), "real HUD exposes independent water and moisture")
	if failures.is_empty():
		print("APEX 0643 DYNAMIC TRACK PASS: rainfall != asphalt water, on/off line, moisture, forecast, crossover, emergency, V21, HUD")
		quit(0)
	else:
		print("APEX 0643 DYNAMIC TRACK FAILED ", failures)
		quit(1)
