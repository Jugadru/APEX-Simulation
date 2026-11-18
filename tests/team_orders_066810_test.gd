extends SceneTree
## APEX 0.6.6.8.10: player-approved and cancellable team orders, replay contract.
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const RaceSpace = preload("res://scripts/core/race_space_0655.gd")
var checks := 0
var fails := 0
func _initialize() -> void: call_deferred("run")
func verify(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		fails += 1
		printerr("TEAM_ORDERS_066810_FAIL: " + label)
func make_race(seed: int):
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = {}
	for t in data.tracks:
		if str(t.code) == "GBR": track = t.duplicate(true)
	var race = Race.new(data.teams, "Ferrari", seed, {}, track, {})
	race.configure_weather("Seco")
	var rear: Dictionary = race.player_cars()[0]
	var front: Dictionary = race.player_cars()[1]
	rear.position = 2
	front.position = 1
	rear.progress = 0.394
	front.progress = 0.397
	rear.interval = 0.8
	front.interval = 0.0
	rear.last_lap = 99.0
	front.last_lap = 100.0
	rear.laps_done = 9
	front.laps_done = 9
	rear.wear = 37.0
	rear.tire = "Médio"
	rear.driver_soul.team_streak = 3
	return race
func run() -> void:
	var race = make_race(810)
	var rear: Dictionary = race.player_cars()[0]
	var front: Dictionary = race.player_cars()[1]
	var rid: int = int(rear.id)
	var fid: int = int(front.id)
	verify(race.team_yield_eligible(fid, rid), "Qualified teammate can ask")
	verify(not race.team_yield_eligible(rid, fid), "Reverse direction refused")
	verify(not race.team_yield_eligible(fid, fid), "Self order refused")
	verify(not race.team_yield_eligible(fid, 999), "Foreign teammate refused")
	rear.driver_soul.team_streak = 1
	verify(not race.team_yield_eligible(fid, rid), "Two faster laps are required")
	rear.driver_soul.team_streak = 3
	rear.interval = 2.5
	verify(not race.team_yield_eligible(fid, rid), "Unsafe distance refused")
	rear.interval = 0.8
	var before: PackedByteArray = var_to_bytes(race.get_state_snapshot())
	verify(race.team_yield_eligible(fid, rid), "Eligible after restoring evidence")
	verify(before == var_to_bytes(race.get_state_snapshot()), "Eligibility has no side effects")
	var s = Replay.new()
	s.attach(race)
	var compound: String = str(race.available_pit_compounds()[0])
	verify(s.enqueue("schedule_pit", [rid, compound, 21], 1), "Manual V21 queued")
	verify(s.enqueue("authorize_team_yield", [fid, rid], 1), "Player order queued")
	verify(not s.enqueue("authorize_team_yield", [fid, rid], 1), "Duplicate order refused")
	verify(not s.enqueue("authorize_team_yield", [rid, fid], 1), "Wrong leader refused")
	verify(int(front.team_yield_ticks) == 0, "No effect before tick")
	verify(s.step_tick(), "Order applied next tick")
	verify(int(front.team_yield_ticks) > 0 and int(front.team_yield_to_id) == rid, "15s instruction active")
	verify(int(rear.pit_scheduled_lap) == 21 and not bool(rear.pit_request), "BOX V21 preserved")
	verify(not race.team_yield_eligible(fid, rid), "Cannot overwrite active authorization")
	verify(s.enqueue("cancel_team_yield", [fid], s.tick + 1), "Cancellation queued")
	verify(not s.enqueue("cancel_team_yield", [fid], s.tick + 1), "Duplicate cancellation refused")
	verify(s.step_tick(), "Cancellation applied")
	verify(int(front.team_yield_ticks) == 0 and int(front.team_yield_to_id) == -1, "Cancellation clears order")
	verify(int(rear.pit_scheduled_lap) == 21, "Cancellation does not alter BOX")
	front.team_yield_to_id = rid
	front.team_yield_ticks = 1
	verify(s.step_tick(), "Expire after simulated time")
	verify(int(front.team_yield_ticks) == 0 and int(front.team_yield_to_id) == -1, "Order expires")
	var next = make_race(811)
	var r = Replay.new()
	r.attach(next)
	var a: int = int(next.player_cars()[1].id)
	var b: int = int(next.player_cars()[0].id)
	verify(r.enqueue("authorize_team_yield", [a, b], 1), "Replay command")
	for tick in range(100):
		if not r.step_tick():
			verify(false, "Tick failed " + str(tick))
			break
	var replay: Dictionary = r.export_data()
	verify(replay.simulation_revision == Replay.SIMULATION_REVISION, "Revision stamped")
	var playback = Replay.new()
	verify(playback.load_data(replay), "New command deserializes")
	verify(playback.seek(r.tick), "100 ticks replay deterministically")
	verify(playback.hashes[-1] == r.hashes[-1], "Sporting replay hash preserved")
	replay.simulation_revision = "06688_grip_aware_defense"
	verify(not Replay.new().load_data(replay), "Old rules explicitly rejected")
	var leader: Dictionary = next.player_cars()[1].duplicate(true)
	var chase: Dictionary = next.player_cars()[0].duplicate(true)
	leader.progress = 0.420
	chase.progress = 0.400
	leader.defense_aggression = 95.0
	leader.spatial_awareness = 85.0
	leader.team_yield_to_id = -1
	leader.team_yield_ticks = 0
	var metric := {int(leader.id): {"target": 90.0}, int(chase.id): {"target": 80.0}}
	var no_order: Dictionary = RaceSpace.plan([leader, chase], metric, 0.2, next.track, next.space_profile, {})
	leader.team_yield_to_id = int(chase.id)
	leader.team_yield_ticks = 60
	var authorized: Dictionary = RaceSpace.plan([leader, chase], metric, 0.2, next.track, next.space_profile, {})
	verify(absf(float(no_order[int(leader.id)].states.race_lane_goal)) > 0.1, "Without order leader attempts early block")
	verify(absf(float(authorized[int(leader.id)].states.race_lane_goal)) < 0.01, "With authorization leader holds line")
	verify(int(authorized[int(leader.id)].states.race_defending_against) == -1, "No preemptive blockade")
	verify(float(authorized[int(chase.id)].progress) >= float(chase.progress), "No backwards teleport")
	verify(int(leader.team_yield_ticks) == 60, "Solver is pure")
	if fails == 0: print("TEAM_ORDERS_066810_PASS checks=%d replay_ticks=%d" % [checks, r.tick])
	quit(0 if fails == 0 else 1)
