extends SceneTree
const O = preload("res://scripts/core/race_overtaking_intelligence_066912.gd")
const P = preload("res://scripts/core/race_revision_policy_0923.gd")
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if not ok: failures.append(label); printerr("073_FAIL ",label)
func run() -> void:
	var car: Dictionary = {"id":1,"progress":0.1,"risk_tolerance":55.0,"combat_state":"closing"}
	var rival: Dictionary = {"id":2}
	var track: Dictionary = {"overtake_zones":[[0.2,0.4]]}
	var dry: Dictionary = {"wetness_factor":0.0}
	var before: PackedByteArray = var_to_bytes([car,rival,track,dry])
	var plan: Dictionary = O.prepare(car,rival,20.0,0.6,90.0,track,dry,0.2)
	check(plan.reason=="wait_zone" and not plan.ready,"outside passing zone")
	check(before==var_to_bytes([car,rival,track,dry]),"frozen observations")
	car.progress=0.19
	plan=O.prepare(car,rival,20.0,0.6,90.0,track,dry,0.2)
	check(plan.reason=="approach_zone" and not plan.ready,"anticipation without premature attack")
	car.progress=0.22
	for i in range(12):
		plan=O.prepare(car,rival,20.0,0.6,90.0,track,dry,0.2)
		car[O.PREPARATION_KEY]=plan
	check(plan.ready and O.preparation_allows(plan,{"threshold_s":0.2},0.0),"sustained relative pace")
	var changed: Dictionary = O.prepare(car,{"id":3},20.0,0.6,90.0,track,dry,0.2)
	check(changed.stable_s==0.0 and not changed.ready,"target change resets evidence")
	check(not O.preparation_allows(plan,{"threshold_s":0.8},0.0),"existing risk threshold preserved")
	car.combat_state="duel";car.combat_target_id=2
	plan=O.prepare(car,rival,6.4,-0.1,90.0,track,dry,0.2)
	check(O.preparation_allows(plan,{"threshold_s":0.8},1.0),"established duel not vetoed")
	check(P.capability_mask(Replay.OVERTAKING_PREPARATION_SIMULATION_REVISION)==(P.capability_mask(Replay.SIMULATION_REVISION)|P.OVERTAKING_PREPARATION),"isolated sporting revision")
	var season: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var real_track: Dictionary=season.tracks[0]
	var a=Race.new(season.teams,"Ferrari",73,{},real_track,{})
	var b=Race.new(season.teams,"Ferrari",73,{},real_track,{})
	var legacy=Race.new(season.teams,"Ferrari",73,{},real_track,{})
	var sa=Replay.new();sa.attach(a,{}, {},false)
	var sb=Replay.new();sb.attach(b,{}, {},false)
	var sl=Replay.new();sl.attach(legacy,{}, {},false)
	sa.recorded_simulation_revision=Replay.OVERTAKING_PREPARATION_SIMULATION_REVISION
	sb.recorded_simulation_revision=Replay.OVERTAKING_PREPARATION_SIMULATION_REVISION
	var observed: bool=false
	for i in range(220):
		if not sa.step_tick() or not sb.step_tick() or not sl.step_tick():
			check(false,"tick rejected");break
		for driver in a.cars:
			if not driver.get(O.PREPARATION_KEY,{}).is_empty(): observed=true
	check(observed,"actual race emits preparation observation")
	check(Codec.sporting_hash(a,sa.policy)==Codec.sporting_hash(b,sb.policy),"same seed deterministic")
	for driver in legacy.cars: check(not driver.has(O.PREPARATION_KEY),"041 untouched")
	if failures.is_empty(): print("OVERTAKING_PREPARATION_073_PASS")
	quit(0 if failures.is_empty() else 1)
