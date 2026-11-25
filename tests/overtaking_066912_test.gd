extends SceneTree
## APEX v0.6.6.9.12 — deterministic overtaking, real corridor and replay 022/023.
const Overtaking = preload("res://scripts/core/race_overtaking_intelligence_066912.gd")
const Space = preload("res://scripts/core/race_space_0655.gd")
const Merge = preload("res://scripts/core/race_merge_traffic_0669174.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, reason: String) -> void:
	checks += 1
	if not ok:
		failures.append(reason)
		printerr("OVERTAKING_066912_FAIL " + reason)

func car(id: int, progress: float, lane: float = 0.0) -> Dictionary:
	return {"id":id,"progress":progress,"race_lane":lane,
		"pit_left":0.0,"finished":false,"skill":88,
		"risk_tolerance":65.0,"spatial_awareness":90.0,
		"defense_aggression":20.0,"attack_charge":1.8,
		"combat_state":"closing","combat_target_id":-1,
		"combat_attempts":0,"combat_pass_pending":false,
		"combat_hesitation_s":0.0,"wear":12.0,
		"combat_cooldown":0.0,"race_defending_against":-1,
		"race_defense_line":0.0}

func _track(season: Dictionary, code: String) -> Dictionary:
	for item in season["tracks"]:
		if str(item.get("code", "")) == code:
			return item
	return {}

# Test-only oracle: the two separate pre-3.1 signed-gap scans.
func reference_neighbors(subject: Dictionary, grid: Array, length: float,
		include_following: bool, wake_stability: bool, wake_range: float) -> Dictionary:
	var id: int=int(subject.id)
	var nearest: Dictionary={}
	var following_gap: float=INF
	if include_following:
		for other in grid:
			if other.id==id: continue
			var g: float=Merge.relative_gap(float(subject.progress),float(other.progress),length)
			if absf(g)<=0.000001:
				if Merge.has_priority(subject,other): continue
				g=0.0
			if g>=0.0 and g<following_gap:
				following_gap=g
				nearest=other
	var leader: Dictionary={}
	var independent_gap: float=INF
	var wake_candidates: Array=[]
	for other in grid:
		if other.id==id: continue
		var g: float=Merge.relative_gap(float(subject.progress),float(other.progress),length)
		if wake_stability and (wake_range==INF or (g>0.0 and g<=wake_range+0.000001)):
			wake_candidates.append(other)
		if g>0.000001 and g<independent_gap and g<=38.0:
			independent_gap=g
			leader=other
	return {"nearest":nearest,"following_gap":following_gap,"leader":leader,"independent_gap":independent_gap,"wake_candidates":wake_candidates}

func tactical_neighbor_fixture() -> void:
	var rng:=RandomNumberGenerator.new()
	rng.seed=93101
	for scenario in range(48):
		var length: float=1000.0 if scenario%2==0 else 5300.0
		var center: float=1.0 if scenario%3==0 else (-0.01 if scenario%3==1 else 0.4)
		var grid: Array=[]
		for i in range(24):
			var p: float=center+rng.randf_range(-60.0,60.0)/length
			grid.append(car(i,p,float(i%3-1)*2.95))
		# Equal progress, lap-separated equal arc, tiny signed separation,
		# equal positive gaps, and exact range boundaries.
		grid[0].progress=center
		grid[1].progress=center
		grid[2].progress=center+1.0
		grid[3].progress=center+0.0000005/length
		grid[4].progress=center+38.0/length
		grid[5].progress=grid[4].progress
		grid[6].progress=center+13.0/length
		if scenario%4==0: grid.resize(1)
		if scenario%2==0: grid.reverse()
		var wake_range: float=INF if scenario%4==0 else (13.0 if scenario%4==1 else 38.0)
		var frozen: PackedByteArray=var_to_bytes(grid)
		for subject in grid:
			for include_following in [false,true]:
				for wake_stability in [false,true]:
					var expected: Dictionary=reference_neighbors(subject,grid,length,include_following,wake_stability,wake_range)
					var actual: Dictionary=Space.tactical_neighbors(subject,grid,length,include_following,wake_stability,wake_range)
					check(var_to_bytes(actual)==var_to_bytes(expected),"tactical neighbor differential %d/%d/%s/%s" % [scenario,subject.id,include_following,wake_stability])
		check(var_to_bytes(grid)==frozen,"tactical neighbor frozen input %d" % scenario)
	var singleton: Dictionary=car(99,0.0)
	check(Space.tactical_neighbors(singleton,[],1000.0,true,true,INF)==reference_neighbors(singleton,[],1000.0,true,true,INF),"empty neighbor input")
	var tied: Array=[car(8,0.5),car(2,0.5),car(4,0.5+10.0/1000.0),car(3,0.5+10.0/1000.0)]
	var obs: Dictionary=Space.tactical_neighbors(tied[0],tied,1000.0,true,true,INF)
	check(obs.nearest.id==2 and obs.following_gap==0.0 and obs.leader.id==4,"following tie priority and independent first-in-order tie remain distinct")
	check(obs.wake_candidates.size()==3,"infinite wake range preserves all non-self candidates in order")

func _run() -> void:
	tactical_neighbor_fixture()
	var attacker: Dictionary = car(1, 0.350)
	attacker["combat_target_id"] = 2 # Established target retains earned charge.
	var defender: Dictionary = car(2, 0.370)
	var blocker: Dictionary = car(3, 0.346, 1.0)
	var dry: Dictionary = {"wetness_factor":0.0}
	var tactic: Dictionary = {"commit":true,"attack_goal":2.95,
		"defend_goal":0.0,"side":"right","margin_m":0.0,
		"threshold_s":0.15,"blocked":false}
	var grid: Array = [attacker, defender, blocker]
	var before: PackedByteArray = var_to_bytes([grid, dry, tactic])
	var choice: Dictionary = Overtaking.refine(attacker,defender,grid,
		20.0,0.65,2.95,1000.0,dry,tactic)
	check(bool(choice.get("commit",false))
		and str(choice.get("side","")) == "left"
		and is_equal_approx(float(choice.get("attack_goal",0.0)),-2.95),
		"early attacker avoids third car and chooses viable opposite side")
	check(str(choice.get("overtaking_reason","")) == "early_clear_side",
		"explicit decision reason is deterministic")
	check(choice == Overtaking.refine(attacker,defender,grid,
		20.0,0.65,2.95,1000.0,dry,tactic),
		"same observations produce same choice")
	check(var_to_bytes([grid,dry,tactic]) == before,
		"decision does not mutate inputs")
	var both: Array = grid.duplicate(true)
	both.append(car(4,0.345,-1.0))
	var blocked: Dictionary = Overtaking.refine(attacker,defender,both,
		20.0,0.65,2.95,1000.0,dry,tactic)
	check(not bool(blocked.get("commit",true))
		and bool(blocked.get("blocked",false)),
		"two occupied corridors cancel unsafe attack")
	var established: Dictionary = attacker.duplicate(true)
	established["race_lane"] = 1.15
	check(not bool(Overtaking.refine(established,defender,grid,
		20.0,0.65,2.95,1000.0,dry,tactic).get("commit",true)),
		"no crossing to far lane after attacker leaves center")
	var overlapping: Dictionary = attacker.duplicate(true)
	overlapping["combat_state"] = "duel"
	check(Overtaking.refine(overlapping,defender,grid,8.0,0.65,
		2.95,1000.0,dry,tactic).get("attack_goal") == 2.95,
		"committed overlap preserves established side")
	var wet: Dictionary = {"wetness_factor":0.85}
	var marginal: Dictionary = Overtaking.refine(attacker,defender,
		[attacker,defender],20.0,0.16,2.95,1000.0,wet,tactic)
	check(not bool(marginal.get("commit",true)),
		"wet narrow advantage is not a free overtaking opportunity")
	var no_base: Dictionary = tactic.duplicate(true)
	no_base["commit"] = false
	check(not bool(Overtaking.refine(attacker,defender,
		grid,20.0,2.0,2.95,1000.0,dry,no_base).get("commit",true)),
		"9.12 cannot turn a rejected baseline attack into a scripted pass")
	var track: Dictionary = {"code":"TEST","race_width_m":14.0,
		"overtake_zones":[[0.0,1.0]]}
	var metrics: Dictionary = {1:{"target":85.0},2:{"target":92.0},
		3:{"target":97.0}}
	var legacy: Dictionary = Space.plan(grid,metrics,0.2,track,
		{"length":1000.0},dry,true,true,false)
	var modern: Dictionary = Space.plan(grid,metrics,0.2,track,
		{"length":1000.0},dry,true,true,true)
	check(str(legacy[1].states.combat_last_side) == "right"
		and str(modern[1].states.combat_last_side) == "left",
		"real RaceSpace uses 9.12 only when the revision switch is enabled")
	check(float(modern[1].progress) >= float(attacker.progress)
		and float(modern[2].progress) >= float(defender.progress)
		and float(modern[3].progress) >= float(blocker.progress),
		"new tactical planning never teleports cars backwards")
	check(var_to_bytes([grid,dry,tactic]) == before,
		"authoritative corridor planning preserves frozen inputs")

	var season_value: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/season_2012.json"))
	if not season_value is Dictionary:
		check(false,"2012 season JSON")
		_finish()
		return
	var season: Dictionary = season_value
	check(season["tracks"].size() == 20,
		"2012 season includes all 20 circuits")
	var silverstone: Dictionary = _track(season,"GBR")
	var monaco: Dictionary = _track(season,"MON")
	check(not silverstone.is_empty() and not monaco.is_empty(),
		"Silverstone and Monaco available for regression")
	if silverstone.is_empty() or monaco.is_empty():
		_finish()
		return
	var first = Race.new(season["teams"],"Ferrari",6612,{},silverstone,{})
	var second = Race.new(season["teams"],"Ferrari",6612,{},silverstone,{})
	check(first.cars.size() == 24 and second.cars.size() == 24,
		"actual season runs 24 drivers")
	check(not Codec.capture(first)["engine"].has("overtaking_intelligence_enabled")
		and Codec.restore(Codec.capture(first)) != null,
		"new session-only rule leaves save/checkpoint schema intact")
	var a = Replay.new()
	a.attach(first)
	var b = Replay.new()
	b.attach(second)
	check(a.recorded_simulation_revision == Replay.SIMULATION_REVISION
		and first.overtaking_intelligence_enabled,
		"new replay records sporting revision 023")
	var ticks_ok: bool = true
	for tick in range(140):
		if not a.step_tick() or not b.step_tick():
			ticks_ok = false
			break
	check(ticks_ok,"two identical live race sessions can advance")
	check(Codec.sporting_hash(first,a.policy) == Codec.sporting_hash(second,b.policy),
		"new replay revision produces equal 24-car sporting hashes")
	var viewer = Replay.new()
	check(viewer.load_data(a.export_data())
		and viewer.seek(a.end_tick) and viewer.first_divergence < 0,
		"023 replay hash and seek parity")

	var old = Replay.new()
	old.attach(Race.new(season["teams"],"Ferrari",6612,{},silverstone,{}))
	old.recorded_simulation_revision = Replay.PRE_OVERTAKING_SIMULATION_REVISION
	old.legacy_overtaking_intelligence = true
	old.race.overtaking_intelligence_enabled = false
	old.checkpoints = [old.checkpoint()]
	for tick in range(140):
		if not old.step_tick():
			check(false,"022 archived race can advance")
			break
	var old_viewer = Replay.new()
	check(old_viewer.load_data(old.export_data())
		and old_viewer.legacy_overtaking_intelligence
		and not old_viewer.legacy_start_intelligence
		and not old_viewer.race.overtaking_intelligence_enabled
		and old_viewer.race.race_start_intelligence_enabled
		and old_viewer.seek(old.end_tick)
		and old_viewer.first_divergence < 0,
		"022 replay preserves 9.11 launch and its original overtaking logic")
	var local_viewer = Replay.new()
	check(local_viewer.load_live_session(old)
		and local_viewer.legacy_overtaking_intelligence
		and local_viewer.seek(old.end_tick)
		and local_viewer.first_divergence < 0,
		"live-session fork preserves original 022 tactical rules")

	var rainy = Race.new(season["teams"],"Ferrari",6613,{},monaco,{})
	rainy.configure_weather("Chuva intensa")
	var player: Dictionary = rainy.player_cars()[0]
	check(rainy.schedule_pit(int(player.id),
		str(rainy.available_pit_compounds()[1]),21),
		"BOX V21 remains available with 9.12 enabled")
	rainy.running = true
	for i in range(40):
		rainy.step(0.2)
	check(int(player.get("pit_scheduled_lap",0)) == 21
		and not bool(player.get("pit_request",false))
		and int(player.get("stops",0)) == 0,
		"wet Monaco race cannot advance manual BOX V21")
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("OVERTAKING_066912_PASS checks=%d" % checks)
	else:
		for message in failures:
			printerr("FAIL: " + message)
	quit(0 if failures.is_empty() else 1)
