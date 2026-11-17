extends SceneTree
## Godot 4.7.2 headless: --script res://tests/core_0570_ai_director_smoke_test.gd
const AIDirector = preload("res://scripts/core/race_ai_director.gd")
const WeatherScript = preload("res://scripts/core/race_weather.gd")
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/tyres_2012.json"))
	var specs: Dictionary = data["compounds"]
	var available: Array = ["Médio", "Duro", "Intermediário", "Chuva"]
	var w: Dictionary = {"wetness_factor": 0.92}
	var car: Dictionary = {"id": 3, "name": "Piloto teste", "team": "Outra", "tire": "Chuva",
		"wear": 99.0, "stint_laps": 19, "laps_done": 14, "pace": "Normal",
		"track_wear_factor": 1.0, "interval": 3.2,
		"pit_request": false, "pit_left": 0.0, "finished": false}
	var first: Dictionary = AIDirector.plan(car, 44, available, specs, w, w, w, 21.8)
	var again: Dictionary = AIDirector.plan(car, 44, available, specs, w, w, w, 21.8)
	assert(first == again, "The strategy planner must be deterministic")
	assert(bool(first["pit_now"]) and str(first["compound"]) == "Chuva",
		"99% W in heavy rain must replace W with fresh W")
	var in_use: Dictionary = car.duplicate(true)
	in_use["pit_request"] = true
	var ordered: Dictionary = AIDirector.plan(in_use, 44, available, specs, w, w, w, 21.8)
	assert(not bool(ordered["pit_now"]), "Never overwrite an existing pit request")
	car["tire"] = "Intermediário"
	car["wear"] = 97.0
	var middle: Dictionary = {"wetness_factor": 0.48}
	var inters: Dictionary = AIDirector.plan(car, 44, available, specs, middle, middle, middle, 21.8)
	assert(bool(inters["pit_now"]) and str(inters["compound"]) == "Intermediário",
		"97% I on intermediate track needs another set of I")
	car["laps_done"] = 43
	var final_lap: Dictionary = AIDirector.plan(car, 44, available, specs, middle, middle, middle, 21.8)
	assert(not bool(final_lap["pit_now"]), "No pit order after final pit entry")
	car["laps_done"] = 10
	car["stint_laps"] = 8
	car["tire"] = "Chuva"
	car["wear"] = 30.0
	var normal: Dictionary = AIDirector.plan(car, 44, available, specs, middle, middle, middle, 21.8, false)
	var stacked: Dictionary = AIDirector.plan(car, 44, available, specs, middle, middle, middle, 21.8, true)
	assert(bool(normal["pit_now"]), "A wet-to-intermediate crossover should offer a pit")
	assert(bool(stacked["deferred"]) and not bool(stacked["pit_now"]),
		"A noncritical stop should be delayed if teammate is already occupying the box")
	car["wear"] = 99.0
	var emergency: Dictionary = AIDirector.plan(car, 44, available, specs, w, w, w, 21.8, true)
	assert(bool(emergency["pit_now"]), "Double stack avoidance must never block a critical tyre")

	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var belgium: Dictionary = {}
	for venue in season["tracks"]:
		if str(venue.get("code", "")) == "BEL":
			belgium = venue
			break
	assert(not belgium.is_empty())
	var climate = WeatherScript.new()
	climate.setup(belgium, 912, "Variável")
	climate.advance(25.0, 25.0, 0.03)
	var before: Dictionary = climate.snapshot()
	var f1: Dictionary = climate.forecast(25.0, 650.0)
	var f2: Dictionary = climate.forecast(25.0, 650.0)
	assert(f1 == f2 and before == climate.snapshot(), "Forecast must not mutate the actual weather")
	assert(float(f1["wetness_factor"]) >= 0.0 and float(f1["wetness_factor"]) <= 1.0)

	var race = RaceScript.new(season["teams"], "Ferrari", 912, {}, belgium, {})
	race.configure_weather("Chuva intensa")
	race.weather.wetness = 0.95
	race.weather.state = race.weather._make_state(190.0, 0.2)
	var ours: Dictionary = race.player_cars()[0]
	ours["tire"] = "Chuva"
	ours["wear"] = 99.0
	ours["stint_laps"] = 18
	ours["laps_done"] = 12
	var my_advice: Dictionary = race.get_engineer_advice(int(ours["id"]))
	assert(bool(my_advice["pit_now"]) and str(my_advice["compound"]) == "Chuva")
	assert(not bool(ours["pit_request"]), "The human engineer must not order a pit")
	var rival: Dictionary = {}
	for candidate in race.cars:
		if str(candidate["team"]) != "Ferrari":
			rival = candidate
			break
	assert(not rival.is_empty())
	rival["tire"] = "Chuva"
	rival["wear"] = 99.0
	rival["stint_laps"] = 18
	rival["laps_done"] = 12
	race._request_ai_pit(rival, true)
	assert(bool(rival["pit_request"]) and str(rival["pit_target"]) == "Chuva")
	print("APEX 0.5.7.0 PASS: predictive plan, I/W, double stack, user engineer, weather forecast and AI integration")
	quit(0)
