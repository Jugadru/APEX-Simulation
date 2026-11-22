extends SceneTree
## APEX 06694: Soul 3.0 facts -> tactical judgment and radio, never covert pit.
const Soul3 = preload("res://scripts/core/race_driver_soul_06694.gd")
const Soul2 = preload("res://scripts/core/race_driver_soul_0647.gd")
const Dynamics = preload("res://scripts/core/race_driver_dynamics_0661.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var errors: Array[String] = []
var checks: int = 0

func verify(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		errors.append(reason)
		printerr("DRIVER_SOUL_06694_FAIL: " + reason)

func car(id: int) -> Dictionary:
	return {"id": id, "name": "Piloto Teste", "team": "Equipe A",
		"laps_done": 0, "position": 6, "interval": 0.9,
		"last_lap": 0.0, "best_lap": 9999.0, "wear": 0.0,
		"tire": "Médio", "pit_request": false, "pit_scheduled_lap": 0,
		"pit_left": 0.0, "finished": false, "pace": "Normal",
		"stint_laps": 0, "progress": 0.350, "race_lane": 0.0,
		"skill": 84, "risk_tolerance": 65.0,
		"spatial_awareness": 89.0, "defense_aggression": 60.0,
		"attack_charge": 2.0, "race_defending_against": -1,
		"race_defense_line": 0.0}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var wet: Dictionary = {"wetness_factor": 0.75}
	var driver: Dictionary = car(4)
	var base: Dictionary = driver.duplicate(true)
	var init: Dictionary = Soul3.initial(driver)
	verify(str(init.get("version", "")) == "3.0", "Soul3 stamped on new drivers")
	verify(var_to_bytes(init) == var_to_bytes(Soul3.initial(driver)), "Initial traits are deterministic")
	verify(var_to_bytes(driver) == var_to_bytes(base), "Initial assessment does not modify a car")
	driver["driver_soul"] = init
	driver["laps_done"] = 4
	driver["wear"] = 78.0
	driver["last_lap"] = 104.0
	driver["best_lap"] = 100.0
	driver["pit_scheduled_lap"] = 21
	var report: Dictionary = Soul3.update(driver, wet)
	verify(str(report.get("kind", "")) == "revisar_plano", "Real booked V21 and wet tyres prompt review")
	verify(str(report.get("message", "")).contains("V21"), "Radio explains actual booked lap")
	verify(int(driver.get("pit_scheduled_lap", -1)) == 21 and not bool(driver.get("pit_request", true)),
		"Radio never creates/cancels a pit order")
	verify(str(driver.get("pace", "")) == "Normal", "Radio never changes pace")
	verify(str(driver.driver_soul.racing_intent) in ["GERIR_PNEUS", "CAUTELA"], "Soul3 chooses justified caution")
	var before: PackedByteArray = var_to_bytes(driver)
	verify(Soul3.update(driver, wet).is_empty(), "No repeated radio on same lap")
	verify(var_to_bytes(driver) == before, "No duplicate lap update or mutation")
	verify(str(Soul3.summary(driver)).contains("SOUL 3.0"), "Soul3 identified in summary")
	# Different personalities must alter *only* the threshold to commit,
	# not target speed, grip, weather, track, control mode or pit requests.
	var leader: Dictionary = car(5)
	leader["progress"] = 0.361
	var confident: Dictionary = car(6)
	confident["driver_soul"] = Soul3.initial(confident)
	confident["driver_soul"]["confidence"] = 0.90
	confident["driver_soul"]["focus"] = 0.94
	confident["driver_soul"]["pressure"] = 0.05
	confident["driver_soul"]["initiative"] = 0.85
	confident["driver_soul"]["perceived_wear"] = 8.0
	confident["wear"] = 8.0
	var stressed: Dictionary = confident.duplicate(true)
	stressed["driver_soul"]["confidence"] = 0.28
	stressed["driver_soul"]["focus"] = 0.52
	stressed["driver_soul"]["pressure"] = 0.84
	stressed["driver_soul"]["initiative"] = 0.32
	stressed["driver_soul"]["perceived_wear"] = 54.0
	var dry: Dictionary = {"wetness_factor": 0.0}
	var track: Dictionary = {"race_width_m": 14.0, "overtake_zones": [[0.0, 1.0]]}
	var confident_before: PackedByteArray = var_to_bytes(confident)
	var stressed_before: PackedByteArray = var_to_bytes(stressed)
	var good: Dictionary = Dynamics.choose(confident, leader, 15.0, 0.18, 2.95, track, dry, true)
	var bad: Dictionary = Dynamics.choose(stressed, leader, 15.0, 0.18, 2.95, track, dry, true)
	verify(float(good.threshold_s) < float(bad.threshold_s), "Confidence/focus changes actual attack threshold")
	verify(bool(good.commit) and not bool(bad.commit), "Same realistic pace produces different sporting commitment")
	verify(Dynamics.choose(confident, leader, 15.0, 0.18, 2.95, track, dry, false).threshold_s ==
		Dynamics.choose(stressed, leader, 15.0, 0.18, 2.95, track, dry, false).threshold_s,
		"Legacy Soul2 does not change traffic dynamics")
	verify(Soul3.attack_bias(confident, dry) < Soul3.attack_bias(stressed, dry), "Personality bias is monotonic")
	verify(var_to_bytes(confident) == confident_before and var_to_bytes(stressed) == stressed_before,
		"Judgment function does not mutate drivers")
	verify(is_equal_approx(Soul3.attack_bias(car(7), dry), 0.0), "No Soul3 fields means no bias")
	# Current 018 retains Soul3; old 017/016 continue with their historical queue and Soul rules.
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var current_engine = Race.new(season.teams, "Ferrari", 6694, {}, season.tracks[0], {})
	var session = Replay.new()
	session.attach(current_engine)
	verify(not Codec.capture(current_engine).engine.has("driver_soul3_enabled"), "Session feature flag not serialized")
	verify(str(session.export_data().simulation_revision) == Replay.SIMULATION_REVISION, "Current sporting revision is 018 with Soul3")
	for tick in range(120):
		if not session.step_tick():
			verify(false, "Current replay recording failed: " + session.error)
			break
	var fresh: Dictionary = session.export_data()
	var loaded = Replay.new()
	verify(loaded.load_data(fresh), "New Soul3 replay loads")
	verify(loaded.race != null and bool(loaded.race.driver_soul3_enabled), "New Soul3 replay enables its own physics")
	verify(loaded.seek(session.tick), "New replay reproduces all tick hashes")
	verify(loaded.first_divergence < 0, "No replay desync")
	var old_engine = Race.new(season.teams, "Ferrari", 6693, {}, season.tracks[0], {})
	for old_car in old_engine.cars:
		old_car["driver_soul"] = Soul2.initial(old_car)
	var old_session = Replay.new()
	old_session.attach(old_engine)
	old_engine.driver_soul3_enabled = false
	old_engine.pit_coordination2_enabled = false
	old_engine.race_start_intelligence_enabled = false
	old_session.legacy_start_intelligence = true
	old_session.legacy_soul_physics = true
	old_session.legacy_pit_coordination = true
	old_session.recorded_simulation_revision = Replay.TRAFFIC_SIMULATION_REVISION
	old_session.checkpoints = [old_session.checkpoint()]
	for tick in range(120):
		if not old_session.step_tick():
			verify(false, "Legacy recording failed: " + old_session.error)
			break
	var old_payload: Dictionary = old_session.export_data()
	var old_loaded = Replay.new()
	verify(old_loaded.load_data(old_payload), "Historical 016 replay accepted")
	verify(not bool(old_loaded.race.driver_soul3_enabled), "Historical 016 replay keeps Soul2 tactical behavior")
	verify(bool(old_loaded.race.driver_traffic_enabled), "Historical 016 replay retains Driver Traffic 9.3")
	verify(not bool(old_loaded.race.pit_coordination2_enabled), "Historical 016 replay retains legacy pit queue physics")
	verify(old_loaded.seek(old_session.tick) and old_loaded.first_divergence < 0, "Historical 016 replay hashes reproduce")
	verify(str(old_loaded.export_data().simulation_revision) == Replay.TRAFFIC_SIMULATION_REVISION, "Re-export does not relabel older archives")
	if errors.is_empty():
		print("DRIVER_SOUL_06694_PASS ", {"checks": checks, "legacy": true, "radio": true, "sporting": true})
		quit(0)
	else:
		quit(1)
