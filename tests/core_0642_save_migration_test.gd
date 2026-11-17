extends SceneTree
## Compatibility: old career and garage saves are upgraded without resetting progress.
const Season = preload("res://scripts/championship_2012.gd")
const Garage = preload("res://scripts/garage.gd")
const TEST := "user://apex_0642_old_career.json"
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST))
	var old = Season.new(TEST)
	assert(old.start_new("Ferrari", 321, fixture["tracks"], fixture["teams"]))
	var grid: Array = []
	for t in fixture["teams"]:
		for driver in t["drivers"]:
			grid.append({"name": driver["name"], "team": t["name"], "best_lap": 95.0, "stops": 2})
	assert(bool(old.record_result(fixture["tracks"][0], grid, 5890.0).get("ok", false)))
	var original: Dictionary = old.state.duplicate(true)
	original.erase("rival_development")
	assert(old._write(original))
	var upgraded = Season.new(TEST)
	assert(upgraded.has_season() and int(upgraded.state["round_index"]) == 1)
	assert(str(upgraded.next_round().get("code", "")) == "MAL")
	assert(upgraded.get_rival_development().size() == 11)
	assert(int(upgraded.state["drivers"]["Fernando Alonso"]) == int(original["drivers"]["Fernando Alonso"]))
	assert(upgraded.save())
	var again = Season.new(TEST)
	assert(again.get_rival_development().size() == 11)
	# Force a schema from older Garage versions (without P&D data).
	var raw_old: Dictionary = {"Ferrari": {"budget": 6500000,
		"levels": {"Motor": 1, "Asa": 2, "Chassi": 0},
		"crew_levels": {"Agilidade": 1, "Precisão": 0, "Coordenação": 1},
		"staff_levels": {"Estrategista": 1, "Engenheiro": 2},
		"championship_awards": {"old-round": 500000}}}
	var stream = FileAccess.open(Garage.SAVE_PATH, FileAccess.WRITE)
	assert(stream != null)
	stream.store_string(JSON.stringify(raw_old))
	stream.close()
	var garage = Garage.new()
	var team: Dictionary = garage.get_team("Ferrari")
	assert(int(team["budget"]) == 6500000)
	assert(int(team["levels"]["Asa"]) == 2)
	assert((team["development_project"] as Dictionary).is_empty())
	assert((team["development_history"] as Array).is_empty())
	assert(int(team["staff_levels"]["Engenheiro"]) == 2)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST))
	print("APEX 0642 SAVE MIGRATION PASS: championship results, garage upgrades, budget and awards retained")
	quit(0)
