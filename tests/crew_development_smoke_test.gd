extends SceneTree
## Run in Godot 4: godot --headless --path . --script res://tests/crew_development_smoke_test.gd
## In-memory simulation only: does not modify the user's saved garage.
const RaceScript = preload("res://scripts/race_engine.gd")
const GarageScript = preload("res://scripts/garage.gd")

func _initialize() -> void:
	call_deferred("_run")

func _perform_single_stop(race, player: Dictionary) -> void:
	race.pit_incidents_enabled = false
	var id: int = int(player["id"])
	player["progress"] = 0.949
	race.order_pit(id, "Duro" if str(player["tire"]) != "Duro" else "Macio")
	race.running = true
	for i in range(700):
		race.step(0.2)
		if int(player["stops"]) == 1 and float(player["pit_left"]) <= 0.0:
			return
	assert(false, "single stop did not finish")

func _run() -> void:
	var json: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	assert(typeof(json) == TYPE_DICTIONARY)
	var season: Dictionary = json
	var track: Dictionary = season["tracks"][11]
	var team := "Ferrari"
	var car_parts := {"Motor": 0, "Asa": 0, "Chassi": 0}
	var crew_base := {"Agilidade": 0, "Precisão": 0, "Coordenação": 0}
	var crew_trained := {"Agilidade": 2, "Precisão": 3, "Coordenação": 1}
	var base = RaceScript.new(season["teams"], team, 127, car_parts, track, crew_base)
	var trained = RaceScript.new(season["teams"], team, 127, car_parts, track, crew_trained)
	var base_effect: Dictionary = base.get_pit_crew_effects()
	var effect: Dictionary = trained.get_pit_crew_effects()
	assert(is_equal_approx(float(base_effect["service_saving"]), 0.0))
	assert(absf(float(effect["service_saving"]) - 0.56) < 0.001)
	assert(absf(float(effect["dock_saving"]) - 0.18) < 0.001)
	assert(float(effect["fault_chance"]) < float(base_effect["fault_chance"]))
	assert(float(effect["unsafe_chance"]) < float(base_effect["unsafe_chance"]))
	var base_p: Dictionary = base.player_cars()[0]
	var trained_p: Dictionary = trained.player_cars()[0]
	_perform_single_stop(base, base_p)
	_perform_single_stop(trained, trained_p)
	assert(float(trained_p["pit_last_service"]) < float(base_p["pit_last_service"]))
	assert(absf(float(base_p["pit_last_service"]) - float(trained_p["pit_last_service"]) - 0.56) < 0.02)
	assert(absf(float(base_p["pit_last_total"]) - float(trained_p["pit_last_total"]) - 0.74) < 0.03)
	assert(float(base_p["pit_last_wait"]) == 0.0)
	assert(float(trained_p["pit_last_wait"]) == 0.0)
	assert(base.pit_crew_owner.is_empty() and trained.pit_crew_owner.is_empty())
	assert(str(base_p["tire"]) == str(trained_p["tire"]))
	var garage = GarageScript.new()
	# Read-only check; buy_crew() is exercised in the actual game's UI.
	assert(garage.crew_next_cost("__APEX_CREW_SMOKE_IN_MEMORY__", "Agilidade") == 240000)
	print("APEX CREW DEVELOPMENT OK: -0.56s service, -0.18s docking, lower incident chance, same pit lane")
	quit(0)
