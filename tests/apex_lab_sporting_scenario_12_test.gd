extends SceneTree
## Bounded real-track integration contract; no benchmark or full race claim.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const TICKS: int = 90
const SEED: int = 991321
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func verify(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("APEX_LAB_SPORTING_FAIL " + label)
	return ok

func scenario(season: Dictionary, code: String, climate: String) -> Dictionary:
	var track: Dictionary = {}
	for entry in season.tracks:
		if str(entry.code) == code:
			track = entry.duplicate(true)
			break
	if not verify(not track.is_empty(), code + " real track exists"):
		return {}
	var race = Race.new(season.teams, "Ferrari", SEED, {}, track, {})
	race.configure_weather(climate)
	if not verify(race.cars.size() == 24 and race.player_cars().size() == 2, code + " complete grid"):
		return {}
	var driver: Dictionary = race.player_cars()[0]
	var id: int = int(driver.id)
	if not verify(race.set_pit_control_mode(id, "Manual"), code + " manual pit control"):
		return {}
	var compounds: Array = race.available_pit_compounds()
	if not verify(compounds.size() >= 2, code + " legal compounds"):
		return {}
	var target: String = str(compounds[0]) if str(driver.tire) != str(compounds[0]) else str(compounds[1])
	var session = Replay.new()
	session.attach(race)
	if not verify(session.enqueue("set_pace", [id, "Atacar"], 3), code + " pace command accepted"):
		return {}
	if not verify(session.enqueue("schedule_pit", [id, target, 3], 4), code + " V3 booking accepted"):
		return {}
	for tick in range(TICKS):
		if not verify(session.step_tick(), code + " replay tick " + str(tick)):
			return {}
	verify(session.tick == TICKS and not race.finished, code + " bounded sporting interval")
	verify(int(driver.get("pit_scheduled_lap", 0)) == 3 and not bool(driver.get("pit_request", false)),
		code + " booking not anticipated")
	var ids: Dictionary = {}
	for car in race.get_sorted():
		var car_id: int = int(car.id)
		verify(not ids.has(car_id), code + " unique classification")
		ids[car_id] = true
		verify(is_finite(float(car.progress)) and is_finite(float(car.wear)), code + " finite sporting state")
	verify(ids.size() == 24, code + " classification retains 24 drivers")
	var saved: Dictionary = session.export_data()
	var playback = Replay.new()
	if not verify(playback.load_data(saved), code + " replay loads"):
		return {}
	if not verify(playback.seek(TICKS), code + " replay reaches final tick"):
		return {}
	verify(playback.first_divergence < 0 and Codec.sporting_hash(playback.race, playback.policy) == session.hashes[-1],
		code + " exact sporting hash parity")
	verify(playback.seek(30) and playback.seek(TICKS) and playback.first_divergence < 0,
		code + " backward and forward replay seek")
	return {"track": code, "weather": climate, "seed": SEED, "ticks": session.tick,
		"cars": ids.size(), "sporting_hash": session.hashes[-1]}

func _run() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var rows: Array[Dictionary] = []
	if verify(raw is Dictionary, "season data parses"):
		var season: Dictionary = raw
		verify(season.tracks.size() == 20, "2012 calendar unchanged")
		for spec in [["ITA", "Seco"], ["GBR", "Chuva intensa"]]:
			var row: Dictionary = scenario(season, str(spec[0]), str(spec[1]))
			if not row.is_empty():
				rows.append(row)
	verify(rows.size() == 2, "both scenarios executed")
	print("APEX_LAB_SPORTING_RESULT ", JSON.stringify({"schema": 1, "checks": checks, "runs": rows,
		"failures": failures, "limitations": "Two short real-track replay scenarios, not full-race or GPU validation."}))
	if failures.is_empty():
		print("APEX_LAB_SPORTING_12_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
