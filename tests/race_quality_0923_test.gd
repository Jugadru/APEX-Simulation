extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Audit = preload("res://scripts/core/racecraft_audit_0662.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		printerr("RACE_QUALITY_FAIL " + label)

func fixture_contract(race) -> void:
	var audit = Audit.new()
	audit.reset(race)
	var a: Dictionary = race.cars[0]
	var b: Dictionary = race.cars[1]
	audit.observe(race, 1)
	verify(audit.quality_report().observed_ticks == 1, "initial observed tick")
	verify(audit.quality_report().counts.reverse_on_track == 0, "negative grid positions allowed")
	var original: Array = race.cars.duplicate(true)
	a.progress = float(a.progress) - 0.001
	a.wear = 101.0
	a.race_lane = NAN
	a.pit_left = -1.0
	a.gap = -0.1
	b.position = a.position
	b.id = a.id
	var before: Dictionary = race.cars[0].duplicate(true)
	audit.observe(race, 2)
	var q: Dictionary = audit.quality_report()
	for kind in ["reverse_on_track", "tyre_wear_out_of_range", "nonfinite_state", "negative_pit_time", "negative_gap", "duplicate_position", "duplicate_driver_id"]:
		verify(int(q.counts[kind]) >= 1, "detect " + kind)
	verify(is_nan(float(a.race_lane)) and a.progress == before.progress and a.wear == before.wear, "observer cannot repair state")
	audit.observe(race, 2)
	verify(audit.quality_report() == q, "same tick is idempotent")
	var detached: Dictionary = audit.quality_report()
	detached.counts.reverse_on_track = 999
	verify(audit.quality_report().counts.reverse_on_track != 999, "report detached")
	race.cars = original
	audit.reset(race, 10)
	a = race.cars[0]
	a.pit_left = 4.0
	a.progress = float(a.progress) - 0.001
	audit.observe(race, 11)
	a.pit_left = 0.0
	a.progress = float(a.progress) - 0.001
	audit.observe(race, 12)
	a.finished = true
	a.progress = float(a.progress) - 0.001
	audit.observe(race, 13)
	verify(audit.quality_report().counts.reverse_on_track == 0, "pit entry exit and finish not reverse evidence")
	a.finished = false
	audit.observe(race, 14)
	a.progress = float(a.progress) - 0.001
	audit.observe(race, 16)
	q = audit.quality_report()
	verify(q.counts.reverse_on_track == 0 and q.missed_ticks == 1 and q.coverage == "partial", "no comparison across missing tick")
	a.wear = 101.0
	for tick in range(17, 117):
		audit.observe(race, tick)
	q = audit.quality_report()
	verify(q.samples.size() == Audit.QUALITY_SAMPLE_LIMIT and q.counts.tyre_wear_out_of_range == 100, "sample ring bounded, full counts retained")
	var copy = Audit.new()
	copy.reset(race, 116)
	copy.restore_quality_snapshot(audit.quality_snapshot())
	verify(copy.quality_snapshot() == audit.quality_snapshot(), "detached session snapshot")

func behaviour_contract(race) -> void:
	var audit = Audit.new()
	var car: Dictionary = race.cars[0]
	var original: Array = race.cars.duplicate(true)
	var id: int = int(car.id)
	car.combat_passes = 7
	audit.reset(race)
	car.combat_passes = 9
	car.race_space_blocked = true
	race._event("pass", id, "ULTRAPASSAGEM CONFIRMADA | Fixture", 85)
	audit.observe(race, 1)
	audit.observe(race, 2)
	audit.observe(race, 3)
	var r: Dictionary = audit.behaviour_report()
	verify(r.pass_event_signals == 1 and r.observed_pass_counter_delta == 2, "one signal may represent two confirmed passes")
	verify(r.drivers[id].blocked_segments == 1 and r.drivers[id].longest_blocked_run_ticks == 3, "three consecutive blocked ticks")
	audit.observe(race, 3)
	verify(audit.behaviour_report() == r, "same tick cannot duplicate behaviour")
	car.combat_passes = 12
	audit.observe(race, 5)
	r = audit.behaviour_report()
	verify(r.observed_pass_counter_delta == 2 and r.missed_ticks == 1 and r.compared_ticks == 3, "missing tick is not invented pass evidence")
	verify(r.drivers[id].blocked_segments == 2 and r.drivers[id].current_blocked_run_ticks == 1, "gap breaks blocked run")
	car.pit_left = 3.0
	audit.observe(race, 6)
	verify(audit.behaviour_report().drivers[id].current_blocked_run_ticks == 0, "pit terminates blocked run")
	car.pit_left = 0.0
	car.finished = true
	audit.observe(race, 7)
	verify(audit.behaviour_report().drivers[id].blocked_observed_ticks == 4, "finish excludes blocked tick")
	car.finished = false
	car.disqualified = true
	audit.observe(race, 8)
	verify(audit.behaviour_report().drivers[id].blocked_observed_ticks == 4, "disqualification excludes blocked tick")
	car.disqualified = false
	car.combat_passes = 1
	audit.observe(race, 9)
	r = audit.behaviour_report()
	verify(r.pass_counter_resets == 1 and r.observed_pass_counter_delta == 2, "counter reset is not a negative overtake")
	var snapshot: Dictionary = audit.behaviour_snapshot()
	var copy = Audit.new()
	copy.reset(race,9)
	copy.restore_behaviour_snapshot(snapshot)
	verify(copy.behaviour_snapshot() == snapshot, "behaviour snapshot round trip")
	r.drivers[id].pass_delta = 999
	verify(audit.behaviour_report().drivers[id].pass_delta == 2, "behaviour report detached")
	verify(car.combat_passes == 1 and car.race_space_blocked, "diagnostics never repair sporting inputs")
	race.cars = original

func real_contract(season: Dictionary, track: Dictionary, climate: String) -> void:
	var monitored = Replay.new()
	var bare = Replay.new()
	var race = Race.new(season.teams, "Ferrari", 923, {}, track, {})
	var other = Race.new(season.teams, "Ferrari", 923, {}, track, {})
	race.configure_weather(climate)
	other.configure_weather(climate)
	monitored.attach(race)
	bare.racecraft_audit_enabled = false
	bare.attach(other)
	verify(race.cars.size() == 24, climate + " grid")
	for tick in range(80):
		if not monitored.step_tick() or not bare.step_tick():
			verify(false, climate + " step " + str(tick))
			return
		verify(monitored.hashes[-1] == bare.hashes[-1], climate + " exact hash " + str(tick))
	var behaviour: Dictionary = monitored.racecraft_report().behaviour
	var actual_passes: int = 0
	for car in race.cars:
		actual_passes += int(car.get("combat_passes",0))
	verify(behaviour.observed_pass_counter_delta == actual_passes and behaviour.compared_ticks == 80, climate + " engine counter parity")
	var q: Dictionary = monitored.racecraft_report().quality
	verify(q.observed_ticks == 80 and q.missed_ticks == 0 and q.coverage == "from_start", climate + " coverage")
	for kind in ["grid_size_changed", "invalid_driver_id", "duplicate_driver_id", "invalid_position", "duplicate_position", "nonfinite_state", "tyre_wear_out_of_range", "negative_pit_time", "negative_gap", "reverse_on_track"]:
		verify(q.counts[kind] == 0, climate + " no " + kind)
	var replay = Replay.new()
	if not replay.load_data(monitored.export_data()):
		verify(false, climate + " replay load")
		return
	verify(replay.seek(80), climate + " seek forward")
	verify(replay.racecraft_report().quality == q, climate + " replay diagnostics parity")
	verify(replay.racecraft_report().behaviour == behaviour, climate + " behaviour replay parity")
	verify(replay.seek(0), climate + " seek rewind")
	verify(replay.racecraft_report().quality.observed_ticks == 0, climate + " reset coverage")
	verify(replay.seek(80), climate + " hot seek")
	verify(replay.racecraft_report().quality == q, climate + " hot diagnostics parity")
	verify(replay.racecraft_report().behaviour == behaviour, climate + " hot behaviour parity")
	verify(Codec.sporting_hash(replay.race, replay.policy) == monitored.hashes[-1], climate + " final sporting parity")

func run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/apex_lab_track.json"))
	var race = Race.new(season.teams, "Ferrari", 923, {}, track, {})
	fixture_contract(race)
	var behaviour_race = Race.new(season.teams, "Ferrari", 923, {}, track, {})
	behaviour_contract(behaviour_race)
	for climate in ["Seco", "Chuva intensa"]:
		real_contract(season, track, climate)
	print("RACE_QUALITY_0923_REPORT ", JSON.stringify({"checks": checks, "failures": failures, "synthetic_track": true, "ticks_per_climate": 80}))
	if failures.is_empty():
		print("RACE_QUALITY_0923_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
