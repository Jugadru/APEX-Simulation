extends SceneTree
## Run in Godot: godot --headless --path . --script res://tests/telemetry_0533_smoke_test.gd
const RaceScript = preload("res://scripts/race_engine.gd")

func _initialize() -> void:
	var loaded: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	assert(typeof(loaded) == TYPE_DICTIONARY, "Season data not found")
	var season: Dictionary = loaded
	var teams: Array = season["teams"]
	var track: Dictionary = season["tracks"][11]
	var upgrades := {"Motor": 1, "Asa": 0, "Chassi": 0}
	var crew := {"Agilidade": 0, "Precisão": 0, "Coordenação": 0}
	var race = RaceScript.new(teams, "Ferrari", 91245, upgrades, track, crew)
	var baseline = RaceScript.new(teams, "Ferrari", 91245, upgrades, track, crew)
	# Same race engine, but no observer: this is the baseline for physics invariance.
	baseline.telemetry = null
	race.running = true
	baseline.running = true
	for i in range(950):
		race.step(4.0)
		baseline.step(4.0)
		assert(is_equal_approx(race.clock, baseline.clock), "observer changed clock")
		for j in range(race.cars.size()):
			var a: Dictionary = race.cars[j]
			var b: Dictionary = baseline.cars[j]
			assert(absf(float(a["progress"]) - float(b["progress"])) < 0.000001, "observer changed progress")
			assert(absf(float(a["wear"]) - float(b["wear"])) < 0.000001, "observer changed tyres")
			assert(int(a["stops"]) == int(b["stops"]), "observer changed pits")
			assert(str(a["tire"]) == str(b["tire"]), "observer changed tyre selection")
		if race.finished:
			break
	var ledger = race.telemetry
	assert(ledger.sector_history.size() > 30, "no sector history")
	assert(ledger.lap_history.size() > 10, "no lap history")
	assert(ledger.position_history.size() > 100, "no position snapshots")
	assert(ledger.event_history.size() >= race.events.size(), "lost events")
	assert(ledger.pit_history.size() == race.pit_history.size(), "pit mirrors disagree")
	for lap_data in ledger.lap_history:
		var total: float = float(lap_data["s1"]) + float(lap_data["s2"]) + float(lap_data["s3"])
		assert(absf(total - float(lap_data["seconds"])) < 0.001, "sector sum mismatch")
		assert(float(lap_data["seconds"]) > 0.0, "bad lap time")
	var previous_event_id := 0
	for event in ledger.event_history:
		assert(int(event["event_id"]) == previous_event_id + 1, "event IDs not sequential")
		previous_event_id = int(event["event_id"])
	var output_folder: String = OS.get_user_data_dir().path_join("testes_telemetria")
	var exported: Dictionary = ledger.export_files(output_folder, {"smoke_test": true})
	assert(bool(exported.get("ok", false)), "export failed")
	assert(exported["files"].size() == 5, "expected 4 CSVs and 1 JSON")
	for filepath in exported["files"]:
		assert(FileAccess.file_exists(str(filepath)), "missing export file")
	print("APEX v0.5.3.3 — OK: telemetry, sectors, CSV/JSON, deterministic gameplay")
	quit(0)
