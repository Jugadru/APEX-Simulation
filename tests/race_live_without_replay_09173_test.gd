extends SceneTree
const Race = preload("res://scripts/race_engine.gd")
const Replay = preload("res://scripts/core/race_replay_0660.gd")
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
var failures := 0
func check(ok: bool, reason: String) -> void:
	if not ok:
		failures += 1
		printerr("LIVE_WITHOUT_REPLAY_09173_FAIL ",reason)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var season: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/season_2012.json"))
	var track: Dictionary = season.tracks[0]
	var a = Replay.new()
	var b = Replay.new()
	var first = Race.new(season.teams,"Ferrari",6617,{},track,{})
	var second = Race.new(season.teams,"Ferrari",6617,{},track,{})
	var modes := {}
	for car in first.player_cars(): modes[int(car.id)] = "Automático"
	a.attach(first,modes,{},true)
	b.attach(second,modes,{},false)
	var id: int = int(first.player_cars()[0].id)
	var on_us := 0
	var off_us := 0
	for i in range(310):
		if i == 10:
			check(a.enqueue("driver_control",[id,"Manual"]) and b.enqueue("driver_control",[id,"Manual"]),"manual command queued")
		if i == 12:
			check(a.enqueue("set_pace",[id,"Atacar"]) and b.enqueue("set_pace",[id,"Atacar"]),"pace command queued")
		if i == 20:
			check(a.enqueue("schedule_pit",[id,first.available_pit_compounds()[0],21]) and b.enqueue("schedule_pit",[id,second.available_pit_compounds()[0],21]),"V21 queued")
		var started := Time.get_ticks_usec()
		check(a.step_tick(),"recorded tick")
		on_us += Time.get_ticks_usec()-started
		started = Time.get_ticks_usec()
		check(b.step_tick(),"live tick")
		off_us += Time.get_ticks_usec()-started
		check(Codec.sporting_hash(first,a.policy)==Codec.sporting_hash(second,b.policy),"sporting parity tick %d" % i)
	check(b.hashes.is_empty() and b.checkpoints.is_empty() and b.commands.is_empty(),"no retained recording data")
	check(b.export_data().is_empty(),"export disabled")
	check(not Replay.new().load_live_session(b),"watch disabled")
	check(a.hashes.size()==310 and a.checkpoints.size()>1,"recording QA still supported")
	print("LIVE_WITHOUT_REPLAY_09173_REPORT ",JSON.stringify({"ticks":310,"recording_us":on_us,"live_only_us":off_us,"failures":failures}))
	if failures==0: print("LIVE_WITHOUT_REPLAY_09173_PASS")
	quit(0 if failures==0 else 1)
