extends SceneTree
## Issue #82 / candidate v0.6.6.9.7.1: dry compulsory stop on last legal lap.
## No sporting outcome is fabricated: all assessments are pure.
const Coordination = preload("res://scripts/core/race_team_pit_coordination_06497.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("PIT_QUEUE_066971_FAIL " + message)

func _car(id: int, position: int, progress: float) -> Dictionary:
	return {"id": id, "name": "Fixture " + str(id), "team": "Rival",
		"pit_control_mode": "IA", "position": position, "progress": progress,
		"wear": 18.0, "stint_laps": 7, "stops": 0, "used_tires": ["Médio"],
		"tire": "Médio", "pit_request": false, "pit_left": 0.0,
		"pit_scheduled_lap": 0, "pitwall49_held": false, "finished": false,
		"laps_done": 7}

func _plan() -> Dictionary:
	return {"planned_pit_lap": 9, "compound": "Duro", "pit_now": false,
		"critical": false, "life_laps": 18.0, "forecast_3": 0.0,
		"forecast_6": 0.0}

func _run() -> void:
	var follower: Dictionary = _car(2, 9, 7.0)
	var leader: Dictionary = _car(1, 5, 7.015)
	var plan: Dictionary = _plan()
	var weather: Dictionary = {"wetness_factor": 0.0, "rain_intensity": 0.0}
	var tyres: Array = ["Médio", "Duro", "Intermediário", "Chuva"]
	var before: PackedByteArray = var_to_bytes([follower, leader, plan, weather])
	var now: Dictionary = Coordination.assess(follower, leader, plan, plan,
		weather, 10, 8, "Ferrari", tyres, true, 8.0, 90.0)
	_check(str(now.get("decision", "")) == "ANTECIPAR" and bool(now.get("executable", false))
		and int(now.get("target_lap", 0)) == 9,
		"compulsory dry V9 pair can safely stagger one car onto V8")
	_check(float(now.get("estimated_queue_s", 0.0)) >= 2.5,
		"pre-entry estimate uses observed teammate gap and physical garage capacity")
	_check(var_to_bytes([follower, leader, plan, weather]) == before,
		"assessment is pure, never changes car state or RNG")
	var old018: Dictionary = Coordination.assess(follower, leader, plan, plan,
		weather, 10, 8, "Ferrari", tyres, false, 8.0, 90.0)
	_check(not bool(old018.get("executable", false)) and str(old018.get("decision", "")) == "MANTER",
		"018 legacy low-wear rule remains unchanged")
	var far: Dictionary = leader.duplicate(true)
	far["progress"] = 7.20
	var distant: Dictionary = Coordination.assess(follower, far, plan, plan,
		weather, 10, 8, "Ferrari", tyres, true, 8.0, 90.0)
	_check(not bool(distant.get("executable", false)),
		"no unnecessary early stop when teammate is far outside garage occupation")
	var already_compliant: Dictionary = follower.duplicate(true)
	already_compliant["used_tires"] = ["Médio", "Duro"]
	var compliant: Dictionary = Coordination.assess(already_compliant, leader, plan, plan,
		weather, 10, 8, "Ferrari", tyres, true, 8.0, 90.0)
	_check(not bool(compliant.get("executable", false)),
		"wear gate not bypassed for a stop that is not compulsory")
	var rain: Dictionary = weather.duplicate(true)
	rain["wetness_factor"] = 0.18
	var wet: Dictionary = Coordination.assess(follower, leader, plan, plan,
		rain, 10, 8, "Ferrari", tyres, true, 8.0, 90.0)
	_check(not bool(wet.get("executable", false)),
		"rainfall blocks tactical dry-stint diversion")
	var critical_plan: Dictionary = plan.duplicate(true)
	critical_plan["critical"] = true
	var critical: Dictionary = Coordination.assess(follower, leader, critical_plan, plan,
		weather, 10, 8, "Ferrari", tyres, true, 8.0, 90.0)
	_check(not bool(critical.get("executable", false)),
		"critical tyres block tactical diversion")
	var manual: Dictionary = follower.duplicate(true)
	manual["team"] = "Ferrari"
	manual["pit_control_mode"] = "Manual"
	var manual_mate: Dictionary = leader.duplicate(true)
	manual_mate["team"] = "Ferrari"
	var no_manual: Dictionary = Coordination.assess(manual, manual_mate, plan, plan,
		weather, 10, 8, "Ferrari", tyres, true, 8.0, 90.0)
	_check(not bool(no_manual.get("executable", false)),
		"never anticipate an explicit manual team's stop")
	var last: Dictionary = plan.duplicate(true)
	last["pit_now"] = true
	var final_entry: Dictionary = Coordination.assess(follower, leader, last, last,
		weather, 10, 9, "Ferrari", tyres, true, 8.0, 90.0)
	_check(not bool(final_entry.get("executable", false)),
		"no postponement from final legal V9 to impossible V10")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var race = Race.new(season["teams"], "Ferrari", 8201, {}, season["tracks"][0], {})
	_check(not Codec.capture(race)["engine"].has("pit_queue_prevention_enabled"),
		"new sporting rule selector is excluded from saved state and hashes")
	var recorded = Replay.new()
	recorded.attach(race)
	recorded.recorded_simulation_revision = Replay.PIT_COORDINATION_SIMULATION_REVISION
	recorded.legacy_pit_queue_prevention = true
	recorded.legacy_start_intelligence = true
	recorded.race.pit_queue_prevention_enabled = false
	recorded.race.race_start_intelligence_enabled = false
	for i in range(14):
		_check(recorded.step_tick(), "018 archive recording tick")
	var archive: Dictionary = recorded.export_data()
	var restored = Replay.new()
	_check(restored.load_data(archive), "018 archive accepted by 019 replay loader")
	if restored.race != null:
		_check(bool(restored.race.pit_coordination2_enabled)
			and not bool(restored.race.pit_queue_prevention_enabled),
			"018 FIFO remains enabled while only 019 strategic prevention is disabled")
		_check(restored.seek(14) and restored.first_divergence < 0,
			"018 replay reproduces sporting hash without new anticipatory rule")
	if failures.is_empty():
		print("PIT_QUEUE_066971_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
