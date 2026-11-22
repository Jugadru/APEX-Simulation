extends SceneTree
## APEX v0.6.6.9.7 — physical FIFO pit crew arbitration and legacy replays.
const Coord = preload("res://scripts/core/race_pit_coordination_06697.gd")
const Race = preload("res://scripts/race_engine.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		printerr("PIT_COORD_06697_FAIL " + message)

func _car(id: int, entered_s: float, stage: String, total: float = 20.0) -> Dictionary:
	return {"id":id, "name":"Car " + str(id), "team":"A", "pit_stage":stage,
		"pit_entered_at":entered_s, "pit_nominal_total":total,
		"pit_wait":0.0, "pit_dock_total":2.0, "pit_service_total":3.0,
		"pit_service_delay":0.0, "pit_release_delay":0.0,
		"pit_stage_elapsed":0.0}

func _run() -> void:
	var later: Dictionary = _car(1, 100.15, "approach")
	var first: Dictionary = _car(2, 100.0, "approach")
	var grid: Array = [later, first]
	var previous: PackedByteArray = var_to_bytes(grid)
	check(Coord.eligible(first, grid, {}, 107.0, 0.31), "earliest real arrival has first claim")
	check(not Coord.eligible(later, grid, {}, 107.0, 0.31), "later arrival blocked despite earlier array position")
	grid.reverse()
	check(Coord.eligible(first, grid, {}, 107.0, 0.31) and not Coord.eligible(later, grid, {}, 107.0, 0.31),
		"arrival ownership independent of array ordering")
	grid.reverse()
	check(previous == var_to_bytes(grid), "arbitration never modifies race cars")
	var tie_hi: Dictionary = _car(9, 100.0, "approach")
	var tie_lo: Dictionary = _car(3, 100.0, "approach")
	check(Coord.eligible(tie_lo, [tie_hi, tie_lo], {}, 107.0, 0.31)
		and not Coord.eligible(tie_hi, [tie_hi, tie_lo], {}, 107.0, 0.31),
		"same physical arrival ties broken by stable driver ID")
	check(not Coord.eligible(first, grid, {"A":1}, 107.0, 0.31),
		"occupied garage never acquired by other car")
	check(Coord.eligible(later, grid, {"A":1}, 107.0, 0.31),
		"current garage owner permitted by pure arbitration")
	first["pit_stage"] = "queue"
	check(Coord.eligible(first, grid, {}, 107.0, 0.31),
		"earliest queued car wins against later approach")
	check(not Coord.eligible(later, grid, {}, 106.0, 0.31),
		"approaching car cannot enter before physical arrival")
	var owner: Dictionary = _car(99, 94.0, "safety_hold")
	owner["pit_release_delay"] = 4.5
	owner["pit_stage_elapsed"] = 1.0
	later["pit_stage"] = "queue"
	later["pit_wait"] = 1.4
	first["pit_wait"] = 2.0
	var stats: Dictionary = Coord.status("A", [later, owner, first], {"A":99}, 110.0, 0.31)
	check(bool(stats["release_held"]) and stats["owner_id"] == 99
		and is_equal_approx(float(stats["remaining_occupation_s"]), 3.5),
		"unsafe-release hold reserves same crew for remaining measured duration")
	var waiters: Array = stats["waiting"]
	check(waiters.size() == 2 and int(waiters[0]["id"]) == 2 and int(waiters[1]["id"]) == 1,
		"snapshot queue ordered by actual arrival not car array")
	check(int(waiters[0]["queue_position"]) == 1 and int(waiters[1]["queue_position"]) == 2,
		"ranked queue for each shared garage")
	check(float(waiters[0]["estimated_additional_wait_s"]) <= float(waiters[1]["estimated_additional_wait_s"]),
		"later garage ETA includes earlier queued service")
	check(is_equal_approx(float(waiters[0]["wait"]), 2.0),
		"reported queue delay measured from actual car")
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = season["tracks"][0]
	var race = Race.new(season["teams"], "Ferrari", 697, {}, track, {})
	var original: Dictionary = Codec.capture(race)
	check(not original["engine"].has("pit_coordination2_enabled"),
		"new revision switch excluded from saved and hashed sporting fields")
	var restored = Codec.restore(original)
	check(restored != null and bool(restored.pit_coordination2_enabled),
		"existing save schema stays unchanged after new queue coordinator")
	var pair: Array = race.player_cars()
	var id_a: int = int(pair[0]["id"])
	var id_b: int = int(pair[1]["id"])
	var compound: String = str(race.available_pit_compounds()[0])
	check(race.schedule_pit(id_a, compound, 21), "manual V21 accepted")
	pair[0]["progress"] = 3.94
	race.running = true
	for t in range(32):
		race.step(0.2)
	check(int(pair[0]["pit_scheduled_lap"]) == 21
		and not bool(pair[0]["pit_request"])
		and int(pair[0]["stops"]) == 0,
		"manual V21 not anticipated by rainy or coordination state")
	check(race.cancel_scheduled_pit(id_a), "player can still cancel protected V21")
	var a = Race.new(season["teams"], "Ferrari", 699, {}, track, {})
	var b = Race.new(season["teams"], "Ferrari", 699, {}, track, {})
	var ac: Array = a.player_cars()
	var bc: Array = b.player_cars()
	for i in range(2):
		ac[i]["progress"] = 0.949 if i == 0 else 0.947
		bc[i]["progress"] = float(ac[i]["progress"])
		a.pit_incident_test_overrides[int(ac[i]["id"])] = {
			"service_fault": "", "service_delay": 0.0,
			"release_delay": 4.5 if i == 0 else 0.0}
		b.pit_incident_test_overrides[int(bc[i]["id"])] = a.pit_incident_test_overrides[int(ac[i]["id"])].duplicate(true)
		a.order_pit(int(ac[i]["id"]), compound)
		b.order_pit(int(bc[i]["id"]), compound)
	a.running = true
	b.running = true
	var saw_queue: bool = false
	var saw_hold: bool = false
	var saw_real_release: bool = false
	for tick in range(700):
		a.step(0.2)
		b.step(0.2)
		if tick % 19 == 0:
			# This read path must never influence the race or its replay hashes.
			a.get_team_pit_status("Ferrari")
			a.get_pit_lane_snapshot()
		var crew_count: int = 0
		for car in ac:
			if str(car.get("pit_stage", "")) in ["dock", "service", "repair", "safety_hold"]:
				crew_count += 1
			if str(car.get("pit_stage", "")) == "queue":
				saw_queue = true
			if str(car.get("pit_stage", "")) == "safety_hold":
				saw_hold = true
		if crew_count > 1:
			check(false, "exclusive garage never serves both teammates simultaneously")
			break
		if int(ac[0]["stops"]) > 0 and int(ac[1]["stops"]) > 0 \
				and float(ac[0]["pit_left"]) <= 0.0 and float(ac[1]["pit_left"]) <= 0.0:
			saw_real_release = true
			break
	check(saw_queue and saw_hold and saw_real_release,
		"double stack queues during safety hold and both real stops exit")
	check(a.get_pit_history("Ferrari").size() == 2,
		"actual exit history records both stops, not pending queue")
	check(float(ac[1].get("pit_last_wait", 0.0)) > 0.0,
		"shared-garage queue costs actual race time")
	check(Codec.sporting_hash(a, {}) == Codec.sporting_hash(b, {}),
		"status reads and FIFO arbitration leave seeded sporting hashes deterministic")
	check(a.get_state_snapshot() == b.get_state_snapshot(),
		"same seed and commands produce equal pit service/exit results")
	# Historical v9.6 replays use the original order, not the 018 FIFO.
	var legacy_race = Race.new(season["teams"], "Ferrari", 700, {}, track, {})
	var recorder = Replay.new()
	recorder.attach(legacy_race)
	recorder.recorded_simulation_revision = Replay.SOUL_SIMULATION_REVISION
	recorder.legacy_pit_coordination = true
	recorder.legacy_start_intelligence = true
	recorder.race.pit_coordination2_enabled = false
	recorder.race.race_start_intelligence_enabled = false
	for i in range(14):
		check(recorder.step_tick(), "legacy 017 recording tick")
	var historical: Dictionary = recorder.export_data()
	var loaded = Replay.new()
	check(loaded.load_data(historical), "017 driver-soul archive still accepted")
	check(not bool(loaded.race.pit_coordination2_enabled)
		and bool(loaded.legacy_pit_coordination), "old queue arbitration applied on 017 playback")
	check(loaded.seek(14) and loaded.first_divergence < 0,
		"legacy replay hashes survive new 018 revision")
	if failures.is_empty():
		print("PIT_COORD_06697_PASS checks=%d" % checks)
	quit(0 if failures.is_empty() else 1)
