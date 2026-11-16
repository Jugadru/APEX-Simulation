extends SceneTree
## Teste regressão: pit incident increases wait of team-mate, crew remains exclusive.
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var race = RaceScript.new(season["teams"], "Ferrari", 1125, {"Motor": 0, "Asa": 0, "Chassi": 0}, season["tracks"][11])
	var pair: Array = race.player_cars()
	var first: Dictionary = pair[0]
	var second: Dictionary = pair[1]
	first["progress"] = 0.949
	second["progress"] = 0.946
	# Deterministic incident on the first car. The second has zero risk in this test.
	race.pit_incident_test_overrides[int(first["id"])] = {"service_fault": "Pistola pneumática", "service_delay": 5.5, "release_delay": 0.0}
	race.pit_incident_test_overrides[int(second["id"])] = {"service_fault": "", "service_delay": 0.0, "release_delay": 0.0}
	race.order_pit(int(first["id"]), "Duro")
	# Historical fixture requested Macio at Spa, which is not in this track's
	# compound allocation. Test queue/repair using a legal request instead.
	var legal_compounds: Array = race.available_pit_compounds()
	race.order_pit(int(second["id"]), str(legal_compounds[0]))
	assert(bool(second.pit_request), "fixture must issue an accepted pit request")
	race.running = true
	var saw_queue := false
	var saw_repair := false
	for i in range(900):
		race.step(0.2)
		var stage_a: String = str(first["pit_stage"])
		var stage_b: String = str(second["pit_stage"])
		assert(not (stage_a in ["service", "repair", "safety_hold"] and stage_b in ["service", "repair", "safety_hold"]), "crew occupied by both")
		if stage_a == "repair":
			saw_repair = true
		if stage_b == "queue":
			saw_queue = true
		if int(first["stops"]) == 1 and int(second["stops"]) == 1 and float(first["pit_left"]) <= 0.0 and float(second["pit_left"]) <= 0.0:
			break
	assert(saw_queue and saw_repair, "double stack did not wait while incident repaired")
	assert(float(second["pit_last_wait"]) >= 5.0, "incident did not contribute to waiting")
	assert(absf(float(first["pit_last_extra"]) - 5.5) < 0.03)
	assert(race.pit_crew_owner.is_empty())
	print("PERF_0657 INCIDENT DOUBLE STACK OK: second car waits through mechanical repair")
	quit(0)
