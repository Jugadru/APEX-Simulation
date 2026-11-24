extends SceneTree
const Codec = preload("res://scripts/core/race_state_codec_0660.gd")
const Motion = preload("res://scripts/apex_racecraft_0654.gd")
const FRAMES := 1875
const DELTA := 1.0/30.0
var failures := 0
func _initialize() -> void: call_deferred("run")
func percentile(values: Array, fraction: float) -> float:
	values.sort()
	return float(values[clampi(int(ceil(values.size()*fraction))-1,0,values.size()-1)])
func run_case(host, code: String, record: bool) -> Dictionary:
	for i in range(host.season_tracks.size()):
		if str(host.season_tracks[i].code)==code: host.selected_track_index=i
	host.seed_picker.value=42
	host.replay_recording_enabled=record
	host._start_race()
	host.set_process(false)
	host.race.running=true
	host.render_mode=1
	var times: Array = []
	var prior: Dictionary = {}
	var worst_jump := 0.0
	var overlaps := 0
	var holds := 0
	var frozen_samples := 0
	for i in range(FRAMES):
		var start := Time.get_ticks_usec()
		host._process(DELTA)
		times.append(Time.get_ticks_usec()-start)
		var poses: Dictionary = host.world_view.occupation
		if poses.size()!=24: failures+=1
		for id in poses:
			var p: Dictionary = poses[id]
			if bool(p.get("held",false)): holds+=1
			if prior.has(id):
				var step := Vector2(p.position).distance_to(Vector2(prior[id].position))
				worst_jump=maxf(worst_jump,step)
				if step<0.015: frozen_samples+=1
			for other in poses:
				if int(id)<int(other) and Motion.overlaps(p,poses[other]): overlaps+=1
		prior=poses.duplicate(true)
	var session = host.replay_session
	var result := {"track":code,"record":record,"frames":FRAMES,"ticks":session.tick,
		"hash":Codec.sporting_hash(host.race,session.policy),"pose_hash":Codec.digest(host.world_view.occupation),
		"stored_hashes":session.hashes.size(),"stored_checkpoints":session.checkpoints.size(),
		"cpu_p50_us":percentile(times.duplicate(),0.50),"cpu_p95_us":percentile(times.duplicate(),0.95),
		"worst_jump":worst_jump,"held":holds,"stationary_samples":frozen_samples,"overlaps":overlaps}
	host.race.running=false
	return result
func run() -> void:
	var reports: Array = []
	for code in ["GBR","MON","BEL"]:
		var pair: Array = []
		for record in [true,false]:
			# Fresh host in each case avoids prior garage/UI state leaking into the comparison.
			var host = load("res://scenes/main.tscn").instantiate()
			root.add_child(host)
			for i in range(5): await process_frame
			host.set_process(false)
			pair.append(run_case(host,code,record))
			host.queue_free()
			await process_frame
		var a: Dictionary=pair[0]
		var b: Dictionary=pair[1]
		if a.ticks!=b.ticks or a.ticks<1 or a.hash!=b.hash or a.pose_hash!=b.pose_hash:
			failures+=1
		if b.stored_hashes!=0 or b.stored_checkpoints!=0 or a.stored_hashes!=a.ticks:
			failures+=1
		if a.overlaps!=0 or b.overlaps!=0: failures+=1
		reports.append({"track":code,"with_recording":a,"without_recording":b})
	print("LIVE_3D_REPLAY_AB_09173_REPORT ",JSON.stringify({"cases":reports,"failures":failures}))
	if failures==0: print("LIVE_3D_REPLAY_AB_09173_PASS")
	quit(0 if failures==0 else 1)
