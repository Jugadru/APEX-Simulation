extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Audit = preload("res://scripts/core/racecraft_audit_0662.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks: int = 0
func _initialize() -> void: call_deferred("run")
func check(condition: bool, message: String) -> void:
	checks += 1
	assert(condition, message)
func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = data.tracks[0].duplicate(true)
	track.laps = 3
	# First validate event interpretation without writing to sporting internals.
	var fixture = Race.new(data.teams, "Ferrari", 662, {}, track, {})
	var a = Audit.new()
	a.reset(fixture)
	var id: int = int(fixture.cars[0].id)
	fixture._event("battle", id, "Test Driver prepara ataque a Rival!", 50)
	fixture._event("battle", id, "Test Driver protege a linha antes do ataque.", 50)
	fixture._event("battle", id, "Test Driver retirou o ataque a Rival: espaço insuficiente na curva.", 50)
	fixture._event("pass", id, "ULTRAPASSAGEM real", 85)
	fixture._event("position_gain", id, "Ganhos por box", 55)
	fixture._event("contact", id, "Contato", 90)
	fixture.cars[0].combat_state = "duel"
	fixture.cars[0].race_space_blocked = true
	a.observe(fixture, 1)
	var counts: Dictionary = a.summary().counts
	for key in ["attack_signals", "defense_signals", "yield_signals", "confirmed_passes", "position_gains_other", "contacts", "duel_entries", "blocked_ticks"]:
		check(int(counts[key]) == 1, "Expected one %s" % key)
	a.observe(fixture, 1)
	check(int(a.summary().counts.confirmed_passes) == 1, "Same tick cannot double-count")
	check(int(a.summary().samples.size()) == 6, "Six classified source events")
	check(int(a.summary().start_tick) == 0, "Full coverage clearly marked")
	a.reset(fixture, 10)
	a.observe(fixture, 11)
	check(int(a.summary().counts.confirmed_passes) == 0, "Checkpoint reset never recounts old events")
	check(a.summary().coverage == "since_checkpoint", "Partial coverage clearly reported")
	# Two independent sport engines; the observer must not impact any sporting hash.
	var engine_on = Race.new(data.teams,"Ferrari",662,{},track,{})
	var engine_off = Race.new(data.teams,"Ferrari",662,{},track,{})
	var monitored = Replay.new()
	var bare = Replay.new()
	monitored.attach(engine_on)
	bare.racecraft_audit_enabled = false
	bare.attach(engine_off)
	check(Codec.sporting_hash(engine_on, monitored.policy) == Codec.sporting_hash(engine_off, bare.policy), "Initial hash parity")
	for i in range(500):
		check(monitored.step_tick() and bare.step_tick(), "Tick %d valid" % i)
		check(monitored.hashes[-1] == bare.hashes[-1], "Observer changed sporting hash tick %d" % i)
	var report: Dictionary = monitored.racecraft_report()
	check(report.schema == "APEX_RACECRAFT_AUDIT_0662", "Report schema")
	check(int(report.end_tick) == monitored.tick and int(report.start_tick) == 0, "Full observed tick range")
	check(int(report.sample_count) <= 256, "Bounded samples")
	check(report.track_code == track.code, "Correct circuit")
	var replay = Replay.new()
	check(replay.load_data(monitored.export_data()), "Existing 0661 replay revision accepted")
	replay.checkpoints = [replay.checkpoints[0]]
	check(replay.seek(monitored.tick), "Replay seek from zero succeeds")
	check(replay.hashes[-1] == monitored.hashes[-1], "Sporting hash identical on playback")
	check(replay.racecraft_report().counts == report.counts, "Telemetry counts deterministic in playback")
	check(replay.racecraft_report().drivers == report.drivers, "Per-driver breakdown deterministic")
	check(replay.seek(0), "Seek back to zero")
	check(int(replay.racecraft_report().end_tick) == 0, "Seeking back clears old statistics")
	check(replay.seek(300), "Seek forward again")
	check(int(replay.racecraft_report().end_tick) == 300, "Seek rebuilds statistics")
	var out: Dictionary = {"version":"0.6.6.2", "checks": checks, "ticks":monitored.tick,
		"final_hash":monitored.hashes[-1], "report":report, "passed":true}
	var f = FileAccess.open("res://qa/racecraft_0662/unit_results.json",FileAccess.WRITE)
	f.store_string(JSON.stringify(out, "  "))
	f.close()
	print("RACECRAFT_0662_UNIT_PASS ", {"checks":checks,"ticks":monitored.tick,"hash":monitored.hashes[-1]})
	quit()
