extends SceneTree
const Tactics = preload("res://scripts/core/race_driver_dynamics_0661.gd")
const Space = preload("res://scripts/core/race_space_0655.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Race = preload("res://scripts/race_engine.gd")
var checks: int = 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	assert(value, message)
func car(id: int, progress: float, pace: float) -> Dictionary:
	return {"id": id, "progress": progress, "race_lane": 0.0,
		"pit_left": 0.0, "finished": false, "skill": 84,
		"risk_tolerance": 65.0, "spatial_awareness": 89.0, "defense_aggression": 60.0,
		"attack_charge": 1.5, "combat_state": "closing", "combat_target_id": -1,
		"combat_attempts": 0, "combat_pass_pending": false,
		"combat_hesitation_s": 0.0, "wear": 12.0,
		"combat_cooldown": 0.0, "race_defending_against": -1,
		"race_defense_line": 0.0, "target_pace": pace}
func run() -> void:
	var track: Dictionary = {"code":"TEST","race_width_m":14.0, "overtake_zones":[[0.0,1.0]]}
	var shape: Dictionary = {"length":1200.0}
	var weather: Dictionary = {"wetness_factor":0.0}
	var challenger: Dictionary = car(1,0.350,88.0)
	var leader: Dictionary = car(2,0.361,91.0)
	var a: Dictionary = Tactics.choose(challenger,leader,13.2,3.0,2.95,track,weather)
	check(bool(a.commit), "Faster driver attacks with clear width")
	check(bool(a.defense), "Early defense is offered")
	check(float(a.margin_m) > 0.0, "Two-car corridor actually fits")
	leader.race_defending_against = 1
	leader.race_defense_line = float(a.defend_goal)
	leader.race_lane = float(a.defend_goal)
	var held: Dictionary = Tactics.choose(challenger,leader,8.0,3.0,2.95,track,weather)
	check(is_equal_approx(float(held.defend_goal),float(a.defend_goal)), "No second defensive change at overlap")
	var overlap_pair: Array = [leader.duplicate(true),challenger.duplicate(true)]
	overlap_pair[0].progress = 0.358
	overlap_pair[1].progress = 0.350
	var locked_plan: Dictionary = Space.plan(overlap_pair,
			{1:{"target":88.0},2:{"target":91.0}},0.2,
			{"code":"TEST","race_width_m":14.0,"overtake_zones":[[0.0,1.0]]},
			{"length":1000.0},weather)
	check(is_equal_approx(float(locked_plan[2].states.race_lane), float(overlap_pair[0].race_lane)),
			"Defender cannot weave back into overlapping attacker")
	var narrow: Dictionary = Tactics.choose(challenger,leader,8.0,3.0,1.00,track,weather)
	check(not bool(narrow.commit), "Narrow corners cannot support two lanes")
	var cautious: Dictionary = challenger.duplicate(true)
	var bold: Dictionary = challenger.duplicate(true)
	cautious.risk_tolerance = 25.0
	bold.risk_tolerance = 85.0
	var cautious_threshold: float = Tactics.choose(cautious,leader,15.0,0.3,2.95,track,weather).threshold_s
	var bold_threshold: float = Tactics.choose(bold,leader,15.0,0.3,2.95,track,weather).threshold_s
	check(bold_threshold < cautious_threshold, "Risk appetite changes commitment, not raw car speed")
	var wet_threshold: float = Tactics.choose(challenger,leader,15.0,0.3,2.95,track,{"wetness_factor":0.9}).threshold_s
	var dry_threshold: float = Tactics.choose(challenger,leader,15.0,0.3,2.95,track,weather).threshold_s
	check(wet_threshold > dry_threshold, "Wet track increases caution")
	var crowded: Dictionary = challenger.duplicate(true)
	crowded.spatial_awareness = 55.0
	check(Tactics.choose(crowded,leader,15.0,0.3,2.95,track,weather).threshold_s >= dry_threshold,
		"Spatial awareness cannot make wet braking less cautious")
	# Snapshot parity and determinism of the actual corridor solver.
	var pair: Array = [leader.duplicate(true),challenger.duplicate(true)]
	var metrics: Dictionary = {1:{"target":88.0},2:{"target":91.0}}
	var state_a: Dictionary = Space.plan(pair,metrics,0.2,track,shape,weather)
	var state_b: Dictionary = Space.plan(pair.duplicate(true),metrics.duplicate(true),0.2,track,shape,weather.duplicate(true))
	check(var_to_bytes(state_a) == var_to_bytes(state_b),"Frozen tactical inputs produce identical outcomes")
	check(pair[0].progress == leader.progress and pair[1].progress == challenger.progress,"Solver does not mutate snapshots")
	check(state_a[1].progress >= challenger.progress and state_a[2].progress >= leader.progress,"No negative progress impulse")
	check(int(state_a[1].states.combat_target_id) == 2,"Correct target recorded for 3D/HUD")
	# A lapped car or a car entering pits must not be forcibly moved by visuals.
	pair[0].pit_left = 6.0
	var ignored: Dictionary = Space.plan(pair,metrics,0.2,track,shape,weather)
	check(not ignored.has(2) and ignored.has(1),"Pit car is removed from sporting traffic")
	# Fresh replays carry the simulation rules revision; legacy traces fail early.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var race = Race.new(data.teams,"Ferrari",661,{},data.tracks[0],{})
	var session = Replay.new()
	session.attach(race)
	var payload: Dictionary = session.export_data()
	check(payload.simulation_revision == "0661_driver_dynamics","Revision stamped in replay")
	payload.erase("simulation_revision")
	var incompatible = Replay.new()
	check(not incompatible.load_data(payload),"0.6.6.0 trace rejected without false playback")
	check(incompatible.error.contains("outra revisão"),"Explanation included")
	print("DRIVER_DYNAMICS_0661_PASS ",{"checks":checks,"seed":661,"pure":true})
	quit()
